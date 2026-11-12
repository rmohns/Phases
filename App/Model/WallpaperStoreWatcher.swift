import AppKit

private let diagLog = Diagnostics.logger("store")

/// [D-outside-change-rule] Watches macOS's wallpaper store (read only) and
/// reports wallpapers picked outside Phases. Event-driven, no polling: it
/// watches the store's folder, because macOS replaces the file rather than
/// writing it in place (`[L-store-watch]`).
@MainActor
final class WallpaperStoreWatcher {
  static let shared = WallpaperStoreWatcher()

  /// Called with each batch of outside changes.
  var onOutsideChange: (([OutsideChange]) -> Void)?

  private let folderURL = FileManager.default.homeDirectoryForCurrentUser
    .appending(path: "Library/Application Support/com.apple.wallpaper/Store")
  private var source: DispatchSourceFileSystemObject?
  private var lastReading: [String: WallpaperStoreEntry] = [:]
  private var ownSets: [OwnWallpaperSet] = []

  func start() {
    guard source == nil else { return }
    lastReading = read()
    let fd = open(folderURL.path, O_EVTONLY)
    guard fd >= 0 else {
      diagLog.log("can't watch the store folder: errno=\(errno)")
      return
    }
    let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fd, eventMask: [.write, .rename, .delete], queue: .main)
    source.setEventHandler { [weak self] in
      MainActor.assumeIsolated { self?.storeChanged() }
    }
    source.setCancelHandler { close(fd) }
    source.resume()
    self.source = source
    diagLog.log("watching the store: \(self.lastReading.count) entries")
  }

  /// Called just before Phases sets a wallpaper, so the store write that
  /// follows isn't taken for an outside change.
  func noteOwnSet(_ url: URL, on screen: NSScreen) {
    guard let uuid = screen.displayUUID else { return }
    let now = Date()
    ownSets.removeAll { now.timeIntervalSince($0.date) > OutsideChangeRule.ownSetWindow }
    ownSets.append(OwnWallpaperSet(displayUUID: uuid, fileName: url.lastPathComponent, date: now))
    diagLog.log("phases-set \(uuid, privacy: .public) -> \(url.lastPathComponent, privacy: .public)")
  }

  private func storeChanged() {
    let reading = read()
    // An unreadable store mid-replace reads as empty; keep the last good one.
    guard !reading.isEmpty else { return }
    let changes = OutsideChangeRule.changes(from: lastReading, to: reading, ownSets: ownSets, now: Date())
    lastReading = reading
    guard !changes.isEmpty else { return }
    for change in changes {
      diagLog.log("outside change on \(change.displayUUID ?? "all displays", privacy: .public): \(change.isImage ? change.fileName ?? "image" : "system wallpaper", privacy: .public)")
    }
    onOutsideChange?(changes)
  }

  /// Every file name the store names, on every Space and display, or nil if
  /// the store can't be read. The photo cache never deletes these
  /// [D-photos-cache].
  func fileNamesInStore() -> Set<String>? {
    let entries = read()
    guard !entries.isEmpty else { return nil }
    return Set(entries.values.compactMap(\.fileName))
  }

  private func read() -> [String: WallpaperStoreEntry] {
    guard let data = try? Data(contentsOf: folderURL.appending(path: "Index.plist")) else { return [:] }
    return WallpaperStoreReader.entries(fromPlist: data)
  }
}
