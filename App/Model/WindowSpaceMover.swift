import AppKit
import os

// [D-diagnostics-switch] Off unless diagnostics are switched on at launch.
private let diagLog = Diagnostics.logger("spaces")

/// [D-open-here] Brings the Phases window to the current Space when it's
/// opened from the menu bar, instead of letting activation switch Spaces
/// [Q-activate-switches-space]. Workaround: ERRATA.md "Open here".
@MainActor
enum WindowSpaceMover {
  /// If the window is open on another Space, moves it to the current one.
  /// Call before activating, so activation has no other Space to go to.
  static func moveToActiveSpace(windowID: String) {
    guard let window = NSApp.windows.first(where: {
      $0.identifier?.rawValue.hasPrefix(windowID) == true
    }) else {
      diagLog.log("no window yet")
      return
    }
    diagLog.log("window \(window.identifier?.rawValue ?? "", privacy: .public) visible=\(window.isVisible) onActiveSpace=\(window.isOnActiveSpace) minimized=\(window.isMiniaturized)")
    guard window.isVisible, !window.isOnActiveSpace, !window.isMiniaturized else { return }
    // On only while the window is ordered front, so the Dock and ⌘Tab still
    // follow the user's Mission Control setting.
    window.collectionBehavior.insert(.moveToActiveSpace)
    window.orderFront(nil)
    window.collectionBehavior.remove(.moveToActiveSpace)
    diagLog.log("moved; onActiveSpace=\(window.isOnActiveSpace)")
  }
}
