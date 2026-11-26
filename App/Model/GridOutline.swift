import Foundation

/// The thumbnail grid as the user sees it: each source's heading, its
/// subheadings, and the images that show, with collapsed headings folded
/// away [D-grid-collapse]. No AppKit or SwiftUI, so the unit tests can reach
/// it [D-tests-unhosted].
struct GridOutline {
  /// A source heading or a subheading (a subfolder, "Top Level", or an album
  /// of a Photos folder).
  struct Heading: Hashable {
    var sourceID: String
    /// The subheading's path (`LibraryListing.Group.folder`); nil for the
    /// source's own heading. "" is a source's "Top Level".
    var folder: String?

    var isSource: Bool { folder == nil }

    /// The name it's saved by [D-grid-collapse-saved]: `K3F9` for a source,
    /// `K3F9:Winter` for a subheading, never a position.
    var key: String { folder.map { sourceID + ":" + $0 } ?? sourceID }

    static func source(_ id: String) -> Heading { Heading(sourceID: id, folder: nil) }
  }

  /// Where the keyboard cursor can be [D-grid-one-tab-stop].
  enum Item: Hashable {
    case heading(Heading)
    case image(String)
  }

  /// One section of the grid as it's drawn: the headings over it, then the
  /// images that show (none when collapsed).
  struct Section: Equatable {
    /// Set on a source's first section only.
    var sourceHeading: Heading?
    /// Set when the source has subfolders (or albums), or its images all
    /// sit in one subfolder.
    var subheading: Heading?
    var names: [String]
  }

  /// One visual row: a heading on its own, or a row of images.
  enum Row: Equatable {
    case heading(Heading)
    case images([String])
  }

  private(set) var groups: [LibraryListing.Group]
  private(set) var collapsed: Set<String>
  /// The sections that show, in order.
  private(set) var sections: [Section] = []

  init(groups: [LibraryListing.Group], collapsed: Set<String>) {
    self.groups = groups
    self.collapsed = collapsed
    for (index, group) in groups.enumerated() {
      let startsSource = index == 0 || groups[index - 1].sourceID != group.sourceID
      let source = Heading.source(group.sourceID)
      if isCollapsed(source) {
        // Only the source's heading shows, over nothing.
        if startsSource { sections.append(Section(sourceHeading: source, subheading: nil, names: [])) }
        continue
      }
      let sub = hasSubheading(group) ? Heading(sourceID: group.sourceID, folder: group.folder) : nil
      sections.append(
        Section(
          sourceHeading: startsSource ? source : nil,
          subheading: sub,
          names: sub.map(isCollapsed) == true ? [] : group.names
        ))
    }
  }

  func isCollapsed(_ heading: Heading) -> Bool {
    collapsed.contains(heading.key)
  }

  /// Every image that shows, in library order.
  var visibleNames: [String] {
    sections.flatMap(\.names)
  }

  /// The headings and images that show, in reading order.
  var items: [Item] {
    sections.flatMap { section -> [Item] in
      [section.sourceHeading, section.subheading].compactMap { $0.map(Item.heading) }
        + section.names.map(Item.image)
    }
  }

  /// The visual rows for `columns` columns. Each heading is a row of its
  /// own, and each section's images start a new row.
  func rows(columns: Int) -> [Row] {
    let width = max(columns, 1)
    return sections.flatMap { section -> [Row] in
      let headings = [section.sourceHeading, section.subheading].compactMap { $0.map(Row.heading) }
      let images = stride(from: 0, to: section.names.count, by: width).map {
        Row.images(Array(section.names[$0..<min($0 + width, section.names.count)]))
      }
      return headings + images
    }
  }

  /// Every image under a heading, shown or not: all of a source's images,
  /// its subfolders' too, or one subheading's.
  func names(under heading: Heading) -> [String] {
    groups
      .filter { $0.sourceID == heading.sourceID && (heading.folder == nil || heading.folder == $0.folder) }
      .flatMap(\.names)
  }

  /// A source heading and all its subheadings, for ⌥-click and ⌥←/⌥→.
  func headingAndSubheadings(of heading: Heading) -> [Heading] {
    guard heading.isSource else { return [heading] }
    let subs = groups.filter { $0.sourceID == heading.sourceID && hasSubheading($0) }
      .map { Heading(sourceID: $0.sourceID, folder: $0.folder) }
    return [heading] + subs
  }

  /// The images a ⇧-click or ⇧-Space range covers: only those showing
  /// between the two ends [D-grid-collapse]. Nil when either end is hidden,
  /// so the click acts as a plain one.
  func range(from anchor: String, to name: String) -> [String]? {
    let names = visibleNames
    guard let from = names.firstIndex(of: anchor), let to = names.firstIndex(of: name) else { return nil }
    return Array(names[min(from, to)...max(from, to)])
  }

  /// Where the cursor belongs once `item` may have been folded away: the
  /// item itself if it shows, else the collapsed heading that hides it.
  /// Nil if it isn't in the grid at all.
  func showing(_ item: Item) -> Item? {
    let shown = items
    if shown.contains(item) { return item }
    let sourceID: String
    let folder: String?
    switch item {
    case .heading(let heading):
      sourceID = heading.sourceID
      folder = nil
    case .image(let name):
      guard let group = groups.first(where: { $0.names.contains(name) }) else { return nil }
      sourceID = group.sourceID
      folder = group.folder
    }
    let source = Heading.source(sourceID)
    if isCollapsed(source) { return .heading(source) }
    if let folder {
      let sub = Heading(sourceID: sourceID, folder: folder)
      if shown.contains(.heading(sub)) { return .heading(sub) }
    }
    return shown.contains(.heading(source)) ? .heading(source) : nil
  }

  /// [D-image-sources] A subheading shows when the source has more than one
  /// group, and also when all its images sit in one subfolder.
  private func hasSubheading(_ group: LibraryListing.Group) -> Bool {
    !group.folder.isEmpty || groups.filter { $0.sourceID == group.sourceID }.count > 1
  }
}
