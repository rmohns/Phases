import Foundation

/// [D-first-launch-shows-window] Whether this launch is the user's first,
/// so the window opens on its own.
enum FirstLaunch {
  /// Set once a launch has been recorded.
  static let recordKey = "hasLaunched"

  /// A first launch has no recorded launch and no settings saved by an
  /// earlier version, so updating never opens the window for an existing
  /// user. Test mode's store always starts empty, so it counts only with
  /// its switch [D-ui-test-mode].
  static func isFirstLaunch(
    hasRecordedLaunch: Bool, hasSavedSettings: Bool, isUITestMode: Bool, testForcesFirstLaunch: Bool
  ) -> Bool {
    if isUITestMode { return testForcesFirstLaunch }
    return !hasRecordedLaunch && !hasSavedSettings
  }
}
