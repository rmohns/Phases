import SwiftUI

/// The single Phases window [D-one-window]: phases and Settings in the sidebar,
/// the selected item's editor in the detail area.
struct PhasesWindow: View {
  static let windowID = "phases"

  var scheduler: WallpaperScheduler
  @State private var selection: SidebarItem?
  /// [D-grid-release-on-close] False once the window has been closed for a
  /// moment, so SwiftUI drops the detail pane and the grid's thumbnails.
  @State private var holdsDetail = true
  @State private var isOpen = true
  /// [D-brand-egg] Held by the window, not the panel row, so scrolling the
  /// panel away doesn't reset it.
  @State private var showsMeme = false
  @FocusState private var sidebarFocused: Bool

  var body: some View {
    NavigationSplitView {
      List(selection: $selection) {
        // [D-brand-scrolls] First list item, so it scrolls away with long
        // phase lists; never pinned.
        SidebarBranding(scheduler: scheduler, showsMeme: $showsMeme)
          .selectionDisabled()
          .listRowSeparator(.hidden)
          // [D-brand-inset] [Q-list-row-padding] Sides line up with the traffic lights and row
          // icons; top lines up with the detail form's first row.
          .listRowInsets(EdgeInsets(top: 20, leading: 3, bottom: 8, trailing: 3))

        // [D-settings-at-top] Above the phases, so it's never pushed offscreen.
        Section("App") {
          Label("Settings", systemImage: "gearshape")
            .tag(SidebarItem.settings)
        }
        Section("Phases") {
          ForEach(scheduler.phasesByTime) { phase in
            PhaseRow(
              phase: phase,
              isActive: phase.id == scheduler.activePhase?.id,
              isSelected: selection == .phase(phase.id),
              sidebarFocused: sidebarFocused,
              availability: scheduler.location.availability(of: phase)
            )
              .tag(SidebarItem.phase(phase.id))
              // [D-phase-actions] Acts on the row clicked, selected or not.
              .contextMenu {
                Button("Duplicate") { duplicatePhase(phase.id, scheduler: scheduler, selection: &selection) }
                // [D-phase-turn-off]
                Button(phase.isOn ? "Turn Off" : "Turn On") { scheduler.togglePhase(id: phase.id) }
                Divider()
                Button("Delete") { deletePhase(phase.id, scheduler: scheduler, selection: &selection) }
              }
          }
        }
      }
      // [D-ui-test-ids]
      .accessibilityIdentifier("sidebar")
      .safeAreaInset(edge: .bottom, spacing: 0) {
        // [D-sidebar-footer-view] [Q-safe-area-inset-refresh] Its own view with
        // a binding, so it refreshes when the selection changes.
        SidebarFooter(scheduler: scheduler, selection: $selection)
      }
      // [D-initial-focus-sidebar] Set in onAppear below.
      .focused($sidebarFocused)
      // [D-sidebar-width] Opens at the 240 pt minimum; widens to 320 pt.
      .navigationSplitViewColumnWidth(min: 240, ideal: 240, max: 320)
      .background {
        // [D-window-helper-order] Toolbar, then sidebar limits, in one helper
        // [Q-split-item-rewrite].
        WindowLayoutConfigurator(
          sidebarMinWidth: 240, sidebarMaxWidth: 320,
          onOpen: windowOpened, onClose: windowClosed
        )
      }
      // [D-sidebar-always-visible] [Q-sidebar-collapse] No toggle button; the configurator above
      // stops drags from collapsing it.
      .toolbar(removing: .sidebarToggle)
    } detail: {
      if holdsDetail {
        detail
          // [D-window-min-size] The editor never gets narrower than this,
          // whatever the sidebar's width.
          .navigationSplitViewColumnWidth(min: 460, ideal: 720)
      }
    }
    // [D-window-min-size]
    .frame(minHeight: 480)
    // [D-app-menu] For Settings… in the app menu.
    .focusedSceneValue(\.sidebarSelection, $selection)
    .onAppear {
      windowOpened()
      scheduler.library.reload()
      if selection == nil {
        selection = (scheduler.activePhase ?? scheduler.phasesByTime.first).map { .phase($0.id) } ?? .settings
      }
      // [D-initial-focus-sidebar] [Q-default-focus-loses] Otherwise macOS focuses the phase's Name
      // field on open and selects its text. Deferred a pass so the editor
      // exists first; `.defaultFocus` alone lost to the field.
      DispatchQueue.main.async { sidebarFocused = true }
    }
  }

