import SwiftUI
import Testing
@testable import PhasesLogic

/// Arrow-key movement in the thumbnail grid `[D-grid-one-tab-stop]`
/// `[D-grid-collapse]`. Three columns. Source S has two groups, so its
/// rows are [S] [S "Top Level"] [a b c] [d e] [S:Sub] [f g]; source T has
/// one group and no subheading, so its rows are [T] [h].
struct ImageGridNavigationTests {
  typealias Heading = GridOutline.Heading
  typealias Item = GridOutline.Item

  private static let groups = [
    LibraryListing.Group(sourceID: "S", folder: "", names: ["a", "b", "c", "d", "e"]),
    LibraryListing.Group(sourceID: "S", folder: "Sub", names: ["f", "g"]),
    LibraryListing.Group(sourceID: "T", folder: "", names: ["h"]),
  ]

  private let s = Heading.source("S")
  private let top = Heading(sourceID: "S", folder: "")
  private let sub = Heading(sourceID: "S", folder: "Sub")
  private let t = Heading.source("T")

  private func outcome(
    _ from: Item, _ direction: MoveCommandDirection, column: Int? = nil, option: Bool = false,
    collapsed: Set<String> = []
  ) -> ImageGridNavigation.Outcome {
    ImageGridNavigation(
      outline: GridOutline(groups: Self.groups, collapsed: collapsed), columns: 3
    ).outcome(from: from, direction, column: column, option: option)
  }

  private func image(_ name: String) -> ImageGridNavigation.Outcome {
    .move(.image(name), column: nil)
  }

  @Test func leftAndRightWrapAcrossRows() {
    #expect(outcome(.image("c"), .right) == image("d"))
    #expect(outcome(.image("d"), .left) == image("c"))
  }

  @Test func leftAndRightStepOntoAndOffHeadings() {
    #expect(outcome(.image("e"), .right) == .move(.heading(sub), column: nil))
    #expect(outcome(.image("f"), .left) == .move(.heading(sub), column: nil))
    #expect(outcome(.heading(sub), .right) == image("f"))
    #expect(outcome(.heading(sub), .left, collapsed: [sub.key]) == image("e"))
    #expect(outcome(.image("a"), .left) == .move(.heading(top), column: nil))
    #expect(outcome(.image("g"), .right) == .move(.heading(t), column: nil))
  }

  @Test func leftAndRightStopAtTheEnds() {
    #expect(outcome(.image("h"), .right) == .stay)
    #expect(outcome(.heading(s), .left, collapsed: [s.key]) == .stay)
  }

  @Test func downKeepsTheColumn() {
    #expect(outcome(.image("a"), .down) == image("d"))
    #expect(outcome(.image("b"), .down) == image("e"))
    #expect(outcome(.image("e"), .up) == image("b"))
  }

  @Test func downOntoAShorterRowLandsOnItsLastImage() {
    #expect(outcome(.image("c"), .down) == image("e"))
  }

  @Test func upAndDownOntoAHeadingCarryTheColumn() {
    #expect(outcome(.image("e"), .down) == .move(.heading(sub), column: 1))
    #expect(outcome(.image("f"), .up) == .move(.heading(sub), column: 0))
    #expect(outcome(.image("c"), .up) == .move(.heading(top), column: 2))
  }

  @Test func downFromAHeadingLandsInTheCarriedColumn() {
    #expect(outcome(.heading(sub), .down, column: 1) == image("g"))
    #expect(outcome(.heading(top), .down, column: 2) == image("c"))
    #expect(outcome(.heading(sub), .up, column: 1) == image("e"))
  }

  @Test func downFromAHeadingWithNoColumnLandsInColumnZero() {
    #expect(outcome(.heading(sub), .down) == image("f"))
    #expect(outcome(.heading(top), .down, column: nil) == image("a"))
  }

  @Test func upAndDownStopAtTheEdges() {
    #expect(outcome(.heading(s), .up) == .stay)
    #expect(outcome(.image("h"), .down) == .stay)
  }

  @Test func leftOnAnExpandedHeadingCollapsesIt() {
    #expect(outcome(.heading(sub), .left) == .setCollapsed([sub], true))
    #expect(outcome(.heading(s), .left) == .setCollapsed([s], true))
  }

  @Test func rightOnACollapsedHeadingExpandsIt() {
    #expect(outcome(.heading(sub), .right, collapsed: [sub.key]) == .setCollapsed([sub], false))
    #expect(outcome(.heading(s), .right, collapsed: [s.key]) == .setCollapsed([s], false))
  }

  @Test func leftOnACollapsedHeadingMovesToThePreviousItem() {
    #expect(outcome(.heading(sub), .left, collapsed: [sub.key]) == image("e"))
    #expect(outcome(.heading(t), .left, collapsed: [t.key]) == image("g"))
  }

  @Test func rightOnAnExpandedHeadingMovesToTheNextItem() {
    #expect(outcome(.heading(s), .right) == .move(.heading(top), column: nil))
    #expect(outcome(.heading(top), .right) == image("a"))
  }

  @Test func optionOnASourceHeadingFoldsItWithAllItsSubheadings() {
    #expect(outcome(.heading(s), .left, option: true) == .setCollapsed([s, top, sub], true))
    #expect(
      outcome(.heading(s), .right, option: true, collapsed: [s.key])
        == .setCollapsed([s, top, sub], false))
  }

  @Test func optionOnASubheadingActsOnItAlone() {
    #expect(outcome(.heading(sub), .left, option: true) == .setCollapsed([sub], true))
    #expect(
      outcome(.heading(sub), .right, option: true, collapsed: [sub.key])
        == .setCollapsed([sub], false))
  }

  @Test func optionOnASourceWithoutSubheadingsActsOnItAlone() {
    #expect(outcome(.heading(t), .left, option: true) == .setCollapsed([t], true))
  }

  @Test func leftAndRightSkipImagesInCollapsedSections() {
    // "Top Level" collapsed: a-e are skipped, its heading isn't.
    #expect(outcome(.heading(top), .right, collapsed: [top.key]) == .setCollapsed([top], false))
    #expect(outcome(.heading(sub), .left, collapsed: [top.key]) == .setCollapsed([sub], true))
    #expect(
      outcome(.heading(sub), .left, collapsed: [top.key, sub.key])
        == .move(.heading(top), column: nil))
    // Source S collapsed: only its heading is left, so ← from T lands on it.
    #expect(
      outcome(.heading(t), .left, collapsed: [s.key, t.key]) == .move(.heading(s), column: nil))
  }

  @Test func upAndDownSkipImagesInCollapsedSections() {
    // With "Top Level" collapsed, the row above S:Sub is its own heading.
    #expect(
      outcome(.heading(sub), .up, column: 1, collapsed: [top.key])
        == .move(.heading(top), column: 1))
    #expect(
      outcome(.heading(top), .down, column: 1, collapsed: [top.key])
        == .move(.heading(sub), column: 1))
    // With S collapsed, down from its heading goes straight to T.
    #expect(outcome(.heading(s), .down, collapsed: [s.key]) == .move(.heading(t), column: 0))
  }

  @Test func unknownItemMovesToTheFirst() {
    #expect(outcome(.image("missing"), .right) == .move(.heading(s), column: nil))
  }
}
