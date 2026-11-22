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
    // [D-store-unreadable-safe] Couldn't read is not "no Aerials".
    guard let storeData,
      let store = try? PropertyListSerialization.propertyList(from: storeData, format: nil) as? [String: Any]
    else {
      return displays.mapValues { _ in .unchecked }
    }
    return displays.mapValues { uuid in
      guard let uuid else { return .unchecked }
      let latest = desktopEntries(in: store, displayUUID: uuid).max { $0.lastUse < $1.lastUse }
      guard let latest else { return .unchecked }
      return latest.provider == imageProvider ? .image : .system
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
    // look" still restores, since macOS can set a file Phases can't read.
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

  private struct DesktopEntry {
    var provider: String
    var lastUse: Date
  }

  /// Every desktop configuration that could apply to the display: all-displays,
  /// per-display, and per-Space settings. The format is undocumented
  /// [Q-wallpaper-store], so this is best-effort.
  private static func desktopEntries(in store: [String: Any], displayUUID: String) -> [DesktopEntry] {
    var containers: [Any?] = [store["AllSpacesAndDisplays"]]
    containers.append((store["Displays"] as? [String: Any])?[displayUUID])
    for case let space as [String: Any] in (store["Spaces"] as? [String: Any])?.values ?? [:].values {
      containers.append(space["Default"])
      containers.append((space["Displays"] as? [String: Any])?[displayUUID])
    }
    return containers.compactMap { container in
      guard let desktop = (container as? [String: Any])?["Desktop"] as? [String: Any],
        let content = desktop["Content"] as? [String: Any],
        let choice = (content["Choices"] as? [[String: Any]])?.first,
        let provider = choice["Provider"] as? String
      else { return nil }
      let lastUse = desktop["LastUse"] as? Date ?? desktop["LastSet"] as? Date ?? .distantPast
      return DesktopEntry(provider: provider, lastUse: lastUse)
    }
  }
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