  @ViewBuilder private var detail: some View {
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

  private func windowOpened() {
    isOpen = true
    holdsDetail = true
  }

  /// [D-grid-release-on-close] Waits out the close before emptying the pane,
  /// so nothing visibly blanks; a reopen in the meantime keeps it.
  private func windowClosed() {
    isOpen = false
    // [D-brand-egg] The window's state outlives a close, so reset explicitly.
    showsMeme = false
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      if !isOpen { holdsDetail = false }
    }
  }
}

/// The + / − bar pinned below the sidebar list.
private struct SidebarFooter: View {
  var scheduler: WallpaperScheduler
  @Binding var selection: SidebarItem?

  var body: some View {
    VStack(spacing: 0) {
      Divider()
      // [D-sidebar-footer-style] [Q-borderless-pressed-state] System Settings'
      // Login Items layout:
      // 24 × 23 pt cells split by a 16 pt divider.
      HStack(spacing: 0) {
        Button {
          selection = .phase(scheduler.addPhase().id)
        } label: {
          cell("Add Phase", systemImage: "plus")
        }
        // [D-footer-ax-labels] [Q-system-events-ax] The wrapped icon-only Label doesn't pass its
        // title through, so name the button explicitly.
        .accessibilityLabel("Add Phase")
        .accessibilityIdentifier("addPhase")
        divider
        Button {
          guard let id = selectedPhaseID else { return }
          deletePhase(id, scheduler: scheduler, selection: &selection)
        } label: {
          cell("Delete Phase", systemImage: "minus")
        }
        .accessibilityLabel("Delete Phase")
        .accessibilityIdentifier("deletePhase")
        .disabled(selectedPhaseID == nil)
        divider
        // [D-phase-actions] Commands for the selected phase; the rows'
        // context menu lists the same ones.
        Menu {
          Button("Duplicate") {
            guard let id = selectedPhaseID else { return }
            duplicatePhase(id, scheduler: scheduler, selection: &selection)
          }
          // [D-phase-turn-off]
          Button(selectedPhase?.isOn == false ? "Turn On" : "Turn Off") {
            guard let id = selectedPhaseID else { return }
            scheduler.togglePhase(id: id)
          }
        } label: {
          cell("Phase Actions", systemImage: "ellipsis")
        }
        .menuIndicator(.hidden)
        .fixedSize()
        .accessibilityLabel("Phase Actions")
        .accessibilityIdentifier("phaseActions")
        .disabled(selectedPhaseID == nil)
        Spacer()
      }
      .buttonStyle(.borderless)
    }
  }

  /// The 1 pt divider between cells.
  private var divider: some View {
    Rectangle()
      .fill(.separator)
      .frame(width: 1, height: 16)
  }

  /// An icon in a fully clickable 24 × 23 pt cell.
  private func cell(_ title: LocalizedStringKey, systemImage: String) -> some View {
    Label(title, systemImage: systemImage)
      .labelStyle(.iconOnly)
      .frame(width: 24, height: 23)
      .contentShape(Rectangle())
  }

  private var selectedPhaseID: Phase.ID? {
    if case .phase(let id) = selection { id } else { nil }
  }

  private var selectedPhase: Phase? {
    selectedPhaseID.flatMap { id in scheduler.phases.first { $0.id == id } }
  }
}

/// Decorative "mini screen" at the top of the sidebar: the app icon and name
/// over the current wallpaper, or the icon's gradient before any is applied.
private struct SidebarBranding: View {
  var scheduler: WallpaperScheduler
  @Binding var showsMeme: Bool
  @State private var wallpaper: NSImage?
  @Environment(\.displayScale) private var displayScale

