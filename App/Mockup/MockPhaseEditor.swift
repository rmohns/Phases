import SwiftUI

/// MOCKUP (experiment/ui-mockup): the proposed phase editor. A short block of
/// phase settings sits above an image browser that fills the rest of the
/// pane. Controls hold throwaway state seeded from the real phase; nothing is
/// saved and the schedule never sees it.
struct MockPhaseEditor: View {
  var scheduler: WallpaperScheduler
  @State private var draft: Phase
  @State private var tab: MockDisplayTab = .shared
  @State private var differentPicks: Bool
  @State private var includesSubfolders: Bool

  init(scheduler: WallpaperScheduler, phase: Phase) {
    self.scheduler = scheduler
    _draft = State(initialValue: phase)
    _differentPicks = State(initialValue: scheduler.displayMode == .differentPerDisplay)
    _includesSubfolders = State(initialValue: scheduler.library.includesSubfolders)
  }

  var body: some View {
    VStack(spacing: 0) {
      settings
      Divider()
      imageHeader
      Divider()
      imageContent
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .navigationTitle(draft.name)
  }

  // MARK: Phase settings

  private var settings: some View {
    Form {
      LabeledContent("Name:") {
        HStack(spacing: 16) {
          TextField("Name", text: $draft.name)
            .labelsHidden()
            .frame(maxWidth: 220)
          Toggle("Use this phase", isOn: $draft.isOn)
            .toggleStyle(.checkbox)
        }
      }

      LabeledContent("Starts:") {
        MockTriggerRow(trigger: $draft.trigger)
      }

      Picker("Use in:", selection: $draft.appearance) {
        Text("Light and Dark Mode").tag(AppearanceCondition.any)
        Text("Light Mode only").tag(AppearanceCondition.light)
        Text("Dark Mode only").tag(AppearanceCondition.dark)
      }
      .fixedSize()

      if let message = scheduler.location.availability(of: draft).editorMessage {
        LabeledContent("") {
          Label(message, systemImage: "exclamationmark.triangle")
            .foregroundStyle(.orange)
        }
      }

      LabeledContent("Images:") {
        HStack(spacing: 6) {
          Picker("Order", selection: $draft.order) {
            Text("In filename order").tag(ImageOrder.inOrder)
            Text("In random order").tag(ImageOrder.random)
          }
          .labelsHidden()
          .fixedSize()
          Toggle("Change every", isOn: $draft.isRotating)
            .toggleStyle(.checkbox)
            .padding(.leading, 10)
          TextField("Interval", value: $draft.rotation.value, format: .number)
            .labelsHidden()
            .frame(width: 44)
            .multilineTextAlignment(.trailing)
            .disabled(!draft.isRotating)
          Stepper("Interval", value: $draft.rotation.value, in: 1...999)
            .labelsHidden()
            .disabled(!draft.isRotating)
          Picker("Unit", selection: $draft.rotation.unit) {
            ForEach(TimeUnit.allCases) { unit in
              Text(unit.title.lowercased()).tag(unit)
            }
          }
          .labelsHidden()
          .fixedSize()
          .disabled(!draft.isRotating)
        }
      }
    }
    .formStyle(.columns)
    .padding(.horizontal, 20)
    .padding(.vertical, 16)
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  // MARK: Image browser

  private var displays: [MockDisplayInfo] {
    MockDisplayInfo.all(for: scheduler)
  }

  private var showsDisplayTabs: Bool {
    displays.count > 1
  }

  private var imageHeader: some View {
    VStack(alignment: .leading, spacing: 10) {
      if showsDisplayTabs {
        HStack(alignment: .top) {
          MockDisplayTabStrip(
            displays: displays,
            sharedCount: sharedSelection.wrappedValue.count,
            ownCounts: draft.displayImageNames.mapValues(\.count),
            selection: $tab
          )
          Spacer()
          folderMenu
        }
      }
      HStack(spacing: 12) {
        switch currentTab {
        case .shared:
          countLabel(sharedSelection.wrappedValue)
          if displays.filter(\.isConnected).count > 1 {
            Toggle("Each display shows a different image", isOn: $differentPicks)
              .toggleStyle(.checkbox)
          }
          Spacer()
          selectButtons(sharedSelection)
        case .display(let uuid):
          Toggle("Use its own images", isOn: usesOwnImages(uuid))
            .toggleStyle(.checkbox)
          if let own = ownSelection(uuid) {
            countLabel(own.wrappedValue)
            Spacer()
            selectButtons(own)
          } else {
            Spacer()
          }
        }
        if !showsDisplayTabs {
          folderMenu
        }
      }
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 12)
  }

  @ViewBuilder private var imageContent: some View {
    switch currentTab {
    case .shared:
      MockImageGrid(library: scheduler.library, selection: sharedSelection)
    case .display(let uuid):
      if let own = ownSelection(uuid) {
        MockImageGrid(library: scheduler.library, selection: own)
          .id(uuid)
      } else {
        ContentUnavailableView {
          Text("Uses the shared images")
        } description: {
          Text("This display shows the images chosen under Shared. Turn on “Use its own images” to choose different ones for it.")
        }
      }
    }
  }

  private var folderMenu: some View {
    Menu {
      Button("Choose Folder…") {}
      Toggle("Include Subfolders", isOn: $includesSubfolders)
      Divider()
      Button("Show in Finder") {}
    } label: {
      Label(scheduler.library.folderURL?.lastPathComponent ?? "Choose Folder", systemImage: "folder")
    }
    .menuStyle(.button)
    .buttonStyle(.accessoryBar)
    .fixedSize()
    .help("The image folder all phases choose from")
  }

  private func countLabel(_ selection: [String]) -> some View {
    Text("\(selection.count) of \(scheduler.library.imageNames.count) selected")
      .foregroundStyle(.secondary)
      .monospacedDigit()
  }

  private func selectButtons(_ selection: Binding<[String]>) -> some View {
    HStack {
      Button("Select All") { selection.wrappedValue = scheduler.library.imageNames }
      Button("Select None") { selection.wrappedValue = [] }
    }
  }

  // MARK: Throwaway selection state

  /// Falls back to Shared if the chosen display disappears.
  private var currentTab: MockDisplayTab {
    if case .display(let uuid) = tab, !displays.contains(where: { $0.uuid == uuid }) { return .shared }
    return showsDisplayTabs ? tab : .shared
  }

  private var sharedSelection: Binding<[String]> {
    $draft.imageNames
  }

  private func usesOwnImages(_ uuid: String) -> Binding<Bool> {
    Binding {
      draft.displayImageNames[uuid] != nil
    } set: { isOn in
      draft.displayImageNames[uuid] = isOn ? [] : nil
    }
  }

  private func ownSelection(_ uuid: String) -> Binding<[String]>? {
    guard draft.displayImageNames[uuid] != nil else { return nil }
    return Binding {
      draft.displayImageNames[uuid] ?? []
    } set: { names in
      draft.displayImageNames[uuid] = names
    }
  }
}

/// The trigger as one sentence: "Dusk, Before, 60 minutes".
private struct MockTriggerRow: View {
  @Binding var trigger: PhaseTrigger

  private enum Timing: Hashable { case at, before, after }

  var body: some View {
    HStack(spacing: 6) {
      Picker("Trigger", selection: kind) {
        ForEach(TriggerKind.allCases) { kind in
          Text(kind.title).tag(kind)
        }
      }
      .labelsHidden()
      .fixedSize()

      switch trigger {
      case .always:
        Text("when no other phase applies")
          .foregroundStyle(.secondary)
      case .clockTime:
        DatePicker("Time", selection: clockTime, displayedComponents: .hourAndMinute)
          .labelsHidden()
          .fixedSize()
      case .solar:
        Picker("Timing", selection: timing) {
          Text("exactly").tag(Timing.at)
          Text("before, by").tag(Timing.before)
          Text("after, by").tag(Timing.after)
        }
        .labelsHidden()
        .fixedSize()
        if timing.wrappedValue != .at {
          TextField("Minutes", value: offsetMagnitude, format: .number)
            .labelsHidden()
            .frame(width: 44)
            .multilineTextAlignment(.trailing)
          Stepper("Minutes", value: offsetMagnitude, in: 1...720, step: 5)
            .labelsHidden()
          Text("minutes")
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
