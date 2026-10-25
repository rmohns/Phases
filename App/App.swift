import SwiftUI

@main
struct AppDefinition: App {
  @State private var scheduler = WallpaperScheduler()

  var body: some Scene {
    MenuBarExtra("Wallpaper Scheduler", systemImage: "photo.on.rectangle.angled") {
      MenuContent(scheduler: scheduler)
    }

    Settings {
      SettingsView(scheduler: scheduler)
    }
  }
}
