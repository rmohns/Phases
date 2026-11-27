import Foundation

/// [D-aerials-untouched] [D-store-unreadable-safe] [D-restore-file-check]
/// What Phases knows about each display's wallpaper from macOS's wallpaper
/// store, and what Quit does with it. Foundation only, so the unit tests
/// can reach it [D-tests-unhosted]; `SystemWallpaperInspector` and
/// `RestorePoint` supply the store and the screens.
enum SystemWallpaperCheck {
  /// [Q-wallpaper-store] The store's folder, in the user's real home.
  /// [Q-sandbox-container-home] Never `homeDirectoryForCurrentUser`, which
  /// points into the container when sandboxed.
  static func storeFolder(home: URL = SourceLocation.realHome) -> URL {
    home.appending(path: "Library/Application Support/com.apple.wallpaper/Store", directoryHint: .isDirectory)
  }

  static func storeFile(home: URL = SourceLocation.realHome) -> URL {
    storeFolder(home: home).appending(path: "Index.plist")
  }

  private static let imageProvider = "com.apple.wallpaper.choice.image"

  /// Each display's wallpaper kind.
  /// - Parameters:
  ///   - storeData: the store file's contents, or nil if it couldn't be read.
  ///   - displays: display ID to hardware UUID; nil when the UUID is unknown.
  static func kinds(storeData: Data?, displays: [UInt32: String?]) -> [UInt32: WallpaperKind] {
    readings(storeData: storeData, displays: displays).mapValues(\.kind)
  }

  /// Each display's kind, with the store entry that decided it (for the
  /// diagnostics log).
  static func readings(storeData: Data?, displays: [UInt32: String?]) -> [UInt32: KindReading] {
    // [D-store-unreadable-safe] Couldn't read is not "no Aerials".
    guard let storeData,
      let store = try? PropertyListSerialization.propertyList(from: storeData, format: nil) as? [String: Any]
    else {
      return displays.mapValues { _ in KindReading(kind: .unchecked, decidedBy: nil, entryCount: 0) }
    }
    return displays.mapValues { uuid in
      guard let uuid else { return KindReading(kind: .unchecked, decidedBy: nil, entryCount: 0) }
      let entries = desktopEntries(in: store, displayUUID: uuid)
      // [Q-store-kind-lastset] The latest pick decides: LastSet, not
      // LastUse, which macOS moves on many entries at once. LastUse only
      // breaks ties.
      let latest = entries.max { ($0.lastSet, $0.lastUse) < ($1.lastSet, $1.lastUse) }
      guard let latest else { return KindReading(kind: .unchecked, decidedBy: nil, entryCount: 0) }
      return KindReading(kind: latest.provider == imageProvider ? .image : .system, decidedBy: latest, entryCount: entries.count)
    }
  }

  /// What Quit does with one display's recorded original.
  static func restoreAction(kind: WallpaperKind, imagePath: String?, file: FileState) -> RestoreAction {
    switch kind {
    case .system: return .leaveAlone(.systemWallpaper)
    case .unchecked: return .leaveAlone(.unchecked)
    case .image: break
    }
    guard imagePath != nil else { return .leaveAlone(.noImage) }
    // [D-restore-file-check] Only "no such file" skips; "not allowed to
    // look" still restores, since macOS can set a file Phases can't read
    // [Q-sandbox-set-unreadable-file].
    return file == .missing ? .leaveAlone(.fileMissing) : .restore
  }

  /// Whether a file exists, telling "no such file" apart from "not allowed
  /// to look" (the sandbox refuses even `stat` outside what it grants).
  static func fileState(atPath path: String) -> FileState {
    var info = stat()
    if stat(path, &info) == 0 { return .exists }
    switch errno {
    case ENOENT, ENOTDIR: return .missing
    default: return .unknown
    }
  }

  // MARK: - Reading the store

  /// One desktop configuration from the store.
  struct DesktopEntry: Equatable {
    /// Where in the store it sits, such as `Displays` or `Space <id> Default`.
    var place: String
    var provider: String
    var lastSet: Date
    var lastUse: Date
  }

  /// Every desktop configuration that could apply to the display: all-displays,
  /// per-display, and per-Space settings. The format is undocumented
  /// [Q-wallpaper-store], so this is best-effort.
  private static func desktopEntries(in store: [String: Any], displayUUID: String) -> [DesktopEntry] {
    var containers: [(String, Any?)] = [("AllSpacesAndDisplays", store["AllSpacesAndDisplays"])]
    containers.append(("Displays", (store["Displays"] as? [String: Any])?[displayUUID]))
    for case let (spaceID, space as [String: Any]) in (store["Spaces"] as? [String: Any]) ?? [:] {
      let name = spaceID.isEmpty ? "\"\"" : String(spaceID.prefix(8))
      containers.append(("Space \(name) Default", space["Default"]))
      containers.append(("Space \(name) Displays", (space["Displays"] as? [String: Any])?[displayUUID]))
    }
    return containers.compactMap { place, container in
      guard let desktop = (container as? [String: Any])?["Desktop"] as? [String: Any],
        let content = desktop["Content"] as? [String: Any],
        let choice = (content["Choices"] as? [[String: Any]])?.first,
        let provider = choice["Provider"] as? String
      else { return nil }
      return DesktopEntry(
        place: place,
        provider: provider,
        lastSet: desktop["LastSet"] as? Date ?? .distantPast,
        lastUse: desktop["LastUse"] as? Date ?? .distantPast
      )
    }
  }
}

/// A display's kind and the store entry that decided it.
struct KindReading: Equatable {
  var kind: WallpaperKind
  /// Nil when the store couldn't be read or had no entry for the display.
  var decidedBy: SystemWallpaperCheck.DesktopEntry?
  /// How many entries could apply to the display.
  var entryCount: Int
}

/// [D-store-unreadable-safe] A display's wallpaper as far as the store says.
enum WallpaperKind: String, Codable, Equatable {
  /// A still image, which Quit can put back.
  case image
  /// An Aerial, dynamic, or other system wallpaper [D-aerials-untouched].
  case system
  /// The store couldn't be read, or has no entry for the display.
  case unchecked
}

enum FileState: Equatable {
  case exists
  /// macOS says there's no such file.
  case missing
  /// Phases isn't allowed to look (or some other error).
  case unknown
}

enum RestoreAction: Equatable {
  case restore
  case leaveAlone(Reason)

  enum Reason: String, Equatable {
    case systemWallpaper = "system wallpaper"
    case unchecked = "couldn't check the wallpaper store"
    case noImage = "no image recorded"
    case fileMissing = "file no longer exists"
  }
}
