import AppKit
import ImageIO
import Photos
import UniformTypeIdentifiers

private let diagLog = Diagnostics.logger("photos")

/// The real Photos library [D-photos-sources]. Findings it relies on are in
/// LEARNINGS.md "Photos library (issue #33)".
@MainActor
final class PhotoKitProvider: NSObject, PhotosProvider {
  var onChange: (() -> Void)?
  private var isObserving = false

  var access: PhotosAccess {
    Self.access(PHPhotoLibrary.authorizationStatus(for: .readWrite))
  }

  /// [D-photos-permission] Only when the user chooses Add Photos Album….
  func requestAccess() async -> PhotosAccess {
    let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    diagLog.log("access asked: \(status.rawValue)")
    startObserving()
    return Self.access(status)
  }

  private static func access(_ status: PHAuthorizationStatus) -> PhotosAccess {
    switch status {
    case .authorized, .limited: .allowed
    case .notDetermined: .notDetermined
    default: .denied
    }
  }

  /// [D-photos-changes] Only once access is allowed, so registering never
  /// prompts.
  func startObserving() {
    guard !isObserving, access == .allowed else { return }
    isObserving = true
    PHPhotoLibrary.shared().register(self)
  }

  // MARK: Listing

  func collections() -> [PhotosCollection] {
    guard access == .allowed else { return [] }
    startObserving()
    let user = Self.nodes(in: PHCollectionList.fetchTopLevelUserCollections(with: nil), location: "")
    var shared: [PhotosCollection] = []
    PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumCloudShared, options: nil)
      .enumerateObjects { album, _, _ in
        shared.append(PhotosCollection(
          id: album.localIdentifier, title: album.localizedTitle ?? "", kind: .sharedAlbum,
          photoCount: Self.images(in: album).count, location: ""
        ))
      }
    return user + shared
  }

  private static func nodes(in collections: PHFetchResult<PHCollection>, location: String) -> [PhotosCollection] {
    var nodes: [PhotosCollection] = []
    collections.enumerateObjects { collection, _, _ in
      let title = collection.localizedTitle ?? ""
      if let list = collection as? PHCollectionList {
        let inner = location.isEmpty ? title : "\(location) / \(title)"
        nodes.append(PhotosCollection(
          id: list.localIdentifier, title: title, kind: .folder, photoCount: nil, location: location,
          children: Self.nodes(in: PHCollection.fetchCollections(in: list, options: nil), location: inner)
        ))
      } else if let album = collection as? PHAssetCollection {
        nodes.append(PhotosCollection(
          id: album.localIdentifier, title: title, kind: .album, photoCount: Self.images(in: album).count,
          location: location
        ))
      }
    }
    return nodes
  }

  /// [D-photos-sources] Still images only; a Live Photo is an image asset.
  /// No sort: the default is the album's own order [L-photos-album-order].
  private static func images(in album: PHAssetCollection) -> PHFetchResult<PHAsset> {
    let options = PHFetchOptions()
    options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
    return PHAsset.fetchAssets(in: album, options: options)
  }

  private static func ids(_ result: PHFetchResult<PHAsset>) -> [String] {
    var ids: [String] = []
    ids.reserveCapacity(result.count)
    result.enumerateObjects { asset, _, _ in ids.append(asset.localIdentifier) }
    return ids
  }

  func contents(of kind: ImageSource.Kind, id: String) -> PhotosSourceContents? {
    guard access == .allowed else { return nil }
    startObserving()
    switch kind {
    case .folder:
      return nil
    case .photosAlbum:
      guard let album = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [id], options: nil).firstObject
      else { return nil }
      let isShared = album.assetCollectionSubtype == .albumCloudShared
      return PhotosSourceContents(
        title: album.localizedTitle ?? "", location: isShared ? "" : Self.location(of: album), isShared: isShared,
        albums: [.init(id: id, group: "", photoIDs: Self.ids(Self.images(in: album)))]
      )
    case .photosFolder:
      guard let list = PHCollectionList.fetchCollectionLists(withLocalIdentifiers: [id], options: nil).firstObject
      else { return nil }
      let title = list.localizedTitle ?? ""
      let node = PhotosCollection(
        id: id, title: title, kind: .folder, photoCount: nil, location: "",
        children: Self.nodes(in: PHCollection.fetchCollections(in: list, options: nil), location: "")
      )
      let albumIDs = node.albums().map(\.album.id)
      var found: [String: PHAssetCollection] = [:]
      PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: albumIDs, options: nil)
        .enumerateObjects { album, _, _ in found[album.localIdentifier] = album }
      return PhotosSourceContents(
        title: title, location: Self.location(of: list), isShared: false,
        albums: node.albums().compactMap { entry in
          found[entry.album.id].map { .init(id: entry.album.id, group: entry.path, photoIDs: Self.ids(Self.images(in: $0))) }
        }
      )
    }
  }

  /// The Photos folders a collection sits in, `Trips / 2019`.
  private static func location(of collection: PHCollection) -> String {
    var titles: [String] = []
    var current = collection
    // Folders nest only so deep; the bound guards against a cycle.
    for _ in 0..<32 {
      guard let parent = PHCollectionList.fetchCollectionListsContaining(current, options: nil).firstObject else { break }
      titles.insert(parent.localizedTitle ?? "", at: 0)
      current = parent
    }
    return titles.joined(separator: " / ")
  }

  // MARK: Images

  private static func asset(_ id: String) -> PHAsset? {
    PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil).firstObject
  }

  func photoInfo(_ photoID: String) -> PhotoInfo? {
    Self.asset(photoID).map { PhotoInfo(modified: $0.modificationDate) }
  }

  func thumbnail(photoID: String, size: CGSize, scale: CGFloat) async -> NSImage? {
    guard let asset = Self.asset(photoID) else { return nil }
    let options = PHImageRequestOptions()
    options.deliveryMode = .highQualityFormat
    options.resizeMode = .fast
    options.isNetworkAccessAllowed = true
    let target = CGSize(width: size.width * scale, height: size.height * scale)
    return await withCheckedContinuation { continuation in
      PHImageManager.default().requestImage(
        for: asset, targetSize: target, contentMode: .aspectFill, options: options
      ) { image, _ in
        continuation.resume(returning: image)
      }
    }
  }

  /// [D-photos-version] The current version (with edits), at full size,
  /// from iCloud if needed. Not time-limited: a change that stops waiting
  /// leaves this to finish, and the file is kept for next time
  /// [D-photos-fetch-ahead].
  func writePhoto(_ photoID: String, into folder: URL) async -> URL? {
    guard let asset = Self.asset(photoID) else { return nil }
    let options = PHImageRequestOptions()
    options.version = .current
    options.deliveryMode = .highQualityFormat
    options.isNetworkAccessAllowed = true
    let started = Date()
    let result: (Data, String?)? = await withCheckedContinuation { continuation in
      PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, uti, _, info in
        if data == nil {
          let error = (info?[PHImageErrorKey] as? Error)?.localizedDescription ?? "no data"
          diagLog.log("photo \(photoID, privacy: .public) not fetched: \(error, privacy: .public)")
        }
        continuation.resume(returning: data.map { ($0, uti) })
      }
    }
    guard let (data, uti) = result else { return nil }
    let modified = asset.modificationDate
    let file = await Task.detached(priority: .utility) {
      PhotoFileWriter.write(data, uti: uti, photoID: photoID, modified: modified, into: folder)
    }.value
    diagLog.log("photo \(photoID, privacy: .public) fetched in \(Date().timeIntervalSince(started), format: .fixed(precision: 2)) s")
    return file
  }
}

