import Foundation
import Testing
@testable import PhasesLogic

/// In order remembers the last image it showed and moves to the next one
/// `[D-in-order-remembers]`.
struct InOrderPickerTests {
  private let first = "AAAAAAAA"
  private let second = "BBBBBBBB"
  private var sources: [String] { [first, second] }

  private func name(_ source: String, _ path: String) -> String {
    StoredImageName.join(source: source, path: path)
  }

  private func next(
    _ pool: [String], after remembered: String?, count: Int = 1, showing: Set<String> = [],
    mode: InOrderPicker.Mode = .advance
  ) -> [String] {
    InOrderPicker.picks(
      count: count, from: pool, remembered: remembered, sourceOrder: sources, showing: showing, mode: mode
    )
  }

  private var abc: [String] { [name(first, "a.jpg"), name(first, "b.jpg"), name(first, "c.jpg")] }

  @Test func nothingRememberedStartsAtTheFirstImage() {
    #expect(next(abc, after: nil) == [abc[0]])
  }

  @Test func advancesToTheImageAfterTheRememberedOne() {
    #expect(next(abc, after: abc[0]) == [abc[1]])
    #expect(next(abc, after: abc[1]) == [abc[2]])
  }

  @Test func wrapsFromTheLastImageToTheFirst() {
    #expect(next(abc, after: abc[2]) == [abc[0]])
  }

  @Test func addingImagesDoesNotMoveThePlace() {
    // Selecting more images only changes what "next" is.
    let more = [abc[0], name(first, "a2.jpg"), abc[1], abc[2]]
    #expect(next(more, after: abc[0]) == [name(first, "a2.jpg")])
  }

  @Test func aDeselectedImageContinuesAfterWhereItSat() {
    let withoutB = [abc[0], abc[2]]
    #expect(next(withoutB, after: abc[1]) == [abc[2]])
  }

  @Test func aDeselectedLastImageWrapsToTheFirst() {
    #expect(next([abc[0], abc[1]], after: abc[2]) == [abc[0]])
  }

  @Test func placeCountsSourcesInLibraryOrder() {
    let pool = [abc[0], name(second, "a.jpg")]
    // b.jpg of the first source is gone; next is the second source's image,
    // even though "a.jpg" sorts before "b.jpg".
    #expect(next(pool, after: abc[1]) == [name(second, "a.jpg")])
  }

  @Test func subfoldersComeAfterTheTopLevel() {
    let pool = [abc[0], name(first, "sub/a.jpg")]
    #expect(next(pool, after: name(first, "z.jpg")) == [name(first, "sub/a.jpg")])
  }

  @Test func anImageWhoseSourceIsGoneStartsAtTheFirstImage() {
    #expect(next(abc, after: name("CCCCCCCC", "b.jpg")) == [abc[0]])
  }

  @Test func neverTheImageAlreadyShowing() {
    // Remembered c, but the display shows a (a Space switch, say).
    #expect(next(abc, after: abc[2], showing: [abc[0]]) == [abc[1]])
  }

  @Test func aSingleImageIsShownEvenIfShowing() {
    #expect(next([abc[0]], after: abc[0], showing: [abc[0]]) == [abc[0]])
  }

  @Test func severalDisplaysTakeConsecutiveImages() {
    #expect(next(abc, after: abc[0], count: 2) == [abc[1], abc[2]])
    #expect(next(abc, after: abc[1], count: 3) == [abc[2], abc[0], abc[1]])
  }

  @Test func repairKeepsTheRememberedImage() {
    #expect(next(abc, after: abc[1], showing: [abc[1]], mode: .repair) == [abc[1]])
  }

  @Test func repairReplacesARememberedImageNoLongerSelected() {
    #expect(next([abc[0], abc[2]], after: abc[1], mode: .repair) == [abc[2]])
  }

  @Test func emptyPoolPicksNothing() {
    #expect(next([], after: abc[0]).isEmpty)
  }
}

/// Photos sources in In order `[D-in-order-remembers]` (draft 54): photo
/// IDs are random, so a missing photo is placed by the library, not by name.
struct InOrderPickerPhotosTests {
  private let folder = "AAAAAAAA"
  private let photos = "PPPPPPPP"

  private func photo(_ album: String, _ id: String) -> String {
    StoredImageName.join(source: photos, path: PhotoImageName.path(album: album, photo: id))
  }

  private func file(_ path: String) -> String { StoredImageName.join(source: folder, path: path) }

  private func next(_ pool: [String], after remembered: String, library: [String]) -> String? {
    InOrderPicker.picks(
      count: 1, from: pool, remembered: remembered, library: library, sourceOrder: [folder, photos],
      photoSources: [photos], showing: [], mode: .advance
    ).first
  }

  // Album X in its own order: z, a, m (IDs that sort differently).
  private var albumX: [String] { [photo("X", "z"), photo("X", "a"), photo("X", "m")] }
  private var albumY: [String] { [photo("Y", "q"), photo("Y", "b")] }

  @Test func aDeselectedPhotoContinuesAfterWhereItSitsInTheAlbum() {
    let library = albumX + albumY
    // z deselected: next is a, though "a" sorts before "z".
    #expect(next([albumX[1], albumX[2]] + albumY, after: albumX[0], library: library) == albumX[1])
    // a deselected: next is m.
    #expect(next([albumX[0], albumX[2]] + albumY, after: albumX[1], library: library) == albumX[2])
  }

  @Test func aPhotoRemovedFromItsAlbumStartsTheAlbumOver() {
    let gone = photo("X", "removed")
    #expect(next(albumX + albumY, after: gone, library: albumX + albumY) == albumX[0])
    // The album's first photo isn't selected: its first selected one.
    #expect(next([albumX[2]] + albumY, after: gone, library: albumX + albumY) == albumX[2])
  }

  @Test func aPhotoWhoseAlbumIsGoneCarriesOnFromItsSource() {
    let library = [file("f.jpg")] + albumY
    #expect(next(library, after: photo("X", "z"), library: library) == albumY[0])
  }

  @Test func aDeselectedFileStillUsesTheLibraryOrder() {
    let library = [file("a.jpg"), file("b.jpg"), file("c.jpg")]
    #expect(next([library[0], library[2]], after: library[1], library: library) == library[2])
  }
}
