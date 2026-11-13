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
  /// Photos sources that are shared albums, at the last reload.
  private(set) var sharedAlbumSources: Set<String> = []

  /// Where each source's folder was found at the last reload.
  @ObservationIgnored private var folderURLs: [String: URL] = [:]
  /// Set when the saved list didn't decode, so it isn't overwritten.
  @ObservationIgnored private var isSavingBlocked = false

  /// The Photos library [D-photos-sources]: PhotoKit, or in UI test mode
  /// the fake one [D-fake-photos], or none (test mode without it).
  @ObservationIgnored let photos: PhotosProvider?
  /// [D-photos-cache]
  @ObservationIgnored let photoCache = PhotoCache()
  /// Called after Photos reports a change and the library has reloaded
  /// [D-photos-changes]; the scheduler re-evaluates.
  @ObservationIgnored var onPhotosChange: (() -> Void)?
  @ObservationIgnored private var photosChangeTask: Task<Void, Never>?
  @ObservationIgnored private var photoFileNames: [String: String] = [:]
  /// Mirrors the provider's access, so views update when it's answered.
  private(set) var photosAccess = PhotosAccess.notDetermined

  private enum Keys {
    static let sources = "imageSources"
    static let order = "imageSourceOrder"
  }

  init() {
    if UITestMode.isOn {
      // [D-ui-test-mode] The harness's folders, never the user's.
      sources = UITestMode.imageSources
      photos = UITestMode.photosFolder.map { FakePhotosProvider(root: $0, refuses: UITestMode.photosRefused) }
    } else {
      photos = PhotoKitProvider()
      load()
    }
    photosAccess = photos?.access ?? .notDetermined
    photos?.onChange = { [weak self] in self?.photosChanged() }
    reload()
  }

  /// [D-photos-changes] Photos reports changes in bursts (five in three
  /// minutes for one add and one remove, LEARNINGS.md
  /// `[L-photos-x5-observer]`), so reloads wait for a quiet second.
  private func photosChanged() {
    photosChangeTask?.cancel()
    photosChangeTask = Task { @MainActor [weak self] in
      try? await Task.sleep(for: .seconds(1))
      guard !Task.isCancelled, let self else { return }
      self.reload()
      self.onPhotosChange?()
    }
  }

  /// [D-photos-permission] Asked only from Add Photos Album….
  func requestPhotosAccess() async -> PhotosAccess {
    guard let photos else { return .denied }
    let access = await photos.requestAccess()
    photosAccess = access
    reload()
    return access
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
  /// A photo cache file maps back to its photo [D-photos-cache].
  func name(for url: URL) -> String? {
    listing.name(for: url) ?? photoCache.photoID(forFile: url).flatMap(listing.name(forPhoto:))
  }

  /// Whether `name` is a photo from a Photos source, which has no file
  /// until it's fetched [D-photos-fetch-ahead].
  func isPhoto(_ name: String) -> Bool {
    StoredImageName.source(of: name).flatMap(source(withID:))?.isPhotos ?? false
  }

  /// The photo's ID, if `name` is a photo.
  func photoID(of name: String) -> String? {
    isPhoto(name) ? PhotoImageName.photo(ofStoredName: name) : nil
  }

  /// The photo's cached file as it is now, without fetching.
  func cachedFile(for name: String) -> URL? {
    guard let photos, let photoID = photoID(of: name), let info = photos.photoInfo(photoID) else { return nil }
    return photoCache.file(for: photoID, info: info)
  }

  /// The photo's file, fetching it if needed; nil if it isn't a photo.
  func fetchPhoto(_ name: String) -> Task<URL?, Never>? {
    guard let photos, let photoID = photoID(of: name) else { return nil }
    return photoCache.fetch(photoID, from: photos)
  }

  /// Whether the photo cache has any files, so cleanup still runs after
  /// the last Photos source is removed [D-photos-cache].
  var photoCacheIsEmpty: Bool {
    ((try? FileManager.default.contentsOfDirectory(atPath: photoCache.folder.path(percentEncoded: false))) ?? [])
      .allSatisfy { $0 == "index.json" || $0.hasPrefix(".") }
  }

  /// A file for each image that's on hand now: a folder's file, or a
  /// photo already in the cache [D-photos-fetch-ahead].
  func fileOnHand(for name: String) -> URL? {
    // A photo gone from its album is missing, even with a cached copy
    // [D-photos-fetch-ahead].
    guard contains(name) else { return nil }
    return url(for: name) ?? cachedFile(for: name)
  }

  /// The selected images that still exist, in library order.
  func availableImages(_ selection: [String]) -> [String] {
    listing.available(selection)
  }

  func source(withID id: String) -> ImageSource? {
    sources.first { $0.id == id }
  }

  /// The folder's or album's name, for headings and Settings rows.
  func displayName(of source: ImageSource) -> String {
    if source.isPhotos { return source.title ?? "" }
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

  /// The image's file name for its caption: a folder image's own, or a
  /// photo's original file name from Photos, remembered once looked up.
  func fileName(of name: String) -> String {
    guard let photoID = photoID(of: name) else { return Self.fileName(of: name) }
    if let known = photoFileNames[photoID] { return known }
    let fileName = photos?.fileName(ofPhoto: photoID) ?? "Photo"
    photoFileNames[photoID] = fileName
    return fileName
  }

  func reload() {
    var scans: [(sourceID: String, entries: [LibraryListing.Entry])] = []
    var counts: [String: Int] = [:]
    var unreachable: Set<String> = []
    var renamed = false
    var shared: Set<String> = []
    for source in sources {
      if source.isPhotos {
        // [D-photos-sources] Nil when access is off or the album is gone.
        guard let photosID = source.photosID, let contents = photos?.contents(of: source.kind, id: photosID) else {
          unreachable.insert(source.id)
          counts[source.id] = 0
          continue
        }
        // [D-photos-names] Renamed or moved in Photos: rows and headings follow.
        if let index = sources.firstIndex(where: { $0.id == source.id }),
          sources[index].title != contents.title || sources[index].location != contents.location
        {
          sources[index].title = contents.title
          sources[index].location = contents.location
          renamed = true
        }
        if contents.isShared { shared.insert(source.id) }
        let entries = contents.entries
        scans.append((source.id, entries))
        counts[source.id] = entries.count
        continue
      }
      guard let folder = folderURL(for: source) else {
        unreachable.insert(source.id)
        counts[source.id] = 0
        continue
      }
      // [D-follow-links] [D-scan-each-folder-once] [D-scoped-bookmarks]
      let items = withAccess(to: folder) {
        FolderScan.items(in: folder, includesSubfolders: source.includesSubfolders)
      }
      scans.append((source.id, items.map(LibraryListing.Entry.init)))
      counts[source.id] = items.count
    }
    if renamed { save() }
    listing = LibraryListing(sources: scans)
    imageCounts = counts
    unreachableSources = unreachable
    sharedAlbumSources = shared
    photosAccess = photos?.access ?? .notDetermined
  }

  /// Whether the source is a shared album, for its Settings row.
  func isSharedAlbum(_ source: ImageSource) -> Bool {
    sharedAlbumSources.contains(source.id)
  }

  func thumbnail(for name: String, size: CGSize, scale: CGFloat) async -> NSImage? {
    if let photos, let photoID = photoID(of: name) {
      return await photos.thumbnail(photoID: photoID, size: size, scale: scale)
    }
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

  /// Adds a Photos album or folder of albums as a new source at the end, or
  /// finds the source it already is [D-photos-sources].
  @discardableResult
  func addPhotos(_ collection: PhotosCollection) -> AddResult {
    if let existing = sources.first(where: { $0.isPhotos && $0.photosID == collection.id }) {
      return .existing(existing.id)
    }
    let source = ImageSource(
      id: ImageSource.makeID(avoiding: Set(sources.map(\.id))),
      kind: collection.sourceKind,
      location: collection.location,
      photosID: collection.id,
      title: collection.title
    )
    sources.append(source)
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
  /// Returns what undo needs to put it back [D-undo-remove-source].
  @discardableResult
  func removeSource(_ id: String) -> (source: ImageSource, index: Int)? {
    guard let index = sources.firstIndex(where: { $0.id == id }) else { return nil }
    let source = sources.remove(at: index)
    folderURLs[id] = nil
    save()
    reload()
    return (source, index)
  }

  /// [D-undo-remove-source] Puts a removed source back at its old place,
  /// with its ID, so phases' selections of its images come back.
  func restoreSource(_ source: ImageSource, at index: Int) {
    guard !sources.contains(where: { $0.id == source.id }) else { return }
    sources.insert(source, at: min(index, sources.count))
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
