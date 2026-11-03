import AppKit
import SwiftUI
import os

// EXPERIMENT (branch experiment/reopen-window, issue #13). Not for main.
// [D-diagnostics-switch] Logs under category "reopen".
private let diagLog = Diagnostics.logger("reopen")

/// Which reopen handling to try, read at launch from
/// `defaults write <bundle id> PhasesReopenMode <mode>`:
/// - `none` (default): log only, let AppKit and SwiftUI do what they do.
/// - `label`: the menu bar icon's view opens the window, the way
///   "Open Phases…" does.
enum ReopenMode: String {
  case none, label

  static let current = ReopenMode(
    rawValue: UserDefaults.standard.string(forKey: "PhasesReopenMode") ?? ""
  ) ?? .none
}

extension Notification.Name {
  static let phasesReopenRequested = Notification.Name("PhasesReopenRequested")
}

final class ReopenExperimentDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ notification: Notification) {
    diagLog.log("launched; mode=\(ReopenMode.current.rawValue, privacy: .public)")
  }

  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    MainActor.assumeIsolated {
      diagLog.log("reopen; hasVisibleWindows=\(flag) \(Self.state(), privacy: .public)")
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        diagLog.log("reopen +0.5s: \(Self.state(), privacy: .public)")
      }
      switch ReopenMode.current {
      case .none:
        return true
      case .label:
        NotificationCenter.default.post(name: .phasesReopenRequested, object: nil)
        return false
      }
    }
  }

  func applicationDidBecomeActive(_ notification: Notification) {
    MainActor.assumeIsolated {
      diagLog.log("became active: \(Self.state(), privacy: .public)")
    }
  }

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

/// The menu bar icon, plus the experiment's listener: in `label` mode it
/// opens the window the way "Open Phases…" does.
struct ReopenExperimentLabel: View {
  var image: NSImage
  @Environment(\.openWindow) private var openWindow

  var body: some View {
    Image(nsImage: image)
      .accessibilityLabel("Phases")
      .onReceive(NotificationCenter.default.publisher(for: .phasesReopenRequested)) { _ in
        diagLog.log("label got reopen request; opening")
        WindowSpaceMover.moveOnNextActivation(windowID: PhasesWindow.windowID)
        DockPresence.show()
        openWindow(id: PhasesWindow.windowID)
        NSApp.activate()
      }
  }
}
