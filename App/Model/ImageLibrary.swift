import AppKit
import Observation
import QuickLookThumbnailing

private let diagLog = Diagnostics.logger("sources")

/// The user's image sources and the images in them [D-image-sources].
/// Images are named by source ID and path within the source
/// [D-source-names].
@MainActor
@Observable
final class ImageLibrary {
  /// The sources in the library's order. The order belongs to the user and
  /// is stored as its own list; nothing may assume a source's place.
  private(set) var sources: [ImageSource] = []
  private(set) var listing = LibraryListing()
  /// Images per source at the last reload.
  private(set) var imageCounts: [String: Int] = [:]
  /// Sources whose folder couldn't be opened at the last reload.
  private(set) var unreachableSources: Set<String> = []

  /// Where each source's folder was found at the last reload.
  @ObservationIgnored private var folderURLs: [String: URL] = [:]
  /// Set when the saved list didn't decode, so it isn't overwritten.
  @ObservationIgnored private var isSavingBlocked = false

  private enum Keys {
    static let sources = "imageSources"
    static let order = "imageSourceOrder"
  }

  init() {
    if UITestMode.isOn {
      // [D-ui-test-mode] The harness's folders, never the user's.
      sources = UITestMode.imageSources
    } else {
      load()
    }
    reload()
  }

  // MARK: - Reading

  var names: [String] { listing.names }
  var groups: [LibraryListing.Group] { listing.groups }

  func contains(_ name: String) -> Bool {
    listing.contains(name)
  }

  func url(for name: String) -> URL? {
    listing.url(for: name)
  }

  /// The library image at `url`, following links, or nil if it isn't one.
  func name(for url: URL) -> String? {
    listing.name(for: url)
  }

  /// The selected images that still exist, in library order.
  func availableImages(_ selection: [String]) -> [String] {
    listing.available(selection)
  }

  func source(withID id: String) -> ImageSource? {
    sources.first { $0.id == id }
  }

  /// The folder's name, for headings and Settings rows.
  func displayName(of source: ImageSource) -> String {
    let name = (source.location as NSString).lastPathComponent
    return name.isEmpty ? source.location : name
  }

  /// The path within its source, for labels: `Winter/snow.jpg`.
  static func path(of name: String) -> String {
    StoredImageName.path(of: name)
  }

  static func fileName(of name: String) -> String {
    (path(of: name) as NSString).lastPathComponent
  }

  func reload() {
    var scans: [(sourceID: String, items: [FolderScan.Item])] = []
    var counts: [String: Int] = [:]
    var unreachable: Set<String> = []
    for source in sources {
      guard let folder = folderURL(for: source) else {
        unreachable.insert(source.id)
        counts[source.id] = 0
        continue
      }
      // [D-follow-links] [D-scan-each-folder-once] [D-scoped-bookmarks]
      let items = withAccess(to: folder) {
        FolderScan.items(in: folder, includesSubfolders: source.includesSubfolders)
      }
      scans.append((source.id, items))
      counts[source.id] = items.count
    }
    listing = LibraryListing(scans)
    imageCounts = counts
    unreachableSources = unreachable
  }

  func thumbnail(for name: String, size: CGSize, scale: CGFloat) async -> NSImage? {
    guard let url = url(for: name) else { return nil }
    let folder = StoredImageName.source(of: name).flatMap { folderURLs[$0] }
    let started = folder?.startAccessingSecurityScopedResource() ?? false
    defer { if started { folder?.stopAccessingSecurityScopedResource() } }
    let request = QLThumbnailGenerator.Request(
      fileAt: url,
      size: size,
      scale: scale,
      representationTypes: .thumbnail
    )
    let representation = try? await QLThumbnailGenerator.shared.generateBestRepresentation(for: request)
    return representation?.nsImage
  }

  /// Runs `body` with every reachable source open [D-scoped-bookmarks],
  /// for work that reads image files, such as setting the wallpaper.
  func withAccessToAllSources<T>(_ body: () throws -> T) rethrows -> T {
    let opened = sources.compactMap { folderURLs[$0.id] }.filter { $0.startAccessingSecurityScopedResource() }
    defer { opened.forEach { $0.stopAccessingSecurityScopedResource() } }
    return try body()
  }

  // MARK: - Changing sources

  enum AddResult: Equatable {
    case added(String)
    /// The folder is already a source [D-image-sources].
    case existing(String)
  }

  /// Adds `url` as a new source at the end, or finds the source it already is.
  @discardableResult
  func addFolder(_ url: URL) -> AddResult {
    for source in sources {
      if let folder = folderURLs[source.id], FolderScan.isSameFolder(folder, url) {
        return .existing(source.id)
      }
    }
    let source = ImageSource(
      id: ImageSource.makeID(avoiding: Set(sources.map(\.id))),
      bookmark: Self.scopedBookmark(for: url),
      location: SourceLocation.string(for: url)
    )
    sources.append(source)
    folderURLs[source.id] = url
    save()
    reload()
    return .added(source.id)
  }

