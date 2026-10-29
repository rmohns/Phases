import AppKit
import os

// [D-diagnostics-switch] Off unless diagnostics are switched on at launch.
private let diagLog = Diagnostics.logger("spaces")

/// [D-open-here] Brings the Phases window to the current Space when it's
/// opened from the menu bar, instead of letting activation switch Spaces
/// [Q-activate-switches-space]. Workaround: ERRATA.md "Open here".
@MainActor
enum WindowSpaceMover {
  /// If the window, open or closed, belongs to another Space, lets the coming activation
  /// bring it here instead of switching Spaces. Call just before activating.
  static func moveOnNextActivation(windowID: String) {
    guard let window = NSApp.windows.first(where: {
      $0.identifier?.rawValue.hasPrefix(windowID) == true
    }) else {
      diagLog.log("no window yet")
      return
    }
    diagLog.log("window \(window.identifier?.rawValue ?? "", privacy: .public) visible=\(window.isVisible) onActiveSpace=\(window.isOnActiveSpace) minimized=\(window.isMiniaturized)")
    // Closed windows count too: SwiftUI keeps them, and they come back on
    // their old Space [Q-closed-window-keeps-space].
    guard !window.isOnActiveSpace, !window.isMiniaturized else { return }
    window.collectionBehavior.insert(.moveToActiveSpace)
    // macOS moves the window after activation finishes, so the flag stays on
    // until the window shows up here. Off again then (or if Phases loses
    // focus first), so the Dock and ⌘Tab still follow the user's Mission
    // Control setting.
    var observers: [NSObjectProtocol] = []
    func finish(_ reason: String) {
      window.collectionBehavior.remove(.moveToActiveSpace)
      observers.forEach(NotificationCenter.default.removeObserver)
      observers = []
      diagLog.log("flag off (\(reason, privacy: .public)); onActiveSpace=\(window.isOnActiveSpace)")
    }
    observers.append(NotificationCenter.default.addObserver(
      forName: NSWindow.didChangeOcclusionStateNotification, object: window, queue: .main
    ) { _ in
      MainActor.assumeIsolated {
        if window.isOnActiveSpace && window.occlusionState.contains(.visible) { finish("arrived") }
      }
    })
    observers.append(NotificationCenter.default.addObserver(
      forName: NSApplication.didResignActiveNotification, object: nil, queue: .main
    ) { _ in
      MainActor.assumeIsolated { finish("resigned active") }
    })
  }
}
