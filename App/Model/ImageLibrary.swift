import AppKit
import Observation
import QuickLookThumbnailing

/// The user's wallpaper folder and the images in it, optionally including
/// subfolders. [D-relative-paths] Images are identified by their path
/// relative to the folder.
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
  /// Where each image is read from. Not always folder + name: the file
  /// system follows symlinks in a path but not aliases [D-follow-links].
  @ObservationIgnored private var imageURLs: [String: URL] = [:]

  var includesSubfolders: Bool {
    didSet {
      SettingsStore.defaults.set(includesSubfolders, forKey: Self.subfoldersKey)
      reload()
    }
  }

  private static let bookmarkKey = "imageFolderBookmark"
  private static let subfoldersKey = "includesSubfolders"

  init() {
    includesSubfolders = SettingsStore.defaults.bool(forKey: Self.subfoldersKey)
    restoreBookmark()
    reload()
  }

  func setFolder(_ url: URL) {
    if let data = try? url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil) {
      SettingsStore.defaults.set(data, forKey: Self.bookmarkKey)
    }
    folderURL = url
    reload()
  }

  func reload() {
    guard let folderURL else {
      imageNames = []
      imageURLs = [:]
      return
    }
    // [D-follow-links] [D-scan-each-folder-once]
    let items = FolderScan.items(in: folderURL, includesSubfolders: includesSubfolders)
    imageURLs = Dictionary(items.map { ($0.name, $0.url) }) { first, _ in first }
    imageNames = items.map(\.name)
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
    FolderScan.folder(of: name)
  }

  static func fileName(of name: String) -> String {
    (name as NSString).lastPathComponent
  }

  func url(for name: String) -> URL? {
    imageURLs[name] ?? folderURL?.appendingPathComponent(name)
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
    // [D-ui-test-mode] The harness's folder, never the user's.
    if UITestMode.isOn {
      folderURL = UITestMode.imageFolder
      return
    }
    guard let data = SettingsStore.defaults.data(forKey: Self.bookmarkKey) else { return }
    var isStale = false
    guard let url = try? URL(resolvingBookmarkData: data, options: [], bookmarkDataIsStale: &isStale) else { return }
    folderURL = url
    if isStale { setFolder(url) }
  }
}
