import Foundation

/// [D-in-order-remembers] In order's picks: the image after the one a
/// selection last showed, in library order. Pure, so the unit tests can
/// reach it.
enum InOrderPicker {
  /// The position key for the All Displays selection; displays with their
  /// own images use their display UUID.
  static let sharedKey = "all"

  enum Mode: Equatable {
    /// A scheduled change, Change Now, or a phase starting: the next image.
    case advance
    /// A display shows an image no longer in its selection, or nothing (a
    /// selection edited, a display connected, the display mode changed):
    /// keep the remembered image where it's still in the selection,
    /// otherwise the next one.
    case repair
  }

  /// `count` consecutive images from `pool` (the selection's available
  /// images, in library order), wrapping.
  /// - Parameters:
  ///   - remembered: the image this selection last showed, if any.
  ///   - library: every image in the library, in library order, to place a
  ///     remembered image that's no longer in the pool but still there.
  ///   - sourceOrder: the library's source IDs, in order, to place a
  ///     remembered image that's gone from the library.
  ///   - photoSources: the IDs of Photos sources, whose missing photos
  ///     can't be placed by name.
  ///   - showing: what the first display these picks go to shows now; an
  ///     advance never lands on it while the pool has another image.
  static func picks(
    count: Int, from pool: [String], remembered: String?, library: [String] = [], sourceOrder: [String],
    photoSources: Set<String> = [], showing: Set<String>, mode: Mode
  ) -> [String] {
    guard !pool.isEmpty, count > 0 else { return [] }
    var start = startIndex(
      in: pool, remembered: remembered, library: library, sourceOrder: sourceOrder, photoSources: photoSources,
      mode: mode
    )
    if mode == .advance, pool.count > 1, showing.contains(pool[start % pool.count]) {
      start += 1
    }
    return (0..<count).map { pool[(start + $0) % pool.count] }
  }

  private static func startIndex(
    in pool: [String], remembered: String?, library: [String], sourceOrder: [String], photoSources: Set<String>,
    mode: Mode
  ) -> Int {
    guard let remembered else { return 0 }
    if let index = pool.firstIndex(of: remembered) {
      return mode == .advance ? index + 1 : index
    }
    let libraryIndex = Dictionary(library.enumerated().map { ($1, $0) }, uniquingKeysWith: { first, _ in first })
    // Deselected but still in the library: the first image after it.
    if let place = libraryIndex[remembered] {
      return pool.firstIndex { (libraryIndex[$0] ?? -1) > place } ?? 0
    }
    // Gone from the library.
    guard let parts = StoredImageName.split(remembered), let source = sourceOrder.firstIndex(of: parts.source) else {
      return 0
    }
    if photoSources.contains(parts.source) {
      // [D-in-order-remembers] A photo can't be placed by its ID: its
      // album starts over, or if the album is gone, its source onward.
      if let album = PhotoImageName.split(parts.path)?.album {
        let prefix = StoredImageName.join(source: parts.source, path: PhotoImageName.path(album: album, photo: ""))
        if let albumStart = library.firstIndex(where: { $0.hasPrefix(prefix) }) {
          return pool.firstIndex { (libraryIndex[$0] ?? -1) >= albumStart } ?? 0
        }
      }
      return pool.firstIndex { name in
        StoredImageName.source(of: name).flatMap(sourceOrder.firstIndex(of:)).map { $0 >= source } ?? false
      } ?? 0
    }
    // A file: the first image after where its path sat.
    let rank = (source: source, path: parts.path)
    return pool.firstIndex { name in
      guard let other = self.rank(of: name, sourceOrder: sourceOrder) else { return false }
      return comesBefore(rank, other)
    } ?? 0
  }

  /// Where a stored name sits in library order: its source's place, then
  /// its path in the source's own order.
  private static func rank(of name: String, sourceOrder: [String]) -> (source: Int, path: String)? {
    guard let parts = StoredImageName.split(name), let source = sourceOrder.firstIndex(of: parts.source) else {
      return nil
    }
    return (source, parts.path)
  }

  private static func comesBefore(_ lhs: (source: Int, path: String), _ rhs: (source: Int, path: String)) -> Bool {
    if lhs.source != rhs.source { return lhs.source < rhs.source }
    return FolderScan.inDisplayOrder(lhs.path, rhs.path)
  }
}
