import Foundation

/// [D-photos-cache] [D-photos-cache-cleanup] Which photo cache files to
/// delete, and what to name them. Pure, so the unit tests can reach it.
enum PhotoCacheRules {
  /// Rule 2: a file not shown in this long goes (author, 2026-11-27).
  static let maxAge: TimeInterval = 30 * 24 * 60 * 60
  /// Rule 3: the size backstop, as Finder counts (author, 2026-11-27).
  static let limit: Int64 = 500_000_000
  /// Rule 4: below this much available space, the disk is low: 10% of a
  /// 256 GB startup disk (author, 2026-11-27).
  static let lowDiskThreshold: Int64 = 25_600_000_000
  /// Rule 4: what the cache shrinks to while the disk is low.
  static let lowDiskFloor: Int64 = 50_000_000
  /// Kept by every rule when the wallpaper store can't be read, since a
  /// Space that isn't showing may still use them.
  static let keepWhenStoreUnreadable: TimeInterval = 30 * 24 * 60 * 60

  /// About's Photos Cache figure [D-cache-in-about]: megabytes as Finder
  /// counts them (1000² bytes, rounded; a cache with anything in it shows
  /// at least 1 MB), gigabytes to one decimal from 1,000 MB, then the
  /// number of photos. "38 MB · 20 photos".
  static func usageText(bytes: Int64, photos: Int, locale: Locale = .current) -> String {
    let megabytes = bytes <= 0 ? 0 : max(1, (bytes + 500_000) / 1_000_000)
    let size =
      megabytes < 1000
      ? "\(megabytes) MB"
      : (Double(bytes) / 1_000_000_000).formatted(.number.precision(.fractionLength(1)).locale(locale)) + " GB"
    return "\(size) · \(photos) \(photos == 1 ? "photo" : "photos")"
  }

  struct File: Equatable {
    var fileName: String
    var size: Int64
    /// When it last showed, or when it was fetched if it never has.
    var lastShown: Date
    /// Rule 1: whether its photo is in a Photos source now and this is the
    /// photo as it is now, not an older file from before an edit
    /// [D-photos-version].
    var isInSources: Bool = true
  }

  /// What a cleanup knows besides the files.
  struct Situation: Equatable {
    /// Never deleted: showing on a display, named in the wallpaper store,
    /// in the restore record, or fetched ahead and waiting.
    var protected: Set<String> = []
    /// False when macOS's wallpaper store can't be read.
    var storeReadable = true
    /// False while any Photos source can't be opened, or before every one
    /// has been read; rule 1 waits for it.
    var sourcesRead = true
    /// Space available on the cache's disk, or nil if it can't be read.
    var availableDiskSpace: Int64?
    var now: Date
  }

  /// Whether `available` (nil if unknown) is under the low-disk threshold.
  static func isLowDisk(available: Int64?) -> Bool {
    guard let available else { return false }
    return available < lowDiskThreshold
  }

  /// The files to delete, applying the four rules in order. Rules 3 and 4
  /// go least recently shown first and stop once the cache is under their
  /// size.
  static func filesToDelete(_ files: [File], in situation: Situation, limit: Int64 = limit) -> [String] {
    // Deletable files, least recently shown first.
    var candidates = files.filter { mayDelete($0, in: situation) }.sorted(by: leastRecentlyShownFirst)
    var total = files.reduce(Int64(0)) { $0 + $1.size }
    var deleting: [String] = []
    /// Deletes candidates in order while `shouldDelete` says so.
    func delete(while shouldDelete: (File) -> Bool) {
      for file in candidates where shouldDelete(file) {
        deleting.append(file.fileName)
        total -= file.size
      }
      let deleted = Set(deleting)
      candidates.removeAll { deleted.contains($0.fileName) }
    }
    // 1. Gone from the sources.
    if situation.sourcesRead { delete { !$0.isInSources } }
    // 2. Not shown in 30 days.
    delete { situation.now.timeIntervalSince($0.lastShown) > maxAge }
    // 3. Over the limit.
    delete { _ in total > limit }
    // 4. Low disk: down to the floor.
    if isLowDisk(available: situation.availableDiskSpace) { delete { _ in total > lowDiskFloor } }
    return deleting
  }

  /// Clear… in Settings: every file the rules may delete, whatever their
  /// age or size [D-cache-in-about].
  static func filesToClear(_ files: [File], in situation: Situation) -> [String] {
    files.filter { mayDelete($0, in: situation) }.sorted(by: leastRecentlyShownFirst).map(\.fileName)
  }

  /// Not protected, and when the store can't be read, not shown in the
  /// last 30 days.
  private static func mayDelete(_ file: File, in situation: Situation) -> Bool {
    guard !situation.protected.contains(file.fileName) else { return false }
    return situation.storeReadable || situation.now.timeIntervalSince(file.lastShown) > keepWhenStoreUnreadable
  }

  private static func leastRecentlyShownFirst(_ a: File, _ b: File) -> Bool {
    (a.lastShown, a.fileName) < (b.lastShown, b.fileName)
  }

  /// A cache file's name: the photo's ID made safe for a file name, then
  /// its modification time, so an edit in Photos makes a new file
  /// [D-photos-version]. `AF0F5151-…/L0/001` → `AF0F5151-…_L0_001-1794501057.jpeg`.
  static func fileName(photoID: String, modified: Date?, fileExtension: String) -> String {
    let safe = String(photoID.map { $0.isLetter || $0.isNumber || $0 == "-" ? $0 : "_" })
    let stamp = modified.map { String(Int64($0.timeIntervalSince1970)) } ?? "0"
    return "\(safe)-\(stamp).\(fileExtension)"
  }

  /// Whether `fileName` is the photo as it is now (last modified
  /// `modified`), whatever its extension [D-photos-version].
  static func isCurrentFile(_ fileName: String, photoID: String, modified: Date?) -> Bool {
    fileName.hasPrefix(Self.fileName(photoID: photoID, modified: modified, fileExtension: ""))
  }
}
