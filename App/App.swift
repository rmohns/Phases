import SwiftUI

@main
struct AppDefinition: App {
  @State private var scheduler = WallpaperScheduler()
  // EXPERIMENT (issue #13): reopen handling.
  @NSApplicationDelegateAdaptor private var reopenDelegate: ReopenExperimentDelegate

  var body: some Scene {
    MenuBarExtra {
      MenuContent(scheduler: scheduler)
    } label: {
      ReopenExperimentLabel(image: Self.menuBarIcon)
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

  /// [D-menubar-icon] Solid shapes, drawn at 20 pt as a template so macOS
  /// colors it for light and dark menu bars.
  private static let menuBarIcon: NSImage = {
    let image = NSImage(named: "MenuBarIcon") ?? NSImage()
    image.size = NSSize(width: 20, height: 20)
    image.isTemplate = true
    return image
  }()
}
