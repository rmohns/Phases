import SwiftUI

/// [D-editor-layout] The name row, one block of settings, then the images
/// under a header that pins while the grid scrolls [D-image-header].
struct PhaseEditor: View {
  var scheduler: WallpaperScheduler
  var phaseID: Phase.ID
  /// The chosen display tab; nil for Shared, which is chosen whenever a
  /// phase is opened [D-display-tabs].
  @State private var chosenDisplay: String?

  var body: some View {
    let phase = phaseBinding
    let availability = scheduler.location.availability(of: phase.wrappedValue)
    ScrollViewReader { scrollProxy in
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
          VStack(alignment: .leading, spacing: 4) {
            PhaseNameRow(name: phase.name, isOn: phase.isOn)
            message(availability.editorMessage(under: .name))
          }
          .padding(.horizontal, 10)
          .padding(.bottom, 14)

          settings(phase, availability: availability)
            .padding(.bottom, 20)

          Section {
            images(phase, scrollProxy: scrollProxy)
          } header: {
            ImageHeader(
              library: scheduler.library,
              phase: phase,
              connected: scheduler.connectedDisplays,
              display: displayBinding(for: phase.wrappedValue)
            )
            .editorBox(.top)
          }
        }
        .padding(.horizontal, 20)
        // [D-brand-inset] The name row's top lines up with the branding
        // panel's (ERRATA.md "Branding panel insets").
        .padding(.top, 20)
        .padding(.bottom, 20)
      }
    }
    .navigationTitle(phase.wrappedValue.name)
    .onChange(of: phaseID) { chosenDisplay = nil }
  }

  private func settings(_ phase: Binding<Phase>, availability: PhaseAvailability) -> some View {
    VStack(spacing: 0) {
      VStack(alignment: .leading, spacing: 0) {
        StartsRow(trigger: phase.trigger)
        startsNote(phase.wrappedValue, availability: availability)
      }
      Divider().padding(.horizontal, 10)
      EditorRow("Use in") {
        Picker("Use in", selection: phase.appearance) {
          ForEach(AppearanceCondition.allCases) { condition in
            Text(condition.editorTitle).tag(condition)
          }
        }
        .labelsHidden()
        .pickerStyle(.segmented)
        .fixedSize()
      }
      Divider().padding(.horizontal, 10)
      EditorRow("Change images") {
        rotationControls(phase)
      }
      Divider().padding(.horizontal, 10)
      EditorRow("Show images") {
        Picker("Show images", selection: phase.order) {
          ForEach(ImageOrder.allCases) { order in
            Text(order.title).tag(order)
          }
        }
        .labelsHidden()
        .pickerStyle(.segmented)
        .fixedSize()
      }
    }
    .editorBox()
  }

  /// [D-start-readout] [D-phase-status-inline] Under the Starts row: the
  /// location message if there is one, otherwise today's start.
  @ViewBuilder
  private func startsNote(_ phase: Phase, availability: PhaseAvailability) -> some View {
    if let reason = availability.editorMessage(under: .starts) {
      HStack(alignment: .firstTextBaseline) {
        message(reason)
        Spacer(minLength: 8)
        if reason.offersLocationSettings {
          Button("Open System Settings…") {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices") {
              NSWorkspace.shared.open(url)
            }
          }
          .controlSize(.small)
        }
      }
      .padding(.horizontal, 10)
      .padding(.bottom, 8)
    } else if let readout = StartReadout.text(
      for: phase.trigger, on: Date(), at: scheduler.location.usableCoordinate
    ) {
      Text(readout)
        .font(.callout)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.horizontal, 10)
        .padding(.bottom, 8)
    }
  }

  @ViewBuilder
  private func message(_ reason: DisabledReason?) -> some View {
    if let reason {
      Text(reason.editorMessage)
        .font(.callout)
        .foregroundStyle(.secondary)
    }
  }

  /// [D-rotation-row] "every [30] [minutes]", or the menu alone when
  /// rotation is off.
  private func rotationControls(_ phase: Binding<Phase>) -> some View {
    HStack(spacing: 6) {
      if phase.wrappedValue.isRotating {
        Text("every")
        TextField("Interval", value: rotationValue(phase), format: .number)
          .labelsHidden()
          .frame(width: 44)
          .multilineTextAlignment(.trailing)
          .accessibilityIdentifier("rotationValue")
        Stepper("Interval", value: rotationValue(phase), in: Phase.rotationRange)
          .labelsHidden()
      }
      Picker("Change images", selection: phase.rotationChoice) {
        ForEach(RotationChoice.allCases.dropLast()) { choice in
          Text(choice.title).tag(choice)
        }
        Divider()
        Text(RotationChoice.onlyAtStart.title).tag(RotationChoice.onlyAtStart)
      }
      .labelsHidden()
      .fixedSize()
      .accessibilityIdentifier("rotationChoice")
    }
  }

  private func rotationValue(_ phase: Binding<Phase>) -> Binding<Int> {
    Binding {
      phase.wrappedValue.rotation.value
    } set: { value in
      phase.wrappedValue.rotation.value = min(max(value, Phase.rotationRange.lowerBound), Phase.rotationRange.upperBound)
    }
  }

  @ViewBuilder
  private func images(_ phase: Binding<Phase>, scrollProxy: ScrollViewProxy) -> some View {
    let header = ImageHeader(
      library: scheduler.library, phase: phase, connected: scheduler.connectedDisplays,
      display: displayBinding(for: phase.wrappedValue)
    )
    VStack(alignment: .leading, spacing: 0) {
      Divider()
      Group {
        if let selection = header.selectionBinding {
          ImageGrid(library: scheduler.library, selection: selection, scrollProxy: scrollProxy)
            .id(header.display ?? "shared")
        } else {
          VStack(spacing: 6) {
            Text("Uses the Shared images")
              .font(.headline)
            Text("This display shows the images chosen under Shared. Turn on “Use different images on this display” to choose different ones for it.")
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.center)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 40)
          .padding(.horizontal, 20)
        }
      }
      .padding(10)
    }
    .editorBox(.bottom)
  }

  /// [D-display-tabs] The chosen tab while it's still shown; Shared otherwise.
  private func displayBinding(for phase: Phase) -> Binding<String?> {
    let tabs = DisplayTabs.tabs(connected: scheduler.connectedDisplays, phase: phase)
    return Binding {
      DisplayTabs.selection(chosenDisplay, among: tabs)
    } set: { chosenDisplay = $0 }
  }

  private var phaseBinding: Binding<Phase> {
    Binding {
      scheduler.phases.first { $0.id == phaseID } ?? Phase(name: "", trigger: .always)
    } set: { newValue in
      scheduler.updatePhase(newValue)
    }
  }
}
