import Foundation

/// The whole library in order [D-image-sources]: the sources in their stored
/// order, then each source's own order (top level first, then each
/// subfolder, sorted the way Finder sorts). Stored names come from source
/// IDs, not positions, so reordering sources changes the order and nothing
/// else [D-source-names]. No AppKit, so the unit tests can reach it.
struct LibraryListing {
  /// One heading's worth of images: a source's top level, or one of its
  /// subfolders.
  struct Group: Equatable {
    var sourceID: String
    /// The subfolder part of the path, or "" for the source's top level.
    var folder: String
    var names: [String]
  }

  private(set) var names: [String] = []
  private(set) var groups: [Group] = []
  private var urls: [String: URL] = [:]
  private var nameSet: Set<String> = []

  init() {}

  /// `scans` pairs each source ID, in the library's order, with that
  /// source's scan, already in the source's own order.
  init(_ scans: [(sourceID: String, items: [FolderScan.Item])]) {
    for (sourceID, items) in scans {
      for item in items {
        let name = StoredImageName.join(source: sourceID, path: item.name)
        // A source listed twice keeps its first place.
        guard nameSet.insert(name).inserted else { continue }
        names.append(name)
        urls[name] = item.url
        let folder = FolderScan.folder(of: item.name)
        if groups.last?.sourceID == sourceID, groups.last?.folder == folder {
          groups[groups.count - 1].names.append(name)
        } else {
          groups.append(Group(sourceID: sourceID, folder: folder, names: [name]))
        }
      }
    }
  }

  func contains(_ name: String) -> Bool {
    nameSet.contains(name)
  }

  /// Where an image is read from: not always folder + path, since the file
  /// system follows symlinks in a path but not aliases [D-follow-links].
  func url(for name: String) -> URL? {
    urls[name]
  }

  /// The selected images that still exist, in library order.
  func available(_ selection: [String]) -> [String] {
    let selected = Set(selection)
    return names.filter(selected.contains)
  }

  /// The first library image whose file is `url`, following links.
  func name(for url: URL) -> String? {
    let target = url.resolvingSymlinksInPath().standardizedFileURL
    return names.first { urls[$0]?.resolvingSymlinksInPath().standardizedFileURL == target }
  }
}
