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
        Section("App") {
          Label("Settings", systemImage: "gearshape")
            .tag(SidebarItem.settings)
        }
        Section("Phases") {
          ForEach(scheduler.phasesByTime) { phase in
            PhaseRow(phase: phase, isActive: phase.id == scheduler.activePhase?.id)
              .tag(SidebarItem.phase(phase.id))
          }
        }
      }
      .safeAreaInset(edge: .top, spacing: 0) {
        SidebarBranding()
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
    .background {
      // ⌘Q while this window is active (spec §7). Phases has no app menu, so
      // nothing else provides it.
      Button("Quit Phases") { NSApp.terminate(nil) }
        .keyboardShortcut("q")
        .opacity(0)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
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

/// Decorative app icon and name at the top of the sidebar.
private struct SidebarBranding: View {
  var body: some View {
    HStack(spacing: 8) {
      Image(nsImage: NSApp.applicationIconImage)
        .resizable()
        .frame(width: 28, height: 28)
        .accessibilityHidden(true)
      Text("Phases")
        .font(.title3.weight(.semibold))
      Spacer()
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 8)
    .accessibilityElement(children: .combine)
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
