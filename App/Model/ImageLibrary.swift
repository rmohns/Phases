import AppKit
import Observation
import QuickLookThumbnailing

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
  /// Set when draft 44 settings were converted at this launch: saved names
  /// still need the source's ID. The scheduler finishes the job.
  @ObservationIgnored private(set) var pendingNameConversion: String?

  private enum Keys {
    static let sources = "imageSources"
    static let order = "imageSourceOrder"
    /// The source ID saved names still need, until the scheduler has
    /// converted them; survives a quit between the two steps.
    static let pendingNameConversion = "imageSourcesPendingNameConversion"
    /// Draft 44's settings, read once and left in place so an older build
    /// still finds its folder.
    static let legacyBookmark = "imageFolderBookmark"
    static let legacySubfolders = "includesSubfolders"
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

  /// Called by the scheduler once saved names have the converted source's ID.
  func finishNameConversion() {
    pendingNameConversion = nil
    SettingsStore.defaults.removeObject(forKey: Keys.pendingNameConversion)
  }

  // MARK: - Finding folders

  /// The source's folder, from its bookmark, else its saved location
  /// [D-source-location]; nil if neither leads to a folder.
  private func folderURL(for source: ImageSource) -> URL? {
    if let url = folderURLs[source.id], Self.isFolder(url) { return url }
    folderURLs[source.id] = nil
    if let data = source.bookmark {
      var isStale = false
      if let url = try? URL(resolvingBookmarkData: data, options: [.withSecurityScope, .withoutUI], bookmarkDataIsStale: &isStale),
        withAccess(to: url, { Self.isFolder(url) })
      {
        folderURLs[source.id] = url
        if isStale { refreshBookmark(of: source.id, at: url) }
        return url
      }
    }
    let url = SourceLocation.url(for: source.location)
    guard Self.isFolder(url) else { return nil }
    folderURLs[source.id] = url
    // Outside test mode, a bookmark that stopped working is remade from
    // the location that still does.
    if !UITestMode.isOn { refreshBookmark(of: source.id, at: url) }
    return url
  }

  private func refreshBookmark(of id: String, at url: URL) {
    guard let index = sources.firstIndex(where: { $0.id == id }),
      let data = withAccess(to: url, { Self.scopedBookmark(for: url) })
    else { return }
    sources[index].bookmark = data
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

  private func load() {
    let defaults = SettingsStore.defaults
    if let data = defaults.data(forKey: Keys.sources),
      let saved = try? JSONDecoder().decode([ImageSource].self, from: data)
    {
      let order = defaults.stringArray(forKey: Keys.order) ?? []
      sources = order.compactMap { id in saved.first { $0.id == id } }
        + saved.filter { !order.contains($0.id) }
      pendingNameConversion = defaults.string(forKey: Keys.pendingNameConversion)
    } else {
      convertDraft44Settings()
    }
  }

  /// [D-source-names] The one folder from draft 44 and earlier becomes the
  /// first source. Its old settings are left in place.
  private func convertDraft44Settings() {
    let defaults = SettingsStore.defaults
    guard let data = defaults.data(forKey: Keys.legacyBookmark) else {
      save()  // First launch: no sources.
      return
    }
    var isStale = false
    guard let url = try? URL(resolvingBookmarkData: data, options: [.withoutUI], bookmarkDataIsStale: &isStale) else {
      // Unresolvable, as it would have been in draft 44: start empty, and
      // try again at the next launch in case a drive comes back.
      return
    }
    let source = ImageSource(
      id: ImageSource.makeID(avoiding: []),
      bookmark: Self.scopedBookmark(for: url),
      location: SourceLocation.string(for: url),
      includesSubfolders: defaults.bool(forKey: Keys.legacySubfolders)
    )
    sources = [source]
    folderURLs[source.id] = url
    pendingNameConversion = source.id
    defaults.set(source.id, forKey: Keys.pendingNameConversion)
    save()
  }

  private func save() {
    guard !UITestMode.isOn else { return }
    let defaults = SettingsStore.defaults
    if let data = try? JSONEncoder().encode(sources) {
      defaults.set(data, forKey: Keys.sources)
    }
    defaults.set(sources.map(\.id), forKey: Keys.order)
  }
}
