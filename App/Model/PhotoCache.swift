import Foundation

private let diagLog = Diagnostics.logger("photos")

/// [D-photos-cache] The files Phases sets as wallpapers for photos, in
/// `~/Library/Application Support/Phases/Photos/`. Which files go is
/// `PhotoCacheRules`; this keeps the files, an index of which photo each
/// is and when it last showed, and the fetches in progress.
@MainActor
final class PhotoCache {
  let folder: URL
  private var index = Index()
  /// Fetches in progress, by photo ID, shared by everyone waiting on one.
  private var inFlight: [String: InFlight] = [:]

  private struct InFlight {
    var task: Task<URL?, Never>
    var started: Date
    /// Tells this fetch from a later one for the same photo.
    var token: UUID
  }

  private struct Index: Codable {
    struct Record: Codable {
      var photoID: String
      var lastShown: Date
    }
    /// File name → its photo and when it last showed.
    var files: [String: Record] = [:]
  }

  private static let indexName = "index.json"

  init() {
    if UITestMode.isOn {
      // [D-ui-test-mode] Never the user's cache.
      folder = FileManager.default.temporaryDirectory.appending(path: "PhasesUITestPhotoCache", directoryHint: .isDirectory)
    } else {
      let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
      folder = support.appending(path: "Phases/Photos", directoryHint: .isDirectory)
    }
    loadIndex()
  }

  // MARK: Finding and fetching

