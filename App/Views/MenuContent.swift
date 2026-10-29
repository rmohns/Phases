import SwiftUI

/// The menu shown from the menu bar icon.
///
/// [D-menu-no-shortcuts] No keyboard shortcuts, no filename, and no Quit item.
struct MenuContent: View {
  @Bindable var scheduler: WallpaperScheduler
  @Environment(\.openWindow) private var openWindow

  var body: some View {
    Section(statusLine) {
      if scheduler.needsLocation && scheduler.location.isDenied {
        Text("Location access is off; dawn and dusk phases are skipped.")
      }

      Button("Change Now", systemImage: "arrow.forward") {
        scheduler.changeNow()
      }
      .disabled(scheduler.activePhase == nil)

      Toggle("Pause Schedule", isOn: $scheduler.isPaused)
    }

    Divider()

    Button("Open Phases…") {
      // [D-dock-while-open] [Q-regular-activation-menubar] Regular before
      // activating, so the menu bar comes with the window.
      // [D-open-here] [Q-activate-switches-space] Come to this Space rather
      // than switching to the window's.
      let moved = WindowSpaceMover.prepare(windowID: PhasesWindow.windowID)
      DockPresence.show()
      openWindow(id: PhasesWindow.windowID)
      NSApp.activate()
      WindowSpaceMover.finish(moved)
    }
  }

  /// [D-menu-status-header] One compact line, e.g. "Dusk · until 7:13 PM".
  private var statusLine: String {
    guard let phase = scheduler.activePhase else { return "No active phase" }
    if scheduler.isPaused { return "\(phase.name) · Paused" }
    guard let ends = scheduler.activePhaseEnds else { return phase.name }
    return "\(phase.name) · until \(formatted(ends))"
  }

  private func formatted(_ date: Date) -> String {
    date.formatted(Calendar.current.isDateInToday(date)
      ? .dateTime.hour().minute()
      : .dateTime.weekday(.abbreviated).hour().minute())
  }
}
