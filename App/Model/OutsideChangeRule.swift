import Foundation

/// [D-outside-change-rule] Tells a wallpaper picked outside Phases from
/// Phases' own sets and from macOS's bookkeeping, by comparing two readings
/// of macOS's wallpaper store. Pure, so the unit tests can test it.
enum OutsideChangeRule {
  /// How long after Phases sets an image the store's matching write still
  /// counts as Phases' own. The write lands about 0.25 s after the set
  /// (`[L-store-watch]`); the margin covers a busy Mac.
  static let ownSetWindow: TimeInterval = 10

  /// The outside changes between two readings. An entry counts when its
  /// "last set" time moved and its image isn't one Phases set there just
  /// now. "Last used"-only writes (System Settings opening or quitting, a
  /// Space switch) never count, and nothing counts against an empty
  /// earlier reading, which means the store couldn't be read.
  static func changes(
    from old: [String: WallpaperStoreEntry], to new: [String: WallpaperStoreEntry],
    ownSets: [OwnWallpaperSet], now: Date
  ) -> [OutsideChange] {
    guard !old.isEmpty else { return [] }
    var found: [OutsideChange] = []
    for key in new.keys.sorted() {
      guard let entry = new[key], let lastSet = entry.lastSet else { continue }
      if let previous = old[key]?.lastSet, lastSet <= previous { continue }
      if isOwn(entry, ownSets: ownSets, now: now) { continue }
      let change = OutsideChange(displayUUID: entry.displayUUID, fileName: entry.fileName, isImage: entry.isImage)
      if !found.contains(change) { found.append(change) }
    }
    return found
  }

  private static func isOwn(_ entry: WallpaperStoreEntry, ownSets: [OwnWallpaperSet], now: Date) -> Bool {
    guard entry.isImage, let fileName = entry.fileName else { return false }
    return ownSets.contains { set in
      set.fileName == fileName
        && (entry.displayUUID == nil || entry.displayUUID == set.displayUUID)
        && now.timeIntervalSince(set.date) <= ownSetWindow
    }
  }
}

/// One Desktop entry in macOS's wallpaper store.
struct WallpaperStoreEntry: Equatable {
  /// The display it's for, or nil for an entry covering every display.
  var displayUUID: String?
  /// A still image, as opposed to an Aerial, dynamic, or other system wallpaper.
  var isImage: Bool
  /// The image's file name, when the entry names a file.
  var fileName: String?
  var lastSet: Date?
}

/// A wallpaper Phases set, noted so its store write isn't taken for an
/// outside change.
struct OwnWallpaperSet: Equatable {
  var displayUUID: String
  var fileName: String
  var date: Date
}

/// A wallpaper picked outside Phases.
struct OutsideChange: Equatable {
  /// The display it was picked for, or nil for every display.
  var displayUUID: String?
  var fileName: String?
  var isImage: Bool
}

/// Reads macOS's wallpaper store (read only, `[D-aerials-untouched]`). The
/// format is undocumented, so this is best-effort; an unreadable store reads
/// as no entries.
enum WallpaperStoreReader {
  static let imageProvider = "com.apple.wallpaper.choice.image"

  /// Every Desktop entry, keyed by where it sits in the store: "all",
  /// "display/<uuid>", "space/<id>/default", or "space/<id>/<uuid>".
  static func entries(fromPlist data: Data) -> [String: WallpaperStoreEntry] {
    guard let store = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
      return [:]
    }
    return entries(in: store)
  }

  static func entries(in store: [String: Any]) -> [String: WallpaperStoreEntry] {
    var entries: [String: WallpaperStoreEntry] = [:]
    func add(_ container: Any?, key: String, displayUUID: String?) {
      guard let desktop = (container as? [String: Any])?["Desktop"] as? [String: Any] else { return }
      let choice = ((desktop["Content"] as? [String: Any])?["Choices"] as? [[String: Any]])?.first
      entries[key] = WallpaperStoreEntry(
        displayUUID: displayUUID,
        isImage: choice?["Provider"] as? String == imageProvider,
        fileName: (choice?["Configuration"] as? Data).flatMap(fileName(inConfiguration:)),
        lastSet: desktop["LastSet"] as? Date
      )
    }
    add(store["AllSpacesAndDisplays"], key: "all", displayUUID: nil)
    for (uuid, display) in (store["Displays"] as? [String: Any]) ?? [:] {
      add(display, key: "display/\(uuid)", displayUUID: uuid)
    }
    for (spaceID, value) in (store["Spaces"] as? [String: Any]) ?? [:] {
      guard let space = value as? [String: Any] else { continue }
      add(space["Default"], key: "space/\(spaceID)/default", displayUUID: nil)
      for (uuid, display) in (space["Displays"] as? [String: Any]) ?? [:] {
        add(display, key: "space/\(spaceID)/\(uuid)", displayUUID: uuid)
      }
    }
    return entries
  }

  /// The configuration is itself a property list; the file name is the last
  /// path component of the first file URL or path found in it.
  static func fileName(inConfiguration data: Data) -> String? {
    guard let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) else { return nil }
    func search(_ value: Any) -> String? {
      if let string = value as? String, string.hasPrefix("file://") || string.hasPrefix("/") {
        return URL(string: string)?.lastPathComponent ?? (string as NSString).lastPathComponent
      }
      if let dict = value as? [String: Any] { return dict.keys.sorted().lazy.compactMap { dict[$0].flatMap(search) }.first }
      if let array = value as? [Any] { return array.lazy.compactMap(search).first }
      return nil
    }
    return search(plist)
  }
}
