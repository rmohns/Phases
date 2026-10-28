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
        // First list item, so it scrolls away with long phase lists (spec §7).
        SidebarBranding(scheduler: scheduler)
          .selectionDisabled()
          .listRowSeparator(.hidden)
          .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 8, trailing: 8))

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
      .navigationSplitViewColumnWidth(min: 240, ideal: 240, max: 320)
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

/// Decorative "mini screen" at the top of the sidebar: the app icon and name
/// over the current wallpaper, or the icon's gradient before any is applied.
private struct SidebarBranding: View {
  var scheduler: WallpaperScheduler
  @State private var wallpaper: NSImage?
  @Environment(\.displayScale) private var displayScale

  var body: some View {
    let shape = RoundedRectangle(cornerRadius: 10)
    Color.clear
      .aspectRatio(16 / 10, contentMode: .fit)
      .frame(maxWidth: .infinity)
      .background {
        if let wallpaper {
          // No overall dimming; a gradient behind the text only (spec §7).
          Image(nsImage: wallpaper)
            .resizable()
            .scaledToFill()
            .overlay {
              LinearGradient(
                stops: [.init(color: .black.opacity(0.55), location: 0), .init(color: .clear, location: 0.55)],
                startPoint: .bottom,
                endPoint: .top
              )
            }
        } else {
          LinearGradient(
            colors: [Color(red: 0.19, green: 0.53, blue: 0.94), Color(red: 0.29, green: 0.25, blue: 0.88)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
          .opacity(0.85)
        }
      }
      .overlay {
        VStack(spacing: 4) {
          Image(nsImage: NSApp.applicationIconImage)
            .resizable()
            .frame(width: 52, height: 52)
            .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
          // Fixed sizes: a decorative, fixed-shape panel (spec §7).
          Text("Phases")
            .font(.system(size: 15, weight: .semibold))
          // Sidebar list rows default to one line, which would cut this off
          // at the line break; allow both lines explicitly.
          Text("Wallpaper for every\nphase of your day")
            .font(.system(size: 12, weight: .light))
            .lineLimit(2)
            .multilineTextAlignment(.center)
            .fixedSize()
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.5), radius: 3, y: 1)
        .padding(.horizontal, 10)
      }
      .clipShape(shape)
      .overlay(shape.strokeBorder(.separator))
      .animation(.smooth, value: wallpaper)
      .task(id: scheduler.currentImageName) {
        guard let name = scheduler.currentImageName else {
          wallpaper = nil
          return
        }
        if let image = await scheduler.library.thumbnail(for: name, size: CGSize(width: 240, height: 150), scale: displayScale) {
          wallpaper = image
        }
      }
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("Phases. Wallpaper for every phase of your day")
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
