import SwiftUI

/// [D-editor-layout] The phase editor's grouped boxes, drawn to match the
/// grouped form the rest of the window uses.
struct EditorBox: Shape {
  /// Which corners are rounded, so the pinned image header and the grid
  /// under it join into one box.
  var corners: Corners = .all

  enum Corners {
    case all, top, bottom
  }

  static let radius: CGFloat = 8

  func path(in rect: CGRect) -> Path {
    let top = corners == .bottom ? 0 : Self.radius
    let bottom = corners == .top ? 0 : Self.radius
    return UnevenRoundedRectangle(
      topLeadingRadius: top, bottomLeadingRadius: bottom, bottomTrailingRadius: bottom, topTrailingRadius: top
    )
    .path(in: rect)
  }
}

extension View {
  /// Fills the box opaquely, so the grid never shows through the pinned
  /// header [D-content-vs-tools].
  func editorBox(_ corners: EditorBox.Corners = .all) -> some View {
    background {
      ZStack {
        EditorBox(corners: corners).fill(Color(nsColor: .windowBackgroundColor))
        EditorBox(corners: corners).fill(.quinary)
        EditorBox(corners: corners).stroke(.separator.opacity(0.5), lineWidth: 0.5)
      }
    }
  }
}
