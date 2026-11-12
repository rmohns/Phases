import Foundation

/// One place images come from [D-image-sources]. For now always a folder.
/// No AppKit, so the unit tests can reach it.
struct ImageSource: Codable, Equatable, Identifiable {
  /// Made once when the source is added; never a path and never a position
  /// [D-source-names]. The library's order is stored separately.
  var id: String
  /// How Phases finds the folder: a security-scoped bookmark
  /// [D-scoped-bookmarks]. Nil only in UI test mode.
  var bookmark: Data?
  /// Where the folder is, home-relative when it's in the home folder
  /// (`~/Pictures/Wallpapers`) [D-source-location]. Shown in Settings and
  /// used when the bookmark stops working.
  var location: String
  var includesSubfolders = false

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
  /// Lenient, like `Phase`, so a list saved before a field was added (a
  /// source kind, for Photos albums) still loads.
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    bookmark = try container.decodeIfPresent(Data.self, forKey: .bookmark)
    location = try container.decodeIfPresent(String.self, forKey: .location) ?? ""
    includesSubfolders = try container.decodeIfPresent(Bool.self, forKey: .includesSubfolders) ?? false
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
