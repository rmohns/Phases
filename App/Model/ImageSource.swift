import Foundation

/// One place images come from [D-image-sources]: a folder, or a Photos album
/// or folder of albums [D-photos-sources]. No AppKit, so the unit tests can
/// reach it.
struct ImageSource: Codable, Equatable, Identifiable {
  enum Kind: String, Codable {
    case folder
    /// One album, by its Photos ID.
    case photosAlbum
    /// A folder of albums, by its Photos ID: every album in it, nested ones
    /// too, each under its own heading.
    case photosFolder
  }

  /// Made once when the source is added; never a path and never a position
  /// [D-source-names]. The library's order is stored separately.
  var id: String
  var kind = Kind.folder
  /// How Phases finds the folder: a security-scoped bookmark
  /// [D-scoped-bookmarks]. Nil for Photos sources, and in UI test mode.
  var bookmark: Data?
  /// A folder: where it is, home-relative when it's in the home folder
  /// (`~/Pictures/Wallpapers`) [D-source-location]. Shown in Settings and
  /// used when the bookmark stops working.
  /// A Photos source: the Photos folders it sits in, `Trips / 2019`, or ""
  /// at the top level; refreshed from Photos at each reload.
  var location: String
  var includesSubfolders = false
  /// The album's or Photos folder's ID in the Photos library
  /// [D-photos-names]. Nil for folders.
  var photosID: String?
  /// The album's or Photos folder's name, refreshed from Photos at each
  /// reload. Nil for folders, whose name comes from `location`.
  var title: String?

  init(
    id: String, kind: Kind = .folder, bookmark: Data? = nil, location: String, includesSubfolders: Bool = false,
    photosID: String? = nil, title: String? = nil
  ) {
    self.id = id
    self.kind = kind
    self.bookmark = bookmark
    self.location = location
    self.includesSubfolders = includesSubfolders
    self.photosID = photosID
    self.title = title
  }

  /// Whether the source lives in the file system, so Show in Finder,
  /// Locate…, and Include subfolders apply [D-image-sources].
  var isInFileSystem: Bool { kind == .folder }

  var isPhotos: Bool { kind != .folder }

  /// Characters an ID is made of. No colon, so a stored name splits at its
  /// first one [D-source-names]; no look-alikes (0/O, 1/I).
  static let idAlphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
  static let idLength = 8

  /// A new ID, different from every one in `existing`.
  static func makeID<G: RandomNumberGenerator>(avoiding existing: Set<String>, using generator: inout G) -> String {
    while true {
      let id = String((0..<idLength).map { _ in idAlphabet.randomElement(using: &generator)! })
      if !existing.contains(id) { return id }
    }
  }

  static func makeID(avoiding existing: Set<String>) -> String {
    var generator = SystemRandomNumberGenerator()
    return makeID(avoiding: existing, using: &generator)
  }

  /// Whether `string` has the shape of a source ID.
  static func isValidID<S: StringProtocol>(_ string: S) -> Bool {
    string.count == idLength && string.allSatisfy(idAlphabet.contains)
  }
}

extension ImageSource {
  /// Lenient, like `Phase`, so a list saved before a field was added (the
  /// source kind, from draft 54) still loads, as folders.
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    kind = try container.decodeIfPresent(Kind.self, forKey: .kind) ?? .folder
    bookmark = try container.decodeIfPresent(Data.self, forKey: .bookmark)
    location = try container.decodeIfPresent(String.self, forKey: .location) ?? ""
    includesSubfolders = try container.decodeIfPresent(Bool.self, forKey: .includesSubfolders) ?? false
    photosID = try container.decodeIfPresent(String.self, forKey: .photosID)
    title = try container.decodeIfPresent(String.self, forKey: .title)
  }
}

extension Phase {
  /// Whether any of the phase's selections (All Displays or per display)
  /// has an image from the source; removing it asks first [D-image-sources].
  func uses(source id: String) -> Bool {
    (imageNames + displayImageNames.values.joined()).contains { StoredImageName.source(of: $0) == id }
  }
}

/// [D-source-names] A saved image name: `<source ID>:<path within the
/// source>`. Stored form only; never shown to users.
enum StoredImageName {
  static let separator: Character = ":"

  static func join(source: String, path: String) -> String {
    "\(source)\(separator)\(path)"
  }

  /// The source ID and path, or nil for a name that has no source part
  /// (saved by draft 44 or earlier). Splits at the first colon, since an ID
  /// never contains one but a file name may.
  static func split(_ name: String) -> (source: String, path: String)? {
    guard let index = name.firstIndex(of: separator) else { return nil }
    let source = name[..<index]
    guard ImageSource.isValidID(source) else { return nil }
    return (String(source), String(name[name.index(after: index)...]))
  }

  static func source(of name: String) -> String? {
    split(name)?.source
  }

  /// The path within the source, or the whole name if it has no source part.
  static func path(of name: String) -> String {
    split(name)?.path ?? name
  }
}

/// [D-photos-names] The path part of a saved photo's name:
/// `<album ID>:<photo ID>`, so a whole name is
/// `<source ID>:<album ID>:<photo ID>`. PhotoKit's local identifiers
/// (`AF0F5151-…/L0/001`) have no colon, so the path splits at its first one.
enum PhotoImageName {
  static func path(album: String, photo: String) -> String {
    "\(album)\(StoredImageName.separator)\(photo)"
  }

  /// The album and photo IDs in a photo's path, or nil if it has no colon.
  static func split(_ path: String) -> (album: String, photo: String)? {
    guard let index = path.firstIndex(of: StoredImageName.separator) else { return nil }
    let album = String(path[..<index])
    let photo = String(path[path.index(after: index)...])
    guard !album.isEmpty, !photo.isEmpty else { return nil }
    return (album, photo)
  }

  /// The photo ID in a whole stored name, or nil if it isn't a photo's.
  static func photo(ofStoredName name: String) -> String? {
    split(StoredImageName.path(of: name))?.photo
  }
}
