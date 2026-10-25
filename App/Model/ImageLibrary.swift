import AppKit
import Observation
import QuickLookThumbnailing
import UniformTypeIdentifiers

/// The user's wallpaper folder and the images in it (top level only).
@MainActor
@Observable
final class ImageLibrary {
  private(set) var folderURL: URL?
  /// Image file names, sorted the way Finder sorts them.
  private(set) var imageNames: [String] = []

  private static let bookmarkKey = "imageFolderBookmark"
  private static let supportedTypes: [UTType] = [.jpeg, .png, .heic, .tiff]

  init() {
    restoreBookmark()
    reload()
  }

  func setFolder(_ url: URL) {
    if let data = try? url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil) {
      UserDefaults.standard.set(data, forKey: Self.bookmarkKey)
    }
    folderURL = url
    reload()
  }

  func reload() {
    guard let folderURL,
      let urls = try? FileManager.default.contentsOfDirectory(
        at: folderURL,
        includingPropertiesForKeys: [.contentTypeKey],
        options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
      )
    else {
      imageNames = []
      return
    }
    imageNames = urls
      .filter { url in
        guard let type = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType else { return false }
        return Self.supportedTypes.contains { type.conforms(to: $0) }
      }
      .map(\.lastPathComponent)
      .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
  }

  func url(for name: String) -> URL? {
    folderURL?.appendingPathComponent(name)
  }

  func contains(_ name: String) -> Bool {
    imageNames.contains(name)
  }

  /// The phase's selected images that still exist, in library order.
  func availableImages(for phase: Phase) -> [String] {
    let selected = Set(phase.imageNames)
    return imageNames.filter(selected.contains)
  }

  func thumbnail(for name: String, size: CGSize, scale: CGFloat) async -> NSImage? {
    guard let url = url(for: name) else { return nil }
    let request = QLThumbnailGenerator.Request(
      fileAt: url,
      size: size,
      scale: scale,
      representationTypes: .thumbnail
    )
    let representation = try? await QLThumbnailGenerator.shared.generateBestRepresentation(for: request)
    return representation?.nsImage
  }

  private func restoreBookmark() {
    guard let data = UserDefaults.standard.data(forKey: Self.bookmarkKey) else { return }
    var isStale = false
    guard let url = try? URL(resolvingBookmarkData: data, options: [], bookmarkDataIsStale: &isStale) else { return }
    folderURL = url
    if isStale { setFolder(url) }
  }
}
