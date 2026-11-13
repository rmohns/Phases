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
  ///   - sourceOrder: the library's source IDs, in order, to place a
  ///     remembered image that's no longer in the pool.
  ///   - showing: what the first display these picks go to shows now; an
  ///     advance never lands on it while the pool has another image.
  static func picks(
    count: Int, from pool: [String], remembered: String?, sourceOrder: [String],
    showing: Set<String>, mode: Mode
  ) -> [String] {
    guard !pool.isEmpty, count > 0 else { return [] }
    var start = startIndex(in: pool, remembered: remembered, sourceOrder: sourceOrder, mode: mode)
    if mode == .advance, pool.count > 1, showing.contains(pool[start % pool.count]) {
      start += 1
    }
    return (0..<count).map { pool[(start + $0) % pool.count] }
  }

  private static func startIndex(in pool: [String], remembered: String?, sourceOrder: [String], mode: Mode) -> Int {
    guard let remembered else { return 0 }
    if let index = pool.firstIndex(of: remembered) {
      return mode == .advance ? index + 1 : index
    }
    // No longer in the selection: the first image after where it sat, or
    // the first image if its source is gone.
    guard let rank = rank(of: remembered, sourceOrder: sourceOrder) else { return 0 }
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
