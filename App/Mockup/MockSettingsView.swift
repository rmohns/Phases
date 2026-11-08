import SwiftUI

/// MOCKUP: the proposed Settings, classic Mac columns and checkboxes. The
/// schedule switch moves to the toolbar, display sharing into each phase,
/// and About into the About panel. Controls hold throwaway state; nothing is saved.
struct MockSettingsView: View {
  var scheduler: WallpaperScheduler
  @State private var transition: TransitionStyle
  @State private var duration: Double
  @State private var launchAtLogin: Bool
  @State private var restoresOnQuit: Bool
  @State private var asksBeforeQuitting: Bool
  @State private var includesSubfolders: Bool

  init(scheduler: WallpaperScheduler) {
    self.scheduler = scheduler
    _transition = State(initialValue: scheduler.transitionStyle)
    _duration = State(initialValue: scheduler.crossfadeDuration)
    _launchAtLogin = State(initialValue: scheduler.launchAtLogin.isEnabled)
    _restoresOnQuit = State(initialValue: scheduler.restoresWallpaperOnQuit)
    _asksBeforeQuitting = State(initialValue: scheduler.asksBeforeQuitting)
    _includesSubfolders = State(initialValue: scheduler.library.includesSubfolders)
  }

  var body: some View {
    ScrollView {
      Form {
        Section {
          LabeledContent("Image folder:") {
            VStack(alignment: .leading, spacing: 8) {
              HStack {
                Label(scheduler.library.folderURL?.lastPathComponent ?? "None chosen", systemImage: "folder")
                  .lineLimit(1)
                  .truncationMode(.middle)
                Button("Choose…") {}
              }
              Toggle("Include subfolders", isOn: $includesSubfolders)
                .toggleStyle(.checkbox)
              Text("\(scheduler.library.imageNames.count) images found")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
        }

        Section {
          LabeledContent("Startup:") {
            Toggle("Open Phases when you log in", isOn: $launchAtLogin)
              .toggleStyle(.checkbox)
          }
        }

        Section {
          Picker("Transition:", selection: $transition) {
            ForEach(TransitionStyle.allCases) { style in
              Text(style.title).tag(style)
            }
          }
          .fixedSize()
          if transition == .crossfade {
            LabeledContent("Duration:") {
              HStack {
                Slider(value: $duration, in: TransitionStyle.durationRange) {
                  Text("Duration")
                } minimumValueLabel: {
                  Text("0.5 s")
                } maximumValueLabel: {
                  Text("3 s")
                }
                .labelsHidden()
                .frame(width: 220)
                Text("\(duration, format: .number.precision(.fractionLength(1))) s")
                  .monospacedDigit()
              }
            }
          }
          LabeledContent("") {
            Text("Changes are instant when Reduce Motion is on.")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }

        Section {
          LabeledContent("Location:") {
            MockLocationSummary(location: scheduler.location)
          }
        }

        Section {
          LabeledContent("When quitting:") {
            VStack(alignment: .leading, spacing: 8) {
              Toggle(isOn: $restoresOnQuit) {
                Text("Put back the wallpaper I had before Phases")
              }
              .toggleStyle(.checkbox)
              Toggle("Ask before quitting", isOn: $asksBeforeQuitting)
                .toggleStyle(.checkbox)
            }
          }
        }
      }
      .formStyle(.columns)
      .padding(.horizontal, 20)
      .padding(.vertical, 20)
      .frame(maxWidth: .infinity, alignment: .center)
    }
    .navigationTitle("Settings")
  }
}

/// Today's dawn and dusk, and when the location was last found, in two lines.
private struct MockLocationSummary: View {
  var location: LocationProvider

  var body: some View {
    if location.isDenied {
      VStack(alignment: .leading, spacing: 6) {
        Text("Location access is off. Dawn and dusk phases are skipped.")
        Button("Open Location Settings…") {}
      }
    } else if let coordinate = location.coordinate {
      let today = Date()
      VStack(alignment: .leading, spacing: 6) {
        Text("Dawn \(format(SolarCalculator.time(of: .dawn, on: today, at: coordinate))) · Dusk \(format(SolarCalculator.time(of: .dusk, on: today, at: coordinate))) today")
        HStack {
          if let lastUpdated = location.lastUpdated {
            Text("Updated \(lastUpdated, format: .relative(presentation: .named))")
              .foregroundStyle(.secondary)
          }
          Button("Update Now") {}
        }
      }
    } else {
      Text("Asked for when you add a dawn or dusk phase.")
        .foregroundStyle(.secondary)
    }
  }

  private func format(_ date: Date?) -> String {
    date?.formatted(date: .omitted, time: .shortened) ?? "none"
  }
}
