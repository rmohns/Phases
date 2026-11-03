import AppKit
import os

// [D-diagnostics-switch] Off unless diagnostics are switched on at launch.
private let diagLog = Diagnostics.logger("reopen")

extension Notification.Name {
  /// Phases was launched again while running; the menu bar icon's view
  /// opens the window [D-reopen-shows-window].
  static let phasesRelaunched = Notification.Name("PhasesRelaunched")
}

/// [D-reopen-shows-window] Turns a launch-while-running into "Open
/// Phases…". SwiftUI ignores the relaunch when the window is closed or was
/// never opened [Q-reopen-ignores-closed-window], and only a view can open
/// a SwiftUI window, so this hands the request to the menu bar icon's view,
/// the one view that's always alive.
final class ReopenHandler: NSObject, NSApplicationDelegate {
  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    diagLog.log("relaunched; hasVisibleWindows=\(flag)")
    NotificationCenter.default.post(name: .phasesRelaunched, object: nil)
    // The view does the whole job, minimized windows included.
    return false
  }
}
