import SwiftUI

@main
struct AppDefinition: App {
  @State private var scheduler = WallpaperScheduler()
  // [D-reopen-shows-window] Launching Phases while it runs opens the window.
  @NSApplicationDelegateAdaptor private var reopenHandler: ReopenHandler

  var body: some Scene {
    MenuBarExtra {
      MenuContent(scheduler: scheduler)
    } label: {
      MenuBarLabel(isPaused: scheduler.isPaused)
    }

    // [D-one-window] Everything, Settings included, lives in this one window.
    Window("Phases", id: PhasesWindow.windowID) {
      PhasesWindow(scheduler: scheduler)
    }
    .defaultSize(width: 960, height: 680)
    // [D-tall-toolbar] Tall unified toolbar over the detail pane, even with
    // no toolbar buttons. Not enough on its own [Q-no-items-no-toolbar].
    .windowToolbarStyle(.unified)
    .defaultLaunchBehavior(.suppressed)
    .commands { PhasesCommands(scheduler: scheduler) }
  }
}
