import Foundation

/// [D-reduce-motion-note] What the Transition section shows for the
/// system's Reduce Motion setting. Pure, so the unit tests can reach it
/// [D-tests-unhosted].
enum ReduceMotionNote {
  /// The note under the Transition controls; nil when Reduce Motion is off.
  static func text(reducesMotion: Bool) -> String? {
    reducesMotion ? "Transitions are off because Reduce Motion is on in System Settings." : nil
  }

  /// Transition and Duration have no effect while Reduce Motion is on
  /// [D-no-fade-cases], so they're dimmed. Their saved values are untouched.
  static func controlsEnabled(reducesMotion: Bool) -> Bool {
    !reducesMotion
  }

  /// System Settings › Accessibility › Motion, for Open Motion Settings…
  /// (verified on macOS 27.2; see the spec).
  static let motionSettingsURL = URL(string: "x-apple.systempreferences:com.apple.Accessibility-Settings.extension?Motion")!
}
