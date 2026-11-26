import SwiftUI

struct SettingsView: View {
  @Bindable var scheduler: WallpaperScheduler
  @State private var isConfirmingLaunchAtLogin = false
  /// [D-memory-in-about] Read each time Settings appears, not on every
  /// body evaluation.
  @State private var memoryFootprint: UInt64?

  var body: some View {
    Form {
      // [D-settings-order] [D-settings-pause-switch] On means paused; same
      // state as the menu's Pause Wallpaper Changes. No heading, and no
      // note. [D-pause-switch-disabled] Disabled while the pause banner
      // shows; its Resume is the way back [D-window-pause-banner].
      Section {
        Toggle("Pause wallpaper changes", isOn: $scheduler.isPaused)
          .disabled(scheduler.isPausedForOutsideChange)
          // [D-ui-test-ids]
          .accessibilityIdentifier("pauseSwitch")
      } header: {
        // [D-settings-order] The pane's header, in the phase editor's
        // name-row style [D-name-row].
        Text("Settings")
          .font(.title2.weight(.semibold))
          .foregroundStyle(.primary)
          .accessibilityAddTraits(.isHeader)
      }

      ImageSourcesSection(scheduler: scheduler)

      // [D-sharing-per-phase] Display sharing is set in each phase's editor.

      Section("Transition") {
        // [D-reduce-motion-note] Dimmed, values kept, while Reduce Motion is on.
        let controlsEnabled = ReduceMotionNote.controlsEnabled(reducesMotion: scheduler.reducesMotion)
        // [D-low-memory-note] The note shares the control's row: no
        // separator, normal size.
        VStack(alignment: .leading, spacing: 6) {
          Picker("Transition", selection: $scheduler.transitionStyle) {
            ForEach(TransitionStyle.allCases) { style in
              Text(style.title).tag(style)
            }
          }
          .pickerStyle(.segmented)
          .disabled(!controlsEnabled)
          if let note = LowMemoryNote.text(
            physicalMemory: MemoryUse.physicalMemory,
            transitionStyle: scheduler.transitionStyle,
            reducesMotion: scheduler.reducesMotion,
            footprint: memoryFootprint
          ) {
            Text(note)
              .foregroundStyle(.secondary)
              // [D-ui-test-ids]
              .accessibilityIdentifier("lowMemoryNote")
          }
        }
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
          .disabled(!controlsEnabled)
        }
        if let note = ReduceMotionNote.text(reducesMotion: scheduler.reducesMotion) {
          VStack(alignment: .leading, spacing: 6) {
            Text(note)
              .font(.caption)
              .foregroundStyle(.secondary)
            // Opens only when clicked; Phases never opens it by itself.
            Button("Open Motion Settings…") {
              NSWorkspace.shared.open(ReduceMotionNote.motionSettingsURL)
            }
          }
        }
      }

      Section("Location") {
        LocationStatusView(scheduler: scheduler)
      }

      // [D-settings-order] Startup and Quitting, merged. [D-restore-on-quit]
      // No Quit button; Quit is in the app menu [D-app-menu].
      Section("Launch & Quit") {
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
        // [D-memory-in-about] A snapshot taken when Settings appears.
        if let memoryFootprint {
          LabeledContent("Memory", value: LowMemoryNote.memoryText(bytes: memoryFootprint))
        }
      }
    }
    .formStyle(.grouped)
    // [D-window-title-phases] The header names the pane; the toolbar keeps
    // the window's name.
    .onAppear { memoryFootprint = MemoryUse.footprint() }
    .alert("Launch Phases at login?", isPresented: $isConfirmingLaunchAtLogin) {
      Button("Add Login Item") { scheduler.launchAtLogin.enable() }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text(
        "This adds Phases to System Settings › General › Login Items so it opens when you log in. It doesn't install any launch agents or background helpers. You can remove it at any time."
      )
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
        LocationPrivacyNote()
      }
    } else if let coordinate = location.coordinate {
      // [D-location-privacy-note] Joined to Current location: same row.
      VStack(alignment: .leading, spacing: 6) {
        LabeledContent("Current location") {
          Text(
            "\(coordinate.latitude.formatted(.number.precision(.fractionLength(2)))), \(coordinate.longitude.formatted(.number.precision(.fractionLength(2))))"
          )
          .monospacedDigit()
        }
        LocationPrivacyNote()
      }
      SolarTimesView(coordinate: coordinate)
      LocationUpdateRow(location: location)
    } else if scheduler.needsLocation {
      VStack(alignment: .leading, spacing: 6) {
        HStack {
          Text("Waiting for location…")
            .foregroundStyle(.secondary)
          Button("Retry") { location.refresh() }
        }
        LocationPrivacyNote()
      }
    } else {
      VStack(alignment: .leading, spacing: 6) {
        Text("Location is requested when you add a dawn or dusk phase.")
          .foregroundStyle(.secondary)
        LocationPrivacyNote()
      }
    }
  }
}

/// [D-location-privacy-note] Shown in every state, in the same row as the
/// section's first line: under Current location when there is one.
private struct LocationPrivacyNote: View {
  var body: some View {
    Text("Phases uses this to work out your dawn and dusk times. Phases never sends your location anywhere; it stays on your Mac.")
      .foregroundStyle(.secondary)
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
