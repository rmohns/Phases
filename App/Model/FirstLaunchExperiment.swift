import AppKit
import SwiftUI
import os

// EXPERIMENT ONLY (branch experiment/first-launch-activation): why the
// first-launch window stays behind [Q-launch-activate-refused]. Pick a try
// with `defaults write <bundle id> PhasesActivationTry -int N`:
//   0 baseline: open at once, as on spec/starter-phases
//   1 open only after the launch has finished
//   3 as 1, then take activation from the frontmost app
//   2 as 1, then the deprecated forced activation
private let diagLog = Diagnostics.logger("firstLaunch")

@MainActor
enum FirstLaunchExperiment {
  /// Set by the app delegate when AppKit finishes launching.
  static var launchFinished = false

  static var tryNumber: Int { UserDefaults.standard.integer(forKey: "PhasesActivationTry") }

  static func open(_ openWindow: OpenWindowAction) async {
    let attempt = tryNumber
    diagLog.log("try \(attempt); at task: finished=\(launchFinished) \(state(), privacy: .public)")
    if attempt != 0 && !launchFinished {
      for await _ in NotificationCenter.default.notifications(named: NSApplication.didFinishLaunchingNotification) {
        break
      }
      diagLog.log("launch finished: \(state(), privacy: .public)")
    }
    let frontmost = NSWorkspace.shared.frontmostApplication
    openWindow.showPhasesWindow()
    diagLog.log("after showPhasesWindow: \(state(), privacy: .public)")
    switch attempt {
    case 3:
      if let frontmost, frontmost != NSRunningApplication.current {
        let ok = NSRunningApplication.current.activate(from: frontmost, options: [])
        diagLog.log("activate(from: \(frontmost.bundleIdentifier ?? "?", privacy: .public)) returned \(ok)")
      }
    case 2:
      NSApp.activate(ignoringOtherApps: true)
      diagLog.log("activate(ignoringOtherApps:) called")
    default:
      break
    }
    for delay in [0.5, 2.0] {
      try? await Task.sleep(for: .seconds(delay == 0.5 ? 0.5 : 1.5))
      diagLog.log("+\(delay)s: \(state(), privacy: .public)")
    }
  }

  static func state() -> String {
    let window = NSApp.windows.first { $0.identifier?.rawValue.hasPrefix(PhasesWindow.windowID) == true }
    let windowState = window.map { "visible=\($0.isVisible) key=\($0.isKeyWindow)" } ?? "no window"
    let front = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? "?"
    return "active=\(NSApp.isActive) policy=\(NSApp.activationPolicy().rawValue) frontmost=\(front) \(windowState)"
  }
}
