import SwiftUI

/// [D-editor-layout] [D-editor-labels] One row of the phase editor's
/// settings block: a plain-word label, then its controls at the trailing
/// edge. VoiceOver reads the label with the controls.
struct EditorRow<Content: View>: View {
  var label: String
  @ViewBuilder var content: Content

  init(_ label: String, @ViewBuilder content: () -> Content) {
    self.label = label
    self.content = content()
  }

  var body: some View {
    HStack(spacing: 12) {
      // Never truncated or pushed out; the pane's minimum width leaves
      // room for the widest row's controls [D-window-min-size].
      Text(label)
        .lineLimit(1)
        .fixedSize()
      Spacer(minLength: 0)
      content
    }
    .frame(minHeight: 24)
    .padding(.horizontal, 10)
    .padding(.vertical, 7)
    .accessibilityElement(children: .contain)
    .accessibilityLabel(label)
  }
}
