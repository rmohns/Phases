import Foundation
import Testing
@testable import PhasesLogic

/// [D-photos-cache] [D-photos-cache-cleanup] [D-cache-in-about] [D-photos-version]
struct PhotoCacheRulesTests {
  private let now = Date(timeIntervalSince1970: 1_800_000_000)
  private let day: TimeInterval = 24 * 60 * 60
  private static let megabyte: Int64 = 1_000_000

  private func file(_ name: String, size: Int64 = 10, daysAgo: Double, inSources: Bool = true) -> PhotoCacheRules.File {
    PhotoCacheRules.File(
      fileName: name, size: size, lastShown: now.addingTimeInterval(-daysAgo * day), isInSources: inSources)
  }

  private func situation(
    protected: Set<String> = [], storeReadable: Bool = true, sourcesRead: Bool = true, available: Int64? = nil
  ) -> PhotoCacheRules.Situation {
    PhotoCacheRules.Situation(
      protected: protected, storeReadable: storeReadable, sourcesRead: sourcesRead, availableDiskSpace: available,
      now: now)
  }

  private func delete(
    _ files: [PhotoCacheRules.File], protected: Set<String> = [], storeReadable: Bool = true,
    sourcesRead: Bool = true, available: Int64? = nil, limit: Int64 = PhotoCacheRules.limit
  ) -> [String] {
    PhotoCacheRules.filesToDelete(
      files,
      in: situation(protected: protected, storeReadable: storeReadable, sourcesRead: sourcesRead, available: available),
      limit: limit)
  }

  // MARK: The numbers

  @Test func numbersAreTheSpecs() {
    #expect(PhotoCacheRules.maxAge == 30 * day)
    #expect(PhotoCacheRules.limit == 500_000_000)
    #expect(PhotoCacheRules.lowDiskThreshold == 25_600_000_000)
    #expect(PhotoCacheRules.lowDiskFloor == 50_000_000)
  }

  // MARK: Rule 1: gone from the sources

  @Test func goneFromTheSourcesIsDeletedWhateverItsAgeOrSize() {
    let files = [file("kept", daysAgo: 1), file("gone", daysAgo: 0, inSources: false)]
    #expect(delete(files) == ["gone"])
  }

  @Test func goneFromTheSourcesWaitsUntilEverySourceIsRead() {
    let files = [file("kept", daysAgo: 1), file("gone", daysAgo: 0, inSources: false)]
    #expect(delete(files, sourcesRead: false).isEmpty)
  }

  @Test func goneFromTheSourcesSparesProtectedFiles() {
    let files = [file("showing", daysAgo: 0, inSources: false), file("gone", daysAgo: 0, inSources: false)]
    #expect(delete(files, protected: ["showing"]) == ["gone"])
  }

  @Test func goneFromTheSourcesSparesRecentFilesWhenTheStoreIsUnreadable() {
    let files = [file("recent", daysAgo: 29, inSources: false), file("old", daysAgo: 31, inSources: false)]
    #expect(delete(files, storeReadable: false) == ["old"])
  }

  // MARK: Rule 2: not shown in 30 days

  @Test func notShownInThirtyDaysIsDeleted() {
    let files = [file("thirty", daysAgo: 30), file("older", daysAgo: 30.01), file("oldest", daysAgo: 90)]
    #expect(delete(files) == ["oldest", "older"])
  }

  @Test func protectedFilesSurviveTheirAge() {
    #expect(delete([file("otherSpace", daysAgo: 90)], protected: ["otherSpace"]).isEmpty)
  }

  // MARK: Rule 3: the 500 MB limit

  @Test func overFiveHundredMegabytesDeletesLeastRecentlyShownFirst() {
    let files = [
      file("a", size: 200 * Self.megabyte, daysAgo: 3),
      file("b", size: 200 * Self.megabyte, daysAgo: 2),
      file("c", size: 200 * Self.megabyte, daysAgo: 1),
    ]
    #expect(delete(files) == ["a"])
    #expect(delete(Array(files.prefix(2))).isEmpty)
  }

  // MARK: Rule 4: low disk

