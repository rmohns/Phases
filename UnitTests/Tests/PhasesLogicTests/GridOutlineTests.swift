import Testing
@testable import PhasesLogic

/// The thumbnail grid's headings and what folds away
/// `[D-grid-collapse]` `[D-grid-collapse-saved]` `[D-grid-one-tab-stop]`.
/// Three sources. S has subfolders: "Top Level" [a b c d], "Winter" [e f],
/// and "Winter/Snow" [g]. T is one group with no subfolder: [h i]. U has
/// all its images in one subfolder "Only": [j].
struct GridOutlineTests {
  typealias Heading = GridOutline.Heading
  typealias Section = GridOutline.Section

  private static let groups = [
    LibraryListing.Group(sourceID: "S", folder: "", names: ["a", "b", "c", "d"]),
    LibraryListing.Group(sourceID: "S", folder: "Winter", names: ["e", "f"]),
    LibraryListing.Group(sourceID: "S", folder: "Winter/Snow", names: ["g"]),
    LibraryListing.Group(sourceID: "T", folder: "", names: ["h", "i"]),
    LibraryListing.Group(sourceID: "U", folder: "Only", names: ["j"]),
  ]

  private let s = Heading.source("S")
  private let top = Heading(sourceID: "S", folder: "")
  private let winter = Heading(sourceID: "S", folder: "Winter")
  private let snow = Heading(sourceID: "S", folder: "Winter/Snow")
  private let t = Heading.source("T")
  private let u = Heading.source("U")
  private let only = Heading(sourceID: "U", folder: "Only")

  private func outline(_ collapsed: Set<String> = []) -> GridOutline {
    GridOutline(groups: Self.groups, collapsed: collapsed)
  }

  @Test func aSourceWithNoSubfoldersHasASourceHeadingAndNoSubheading() {
    let sections = GridOutline(
      groups: [LibraryListing.Group(sourceID: "T", folder: "", names: ["h", "i"])], collapsed: []
    ).sections
    #expect(sections == [Section(sourceHeading: t, subheading: nil, names: ["h", "i"])])
  }

