import SwiftUI

/// [D-sidebar-footer-style] Pieces of a + / − bar under a list, in System
/// Settings' Login Items layout: 24 × 23 pt cells, the whole cell
/// clickable, split by a 16 pt divider. Shared by the phase list and the
/// Image Sources list [D-image-sources].
enum ListFooter {
  /// An icon in a fully clickable 24 × 23 pt cell.
  static func cell(_ title: LocalizedStringKey, systemImage: String) -> some View {
    Label(title, systemImage: systemImage)
      .labelStyle(.iconOnly)
      .frame(width: 24, height: 23)
      .contentShape(Rectangle())
  }

  /// The 1 pt divider between cells.
  static var divider: some View {
    Rectangle()
      .fill(.separator)
      .frame(width: 1, height: 16)
  }
}
