import SwiftUI

struct PhaseEditor: View {
  var scheduler: WallpaperScheduler
  var phaseID: Phase.ID
  /// Which display's images are being edited; nil for All Displays.
  @State private var display: String?

  var body: some View {
    let phase = phaseBinding
    Form {
      Section {
        TextField("Name", text: phase.name)
      }

      Section("Starts") {
        TriggerEditor(trigger: phase.trigger)
        if phase.wrappedValue.trigger == .always && scheduler.phases.count > 1 {
          Text("An “Always” phase is used only when no timed phase applies. Use “Only in” to switch between Always phases with Light and Dark Mode.")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        Picker("Only in", selection: phase.appearance) {
          ForEach(AppearanceCondition.allCases) { condition in
            Text(condition.title).tag(condition)
          }
        }
        .pickerStyle(.segmented)
        if phase.wrappedValue.trigger.usesLocation && scheduler.location.isDenied {
          Label("Location access is off, so this phase is skipped.", systemImage: "exclamationmark.triangle")
            .foregroundStyle(.orange)
        }
      }

      Section("Wallpaper") {
        Picker("Order", selection: phase.order) {
          ForEach(ImageOrder.allCases) { order in
            Text(order.title).tag(order)
          }
        }
        .pickerStyle(.segmented)

        Toggle("Rotate images during this phase", isOn: phase.isRotating)
        if phase.wrappedValue.isRotating {
          LabeledContent("Every") {
            HStack {
              TextField("Interval", value: phase.rotation.value, format: .number)
                .labelsHidden()
                .frame(width: 56)
                .multilineTextAlignment(.trailing)
              Stepper("Interval", value: phase.rotation.value, in: 1...999)
                .labelsHidden()
              Picker("Unit", selection: phase.rotation.unit) {
                ForEach(TimeUnit.allCases) { unit in
                  Text(unit.title).tag(unit)
                }
              }
              .labelsHidden()
              .fixedSize()
            }
          }
        }
      }

      Section("Images") {
        let displays = scheduler.displaysForPicker
        if displays.count > 1 {
          Picker("Display", selection: $display) {
            Text("All Displays").tag(nil as String?)
            ForEach(displays) { known in
              Text(scheduler.isConnected(known) ? known.name : "\(known.name) (not connected)")
                .tag(Optional(known.uuid))
            }
          }
        }
        if let display, displays.contains(where: { $0.uuid == display }) {
          Toggle("Use different images on this display", isOn: usesOwnImages(display, in: phase))
          if let own = ownImages(display, in: phase) {
            ImageGrid(library: scheduler.library, selection: own)
              .id(display)
          } else {
            Text("This display uses the All Displays images.")
              .foregroundStyle(.secondary)
          }
        } else {
          ImageGrid(library: scheduler.library, selection: phase.imageNames)
            .id("all")
        }
      }
    }
    .formStyle(.grouped)
    .navigationTitle(phase.wrappedValue.name)
  }

  /// On: the display gets its own (initially empty) selection. Off: its
  /// selection for this phase is discarded (spec §4).
  private func usesOwnImages(_ uuid: String, in phase: Binding<Phase>) -> Binding<Bool> {
    Binding {
      phase.wrappedValue.displayImageNames[uuid] != nil
    } set: { isOn in
      phase.wrappedValue.displayImageNames[uuid] = isOn ? [] : nil
    }
  }

  private func ownImages(_ uuid: String, in phase: Binding<Phase>) -> Binding<[String]>? {
    guard phase.wrappedValue.displayImageNames[uuid] != nil else { return nil }
    return Binding {
      phase.wrappedValue.displayImageNames[uuid] ?? []
    } set: { names in
      phase.wrappedValue.displayImageNames[uuid] = names
    }
  }

  private var phaseBinding: Binding<Phase> {
    Binding {
      scheduler.phases.first { $0.id == phaseID } ?? Phase(name: "", trigger: .always)
    } set: { newValue in
      scheduler.updatePhase(newValue)
    }
  }
}

/// Picks the trigger type and its time or offset.
private struct TriggerEditor: View {
  @Binding var trigger: PhaseTrigger

  private enum Timing: String, CaseIterable, Identifiable {
    case at, before, after
    var id: Self { self }
    var title: String {
      switch self {
      case .at: "At"
      case .before: "Before"
      case .after: "After"
      }
    }
  }

  var body: some View {
    Picker("Trigger", selection: kind) {
      ForEach(TriggerKind.allCases) { kind in
        Label(kind.title, systemImage: kind.systemImage).tag(kind)
      }
    }

    switch trigger {
    case .always:
      EmptyView()
    case .clockTime:
      DatePicker("Time", selection: clockTime, displayedComponents: .hourAndMinute)
    case .solar(let event, _):
      Picker("Timing", selection: timing) {
        ForEach(Timing.allCases) { timing in
          Text(timing.title).tag(timing)
        }
      }
      .pickerStyle(.segmented)
      if timing.wrappedValue != .at {
        LabeledContent("Offset") {
          HStack {
            TextField("Minutes", value: offsetMagnitude, format: .number)
              .labelsHidden()
              .frame(width: 56)
              .multilineTextAlignment(.trailing)
            Stepper("Minutes", value: offsetMagnitude, in: 1...720, step: 5)
              .labelsHidden()
            Text("minutes \(timing.wrappedValue == .before ? "before" : "after") \(event == .dawn ? "dawn" : "dusk")")
              .foregroundStyle(.secondary)
          }
        }
      }
    }
  }

  private var offset: Int {
    if case .solar(_, let offset) = trigger { offset } else { 0 }
  }

  private var kind: Binding<TriggerKind> {
    Binding {
      trigger.kind
    } set: { newKind in
      switch newKind {
      case .always: trigger = .always
      case .clockTime: trigger = .clockTime(minutes: 9 * 60)
      case .dawn: trigger = .solar(.dawn, offsetMinutes: offset)
      case .dusk: trigger = .solar(.dusk, offsetMinutes: offset)
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

  private var timing: Binding<Timing> {
    Binding {
      offset == 0 ? .at : (offset < 0 ? .before : .after)
    } set: { newTiming in
      guard case .solar(let event, _) = trigger else { return }
      let magnitude = max(abs(offset), 30)
      switch newTiming {
      case .at: trigger = .solar(event, offsetMinutes: 0)
      case .before: trigger = .solar(event, offsetMinutes: -magnitude)
      case .after: trigger = .solar(event, offsetMinutes: magnitude)
      }
    }
  }

  private var offsetMagnitude: Binding<Int> {
    Binding {
      abs(offset)
    } set: { newValue in
      guard case .solar(let event, _) = trigger else { return }
      let magnitude = min(max(newValue, 1), 720)
      trigger = .solar(event, offsetMinutes: offset < 0 ? -magnitude : magnitude)
    }
  }
}
