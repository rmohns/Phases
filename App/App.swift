import SwiftUI

@main
struct AppDefinition: App {
  @State private var scheduler = WallpaperScheduler()

  var body: some Scene {
    MenuBarExtra {
      MenuContent(scheduler: scheduler)
    } label: {
      Image(nsImage: Self.menuBarIcon)
        .accessibilityLabel("Phases")
    }

    Window("Phases", id: PhasesWindow.windowID) {
      PhasesWindow(scheduler: scheduler)
    }
    .defaultSize(width: 960, height: 680)
    .defaultLaunchBehavior(.suppressed)
  }

  /// The supplied 24×24 line drawing, scaled to fit the menu bar and drawn as
  /// a template so macOS colors it for light and dark menu bars.
  private static let menuBarIcon: NSImage = {
    let image = NSImage(named: "MenuBarIcon") ?? NSImage()
    image.size = NSSize(width: 20, height: 20)
    image.isTemplate = true
    return image
  }()
}