  /// The cached file for the photo as it is now, if there is one. A photo
  /// edited since it was cached has a new name, so this misses
  /// [D-photos-version].
  func file(for photoID: String, info: PhotoInfo) -> URL? {
    let stem = PhotoCacheRules.fileName(photoID: photoID, modified: info.modified, fileExtension: "")
    guard let name = index.files.first(where: { $0.value.photoID == photoID && $0.key.hasPrefix(stem) })?.key
    else { return nil }
    let url = folder.appending(path: name)
    return FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) ? url : nil
  }

  /// The photo's file: from the cache, or fetched from Photos. One fetch per
  /// photo at a time; a caller that stops waiting leaves it to finish, and
  /// the file is kept [D-photos-fetch-ahead]. A fetch that hasn't answered
  /// in `FetchAhead.giveUpAfter` is given up on and asked again, so a
  /// PhotoKit request that never calls back can't block the photo for good.
  func fetch(_ photoID: String, from provider: PhotosProvider) -> Task<URL?, Never> {
    if let info = provider.photoInfo(photoID), let url = file(for: photoID, info: info) {
      return Task { url }
    }
    if let fetch = inFlight[photoID], Date().timeIntervalSince(fetch.started) < FetchAhead.giveUpAfter {
      return fetch.task
    }
    let folder = folder
    let token = UUID()
    let task = Task { @MainActor [weak self] () -> URL? in
      let url = await provider.writePhoto(photoID, into: folder)
      if let self {
        if self.inFlight[photoID]?.token == token { self.inFlight[photoID] = nil }
        if let url { self.record(url, photoID: photoID) }
      }
      return url
    }
    inFlight[photoID] = InFlight(task: task, started: Date(), token: token)
    return task
  }

  /// The photo a cache file holds, so Phases knows its own photo when it's
  /// showing [D-photos-cache].
  func photoID(forFile url: URL) -> String? {
    guard url.deletingLastPathComponent().standardizedFileURL.path == folder.standardizedFileURL.path else {
      return nil
    }
    return index.files[url.lastPathComponent]?.photoID
  }

  func noteShown(_ url: URL) {
    guard index.files[url.lastPathComponent] != nil else { return }
    index.files[url.lastPathComponent]?.lastShown = Date()
    saveIndex()
  }

  private func record(_ url: URL, photoID: String) {
    // An older file of the same photo (before an edit) stays until the
    // cleanup rules let it go; another Space may still show it.
    index.files[url.lastPathComponent] = .init(photoID: photoID, lastShown: Date())
    saveIndex()
  }

  // MARK: Cleanup

  /// Rule 1's test [D-photos-cache-cleanup]: whether a file (its photo's ID,
  /// its name) is a photo in a Photos source as it is now.
  typealias SourceCheck = (_ photoID: String, _ fileName: String) -> Bool

  /// Deletes what `PhotoCacheRules` allows [D-photos-cache-cleanup].
  /// `protected` holds file names that must stay: showing, in the restore
  /// record, or fetched ahead and waiting. `storeFileNames` is every file
  /// macOS's wallpaper store names, or nil if it can't be read.
  /// `isInSources` is nil while any Photos source can't be read, which
  /// skips rule 1.
  func cleanUp(protected: Set<String>, storeFileNames: Set<String>?, isInSources: SourceCheck?) {
    let files = cachedFiles(isInSources: isInSources)
    let situation = situation(protected: protected, storeFileNames: storeFileNames, sourcesRead: isInSources != nil)
    delete(PhotoCacheRules.filesToDelete(files, in: situation), present: files, reason: "cleanup")
  }

  /// [D-cache-in-about] Clear…: deletes every file the rules may delete,
  /// keeping the ones they never do.
  func clear(protected: Set<String>, storeFileNames: Set<String>?) {
    let files = cachedFiles(isInSources: nil)
    let situation = situation(protected: protected, storeFileNames: storeFileNames, sourcesRead: false)
    delete(PhotoCacheRules.filesToClear(files, in: situation), present: files, reason: "Clear…")
  }

  /// [D-cache-in-about] What the cache holds now, and whether the low-disk
  /// rule applies.
  struct Usage: Equatable {
    var bytes: Int64
    var photos: Int
    var isLowDisk: Bool
  }

  func usage() -> Usage {
    let files = cachedFiles(isInSources: nil)
    return Usage(
      bytes: files.reduce(0) { $0 + $1.size },
      photos: files.count,
      isLowDisk: PhotoCacheRules.isLowDisk(available: availableDiskSpace())
    )
  }

  /// The photo files in the folder, without the index.
  private func cachedFiles(isInSources: SourceCheck?) -> [PhotoCacheRules.File] {
    let keys: [URLResourceKey] = [.fileSizeKey, .contentModificationDateKey]
    let urls = (try? FileManager.default.contentsOfDirectory(
      at: folder, includingPropertiesForKeys: keys, options: [.skipsHiddenFiles]
    )) ?? []
    return urls.filter { $0.lastPathComponent != Self.indexName }.map { url in
      let values = try? url.resourceValues(forKeys: Set(keys))
      let name = url.lastPathComponent
      let record = index.files[name]
      return PhotoCacheRules.File(
        fileName: name,
        size: Int64(values?.fileSize ?? 0),
        // Fetched but never shown counts from the fetch, which `record` sets.
        lastShown: record?.lastShown ?? values?.contentModificationDate ?? .distantPast,
        // A file the index doesn't know is no photo of any source.
        isInSources: record.map { isInSources?($0.photoID, name) ?? true } ?? false
      )
    }
  }

  private func situation(
    protected: Set<String>, storeFileNames: Set<String>?, sourcesRead: Bool
  ) -> PhotoCacheRules.Situation {
    PhotoCacheRules.Situation(
      protected: protected.union(storeFileNames ?? []),
      storeReadable: storeFileNames != nil,
      sourcesRead: sourcesRead,
      availableDiskSpace: availableDiskSpace(),
      now: Date()
    )
  }

  /// Space available on the cache's disk for things the user wants kept,
  /// as Finder reports it; nil if it can't be read.
  private func availableDiskSpace() -> Int64? {
    // The folder may not exist yet; its disk is its parent's.
    let existing = FileManager.default.fileExists(atPath: folder.path(percentEncoded: false))
      ? folder : folder.deletingLastPathComponent()
    let values = try? existing.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
    return values?.volumeAvailableCapacityForImportantUsage
  }

  private func delete(_ names: [String], present files: [PhotoCacheRules.File], reason: String) {
    for name in names {
      try? FileManager.default.removeItem(at: folder.appending(path: name))
      index.files[name] = nil
    }
    // Forget files that are gone from the folder.
    let present = Set(files.map(\.fileName))
    index.files = index.files.filter { present.contains($0.key) }
    if !names.isEmpty { diagLog.log("cache: \(reason, privacy: .public) deleted \(names.count) files") }
    saveIndex()
  }

  // MARK: Index

  private func loadIndex() {
    guard let data = try? Data(contentsOf: folder.appending(path: Self.indexName)),
      let saved = try? JSONDecoder().decode(Index.self, from: data)
    else { return }
    index = saved
  }

  private func saveIndex() {
    try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    guard let data = try? JSONEncoder().encode(index) else { return }
    try? data.write(to: folder.appending(path: Self.indexName), options: .atomic)
  }
}
