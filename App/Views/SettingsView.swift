import SwiftUI

struct SettingsView: View {
  @Bindable var scheduler: WallpaperScheduler
  @State private var isChoosingFolder = false
  @State private var isConfirmingLaunchAtLogin = false

  var body: some View {
    Form {
      Section("Images") {
        LabeledContent("Folder") {
          HStack {
            if let url = scheduler.library.folderURL {
              Image(systemName: "folder")
                .foregroundStyle(.secondary)
              Text(url.lastPathComponent)
                .lineLimit(1)
                .truncationMode(.middle)
                .layoutPriority(1)
                .help(url.path(percentEncoded: false))
                // [D-ui-test-ids]
                .accessibilityIdentifier("imageFolderName")
            } else {
              Text("None chosen")
                .foregroundStyle(.secondary)
            }
            Button("Choose…") { isChoosingFolder = true }
              // The name's layout priority would otherwise squeeze this to
              // a sliver with a long folder name (found 2026-10-29).
              .fixedSize()
          }
        }
        Toggle("Include subfolders", isOn: includesSubfoldersBinding)
        if scheduler.library.folderURL != nil {
          LabeledContent("Images found", value: scheduler.library.imageNames.count, format: .number)
        }
      }

      Section("Displays") {
        Picker("Displays", selection: $scheduler.displayMode) {
          ForEach(DisplayMode.allCases) { mode in
            Text(mode.title).tag(mode)
          }
        }
        .pickerStyle(.radioGroup)
        .labelsHidden()
        Text("Applies to displays that don't have their own images in a phase. Changes apply to the current Space on each display.")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Section("Transition") {
        Picker("Transition", selection: $scheduler.transitionStyle) {
          ForEach(TransitionStyle.allCases) { style in
            Text(style.title).tag(style)
          }
        }
        .pickerStyle(.segmented)
        if scheduler.transitionStyle == .crossfade {
          LabeledContent("Duration") {
            HStack {
              Slider(value: $scheduler.crossfadeDuration, in: TransitionStyle.durationRange) {
                Text("Duration")
              } minimumValueLabel: {
                Text("0.5 s")
              } maximumValueLabel: {
                Text("3 s")
              }
              .labelsHidden()
              Text("\(scheduler.crossfadeDuration, format: .number.precision(.fractionLength(1))) s")
                .monospacedDigit()
                .frame(width: 44, alignment: .trailing)
            }
          }
        }
        Text("Changes are instant when Reduce Motion is on.")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Section("Startup") {
        Toggle("Launch at Login", isOn: launchAtLoginBinding)
        if scheduler.launchAtLogin.needsApproval {
          HStack {
            Text("Waiting for approval in System Settings.")
              .foregroundStyle(.secondary)
            Button("Open Login Items…") { scheduler.launchAtLogin.openLoginItemsSettings() }
          }
        }
        if let error = scheduler.launchAtLogin.lastError {
          Text(error)
            .foregroundStyle(.red)
        }
      }

      Section("Location") {
        LocationStatusView(scheduler: scheduler)
      }

      // [D-restore-on-quit] No Quit button; Quit is in the app menu [D-app-menu].
      Section("Quitting") {
        Toggle(isOn: $scheduler.restoresWallpaperOnQuit) {
          Text("Restore original wallpaper when quitting")
          Text(
            scheduler.restoresWallpaperOnQuit
              ? "Quitting Phases puts back the wallpaper you had before it started."
              : "Quitting Phases keeps the current wallpaper."
          )
        }
        // [D-quit-confirm] Turns the question back on after "Don't ask again".
        Toggle(isOn: $scheduler.asksBeforeQuitting) {
          Text("Ask before quitting")
          Text("Quit Phases (⌘Q) checks first, and offers to keep Phases running in the menu bar.")
        }
      }

      // [D-version-in-settings]
      Section("About") {
        LabeledContent("Version", value: AppVersion.versionAndBuild)
        LabeledContent("Spec", value: "Draft \(AppVersion.specDraft)")
        if let built = AppVersion.buildDate {
          LabeledContent("Built", value: built.formatted(date: .abbreviated, time: .shortened))
        }
      }
    }
    .formStyle(.grouped)
    .navigationTitle("Settings")
    .fileImporter(isPresented: $isChoosingFolder, allowedContentTypes: [.folder]) { result in
      if case .success(let url) = result {
        scheduler.library.setFolder(url)
        scheduler.evaluate()
      }
    }
    .alert("Launch Phases at login?", isPresented: $isConfirmingLaunchAtLogin) {
      Button("Add Login Item") { scheduler.launchAtLogin.enable() }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text(
        "This adds Phases to System Settings › General › Login Items so it opens when you log in. It doesn't install any launch agents or background helpers. You can remove it at any time."
      )
    }
  }

  private var includesSubfoldersBinding: Binding<Bool> {
    Binding {
      scheduler.library.includesSubfolders
    } set: { isOn in
      scheduler.library.includesSubfolders = isOn
      scheduler.evaluate(reloadingLibrary: false)
    }
  }

  /// Turning on asks first; turning off takes effect right away.
  /// [D-login-consent] Turning it on only asks; registering waits for the
  /// confirmation alert.
  private var launchAtLoginBinding: Binding<Bool> {
    Binding {
      scheduler.launchAtLogin.isEnabled
    } set: { isOn in
      if isOn {
        isConfirmingLaunchAtLogin = true
      } else {
        scheduler.launchAtLogin.disable()
      }
    }
  }
}

private struct LocationStatusView: View {
  var scheduler: WallpaperScheduler

  var body: some View {
    let location = scheduler.location
    if location.isDenied {
      VStack(alignment: .leading, spacing: 6) {
        Label("Location access is off", systemImage: "location.slash")
        Text("Dawn and dusk phases are skipped until you allow access in System Settings › Privacy & Security › Location Services.")
          .font(.caption)
          .foregroundStyle(.secondary)
        Button("Open Location Settings…") {
          if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices") {
            NSWorkspace.shared.open(url)
          }
        }
      }
    } else if let coordinate = location.coordinate {
      LabeledContent("Current location") {
        Text(
          "\(coordinate.latitude.formatted(.number.precision(.fractionLength(2)))), \(coordinate.longitude.formatted(.number.precision(.fractionLength(2))))"
        )
        .monospacedDigit()
      }
      SolarTimesView(coordinate: coordinate)
      LocationUpdateRow(location: location)
    } else if scheduler.needsLocation {
      HStack {
        Text("Waiting for location…")
          .foregroundStyle(.secondary)
        Button("Retry") { location.refresh() }
      }
    } else {
      Text("Location is requested when you add a dawn or dusk phase.")
        .foregroundStyle(.secondary)
    }
  }
}

private struct LocationUpdateRow: View {
  var location: LocationProvider

  var body: some View {
    LabeledContent {
      HStack {
        if location.isUpdating {
          ProgressView()
            .controlSize(.small)
        }
        Button("Update Now") { location.refresh() }
          .disabled(location.isUpdating)
      }
    } label: {
      if let lastUpdated = location.lastUpdated {
        Text("Updated \(lastUpdated, format: .relative(presentation: .named))")
      } else {
        Text("Updated")
      }
    }
  }
}

private struct SolarTimesView: View {
  var coordinate: SolarCalculator.Coordinate

  var body: some View {
    let today = Date()
    LabeledContent("Civil dawn today") {
      Text(format(SolarCalculator.time(of: .dawn, on: today, at: coordinate)))
    }
    LabeledContent("Civil dusk today") {
      Text(format(SolarCalculator.time(of: .dusk, on: today, at: coordinate)))
    }
  }

  private func format(_ date: Date?) -> String {
    date?.formatted(date: .omitted, time: .shortened) ?? "None today"
  }
}
