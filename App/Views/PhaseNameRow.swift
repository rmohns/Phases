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
    // No spacing, so the pencil's highlight starts about 5.5 pt after the
    // name's last letter; 17.5 pt, with spacing 8 and padding 6, looked
    // detached (author, 2026-11-26).
    HStack(spacing: 0) {
      // The hidden text sizes the field to its name, so the pencil sits
      // right after it; a long name truncates instead. The padding leaves
      // room for the insertion point after the last letter.
      Text(name.isEmpty ? "Name" : name)
        .font(font)
        .lineLimit(1)
        .padding(.trailing, 2)
        .hidden()
        // On the hidden text's baseline: centered in its frame, the field
        // drew its text about 1.25 pt above the pencil and switch
        // (measured by Claude, 2026-11-26).
        .overlay(alignment: Alignment(horizontal: .leading, vertical: .firstTextBaseline)) {
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
        // Highlights under the pointer, so it reads as clickable
        // [D-name-row].
        .buttonStyle(.accessoryBar)
        .font(.title3)
        .foregroundStyle(.secondary)
        // Centered on its cap height, as the symbol sits beside text;
        // centered on its frame, its square sat 1.5 pt below the name's
        // capitals (measured by Claude, 2026-11-26).
        .alignmentGuide(VerticalAlignment.center) { dimensions in
          dimensions[.firstTextBaseline]
            - NSFont.preferredFont(forTextStyle: .title3).capHeight / 2
        }
        .padding(.leading, 3)
        .help("Edit the name")
        // The field itself is what VoiceOver uses to edit the name.
        .accessibilityHidden(true)
        .accessibilityIdentifier("phaseNamePencil")

      // 12 plus the 8 pt the row's spacing gave on each side.
      Spacer(minLength: 28)

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
