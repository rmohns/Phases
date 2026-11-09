import Foundation

/// AppKit's saved window frame and sidebar layout for the Phases window.
/// They live in Phases' normal settings, which test mode's separate store
/// doesn't cover [D-ui-test-mode]: a test that collapsed the sidebar once
/// left the author's real window with no sidebar (2026-10-29).
struct SavedLayout {
  static let keys = [
    "NSWindow Frame phases",
    "NSSplitView Subview Frames phases, SidebarNavigationSplitView",
  ]

  var appID: String
  var values: [String: CFPropertyList]

  /// Records the current values, then removes them.
  static func clear(for appID: String) -> SavedLayout {
    guard !appID.isEmpty else { return SavedLayout(appID: appID, values: [:]) }
    let id = appID as CFString
    CFPreferencesAppSynchronize(id)
    var values: [String: CFPropertyList] = [:]
    for key in keys {
      if let value = CFPreferencesCopyAppValue(key as CFString, id) { values[key] = value }
      CFPreferencesSetAppValue(key as CFString, nil, id)
    }
    CFPreferencesAppSynchronize(id)
    return SavedLayout(appID: appID, values: values)
  }

  /// Puts the recorded values back, and removes keys that had none.
  func restore() {
    guard !appID.isEmpty else { return }
    let id = appID as CFString
    for key in Self.keys {
      CFPreferencesSetAppValue(key as CFString, values[key], id)
    }
    CFPreferencesAppSynchronize(id)
  }
}
