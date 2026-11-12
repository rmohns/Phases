import AppKit

/// What Phases needs from a Photos library [D-photos-sources]: the real one
/// through PhotoKit, or in UI test mode a fake one made from a folder
/// [D-fake-photos]. Everything above this (sources, names, the cache,
/// fetching ahead) is the same for both.
@MainActor
protocol PhotosProvider: AnyObject {
  var access: PhotosAccess { get }
  /// Asks once; later calls return the answer [D-photos-permission].
  func requestAccess() async -> PhotosAccess
  /// The library as Photos' sidebar shows it: folders of albums, nested,
  /// in sidebar order, then a group of shared albums.
  func collections() -> [PhotosCollection]
  /// A source's albums and their still images, each album in its own order
  /// [D-photos-order]; nil if the album or folder is gone or access is off.
  func contents(of kind: ImageSource.Kind, id: String) -> PhotosSourceContents?
  func thumbnail(photoID: String, size: CGSize, scale: CGFloat) async -> NSImage?
  /// The photo's details, or nil if it's gone from the library.
  func photoInfo(_ photoID: String) -> PhotoInfo?
  /// Writes the photo, as it looks in Photos (with edits, still image) at
  /// full size, into `folder`, downloading it from iCloud if needed
  /// [D-photos-version]. The file's name comes from `PhotoCacheRules`.
  /// Nil if it can't be had (offline and only in iCloud, or deleted).
  func writePhoto(_ photoID: String, into folder: URL) async -> URL?
  /// Called on the main actor after the library changes [D-photos-changes].
  var onChange: (() -> Void)? { get set }
}

struct PhotoInfo: Equatable {
  /// When it was last edited, for the cache file's name, so an edit in
  /// Photos makes a new file [D-photos-version].
  var modified: Date?
}

enum PhotosAccess: Equatable {
  case notDetermined
  case allowed
  case denied
}

/// A node in the Add Photos Album… sheet.
struct PhotosCollection: Identifiable, Equatable {
  enum Kind: Equatable {
    case album
    case folder
    case sharedAlbum
  }

  var id: String
  var title: String
  var kind: Kind
  /// Still images, for albums; nil for folders.
  var photoCount: Int?
  /// The folders it sits in, `Trips / 2019`, "" at the top level.
  var location: String
  var children: [PhotosCollection] = []

  /// Nil for albums, so `OutlineGroup` shows no disclosure triangle.
  var outlineChildren: [PhotosCollection]? { kind == .folder ? children : nil }

  var sourceKind: ImageSource.Kind { kind == .folder ? .photosFolder : .photosAlbum }
}

/// A Photos source's current name, place, and photos.
struct PhotosSourceContents: Equatable {
  struct Album: Equatable {
    var id: String
    /// The grid's subheading: "" for a single-album source, else the
    /// album's path within the source's folder, `2019 / Iceland`.
    var group: String
    var photoIDs: [String]
  }

  var title: String
  var location: String
  var isShared: Bool
  var albums: [Album]

  /// The source's entries in its own order [D-photos-order] [D-photos-names].
  var entries: [LibraryListing.Entry] {
    albums.flatMap { album in
      album.photoIDs.map {
        LibraryListing.Entry(path: PhotoImageName.path(album: album.id, photo: $0), group: album.group, url: nil)
      }
    }
  }
}

extension PhotosCollection {
  /// Every album at or under this node, depth first in sidebar order, with
  /// its path below this node.
  func albums(under prefix: String = "") -> [(album: PhotosCollection, path: String)] {
    switch kind {
    case .album, .sharedAlbum:
      return [(self, prefix)]
    case .folder:
      return children.flatMap { child in
        let path = prefix.isEmpty ? child.title : "\(prefix) / \(child.title)"
        return child.kind == .folder ? child.albums(under: path) : [(child, path)]
      }
    }
  }

  /// The node with `id` at or under this one.
  func find(_ id: String) -> PhotosCollection? {
    if self.id == id { return self }
    for child in children {
      if let found = child.find(id) { return found }
    }
    return nil
  }
}
