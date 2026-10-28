import SwiftUI
import Testing

/// Arrow-key movement in the thumbnail grid `[D-grid-one-tab-stop]`.
/// Three columns; rows are [a b c] [d e] in the top folder, then [f g] under
/// the "Sub" heading.
struct ImageGridNavigationTests {
  private let navigation = ImageGridNavigation(
    groups: [(folder: "", names: ["a", "b", "c", "d", "e"]), (folder: "Sub", names: ["f", "g"])],
    columns: 3
  )

  private func move(_ from: String, _ direction: MoveCommandDirection) -> String {
    navigation.destination(from: from, direction)
  }

  @Test func leftAndRightWrapAcrossRows() {
    #expect(move("c", .right) == "d")
    #expect(move("d", .left) == "c")
  }

  @Test func leftAndRightCrossSubfolderHeadings() {
    #expect(move("e", .right) == "f")
    #expect(move("f", .left) == "e")
  }

  @Test func leftAndRightStopAtTheEnds() {
    #expect(move("a", .left) == "a")
    #expect(move("g", .right) == "g")
  }

  @Test func downKeepsTheColumn() {
    #expect(move("a", .down) == "d")
    #expect(move("b", .down) == "e")
  }

  @Test func downOntoAShorterRowLandsOnItsLastImage() {
    #expect(move("c", .down) == "e")
  }

  @Test func upAndDownCrossSubfolderHeadings() {
    #expect(move("e", .down) == "g")
    #expect(move("f", .up) == "d")
  }

  @Test func upAndDownStopAtTheEdges() {
    #expect(move("b", .up) == "b")
    #expect(move("g", .down) == "g")
  }

  @Test func unknownImageMovesToTheFirst() {
    #expect(move("missing", .right) == "a")
  }
}
