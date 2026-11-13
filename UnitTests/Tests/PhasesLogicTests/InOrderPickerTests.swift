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
