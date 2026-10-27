import SwiftUI

/// The menu shown from the menu bar icon.
struct MenuContent: View {
  @Bindable var scheduler: WallpaperScheduler
  @Environment(\.openWindow) private var openWindow

  var body: some View {
    Group {
      if let phase = scheduler.activePhase {
        Text("Phase: \(phase.name)")
      } else {
        Text("No active phase")
      }
      if let image = scheduler.currentImageName {
        Text(image)
      }
      if scheduler.isPaused {
        Text("Paused")
      } else if let next = scheduler.nextChange {
        Text(nextChangeDescription(next))
      }
      if scheduler.needsLocation && scheduler.location.isDenied {
        Text("Location access is off; dawn and dusk phases are skipped.")
      }
    }

    Divider()

    Button("Change Now", systemImage: "arrow.forward") {
      scheduler.changeNow()
    }
    .disabled(scheduler.activePhase == nil)

    Toggle("Pause Schedule", isOn: $scheduler.isPaused)

    Divider()

    Button("Open Phases…") {
      NSApp.activate()
      openWindow(id: PhasesWindow.windowID)
    }

    Button("Quit Phases") {
      NSApp.terminate(nil)
    }
    .keyboardShortcut("q")
  }

  private func nextChangeDescription(_ next: WallpaperScheduler.NextChange) -> String {
    let time = next.date.formatted(Calendar.current.isDateInToday(next.date)
      ? .dateTime.hour().minute()
      : .dateTime.weekday(.abbreviated).hour().minute())
    if let name = next.phaseName {
      return "Next: \(name) at \(time)"
    }
    return "Next image at \(time)"
  }
}
