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
  private var inFlight: [String: Task<URL?, Never>] = [:]

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
  /// the file is kept [D-photos-fetch-ahead].
  func fetch(_ photoID: String, from provider: PhotosProvider) -> Task<URL?, Never> {
    if let info = provider.photoInfo(photoID), let url = file(for: photoID, info: info) {
      return Task { url }
    }
    if let task = inFlight[photoID] { return task }
    let folder = folder
    let task = Task { @MainActor [weak self] () -> URL? in
      let url = await provider.writePhoto(photoID, into: folder)
      if let self {
        self.inFlight[photoID] = nil
        if let url { self.record(url, photoID: photoID) }
      }
      return url
    }
    inFlight[photoID] = task
    return task
  }

  func isFetching(_ photoID: String) -> Bool {
    inFlight[photoID] != nil
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

  /// Deletes what `PhotoCacheRules` allows. `protected` holds file names
  /// that must stay: showing, in the restore record, or fetched ahead and
  /// waiting. `storeFileNames` is every file macOS's wallpaper store names,
  /// or nil if it can't be read.
  func cleanUp(protected: Set<String>, storeFileNames: Set<String>?) {
    let keys: [URLResourceKey] = [.fileSizeKey, .contentModificationDateKey]
    let urls = (try? FileManager.default.contentsOfDirectory(
      at: folder, includingPropertiesForKeys: keys, options: [.skipsHiddenFiles]
    )) ?? []
    let files = urls.filter { $0.lastPathComponent != Self.indexName }.map { url in
      let values = try? url.resourceValues(forKeys: Set(keys))
      return PhotoCacheRules.File(
        fileName: url.lastPathComponent,
        size: Int64(values?.fileSize ?? 0),
        lastShown: index.files[url.lastPathComponent]?.lastShown ?? values?.contentModificationDate ?? .distantPast
      )
    }
    let deleting = PhotoCacheRules.filesToDelete(
      files, protected: protected.union(storeFileNames ?? []), storeReadable: storeFileNames != nil, now: Date()
    )
    for name in deleting {
      try? FileManager.default.removeItem(at: folder.appending(path: name))
      index.files[name] = nil
    }
    // Forget files that are gone from the folder.
    let present = Set(files.map(\.fileName))
    index.files = index.files.filter { present.contains($0.key) }
    if !deleting.isEmpty { diagLog.log("cache: deleted \(deleting.count) files") }
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
