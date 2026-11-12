import Foundation

/// The whole library in order [D-image-sources]: the sources in their stored
/// order, then each source's own order (for a folder: top level first, then
/// each subfolder, sorted the way Finder sorts; for Photos: each album in
/// its own order [D-photos-order]). Stored names come from source IDs, not
/// positions, so reordering sources changes the order and nothing else
/// [D-source-names]. No AppKit, so the unit tests can reach it.
struct LibraryListing {
  /// One heading's worth of images: a source's top level, one of its
  /// subfolders, or one album of a Photos folder.
  struct Group: Equatable {
    var sourceID: String
    /// The subheading: the subfolder part of the path, or a Photos folder's
    /// album path (`2019 / Iceland`); "" for a source's top level or a
    /// single album.
    var folder: String
    var names: [String]
  }

  /// One image of one source, in that source's order.
  struct Entry: Equatable {
    /// The path within the source [D-source-names].
    var path: String
    /// Its group's subheading (see `Group.folder`).
    var group: String
    /// Where the file is. Nil for a photo, which is written to the photo
    /// cache when it's needed [D-photos-cache].
    var url: URL?

    init(path: String, group: String, url: URL?) {
      self.path = path
      self.group = group
      self.url = url
    }

    init(_ item: FolderScan.Item) {
      self.init(path: item.name, group: FolderScan.folder(of: item.name), url: item.url)
    }
  }

  private(set) var names: [String] = []
  private(set) var groups: [Group] = []
  private var urls: [String: URL] = [:]
  private var nameSet: Set<String> = []

  init() {}

  /// `sources` pairs each source ID, in the library's order, with that
  /// source's entries, already in the source's own order.
  init(sources: [(sourceID: String, entries: [Entry])]) {
    for (sourceID, entries) in sources {
      for entry in entries {
        let name = StoredImageName.join(source: sourceID, path: entry.path)
        // A source listed twice keeps its first place.
        guard nameSet.insert(name).inserted else { continue }
        names.append(name)
        if let url = entry.url { urls[name] = url }
        if groups.last?.sourceID == sourceID, groups.last?.folder == entry.group {
          groups[groups.count - 1].names.append(name)
        } else {
          groups.append(Group(sourceID: sourceID, folder: entry.group, names: [name]))
        }
      }
    }
  }

  /// Folder scans only, as before Photos sources.
  init(_ scans: [(sourceID: String, items: [FolderScan.Item])]) {
    self.init(sources: scans.map { ($0.sourceID, $0.items.map(Entry.init)) })
  }

  func contains(_ name: String) -> Bool {
    nameSet.contains(name)
  }

  /// Where an image is read from: not always folder + path, since the file
  /// system follows symlinks in a path but not aliases [D-follow-links].
  /// Nil for a photo [D-photos-cache].
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

  /// The first library image that is the photo `photoID` [D-photos-cache].
  func name(forPhoto photoID: String) -> String? {
    names.first { PhotoImageName.photo(ofStoredName: $0) == photoID }
  }
}