  var body: some View {
    let shape = RoundedRectangle(cornerRadius: 10)
    Color.clear
      .aspectRatio(16 / 10, contentMode: .fit)
      .frame(maxWidth: .infinity)
      .background {
        if showsMeme {
          // [D-brand-egg] The meme alone: no icon, text, or gradient.
          Image("VibeCodingMeme")
            .resizable()
            .scaledToFill()
        } else if let wallpaper {
          // [D-brand-legibility] No overall dimming; a gradient behind the
          // text only.
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
        if !showsMeme {
          brandText
        }
      }
      .clipShape(shape)
      .overlay(shape.strokeBorder(.separator))
      .animation(.smooth, value: wallpaper)
      .animation(.smooth, value: showsMeme)
      .task(id: scheduler.currentImageName) {
        guard let name = scheduler.currentImageName else {
          wallpaper = nil
          return
        }
        if let image = await scheduler.library.thumbnail(for: name, size: CGSize(width: 240, height: 150), scale: displayScale) {
          wallpaper = image
        }
      }
      // [D-brand-egg] One-way; no pointer change, no selection change.
      .contentShape(shape)
      .onTapGesture { showsMeme = true }
      .accessibilityElement(children: .ignore)
      .accessibilityAddTraits(.isButton)
      .accessibilityLabel(showsMeme
        ? "Meme: three women in a convertible. Get in loser, we're going vibe coding."
        : "Phases. Wallpaper for every phase of your day")
      .accessibilityHint(showsMeme ? "" : "Get in.")
      .accessibilityAction { showsMeme = true }
  }

  private var brandText: some View {
    // [D-brand-layout] 52 pt icon, two-line tagline with a chosen break.
    VStack(spacing: 4) {
      Image(nsImage: NSApp.applicationIconImage)
        .resizable()
        .frame(width: 52, height: 52)
        .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
      // [D-brand-fixed-text] Fixed sizes: a decorative, fixed-shape panel.
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
}

/// [D-delete-selects-next] Deleting the selected phase selects the one that
/// takes its place, or the one above if it was last. Deleting another
/// phase leaves the selection alone [D-phase-actions].
@MainActor private func deletePhase(_ id: Phase.ID, scheduler: WallpaperScheduler, selection: inout SidebarItem?) {
  let next = PhaseListSelection.afterDeleting(id, from: scheduler.phasesByTime.map(\.id))
  scheduler.deletePhase(id: id)
  if selection == .phase(id) {
    selection = next.map { .phase($0) } ?? .settings
  }
}

/// [D-duplicate-phase] The copy is selected once made.
@MainActor private func duplicatePhase(_ id: Phase.ID, scheduler: WallpaperScheduler, selection: inout SidebarItem?) {
  if let copy = scheduler.duplicatePhase(id: id) {
    selection = .phase(copy.id)
  }
}

enum SidebarItem: Hashable {
  case phase(Phase.ID)
  case settings
}

private struct PhaseRow: View {
  var phase: Phase
  var isActive: Bool
  var isSelected: Bool
  var sidebarFocused: Bool
  var availability: PhaseAvailability
  @Environment(\.appearsActive) private var windowInFront

  /// [D-active-badge] [Q-tint-on-highlight] The row's text color on the
  /// colored highlight, where the accent color would vanish.
  private var badgeStyle: AnyShapeStyle {
    SidebarHighlight.isColored(isSelected: isSelected, windowInFront: windowInFront, sidebarFocused: sidebarFocused)
      ? AnyShapeStyle(.primary) : AnyShapeStyle(.tint)
  }

  var body: some View {
    Label {
      VStack(alignment: .leading, spacing: 2) {
        HStack(spacing: 4) {
          Text(phase.name)
            // [D-phase-cant-run] Dimmed when the phase can't run.
            .foregroundStyle(availability.isDisabled ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary))
          if isActive {
            Text("Active")
              .font(.caption2.weight(.semibold))
              .foregroundStyle(badgeStyle)
          }
        }
        HStack(spacing: 4) {
          Text(phase.trigger.summary)
          if let symbol = phase.appearance.systemImage {
            Image(systemName: symbol)
              .accessibilityLabel("\(phase.appearance.title) Mode only")
          }
          // [D-row-status-not-cause] The status only; the phase editor names
          // the cause. [D-phase-turn-off] "Off". No warning symbol (draft 45).
          if let status = availability.rowStatus {
            Text(status)
          }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
      }
    } icon: {
      Image(systemName: phase.trigger.kind.systemImage)
        .opacity(availability.isDisabled ? 0.5 : 1)
    }
    .padding(.vertical, 2)
    .accessibilityElement(children: .combine)
  }
}
