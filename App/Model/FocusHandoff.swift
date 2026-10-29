import AppKit
import os

// [D-diagnostics-switch] Off unless diagnostics are switched on at launch.
private let diagLog = Diagnostics.logger("spaces")

/// [D-close-stays-here] Hands focus to an app on the current Space before
/// Phases drops back to the menu bar, so macOS doesn't pick one on another
/// Space [Q-accessory-focus-handoff].
@MainActor
enum FocusHandoff {
  static func toCurrentSpace() {
    guard NSApp.isActive else { return }
    let info = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
      as? [[String: Any]] ?? []
    let windows = info.map { entry in
      let bounds = entry[kCGWindowBounds as String] as? [String: Double] ?? [:]
      return HandoffChoice.Window(
        ownerPID: entry[kCGWindowOwnerPID as String] as? Int32 ?? 0,
        layer: entry[kCGWindowLayer as String] as? Int ?? -1,
        alpha: entry[kCGWindowAlpha as String] as? Double ?? 0,
        width: bounds["Width"] ?? 0,
        height: bounds["Height"] ?? 0
      )
    }
    let finder = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder").first
    guard let pid = HandoffChoice.target(
      windows: windows,
      excluding: ProcessInfo.processInfo.processIdentifier,
      finderPID: finder?.processIdentifier
    ), let app = NSRunningApplication(processIdentifier: pid) else {
      diagLog.log("handoff: no target")
      return
    }
    NSApp.yieldActivation(to: app)
    let ok = app.activate(from: .current)
    diagLog.log("handoff to \(app.bundleIdentifier ?? "?", privacy: .public) ok=\(ok)")
  }
}
