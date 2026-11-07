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
  /// [D-first-launch-shows-window] The first-launch window waits for this
  /// [Q-launch-activate-refused].
  func applicationDidFinishLaunching(_ notification: Notification) {
    MainActor.assumeIsolated { FirstLaunchWindow.launchFinished = true }
  }

  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    diagLog.log("relaunched; hasVisibleWindows=\(flag) \(Self.state(), privacy: .public)")
    NotificationCenter.default.post(name: .phasesRelaunched, object: nil)
    if Diagnostics.isEnabled {
      for delay in [0.5, 2.0] {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
          diagLog.log("relaunch +\(delay)s: \(Self.state(), privacy: .public)")
        }
      }
    }
    // The view does the whole job, minimized windows included.
    return false
  }

  /// For the log: whether Phases is active, its activation policy, and the
  /// window's state.
  @MainActor
  private static func state() -> String {
    let window = NSApp.windows.first {
      $0.identifier?.rawValue.hasPrefix(PhasesWindow.windowID) == true
    }
    let windowState = window.map {
      "visible=\($0.isVisible) key=\($0.isKeyWindow) minimized=\($0.isMiniaturized) onActiveSpace=\($0.isOnActiveSpace)"
    } ?? "no window"
    return "active=\(NSApp.isActive) policy=\(NSApp.activationPolicy().rawValue) \(windowState)"
  }
}
