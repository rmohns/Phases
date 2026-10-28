import SwiftUI

/// Arrow-key movement through the thumbnail grid's sections and rows
/// `[D-grid-one-tab-stop]`. Left/right step through images in order; up/down
/// keep the column, crossing subfolder headings.
struct ImageGridNavigation {
  var groups: [(folder: String, names: [String])]
  var columns: Int

  /// The image the cursor moves to, or `current` if it can't move that way.
  func destination(from current: String, _ direction: MoveCommandDirection) -> String {
    let names = groups.flatMap(\.names)
    guard let index = names.firstIndex(of: current) else { return names.first ?? current }
    switch direction {
    case .left:
      return index > 0 ? names[index - 1] : current
    case .right:
      return index < names.count - 1 ? names[index + 1] : current
    case .up:
      return vertical(from: current, by: -1) ?? current
    case .down:
      return vertical(from: current, by: 1) ?? current
    @unknown default:
      return current
    }
  }

  private func vertical(from current: String, by step: Int) -> String? {
    let rows = self.rows
    for (rowIndex, row) in rows.enumerated() {
      guard let column = row.firstIndex(of: current) else { continue }
      let target = rowIndex + step
      guard rows.indices.contains(target) else { return nil }
      let targetRow = rows[target]
      return targetRow[min(column, targetRow.count - 1)]
    }
    return nil
  }

  /// Every visual row, in order. Each group starts a new row.
  private var rows: [[String]] {
    let width = max(columns, 1)
    return groups.flatMap { group in
      stride(from: 0, to: group.names.count, by: width).map {
        Array(group.names[$0..<min($0 + width, group.names.count)])
      }
    }
  }
}
