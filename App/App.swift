import SwiftUI

@main
struct AppDefinition: App {
  @State private var scheduler = WallpaperScheduler()

  var body: some Scene {
    MenuBarExtra("Phases", systemImage: "photo.on.rectangle.angled") {
      MenuContent(scheduler: scheduler)
    }

    Window("Phases", id: PhasesWindow.windowID) {
      PhasesWindow(scheduler: scheduler)
    }
    .defaultSize(width: 960, height: 680)
    .defaultLaunchBehavior(.suppressed)
  }
}
