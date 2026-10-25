import SwiftUI

struct SettingsView: View {
  var scheduler: WallpaperScheduler

  var body: some View {
    TabView {
      Tab("General", systemImage: "gearshape") {
        GeneralSettingsView(scheduler: scheduler)
      }
      Tab("Phases", systemImage: "sun.horizon") {
        PhasesSettingsView(scheduler: scheduler)
      }
    }
    .frame(minWidth: 760, minHeight: 520)
  }
}
