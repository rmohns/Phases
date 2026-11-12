import AppKit
import QuickLookThumbnailing
import UniformTypeIdentifiers

/// [D-fake-photos] A Photos library made from a folder the UI test harness
/// builds, so the tests never touch the real one. Each subfolder is an
/// album, a subfolder holding subfolders is a folder of albums, and a
/// top-level folder named `Shared` holds shared albums. IDs are made from
/// paths: `FAKE/<path>` for collections, `FAKEPHOTO/<path>` for photos,
/// both without colons [D-photos-names].
@MainActor
final class FakePhotosProvider: PhotosProvider {
  var onChange: (() -> Void)?
  private let root: URL
  private let refuses: Bool
  private var asked = false

  init(root: URL, refuses: Bool) {
    self.root = root
    self.refuses = refuses
  }

  var access: PhotosAccess {
    guard asked else { return .notDetermined }
    return refuses ? .denied : .allowed
  }

  func requestAccess() async -> PhotosAccess {
    asked = true
    return access
  }

  // MARK: Listing

  func collections() -> [PhotosCollection] {
    guard access == .allowed else { return [] }
    let top = subfolders(of: root)
    let user = top.filter { $0.lastPathComponent != "Shared" }.map { node(for: $0, location: "") }
    let shared = top.first { $0.lastPathComponent == "Shared" }.map { shared in
      subfolders(of: shared).map { url in
        PhotosCollection(
          id: id(for: url), title: url.lastPathComponent, kind: .sharedAlbum, photoCount: photos(in: url).count,
          location: ""
        )
      }
    } ?? []
    return user + shared
  }

  private func node(for url: URL, location: String) -> PhotosCollection {
    let children = subfolders(of: url)
    let title = url.lastPathComponent
    guard !children.isEmpty else {
      return PhotosCollection(
        id: id(for: url), title: title, kind: .album, photoCount: photos(in: url).count, location: location
      )
    }
    let inner = location.isEmpty ? title : "\(location) / \(title)"
    return PhotosCollection(
      id: id(for: url), title: title, kind: .folder, photoCount: nil, location: location,
      children: children.map { node(for: $0, location: inner) }
    )
  }

  func contents(of kind: ImageSource.Kind, id: String) -> PhotosSourceContents? {
    guard access == .allowed, kind != .folder,
      let node = collections().lazy.compactMap({ $0.find(id) }).first
    else { return nil }
    let albums = node.albums().map { entry in
      PhotosSourceContents.Album(
        id: entry.album.id, group: node.kind == .folder ? entry.path : "",
        photoIDs: photos(in: url(for: entry.album.id)).map(photoID(for:))
      )
    }
    return PhotosSourceContents(
      title: node.title, location: node.location, isShared: node.kind == .sharedAlbum, albums: albums
    )
  }

  // MARK: Images

  func fileName(ofPhoto photoID: String) -> String? {
    fileURL(forPhoto: photoID)?.lastPathComponent
  }

  func photoInfo(_ photoID: String) -> PhotoInfo? {
    guard let url = fileURL(forPhoto: photoID),
      let modified = try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
    else { return nil }
    return PhotoInfo(modified: modified)
  }

  func thumbnail(photoID: String, size: CGSize, scale: CGFloat) async -> NSImage? {
    guard let url = fileURL(forPhoto: photoID) else { return nil }
    let request = QLThumbnailGenerator.Request(fileAt: url, size: size, scale: scale, representationTypes: .thumbnail)
    return try? await QLThumbnailGenerator.shared.generateBestRepresentation(for: request).nsImage
  }

  func writePhoto(_ photoID: String, into folder: URL) async -> URL? {
    guard let url = fileURL(forPhoto: photoID), let data = try? Data(contentsOf: url) else { return nil }
    let uti = UTType(filenameExtension: url.pathExtension)?.identifier
    return PhotoFileWriter.write(data, uti: uti, photoID: photoID, modified: photoInfo(photoID)?.modified, into: folder)
  }

  // MARK: Paths and IDs

  private func subfolders(of url: URL) -> [URL] {
    let items = (try? FileManager.default.contentsOfDirectory(
      at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]
    )) ?? []
    return items
      .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }
      .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
  }

  /// An album's images, sorted by name: the fake album's own order.
  private func photos(in url: URL) -> [URL] {
    let items = (try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)) ?? []
    return items
      .filter { UTType(filenameExtension: $0.pathExtension).map { FolderScan.supportedTypes.contains($0) } ?? false }
      .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
  }

  private func relativePath(of url: URL) -> String {
    String(url.standardizedFileURL.path.dropFirst(root.standardizedFileURL.path.count))
      .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
      .replacingOccurrences(of: ":", with: "_")
  }

  private func id(for url: URL) -> String { "FAKE/" + relativePath(of: url) }
  private func url(for id: String) -> URL { root.appending(path: String(id.dropFirst("FAKE/".count))) }
  private func photoID(for url: URL) -> String { "FAKEPHOTO/" + relativePath(of: url) }

  private func fileURL(forPhoto photoID: String) -> URL? {
    guard photoID.hasPrefix("FAKEPHOTO/") else { return nil }
    let url = root.appending(path: String(photoID.dropFirst("FAKEPHOTO/".count)))
    return FileManager.default.fileExists(atPath: url.path) ? url : nil
  }
}
