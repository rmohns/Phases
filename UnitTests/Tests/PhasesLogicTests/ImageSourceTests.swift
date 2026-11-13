import Foundation
import Testing
@testable import PhasesLogic

/// [D-image-sources] [D-source-names] [D-source-location] [D-photos-names] [D-photos-sources]
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

  // MARK: Saved sources and phases

  /// A valid ID: the alphabet leaves out I and O.
  private let id = "MGRATED2"
  private let display = "DISPLAY-UUID"

  @Test func testIDsAreValid() {
    #expect(ImageSource.isValidID(id))
    #expect(ImageSource.isValidID("QTHERXYZ"))
  }

  @Test func sourceRoundTripsAndOlderListsLoad() throws {
    let source = ImageSource(id: id, bookmark: Data([1, 2]), location: "~/Pictures", includesSubfolders: true)
    let data = try JSONEncoder().encode([source])
    #expect(try JSONDecoder().decode([ImageSource].self, from: data) == [source])
    // Only an ID: every other field falls back to its default.
    let sparse = try JSONDecoder().decode([ImageSource].self, from: Data(#"[{"id":"MGRATED2"}]"#.utf8))
    #expect(sparse == [ImageSource(id: id, bookmark: nil, location: "")])
  }

  @Test func phaseUsesASourceThroughAnySelection() {
    var phase = Phase(name: "Morning", trigger: .clockTime(minutes: 420))
    #expect(!phase.uses(source: id))
    phase.displayImageNames = [display: ["MGRATED2:b.png"]]
    #expect(phase.uses(source: id))
    #expect(!phase.uses(source: "QTHERXYZ"))
    phase.displayImageNames = [:]
    phase.imageNames = ["QTHERXYZ:a.png"]
    #expect(phase.uses(source: "QTHERXYZ"))
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

  // MARK: Photos sources [D-photos-names] [D-photos-sources]

  private let photoID = "AF0F5151-9FF0-4C58-AB92-57A7233FBB99/L0/001"
  private let albumID = "0E1F2A3B-1111-2222-3333-444455556666/L0/040"

  @Test func photoPathJoinsAndSplitsAtTheColon() throws {
    let path = PhotoImageName.path(album: albumID, photo: photoID)
    #expect(path == "\(albumID):\(photoID)")
    let parts = try #require(PhotoImageName.split(path))
    #expect(parts.album == albumID)
    #expect(parts.photo == photoID)
  }

  @Test func wholeStoredNameYieldsThePhotoID() {
    let name = StoredImageName.join(source: id, path: PhotoImageName.path(album: albumID, photo: photoID))
    #expect(StoredImageName.source(of: name) == id)
    #expect(PhotoImageName.photo(ofStoredName: name) == photoID)
  }

  @Test func pathWithNoColonDoesNotSplit() {
    #expect(PhotoImageName.split(photoID) == nil)
    #expect(PhotoImageName.split("Winter/snow.jpg") == nil)
    #expect(PhotoImageName.photo(ofStoredName: "MGRATED2:Winter/snow.jpg") == nil)
  }

  @Test func photosSourceRoundTrips() throws {
    let source = ImageSource(id: id, kind: .photosAlbum, location: "Trips / 2019", photosID: albumID, title: "Iceland")
    let data = try JSONEncoder().encode([source])
    let back = try JSONDecoder().decode([ImageSource].self, from: data)
    #expect(back == [source])
    #expect(back[0].kind == .photosAlbum)
    #expect(back[0].photosID == albumID)
    #expect(back[0].title == "Iceland")
  }

  @Test func sourceWithNoKindDecodesAsFolder() throws {
    let json = #"[{"id":"MGRATED2","location":"~/Pictures","includesSubfolders":true}]"#
    let sources = try JSONDecoder().decode([ImageSource].self, from: Data(json.utf8))
    #expect(sources[0].kind == .folder)
    #expect(sources[0].photosID == nil)
    #expect(sources[0].title == nil)
  }

  @Test func photosKindsAreNotInTheFileSystem() {
    #expect(ImageSource(id: id, location: "~/Pictures").isInFileSystem)
    for kind in [ImageSource.Kind.photosAlbum, .photosFolder] {
      let source = ImageSource(id: id, kind: kind, location: "", photosID: albumID)
      #expect(!source.isInFileSystem)
      #expect(source.isPhotos)
    }
  }

  private func photoEntries(album: String, photos: [String], group: String) -> [LibraryListing.Entry] {
    photos.map { LibraryListing.Entry(path: PhotoImageName.path(album: album, photo: $0), group: group, url: nil) }
  }

  @Test func photoEntriesHaveNoURLAndGroupByEntryGroup() {
    let album1 = "AAAAAAAA-0000-0000-0000-000000000000/L0/001"
    let album2 = "BBBBBBBB-0000-0000-0000-000000000000/L0/002"
    let entries =
      photoEntries(album: album1, photos: ["P1/L0/001", "P2/L0/001"], group: "2019 / Iceland")
      + photoEntries(album: album2, photos: ["P3/L0/001"], group: "2019 / Norway")
    let listing = LibraryListing(sources: [(id, entries)])
    #expect(listing.names.count == 3)
    for name in listing.names { #expect(listing.url(for: name) == nil) }
    #expect(listing.groups.map(\.folder) == ["2019 / Iceland", "2019 / Norway"])
    #expect(listing.groups.map(\.names.count) == [2, 1])
    #expect(listing.groups.allSatisfy { $0.sourceID == id })
  }

  @Test func photoInTwoAlbumsIsListedTwiceAndFoundByItsFirstName() throws {
    let shared = "SHARED00-0000-0000-0000-000000000000/L0/007"
    let entries =
      photoEntries(album: albumID, photos: [shared], group: "One")
      + photoEntries(album: "OTHERALB/L0/002", photos: [shared], group: "Two")
    let listing = LibraryListing(sources: [(id, entries)])
    #expect(listing.names.count == 2)
    let first = try #require(listing.name(forPhoto: shared))
    #expect(first == listing.names[0])
    #expect(first == StoredImageName.join(source: id, path: PhotoImageName.path(album: albumID, photo: shared)))
    #expect(listing.name(forPhoto: "NOSUCHPHOTO") == nil)
  }
}
