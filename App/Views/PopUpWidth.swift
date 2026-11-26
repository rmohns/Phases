import SwiftUI

extension View {
  /// Sizes a pop-up menu picker to its current choice instead of its
  /// longest item, which macOS uses by default. The Change images menu's
  /// "Only when the phase starts" otherwise made it as wide as that even
  /// while showing "minutes" [D-rotation-row] (author, 2026-11-25).
  /// The picker must not be `.fixedSize()`; it takes the width of the
  /// hidden title plus room for the pop-up's insets and arrows.
  func popUpWidth(fitting title: String) -> some View {
    Text(title)
      .lineLimit(1)
      .fixedSize()
      .padding(.leading, 12)
      .padding(.trailing, 30)
      .padding(.vertical, 3)
      .hidden()
      .overlay { self }
  }
}
