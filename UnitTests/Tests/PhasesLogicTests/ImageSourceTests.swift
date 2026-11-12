import Foundation
import Testing
@testable import PhasesLogic

/// [D-image-sources] [D-source-names] [D-source-location]
struct ImageSourceTests {
  // MARK: Stored names

  @Test func joinAndSplitRoundTrip() throws {
    let name = StoredImageName.join(source: "K3F9ABCD", path: "Winter/snow.jpg")
    #expect(name == "K3F9ABCD:Winter/snow.jpg")
    let parts = try #require(StoredImageName.split(name))
    #expect(parts.source == "K3F9ABCD")
    #expect(parts.path == "Winter/snow.jpg")
  }

  @Test func splitsAtFirstColonWhenFileNameHasOne() throws {
    let parts = try #require(StoredImageName.split("K3F9ABCD:Notes: 10:30.png"))
    #expect(parts.source == "K3F9ABCD")
    #expect(parts.path == "Notes: 10:30.png")
  }

  @Test func draft44NamesHaveNoSourcePart() {
    #expect(StoredImageName.split("Winter/snow.jpg") == nil)
    // A draft 44 file name with a colon: the part before it isn't an ID.
    #expect(StoredImageName.split("Meeting: notes.png") == nil)
    #expect(StoredImageName.split("abcdefgh:x.png") == nil)  // lowercase
    #expect(StoredImageName.path(of: "Winter/snow.jpg") == "Winter/snow.jpg")
  }

  @Test func newIDsAreValidAndAvoidExistingOnes() {
    var ids: Set<String> = []
    for _ in 0..<200 {
      let id = ImageSource.makeID(avoiding: ids)
      #expect(ImageSource.isValidID(id))
      #expect(!id.contains(":"))
      #expect(!ids.contains(id))
      ids.insert(id)
    }
  }

  // MARK: Locations

  private let home = URL(filePath: "/Users/someone", directoryHint: .isDirectory)

  @Test func insideHomeIsTilde() {
    let url = URL(filePath: "/Users/someone/Pictures/Wallpapers", directoryHint: .isDirectory)
    #expect(SourceLocation.string(for: url, home: home) == "~/Pictures/Wallpapers")
    #expect(SourceLocation.string(for: home, home: home) == "~")
  }

  @Test func outsideHomeKeepsFullPath() {
    let url = URL(filePath: "/Volumes/Art/Wallpapers", directoryHint: .isDirectory)
    #expect(SourceLocation.string(for: url, home: home) == "/Volumes/Art/Wallpapers")
    // A sibling whose name starts with the home folder's isn't inside it.
    let sibling = URL(filePath: "/Users/someone-else/Pictures", directoryHint: .isDirectory)
    #expect(SourceLocation.string(for: sibling, home: home) == "/Users/someone-else/Pictures")
  }

  @Test func locationRoundTrips() {
    for path in ["/Users/someone/Pictures/Wallpapers", "/Volumes/Art/Wallpapers", "/Users/someone"] {
      let url = URL(filePath: path, directoryHint: .isDirectory)
      let back = SourceLocation.url(for: SourceLocation.string(for: url, home: home), home: home)
      #expect(back.standardizedFileURL.path(percentEncoded: false).hasPrefix(path))
    }
  }

  @Test func realHomeIsNotASandboxContainer() {
    #expect(!SourceLocation.realHome.path(percentEncoded: false).contains("/Library/Containers/"))
  }

  // MARK: Migration from draft 44

  /// A valid ID: the alphabet leaves out I and O.
  private let id = "MGRATED2"
  private let display = "DISPLAY-UUID"

  @Test func testIDsAreValid() {
    #expect(ImageSource.isValidID(id))
    #expect(ImageSource.isValidID("QTHERXYZ"))
  }

  @Test func convertsEverySavedSelection() {
    var phase = Phase(name: "Morning", trigger: .clockTime(minutes: 420))
    phase.imageNames = ["a.png", "Winter/snow.jpg"]
    phase.displayImageNames = [display: ["b.png"], "EMPTY": []]
    let converted = SourceMigration.convert([phase], to: id)
    #expect(converted[0].imageNames == ["MGRATED2:a.png", "MGRATED2:Winter/snow.jpg"])
    #expect(converted[0].displayImageNames == [display: ["MGRATED2:b.png"], "EMPTY": []])
    #expect(converted[0].id == phase.id)
  }