  @Test func lowDiskIsUnderTwentyFivePointSixGigabytes() {
    #expect(PhotoCacheRules.isLowDisk(available: 25_599_999_999))
    #expect(!PhotoCacheRules.isLowDisk(available: 25_600_000_000))
    #expect(!PhotoCacheRules.isLowDisk(available: nil))
  }

  @Test func lowDiskShrinksTheCacheToTheFloor() {
    let files = (0..<10).map { file("f\($0)", size: 10 * Self.megabyte, daysAgo: Double(10 - $0)) }
    // 100 MB: down to 50 MB, oldest first.
    #expect(delete(files, available: 25_000_000_000) == ["f0", "f1", "f2", "f3", "f4"])
    #expect(delete(files, available: 26_000_000_000).isEmpty)
    #expect(delete(files, available: nil).isEmpty)
  }

  @Test func lowDiskNeverDeletesProtectedFiles() {
    let files = [file("showing", size: 80 * Self.megabyte, daysAgo: 5), file("other", size: 10 * Self.megabyte, daysAgo: 1)]
    #expect(delete(files, protected: ["showing"], available: 1) == ["other"])
  }

  @Test func rulesApplyInOrderEachFileOnce() {
    let files = [
      file("gone", size: 300 * Self.megabyte, daysAgo: 1, inSources: false),
      file("stale", size: 10 * Self.megabyte, daysAgo: 40),
      file("big", size: 400 * Self.megabyte, daysAgo: 5),
      file("recent", size: 200 * Self.megabyte, daysAgo: 2),
    ]
    // Rule 1, rule 2, then 600 MB is over 500: the least recently shown goes.
    #expect(delete(files) == ["gone", "stale", "big"])
    // Low disk: the rest goes too, to get under 50 MB.
    #expect(delete(files, available: 0) == ["gone", "stale", "big", "recent"])
  }

  // MARK: Clear…

  @Test func clearDeletesEverythingButProtectedFiles() {
    let files = [file("a", daysAgo: 1), file("showing", daysAgo: 2), file("b", daysAgo: 3)]
    #expect(PhotoCacheRules.filesToClear(files, in: situation(protected: ["showing"])) == ["b", "a"])
  }

  @Test func clearKeepsRecentFilesWhenTheStoreIsUnreadable() {
    let files = [file("recent", daysAgo: 1), file("old", daysAgo: 31)]
    #expect(PhotoCacheRules.filesToClear(files, in: situation(storeReadable: false)) == ["old"])
  }

  // MARK: About's figure

  @Test func usageTextInFinderMegabytes() {
    let en = Locale(identifier: "en_US")
    #expect(PhotoCacheRules.usageText(bytes: 38_400_000, photos: 20, locale: en) == "38 MB · 20 photos")
    #expect(PhotoCacheRules.usageText(bytes: 38_500_000, photos: 1, locale: en) == "39 MB · 1 photo")
    #expect(PhotoCacheRules.usageText(bytes: 0, photos: 0, locale: en) == "0 MB · 0 photos")
    #expect(PhotoCacheRules.usageText(bytes: 1, photos: 1, locale: en) == "1 MB · 1 photo")
    #expect(PhotoCacheRules.usageText(bytes: 999_499_999, photos: 600, locale: en) == "999 MB · 600 photos")
    #expect(PhotoCacheRules.usageText(bytes: 1_234_000_000, photos: 700, locale: en) == "1.2 GB · 700 photos")
  }

  @Test func currentFileIsTheNameForThePhotosModificationDate() {
    let modified = Date(timeIntervalSince1970: 1_000)
    let name = PhotoCacheRules.fileName(photoID: "p/1", modified: modified, fileExtension: "heic")
    #expect(PhotoCacheRules.isCurrentFile(name, photoID: "p/1", modified: modified))
    #expect(!PhotoCacheRules.isCurrentFile(name, photoID: "p/1", modified: Date(timeIntervalSince1970: 2_000)))
    #expect(!PhotoCacheRules.isCurrentFile(name, photoID: "p/2", modified: modified))
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
