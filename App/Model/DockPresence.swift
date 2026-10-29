import AppKit

/// [D-dock-while-open] A Dock icon and a place in ⌘Tab only while the Phases
/// window is open. Phases launches as an accessory (`LSUIElement`).
@MainActor
enum DockPresence {
  /// Becomes a regular app. Call before activating, so the menu bar comes
  /// with the window [Q-regular-activation-menubar].
  static func show() {
    guard NSApp.activationPolicy() != .regular else { return }
    NSApp.setActivationPolicy(.regular)
  }

  /// Back to a menu bar accessory. Only when the window closes, never on
  /// minimize, so a minimized window stays reachable from the Dock.
  static func hide() {
    guard NSApp.activationPolicy() != .accessory else { return }
    NSApp.setActivationPolicy(.accessory)
  }
}