  @Test func aSourceWithSubfoldersGetsTopLevelAndSubfolderSubheadings() {
    let sections = outline().sections.filter { $0.sourceHeading == s || $0.subheading?.sourceID == "S" }
    #expect(
      sections == [
        Section(sourceHeading: s, subheading: top, names: ["a", "b", "c", "d"]),
        Section(sourceHeading: nil, subheading: winter, names: ["e", "f"]),
        Section(sourceHeading: nil, subheading: snow, names: ["g"]),
      ])
    #expect(top.folder == "")
  }

  @Test func aSourceWithAllImagesInOneSubfolderStillGetsASubheading() {
    #expect(
      outline().sections.last == Section(sourceHeading: u, subheading: only, names: ["j"]))
  }

  @Test func sourcesStaySeparate() {
    let sections = outline().sections
    #expect(sections.count == 5)
    #expect(sections.compactMap(\.sourceHeading) == [s, t, u])
    #expect(outline().visibleNames == ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j"])
  }

  @Test func collapsingASourceLeavesOnlyItsHeading() {
    let sections = outline([s.key]).sections
    #expect(
      sections == [
        Section(sourceHeading: s, subheading: nil, names: []),
        Section(sourceHeading: t, subheading: nil, names: ["h", "i"]),
        Section(sourceHeading: u, subheading: only, names: ["j"]),
      ])
    #expect(!outline([s.key]).items.contains(.heading(winter)))
  }

  @Test func expandingASourceRestoresItsSubheadingsOwnState() {
    let both: Set = [s.key, winter.key]
    let folded = outline(both)
    #expect(folded.sections.first == Section(sourceHeading: s, subheading: nil, names: []))
    let expanded = outline(both.subtracting([s.key])).sections
    #expect(expanded[0] == Section(sourceHeading: s, subheading: top, names: ["a", "b", "c", "d"]))
    #expect(expanded[1] == Section(sourceHeading: nil, subheading: winter, names: []))
    #expect(expanded[2] == Section(sourceHeading: nil, subheading: snow, names: ["g"]))
  }

  @Test func collapsingASubheadingHidesOnlyItsImages() {
    let sections = outline([top.key]).sections
    #expect(sections[0] == Section(sourceHeading: s, subheading: top, names: []))
    #expect(sections[1] == Section(sourceHeading: nil, subheading: winter, names: ["e", "f"]))
    #expect(outline([top.key]).visibleNames == ["e", "f", "g", "h", "i", "j"])
  }

  @Test func subheadingsAreFlat() {
    let sections = outline([winter.key]).sections
    #expect(sections[1] == Section(sourceHeading: nil, subheading: winter, names: []))
    #expect(sections[2] == Section(sourceHeading: nil, subheading: snow, names: ["g"]))
  }

  @Test func headingKeysNameTheSourceAndPath() {
    #expect(Heading.source("K3F9").key == "K3F9")
    #expect(Heading(sourceID: "K3F9", folder: "Winter").key == "K3F9:Winter")
    #expect(Heading(sourceID: "K3F9", folder: "").key == "K3F9:")
    #expect(Heading.source("K3F9").isSource)
    #expect(!Heading(sourceID: "K3F9", folder: "").isSource)
  }

  @Test func namesUnderASourceIncludeAllItsGroupsEvenCollapsed() {
    let collapsed = outline([s.key, winter.key])
    #expect(collapsed.names(under: s) == ["a", "b", "c", "d", "e", "f", "g"])
    #expect(collapsed.names(under: t) == ["h", "i"])
  }

  @Test func namesUnderASubheadingAreJustThatGroups() {
    let collapsed = outline([winter.key])
    #expect(collapsed.names(under: winter) == ["e", "f"])
    #expect(collapsed.names(under: snow) == ["g"])
    #expect(collapsed.names(under: top) == ["a", "b", "c", "d"])
  }

  @Test func aRangeCoversOnlyTheImagesShowing() {
    #expect(outline().range(from: "b", to: "e") == ["b", "c", "d", "e"])
    #expect(outline().range(from: "e", to: "b") == ["b", "c", "d", "e"])
    #expect(outline([winter.key]).range(from: "d", to: "g") == ["d", "g"])
    #expect(outline([top.key]).range(from: "e", to: "h") == ["e", "f", "g", "h"])
  }

  @Test func aRangeWithAHiddenEndIsNil() {
    #expect(outline([top.key]).range(from: "a", to: "e") == nil)
    #expect(outline([top.key]).range(from: "e", to: "a") == nil)
    #expect(outline([s.key]).range(from: "e", to: "h") == nil)
    #expect(outline().range(from: "a", to: "missing") == nil)
  }

  @Test func showingMapsAHiddenImageToItsCollapsedSubheading() {
    #expect(outline([winter.key]).showing(.image("f")) == .heading(winter))
    #expect(outline([winter.key]).showing(.image("g")) == .image("g"))
  }

  @Test func showingMapsAHiddenImageToItsCollapsedSourceHeading() {
    #expect(outline([s.key]).showing(.image("g")) == .heading(s))
    // Even when its subheading is collapsed too, the source's heading is what shows.
    #expect(outline([s.key, winter.key]).showing(.image("e")) == .heading(s))
    #expect(outline([s.key]).showing(.heading(winter)) == .heading(s))
  }

  @Test func showingLeavesVisibleItemsUnchanged() {
    #expect(outline().showing(.image("a")) == .image("a"))
    #expect(outline().showing(.heading(winter)) == .heading(winter))
    #expect(outline([winter.key]).showing(.heading(winter)) == .heading(winter))
    #expect(outline([s.key]).showing(.heading(s)) == .heading(s))
  }

  @Test func showingIsNilForAnItemNotInTheGrid() {
    #expect(outline().showing(.image("missing")) == nil)
  }

  @Test func rowsPutEachHeadingOnItsOwnRow() {
    #expect(
      outline().rows(columns: 3) == [
        .heading(s), .heading(top), .images(["a", "b", "c"]), .images(["d"]),
        .heading(winter), .images(["e", "f"]),
        .heading(snow), .images(["g"]),
        .heading(t), .images(["h", "i"]),
        .heading(u), .heading(only), .images(["j"]),
      ])
  }

  @Test func rowsOmitCollapsedImages() {
    #expect(
      outline([s.key, u.key]).rows(columns: 3) == [
        .heading(s), .heading(t), .images(["h", "i"]), .heading(u),
      ])
  }

  @Test func itemsListHeadingsAndShowingImagesInReadingOrder() {
    #expect(
      outline([winter.key]).items == [
        .heading(s), .heading(top), .image("a"), .image("b"), .image("c"), .image("d"),
        .heading(winter), .heading(snow), .image("g"),
        .heading(t), .image("h"), .image("i"),
        .heading(u), .heading(only), .image("j"),
      ])
  }

  @Test func headingAndSubheadingsOfASourceListsAllItsSubheadings() {
    #expect(outline().headingAndSubheadings(of: s) == [s, top, winter, snow])
    #expect(outline().headingAndSubheadings(of: u) == [u, only])
  }

  @Test func headingAndSubheadingsOfASourceWithoutSubheadingsIsJustIt() {
    #expect(outline().headingAndSubheadings(of: t) == [t])
  }

  @Test func headingAndSubheadingsOfASubheadingIsJustIt() {
    #expect(outline().headingAndSubheadings(of: winter) == [winter])
  }
}
