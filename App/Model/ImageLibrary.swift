import AppKit
import Observation
import QuickLookThumbnailing
import UniformTypeIdentifiers

/// The user's wallpaper folder and the images in it, optionally including
/// subfolders. Images are identified by their path relative to the folder.
@MainActor
@Observable
final class ImageLibrary {
  private(set) var folderURL: URL?
  /// Relative image paths: top-level files first, then each subfolder, sorted
  /// the way Finder sorts them.
  private(set) var imageNames: [String] = [] {
    didSet { imageNameSet = Set(imageNames) }
  }
  @ObservationIgnored private var imageNameSet: Set<String> = []

  var includesSubfolders: Bool {
    didSet {
      UserDefaults.standard.set(includesSubfolders, forKey: Self.subfoldersKey)
      reload()
    }
  }

  private static let bookmarkKey = "imageFolderBookmark"
  private static let subfoldersKey = "includesSubfolders"
  private static let supportedTypes: [UTType] = [.jpeg, .png, .heic, .tiff]

  init() {
    includesSubfolders = UserDefaults.standard.bool(forKey: Self.subfoldersKey)
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
    guard let folderURL else {
      imageNames = []
      return
    }
    var options: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles, .skipsPackageDescendants]
    if !includesSubfolders { options.insert(.skipsSubdirectoryDescendants) }
    guard let enumerator = FileManager.default.enumerator(
      at: folderURL,
      includingPropertiesForKeys: [.contentTypeKey],
      options: options
    ) else {
      imageNames = []
      return
    }

    let basePath = folderURL.standardizedFileURL.path(percentEncoded: false)
    let prefix = basePath.hasSuffix("/") ? basePath : basePath + "/"
    var names: [String] = []
    for case let url as URL in enumerator {
      guard let type = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType,
        Self.supportedTypes.contains(where: { type.conforms(to: $0) })
      else { continue }
      let path = url.standardizedFileURL.path(percentEncoded: false)
      guard path.hasPrefix(prefix) else { continue }
      names.append(String(path.dropFirst(prefix.count)))
    }
    imageNames = names.sorted { lhs, rhs in
      let l = Self.folder(of: lhs), r = Self.folder(of: rhs)
      if l != r {
        if l.isEmpty || r.isEmpty { return l.isEmpty }
        return l.localizedStandardCompare(r) == .orderedAscending
      }
      return lhs.localizedStandardCompare(rhs) == .orderedAscending
    }
  }

  /// Images grouped by subfolder ("" for the top level), in display order.
  var groups: [(folder: String, names: [String])] {
    var result: [(folder: String, names: [String])] = []
    for name in imageNames {
      let folder = Self.folder(of: name)
      if result.last?.folder == folder {
        result[result.count - 1].names.append(name)
      } else {
        result.append((folder, [name]))
      }
    }
    return result
  }

  /// The subfolder part of a relative path, or "" for a top-level file.
  static func folder(of name: String) -> String {
    (name as NSString).deletingLastPathComponent
  }

  static func fileName(of name: String) -> String {
    (name as NSString).lastPathComponent
  }

  func url(for name: String) -> URL? {
    folderURL?.appendingPathComponent(name)
  }

  func contains(_ name: String) -> Bool {
    imageNameSet.contains(name)
  }

  /// The selected images that still exist, in library order.
  func availableImages(_ selection: [String]) -> [String] {
    let selected = Set(selection)
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
