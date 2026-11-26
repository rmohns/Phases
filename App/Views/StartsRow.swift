import SwiftUI

/// [D-starts-row] "Starts" and controls that read as a sentence, changing
/// with the trigger: the trigger menu leads for a clock time and trails a
/// dawn or dusk offset.
struct StartsRow: View {
  @Binding var trigger: PhaseTrigger
  /// The offset as last edited, so "60 minutes" doesn't turn into "1 hour"
  /// while it's being typed. Stored minutes are the truth; these are only
  /// kept while they still describe them.
  @State private var editedParts: OffsetParts?

  var body: some View {
    EditorRow("Starts") {
      HStack(spacing: 6) {
        switch trigger {
        case .always:
          triggerMenu
        case .clockTime:
          triggerMenu
          DatePicker("Time", selection: clockTime, displayedComponents: .hourAndMinute)
            .labelsHidden()
            .datePickerStyle(.stepperField)
            .accessibilityIdentifier("startTime")
        case .solar:
          if parts.direction != .at {
            TextField("Offset", value: offsetValue, format: .number)
              .labelsHidden()
              .frame(width: 44)
              .multilineTextAlignment(.trailing)
              .accessibilityIdentifier("offsetValue")
            Stepper(
              "Offset", value: offsetValue, in: OffsetParts.range(for: parts.unit),
              step: OffsetParts.step(for: parts.unit)
            )
            .labelsHidden()
            // [D-editor-popups]
            SettingsPopUp(
              title: "Offset unit", selection: offsetUnit,
              items: TimeUnit.allCases.map { .choice($0, title: $0.title) }
            )
          }
          SettingsPopUp(
            title: "Before or after", selection: offsetDirection,
            items: OffsetParts.Direction.allCases.map { .choice($0, title: $0.title) }
          )
          .accessibilityIdentifier("offsetDirection")
          triggerMenu
        }
      }
    }
  }

  private var triggerMenu: some View {
    // [D-editor-popups]
    SettingsPopUp(
      title: "Trigger", selection: kind,
      items: TriggerKind.allCases.map { .choice($0, title: $0.title, systemImage: $0.systemImage) }
    )
    .accessibilityIdentifier("startTrigger")
  }

  private var storedOffset: Int {
    if case .solar(_, let offset) = trigger { offset } else { 0 }
  }

  private var parts: OffsetParts {
    if let editedParts, editedParts.minutes == storedOffset { return editedParts }
    return OffsetParts(minutes: storedOffset)
  }

  private func update(_ change: (inout OffsetParts) -> Void) {
    guard case .solar(let event, _) = trigger else { return }
    var newParts = parts
    change(&newParts)
    editedParts = newParts
    trigger = .solar(event, offsetMinutes: newParts.minutes)
  }

  private var offsetValue: Binding<Int> {
    Binding { parts.value } set: { value in update { $0.setValue(value) } }
  }

  private var offsetUnit: Binding<TimeUnit> {
    Binding { parts.unit } set: { unit in update { $0.setUnit(unit) } }
  }

  private var offsetDirection: Binding<OffsetParts.Direction> {
    Binding { parts.direction } set: { direction in update { $0.setDirection(direction) } }
  }

  private var kind: Binding<TriggerKind> {
    Binding {
      trigger.kind
    } set: { newKind in
      switch newKind {
      case .always: trigger = .always
      case .clockTime: trigger = .clockTime(minutes: 9 * 60)
      case .dawn: trigger = .solar(.dawn, offsetMinutes: storedOffset)
      case .dusk: trigger = .solar(.dusk, offsetMinutes: storedOffset)
      }
    }
  }

  private var clockTime: Binding<Date> {
    Binding {
      guard case .clockTime(let minutes) = trigger else { return Date() }
      return Calendar.current.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: Date()) ?? Date()
    } set: { date in
      let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
      trigger = .clockTime(minutes: (parts.hour ?? 0) * 60 + (parts.minute ?? 0))
    }
  }
}