  /// Reorders sources, as `List`'s move does [D-image-sources]. Changes
  /// the library's order and nothing else.
  func moveSources(fromOffsets offsets: IndexSet, toOffset destination: Int) {
    sources.move(fromOffsets: offsets, toOffset: destination)
    save()
    reload()
  }

  /// Where the source's folder was found at the last reload.
  func folder(of id: String) -> URL? {
    folderURLs[id]
  }

  /// Removes the source. Selections of its images then show as missing;
  /// adding the folder again makes a new source.
  func removeSource(_ id: String) {
    sources.removeAll { $0.id == id }
    folderURLs[id] = nil
    save()
    reload()
  }

  func setIncludesSubfolders(_ isOn: Bool, for id: String) {
    guard let index = sources.firstIndex(where: { $0.id == id }) else { return }
    sources[index].includesSubfolders = isOn
    save()
    reload()
  }

  /// Points a source at `url`, keeping its ID so its selections come back.
  func locate(_ id: String, at url: URL) {
    guard let index = sources.firstIndex(where: { $0.id == id }) else { return }
    sources[index].bookmark = Self.scopedBookmark(for: url)
    sources[index].location = SourceLocation.string(for: url)
    folderURLs[id] = url
    save()
    reload()
  }

  // MARK: - Finding folders

  /// The source's folder, from its bookmark, else its saved location
  /// [D-source-location]; nil if neither leads to a folder.
  private func folderURL(for source: ImageSource) -> URL? {
    if let url = folderURLs[source.id], Self.isFolder(url) { return url }
    folderURLs[source.id] = nil
    if let data = source.bookmark {
      var isStale = false
      // Without mounting: an unreachable source is retried at every reload.
      if let url = try? URL(
        resolvingBookmarkData: data, options: [.withSecurityScope, .withoutUI, .withoutMounting],
        bookmarkDataIsStale: &isStale
      ), withAccess(to: url, { Self.isFolder(url) }) {
        diagLog.log("source \(source.id, privacy: .public) found by its bookmark\(isStale ? " (stale)" : "", privacy: .public)")
        folderURLs[source.id] = url
        // The folder may have moved or been renamed: keep the location
        // shown in Settings, and the fallback below, up to date.
        if isStale || SourceLocation.string(for: url) != source.location {
          update(source.id, at: url)
        }
        return url
      }
    }
    let url = SourceLocation.url(for: source.location)
    guard !source.location.isEmpty, Self.isFolder(url) else {
      diagLog.log("source \(source.id, privacy: .public) can't be opened")
      return nil
    }
    diagLog.log("source \(source.id, privacy: .public) found by its location, not its bookmark")
    folderURLs[source.id] = url
    // Outside test mode, a bookmark that stopped working is remade from
    // the location that still does.
    if !UITestMode.isOn { update(source.id, at: url) }
    return url
  }

  /// A fresh bookmark and location for a source found at `url`.
  private func update(_ id: String, at url: URL) {
    guard let index = sources.firstIndex(where: { $0.id == id }) else { return }
    if let data = withAccess(to: url, { Self.scopedBookmark(for: url) }) {
      sources[index].bookmark = data
    }
    sources[index].location = SourceLocation.string(for: url)
    save()
  }

  private static func isFolder(_ url: URL) -> Bool {
    var isDirectory: ObjCBool = false
    return FileManager.default.fileExists(atPath: url.path(percentEncoded: false), isDirectory: &isDirectory)
      && isDirectory.boolValue
  }

  /// [D-scoped-bookmarks]
  private static func scopedBookmark(for url: URL) -> Data? {
    try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
  }

  /// [D-scoped-bookmarks] Access is open only while reading.
  private func withAccess<T>(to url: URL, _ body: () throws -> T) rethrows -> T {
    let started = url.startAccessingSecurityScopedResource()
    defer { if started { url.stopAccessingSecurityScopedResource() } }
    return try body()
  }

  // MARK: - Persistence

  /// Draft 44's one-folder settings aren't read: the author re-adds the
  /// folder (2026-11-12, `[D-source-names]`).
  private func load() {
    let defaults = SettingsStore.defaults
    guard let data = defaults.data(forKey: Keys.sources) else { return }
    guard let saved = try? JSONDecoder().decode([ImageSource].self, from: data) else {
      // Keep the data rather than overwrite it at the next save.
      diagLog.error("image sources: saved list didn't decode; not saving over it")
      isSavingBlocked = true
      return
    }
    let order = defaults.stringArray(forKey: Keys.order) ?? []
    sources = order.compactMap { id in saved.first { $0.id == id } }
      + saved.filter { !order.contains($0.id) }
  }

  private func save() {
    guard !isSavingBlocked else { return }
    guard !UITestMode.isOn else { return }
    let defaults = SettingsStore.defaults
    if let data = try? JSONEncoder().encode(sources) {
      defaults.set(data, forKey: Keys.sources)
    }
    defaults.set(sources.map(\.id), forKey: Keys.order)
  }
}