  @Test func convertsLastAppliedImages() {
    let state = AppliedState(
      phaseID: UUID(), phaseStart: Date(), rotationSlot: 2, manualSteps: 1, imagesByDisplay: [display: "a.png"]
    )
    let converted = SourceMigration.convert(state, to: id)
    #expect(converted?.imagesByDisplay == [display: "MGRATED2:a.png"])
    #expect(converted?.rotationSlot == 2)
    #expect(SourceMigration.convert(nil, to: id) == nil)
  }

  @Test func emptySettingsStayEmpty() {
    #expect(SourceMigration.convert([], to: id).isEmpty)
    let phase = Phase(name: "Evening", trigger: .clockTime(minutes: 1080))
    #expect(SourceMigration.convert([phase], to: id) == [phase])
  }

  @Test func runningTwiceChangesNothing() {
    var phase = Phase(name: "Morning", trigger: .clockTime(minutes: 420))
    phase.imageNames = ["a.png"]
    phase.displayImageNames = [display: ["b.png"]]
    let once = SourceMigration.convert([phase], to: id)
    #expect(SourceMigration.convert(once, to: id) == once)
    #expect(SourceMigration.convert(once, to: "QTHERXYZ") == once)
  }

  // MARK: Library order

  private func items(_ names: [String]) -> [FolderScan.Item] {
    names.map { FolderScan.Item(name: $0, url: URL(filePath: "/x/\($0)")) }
  }

  @Test func sourcesInStoredOrderThenEachSourcesOwnOrder() {
    let listing = LibraryListing([
      ("AAAAAAAA", items(["z.png", "Winter/snow.jpg"])),
      ("BBBBBBBB", items(["a.png"])),
    ])
    #expect(listing.names == ["AAAAAAAA:z.png", "AAAAAAAA:Winter/snow.jpg", "BBBBBBBB:a.png"])
    #expect(listing.groups.map(\.sourceID) == ["AAAAAAAA", "AAAAAAAA", "BBBBBBBB"])
    #expect(listing.groups.map(\.folder) == ["", "Winter", ""])
  }

  @Test func reorderingSourcesKeepsEveryName() {
    let a = ("AAAAAAAA", items(["z.png"]))
    let b = ("BBBBBBBB", items(["a.png"]))
    let forward = LibraryListing([a, b])
    let reversed = LibraryListing([b, a])
    #expect(reversed.names == ["BBBBBBBB:a.png", "AAAAAAAA:z.png"])
    #expect(Set(forward.names) == Set(reversed.names))
    #expect(reversed.available(["AAAAAAAA:z.png", "BBBBBBBB:a.png"]) == ["BBBBBBBB:a.png", "AAAAAAAA:z.png"])
  }

  @Test func availableSkipsMissingAndOldNames() {
    let listing = LibraryListing([("AAAAAAAA", items(["a.png"]))])
    #expect(listing.available(["a.png", "AAAAAAAA:a.png", "CCCCCCCC:a.png"]) == ["AAAAAAAA:a.png"])
  }

  @Test func sameImageInTwoSourcesIsListedTwice() {
    let shared = items(["a.png"])
    let listing = LibraryListing([("AAAAAAAA", shared), ("BBBBBBBB", shared)])
    #expect(listing.names == ["AAAAAAAA:a.png", "BBBBBBBB:a.png"])
    #expect(listing.name(for: URL(filePath: "/x/a.png")) == "AAAAAAAA:a.png")
  }

  // MARK: Same folder

  @Test func sameFolderReachedByASymlinkIsDetected() throws {
    let fm = FileManager.default
    let root = fm.temporaryDirectory.appending(path: "ImageSourceTests-\(UUID().uuidString)", directoryHint: .isDirectory)
    defer { try? fm.removeItem(at: root) }
    let real = root.appending(path: "Real", directoryHint: .isDirectory)
    let other = root.appending(path: "Other", directoryHint: .isDirectory)
    try fm.createDirectory(at: real, withIntermediateDirectories: true)
    try fm.createDirectory(at: other, withIntermediateDirectories: true)
    let link = root.appending(path: "Link", directoryHint: .isDirectory)
    try fm.createSymbolicLink(at: link, withDestinationURL: real)
    #expect(FolderScan.isSameFolder(real, link))
    #expect(!FolderScan.isSameFolder(real, other))
  }
}
