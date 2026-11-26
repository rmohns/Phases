import SwiftUI

/// [D-name-row] The phase's name as an in-place text field with a pencil
/// hint, and the On/Off switch [D-phase-turn-off].
struct PhaseNameRow: View {
  @Binding var name: String
  @Binding var isOn: Bool
  @FocusState private var isEditing: Bool
  /// The name when editing started, for Escape to put back.
  @State private var nameBeforeEditing: String?

  private let font = Font.title2.weight(.semibold)

  var body: some View {
    HStack(spacing: 8) {
      // The hidden text sizes the field to its name, so the pencil sits
      // right after it; a long name truncates instead.
      Text(name.isEmpty ? "Name" : name)
        .font(font)
        .lineLimit(1)
        .padding(.trailing, 6)
        .hidden()
        .overlay(alignment: .leading) {
          TextField("Name", text: $name)
            .textFieldStyle(.plain)
            .font(font)
            .focused($isEditing)
            .onSubmit { isEditing = false }
            .onExitCommand {
              if let nameBeforeEditing { name = nameBeforeEditing }
              isEditing = false
            }
            // VoiceOver hears "Name"; the placeholder alone is spoken
            // only while the field is empty (Phase editor checks,
            // 2026-11-25).
            .accessibilityLabel("Name")
            // [D-ui-test-ids]
            .accessibilityIdentifier("phaseName")
        }
        .layoutPriority(1)

      Button("Edit Name", systemImage: "square.and.pencil") { isEditing = true }
        .labelStyle(.iconOnly)
        .buttonStyle(.borderless)
        .font(.title3)
        .foregroundStyle(.secondary)
        .help("Edit the name")
        // The field itself is what VoiceOver uses to edit the name.
        .accessibilityHidden(true)
        .accessibilityIdentifier("phaseNamePencil")

      Spacer(minLength: 12)

      Toggle(isOn: $isOn) {
        Text(isOn ? "On" : "Off")
          .foregroundStyle(.secondary)
      }
      .toggleStyle(.switch)
      .accessibilityLabel("Use this phase")
      .accessibilityIdentifier("phaseIsOn")
    }
    .onChange(of: isEditing) {
      nameBeforeEditing = isEditing ? name : nil
    }
  }
}
