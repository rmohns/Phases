import SwiftUI

/// The Schedule window: phase list on the left, editor on the right.
struct ScheduleView: View {
  static let windowID = "schedule"

  var scheduler: WallpaperScheduler
  @State private var selection: Phase.ID?

  var body: some View {
    HStack(spacing: 0) {
      VStack(spacing: 0) {
        List(selection: $selection) {
          ForEach(scheduler.phasesByTime) { phase in
            PhaseRow(phase: phase, isActive: phase.id == scheduler.activePhase?.id)
              .tag(phase.id)
          }
        }
        .listStyle(.sidebar)

        Divider()

        HStack(spacing: 0) {
          Button("Add Phase", systemImage: "plus") {
            selection = scheduler.addPhase().id
          }
          Button("Delete Phase", systemImage: "minus") {
            if let selection { scheduler.deletePhase(id: selection) }
            selection = scheduler.phasesByTime.first?.id
          }
          .disabled(selection == nil)
          Spacer()
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.borderless)
        .padding(6)
      }
      .frame(width: 240)

      Divider()

      if let selection, scheduler.phases.contains(where: { $0.id == selection }) {
        PhaseEditor(scheduler: scheduler, phaseID: selection)
          .id(selection)
      } else {
        ContentUnavailableView(
          "No Phase Selected",
          systemImage: "sun.horizon",
          description: Text("Select a phase, or add one with the + button.")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    .onAppear {
      scheduler.library.reload()
      if selection == nil { selection = scheduler.activePhase?.id ?? scheduler.phasesByTime.first?.id }
    }
  }
}

private struct PhaseRow: View {
  var phase: Phase
  var isActive: Bool

  var body: some View {
    Label {
      VStack(alignment: .leading, spacing: 2) {
        HStack(spacing: 4) {
          Text(phase.name)
          if isActive {
            Text("Active")
              .font(.caption2.weight(.semibold))
              .foregroundStyle(.tint)
          }
        }
        HStack(spacing: 4) {
          Text(phase.trigger.summary)
          if let symbol = phase.appearance.systemImage {
            Image(systemName: symbol)
              .accessibilityLabel("\(phase.appearance.title) Mode only")
          }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
      }
    } icon: {
      Image(systemName: phase.trigger.kind.systemImage)
    }
    .padding(.vertical, 2)
    .accessibilityElement(children: .combine)
  }
}
