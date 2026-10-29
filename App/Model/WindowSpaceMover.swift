import AppKit
import os

// [D-diagnostics-switch] Off unless diagnostics are switched on at launch.
private let diagLog = Diagnostics.logger("spaces")

/// [D-open-here] Brings the Phases window to the current Space when it's
/// opened from the menu bar, instead of letting activation switch Spaces
/// [Q-activate-switches-space]. Workaround: ERRATA.md "Open here".
@MainActor
enum WindowSpaceMover {
  /// Takes the window off screen if it's open on another Space. Returns the
  /// window to show again after activating, or nil if there's nothing to do.
  static func prepare(windowID: String) -> NSWindow? {
    guard let window = NSApp.windows.first(where: {
      $0.identifier?.rawValue.hasPrefix(windowID) == true
    }) else {
      diagLog.log("no window yet")
      return nil
    }
    diagLog.log("window \(window.identifier?.rawValue ?? "", privacy: .public) visible=\(window.isVisible) onActiveSpace=\(window.isOnActiveSpace) minimized=\(window.isMiniaturized)")
    guard window.isVisible, !window.isOnActiveSpace, !window.isMiniaturized else { return nil }
    // Ordering out doesn't post willClose, so the Dock icon stays [D-dock-while-open].
    window.orderOut(nil)
    return window
  }

  /// Shows the window again, on the current Space. Call after activating.
  static func finish(_ window: NSWindow?) {
    guard let window else { return }
    window.makeKeyAndOrderFront(nil)
    diagLog.log("moved; onActiveSpace=\(window.isOnActiveSpace)")
  }
}
