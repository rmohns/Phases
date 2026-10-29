import AppKit
import os

// [D-diagnostics-switch] Off unless diagnostics are switched on at launch.
private let diagLog = Diagnostics.logger("spaces")

/// [D-open-here] Brings the Phases window to the current Space when it's
/// opened from the menu bar, instead of letting activation switch Spaces
/// [Q-activate-switches-space]. Workaround: ERRATA.md "Open here".
@MainActor
enum WindowSpaceMover {
  /// If the window is open on another Space, lets the coming activation
  /// bring it here. Call just before activating.
  static func moveOnNextActivation(windowID: String) {
    guard let window = NSApp.windows.first(where: {
      $0.identifier?.rawValue.hasPrefix(windowID) == true
    }) else {
      diagLog.log("no window yet")
      return
    }
    diagLog.log("window \(window.identifier?.rawValue ?? "", privacy: .public) visible=\(window.isVisible) onActiveSpace=\(window.isOnActiveSpace) minimized=\(window.isMiniaturized)")
    guard window.isVisible, !window.isOnActiveSpace, !window.isMiniaturized else { return }
    window.collectionBehavior.insert(.moveToActiveSpace)
    // Off again once activation is done, so the Dock and ⌘Tab still follow
    // the user's Mission Control setting.
    var observer: NSObjectProtocol?
    observer = NotificationCenter.default.addObserver(
      forName: NSApplication.didBecomeActiveNotification, object: nil, queue: .main
    ) { _ in
      MainActor.assumeIsolated {
        window.collectionBehavior.remove(.moveToActiveSpace)
        diagLog.log("activated; onActiveSpace=\(window.isOnActiveSpace)")
        if let observer { NotificationCenter.default.removeObserver(observer) }
      }
    }
  }
}