extension PhotoKitProvider: PHPhotoLibraryChangeObserver {
  nonisolated func photoLibraryDidChange(_ changeInstance: PHChange) {
    Task { @MainActor [weak self] in self?.onChange?() }
  }
}

/// Writes a photo's data into the cache folder: as is for a supported
/// format, else converted to HEIC [D-photos-version]. Shared with the fake
/// library.
enum PhotoFileWriter {
  private static let supported: [UTType: String] = [.jpeg: "jpeg", .png: "png", .heic: "heic", .tiff: "tiff"]

  static func write(_ data: Data, uti: String?, photoID: String, modified: Date?, into folder: URL) -> URL? {
    try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    let type = uti.flatMap(UTType.init)
    if let type, let ext = supported.first(where: { type.conforms(to: $0.key) })?.value {
      let url = folder.appending(path: PhotoCacheRules.fileName(photoID: photoID, modified: modified, fileExtension: ext))
      return (try? data.write(to: url, options: .atomic)) == nil ? nil : url
    }
    let url = folder.appending(path: PhotoCacheRules.fileName(photoID: photoID, modified: modified, fileExtension: "heic"))
    guard let source = CGImageSourceCreateWithData(data as CFData, nil),
      let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.heic.identifier as CFString, 1, nil)
    else { return nil }
    // Keeps the orientation and other properties.
    CGImageDestinationAddImageFromSource(destination, source, 0, nil)
    return CGImageDestinationFinalize(destination) ? url : nil
  }
}
