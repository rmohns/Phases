import SwiftUI

@main
struct AppDefinition: App {
  @State private var scheduler = WallpaperScheduler()

  var body: some Scene {
    MenuBarExtra("Phases", systemImage: "photo.on.rectangle.angled") {
      MenuContent(scheduler: scheduler)
    }

    Window("Schedule", id: ScheduleView.windowID) {
      ScheduleView(scheduler: scheduler)
    }
    .defaultSize(width: 900, height: 640)
    .defaultLaunchBehavior(.suppressed)

    Settings {
      SettingsView(scheduler: scheduler)
    }
  }
}
