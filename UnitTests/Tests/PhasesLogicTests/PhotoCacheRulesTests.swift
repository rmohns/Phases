import Foundation
import Testing
@testable import PhasesLogic

/// [D-photos-cache] [D-photos-version]
struct PhotoCacheRulesTests {
  private let now = Date(timeIntervalSince1970: 1_800_000_000)
  private let day: TimeInterval = 24 * 60 * 60

  private func file(_ name: String, size: Int64 = 10, daysAgo: Double) -> PhotoCacheRules.File {
    PhotoCacheRules.File(fileName: name, size: size, lastShown: now.addingTimeInterval(-daysAgo * day))
  }

  private func delete(
    _ files: [PhotoCacheRules.File], protected: Set<String> = [], storeReadable: Bool = true, limit: Int64
  ) -> [String] {
    PhotoCacheRules.filesToDelete(files, protected: protected, storeReadable: storeReadable, now: now, limit: limit)
  }

  @Test func underTheLimitDeletesNothing() {
    let files = [file("a", daysAgo: 5), file("b", daysAgo: 1)]
    #expect(delete(files, limit: 100).isEmpty)
    // Exactly at the limit is not over it.
    #expect(delete(files, limit: 20).isEmpty)
  }

  @Test func overTheLimitDeletesLeastRecentlyShownFirstAndStopsOnceUnder() {
    let files = [file("new", daysAgo: 1), file("oldest", daysAgo: 9), file("mid", daysAgo: 5), file("old", daysAgo: 7)]
    // 40 total, limit 25: deleting oldest (30) is not enough, old (20) is.
    #expect(delete(files, limit: 25) == ["oldest", "old"])
    // Limit 35: one deletion gets under it.
    #expect(delete(files, limit: 35) == ["oldest"])
  }

  @Test func protectedFilesAreNeverDeletedEvenIfThatLeavesItOver() {
    let files = [file("a", daysAgo: 9), file("b", daysAgo: 8), file("c", daysAgo: 1)]
    #expect(delete(files, protected: ["a"], limit: 5) == ["b", "c"])
    #expect(delete(files, protected: ["a", "b", "c"], limit: 5).isEmpty)
  }

  @Test func unreadableStoreKeepsFilesShownInTheLast30Days() {
    let files = [file("recent", daysAgo: 29), file("old", daysAgo: 31), file("older", daysAgo: 60)]
    #expect(delete(files, storeReadable: false, limit: 0) == ["older", "old"])
    // The same files with a readable store: everything can go.
    #expect(delete(files, storeReadable: true, limit: 0) == ["older", "old", "recent"])
  }

  @Test func tiesBreakByFileNameDeterministically() {
    let files = [file("c", daysAgo: 3), file("a", daysAgo: 3), file("b", daysAgo: 3)]
    #expect(delete(files, limit: 15) == ["a", "b"])
    #expect(delete(files.reversed(), limit: 15) == ["a", "b"])
  }

  // MARK: File names

  private let photoID = "AF0F5151-9FF0-4C58-AB92-57A7233FBB99/L0/001"

  @Test func fileNameReplacesSlashesAndAppendsModificationSeconds() {
    let name = PhotoCacheRules.fileName(
      photoID: photoID, modified: Date(timeIntervalSince1970: 1_794_501_057.9), fileExtension: "jpeg")
    #expect(name == "AF0F5151-9FF0-4C58-AB92-57A7233FBB99_L0_001-1794501057.jpeg")
    #expect(!name.contains("/"))
  }

  @Test func differentModificationDateGivesADifferentName() {
    let a = PhotoCacheRules.fileName(photoID: photoID, modified: Date(timeIntervalSince1970: 1_000), fileExtension: "heic")
    let b = PhotoCacheRules.fileName(photoID: photoID, modified: Date(timeIntervalSince1970: 2_000), fileExtension: "heic")
    #expect(a != b)
  }

  @Test func nilModifiedIsZero() {
    #expect(
      PhotoCacheRules.fileName(photoID: photoID, modified: nil, fileExtension: "heic")
        == "AF0F5151-9FF0-4C58-AB92-57A7233FBB99_L0_001-0.heic")
  }
}
