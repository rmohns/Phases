import AppKit
import SwiftUI

/// [D-first-launch-shows-window] Opens the window on the first launch and
/// brings it to the front. macOS refuses `NSApp.activate()` here, even
/// after the launch has finished, so Phases takes activation from the app
/// that was frontmost when it launched [Q-launch-activate-refused]. A click
/// on the pause notification comes here too, since it may have launched
/// Phases [D-notice-opens-window].
@MainActor
enum FirstLaunchWindow {
  /// Set by the app delegate when AppKit finishes launching. The menu bar
  /// icon's view appears just before that.
  static var launchFinished = false {
    didSet {
      guard launchFinished else { return }
      waiter?.resume()
      waiter = nil
    }
  }

  private static var waiter: CheckedContinuation<Void, Never>?

  static func open(_ openWindow: OpenWindowAction) async {
    if !launchFinished {
      await withCheckedContinuation { waiter = $0 }
    }
    let launcher = NSWorkspace.shared.frontmostApplication
    openWindow.showPhasesWindow()
    if let launcher, launcher != NSRunningApplication.current {
      NSRunningApplication.current.activate(from: launcher)
    }
  }
}
