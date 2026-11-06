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

      // [D-menu-pause-verb] A command that says what it will do, not a checkmark.
      Button(scheduler.isPaused ? "Resume Schedule" : "Pause Schedule") {
        scheduler.isPaused.toggle()
      }
    }

    Divider()

    Button("Open Phases…") {
      openWindow.showPhasesWindow()
    }
  }

  /// [D-menu-status-header] One compact line, e.g. "Dusk · until 7:13 PM".
  /// [D-outside-change-notice] An outside change replaces the phase line.
  private var statusLine: String {
    if scheduler.isPaused && scheduler.pausedForOutsideChangeAt != nil {
      return "Paused · wallpaper changed in System Settings"
    }
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
