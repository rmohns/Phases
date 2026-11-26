import SwiftUI

/// Arrow keys in the thumbnail grid `[D-grid-one-tab-stop]`
/// `[D-grid-collapse]`. The cursor is on an image or a heading; images in
/// collapsed sections are skipped, their headings aren't. On an image,
/// left/right step through items in order and up/down move by one row,
/// keeping the column even across headings. On a heading, → expands and ←
/// collapses, as in Finder's list view, and moves on when there's nothing
/// to expand or collapse.
struct ImageGridNavigation {
  typealias Item = GridOutline.Item

  var outline: GridOutline
  var columns: Int

  enum Outcome: Equatable {
    /// Move the cursor. `column` is the column to keep while it sits on a
    /// heading; nil on an image, whose own column counts next time.
    case move(Item, column: Int?)
    /// Collapse (true) or expand (false) these headings; the cursor stays.
    case setCollapsed([GridOutline.Heading], Bool)
    /// Nothing to do: at an edge.
    case stay
  }

  /// `column` is the column remembered from before the cursor reached a
  /// heading. `option` is ⌥, which on a source heading also folds or
  /// unfolds its subheadings.
  func outcome(
    from current: Item, _ direction: MoveCommandDirection, column: Int? = nil, option: Bool = false
  ) -> Outcome {
    let items = outline.items
    guard let index = items.firstIndex(of: current) else {
      return items.first.map { .move($0, column: nil) } ?? .stay
    }
    switch direction {
    case .left:
      if case .heading(let heading) = current, !outline.isCollapsed(heading) {
        return .setCollapsed(headings(heading, option: option), true)
      }
      return index > 0 ? .move(items[index - 1], column: nil) : .stay
    case .right:
      if case .heading(let heading) = current, outline.isCollapsed(heading) {
        return .setCollapsed(headings(heading, option: option), false)
      }
      return index < items.count - 1 ? .move(items[index + 1], column: nil) : .stay
    case .up:
      return vertical(from: current, by: -1, column: column)
    case .down:
      return vertical(from: current, by: 1, column: column)
    @unknown default:
      return .stay
    }
  }

  /// ⌥ widens a source heading to its subheadings too; otherwise just it.
  private func headings(_ heading: GridOutline.Heading, option: Bool) -> [GridOutline.Heading] {
    option ? outline.headingAndSubheadings(of: heading) : [heading]
  }

  private func vertical(from current: Item, by step: Int, column remembered: Int?) -> Outcome {
    let rows = outline.rows(columns: columns)
    for (rowIndex, row) in rows.enumerated() {
      let column: Int
      switch (row, current) {
      case (.heading(let heading), .heading(let target)) where heading == target:
        column = remembered ?? 0
      case (.images(let names), .image(let name)):
        guard let found = names.firstIndex(of: name) else { continue }
        column = found
      default:
        continue
      }
      let target = rowIndex + step
      guard rows.indices.contains(target) else { return .stay }
      switch rows[target] {
      case .heading(let heading):
        return .move(.heading(heading), column: column)
      case .images(let names):
        return .move(.image(names[min(column, names.count - 1)]), column: nil)
      }
    }
    return .stay
  }
}
