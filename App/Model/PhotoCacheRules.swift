import Foundation

/// [D-photos-cache] Which photo cache files to delete, and what to name
/// them. Pure, so the unit tests can reach it.
enum PhotoCacheRules {
  /// 1 GB (author, 2026-11-12; cache management gets its own issue).
  static let limit: Int64 = 1_000_000_000
  /// Kept regardless of the limit when the wallpaper store can't be read,
  /// since a Space that isn't showing may still use them.
  static let keepWhenStoreUnreadable: TimeInterval = 30 * 24 * 60 * 60

  struct File: Equatable {
    var fileName: String
    var size: Int64
    var lastShown: Date
  }

  /// The files to delete, least recently shown first, to bring the cache
  /// under `limit`. Never one in `protected`: showing on a display, named in
  /// the wallpaper store, in the restore record, or fetched ahead and
  /// waiting. When the store can't be read, files shown in the last 30 days
  /// are kept as well.
  static func filesToDelete(
    _ files: [File], protected: Set<String>, storeReadable: Bool, now: Date, limit: Int64 = limit
  ) -> [String] {
    var total = files.reduce(Int64(0)) { $0 + $1.size }
    guard total > limit else { return [] }
    let candidates = files
      .filter { !protected.contains($0.fileName) }
      .filter { storeReadable || now.timeIntervalSince($0.lastShown) > keepWhenStoreUnreadable }
      .sorted { ($0.lastShown, $0.fileName) < ($1.lastShown, $1.fileName) }
    var deleting: [String] = []
    for file in candidates where total > limit {
      deleting.append(file.fileName)
      total -= file.size
    }
    return deleting
  }

  /// A cache file's name: the photo's ID made safe for a file name, then
  /// its modification time, so an edit in Photos makes a new file
  /// [D-photos-version]. `AF0F5151-…/L0/001` → `AF0F5151-…_L0_001-1794501057.jpeg`.
  static func fileName(photoID: String, modified: Date?, fileExtension: String) -> String {
    let safe = String(photoID.map { $0.isLetter || $0.isNumber || $0 == "-" ? $0 : "_" })
    let stamp = modified.map { String(Int64($0.timeIntervalSince1970)) } ?? "0"
    return "\(safe)-\(stamp).\(fileExtension)"
  }
}
