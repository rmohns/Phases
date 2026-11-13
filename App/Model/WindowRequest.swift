import Foundation

// [D-diagnostics-switch] Off unless diagnostics are switched on at launch.
private let diagLog = Diagnostics.logger("reopen")

extension Notification.Name {
  /// Something outside the menu asked for the window; the menu bar icon's
  /// view opens it [D-reopen-shows-window]. The object is the
  /// `WindowRequest.Source`.
  static let showPhasesWindowRequested = Notification.Name("ShowPhasesWindowRequested")
}

/// Requests for the window from outside SwiftUI: a relaunch while running
/// [D-reopen-shows-window] and a click on the pause notification
/// [D-notice-opens-window]. Only a view can open a SwiftUI window, so these
/// go to the menu bar icon's view, the one view that's always alive. A
/// request that arrives before that view does (a click on the notification
/// that launched Phases) waits for it.
@MainActor
enum WindowRequest {
  enum Source: String {
    case relaunch, notification
  }

  private static var labelIsListening = false
  private static var pending = false

  static func send(from source: Source) {
    diagLog.log("window requested by \(source.rawValue, privacy: .public); labelIsListening=\(labelIsListening)")
    if labelIsListening {
      NotificationCenter.default.post(name: .showPhasesWindowRequested, object: source)
    } else {
      pending = true
    }
  }

  /// Called once by the menu bar icon's view when it appears. Returns
  /// whether a request came in before it.
  static func labelAppeared() -> Bool {
    labelIsListening = true
    defer { pending = false }
    return pending
  }
}
