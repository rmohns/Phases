import Foundation

/// [D-ui-test-mode] One launch for UI tests that touches nothing real: no
/// wallpaper changes, a throwaway settings store seeded with fixed phases,
/// and an image folder chosen by the test harness. Launch arguments only,
/// so it can't leak into normal use.
enum UITestMode {
  static let isOn = UserDefaults.standard.bool(forKey: "PhasesUITestMode")

  /// `-PhasesUITestFirstLaunch YES` makes a test-mode launch a first launch
  /// [D-first-launch-shows-window]; otherwise test mode never is.
  static let forcesFirstLaunch = UserDefaults.standard.bool(forKey: "PhasesUITestFirstLaunch")

  /// [D-test-paused-by-outside-change] `-PhasesUITestPausedByOutsideChange
  /// YES` starts a test-mode launch paused as if the wallpaper had just
  /// been changed in System Settings, so the pause banner shows the
  /// two-line reason. Ignored outside test mode.
  static let startsPausedByOutsideChange = isOn
    && UserDefaults.standard.bool(forKey: "PhasesUITestPausedByOutsideChange")

  /// The harness's image folder, from `-PhasesUITestImages <path>`.
  static var imageFolder: URL? {
    UserDefaults.standard.string(forKey: "PhasesUITestImages")
      .map { URL(filePath: $0, directoryHint: .isDirectory) }
  }

  /// Three clock-time phases, in order through the day, so tests can
  /// delete a middle one [D-delete-selects-next].
  static var fixturePhases: [Phase] {
    [
      Phase(name: "Morning", trigger: .clockTime(minutes: 7 * 60)),
      Phase(name: "Afternoon", trigger: .clockTime(minutes: 12 * 60)),
      Phase(name: "Evening", trigger: .clockTime(minutes: 18 * 60)),
    ]
  }
}
