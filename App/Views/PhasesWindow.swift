import SwiftUI

/// The single Phases window (spec §7): phases and Settings in the sidebar,
/// the selected item's editor in the detail area.
struct PhasesWindow: View {
  static let windowID = "phases"

  var scheduler: WallpaperScheduler
  @State private var selection: SidebarItem?

  var body: some View {
    NavigationSplitView {
      List(selection: $selection) {
        Section("Phases") {
          ForEach(scheduler.phasesByTime) { phase in
            PhaseRow(phase: phase, isActive: phase.id == scheduler.activePhase?.id)
              .tag(SidebarItem.phase(phase.id))
          }
        }
        Section {
          Label("Settings", systemImage: "gearshape")
            .tag(SidebarItem.settings)
        }
      }
      .safeAreaInset(edge: .bottom, spacing: 0) {
        VStack(spacing: 0) {
          Divider()
          HStack(spacing: 0) {
            Button("Add Phase", systemImage: "plus") {
              selection = .phase(scheduler.addPhase().id)
            }
            Button("Delete Phase", systemImage: "minus") {
              if case .phase(let id) = selection { scheduler.deletePhase(id: id) }
              selection = scheduler.phasesByTime.first.map { .phase($0.id) }
            }
            .disabled(selectedPhaseID == nil)
            Spacer()
          }
          .labelStyle(.iconOnly)
          .buttonStyle(.borderless)
          .padding(6)
        }
      }
      .navigationSplitViewColumnWidth(min: 220, ideal: 240)
    } detail: {
      switch selection {
      case .settings:
        SettingsView(scheduler: scheduler)
      case .phase(let id) where scheduler.phases.contains(where: { $0.id == id }):
        PhaseEditor(scheduler: scheduler, phaseID: id)
          .id(id)
      default:
        ContentUnavailableView(
          "No Phase Selected",
          systemImage: "sun.horizon",
          description: Text("Select a phase, or add one with the + button.")
        )
      }
    }
    .onAppear {
      scheduler.library.reload()
      if selection == nil {
        selection = (scheduler.activePhase ?? scheduler.phasesByTime.first).map { .phase($0.id) } ?? .settings
      }
    }
  }

  private var selectedPhaseID: Phase.ID? {
    if case .phase(let id) = selection { id } else { nil }
  }
}

private enum SidebarItem: Hashable {
  case phase(Phase.ID)
  case settings
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
