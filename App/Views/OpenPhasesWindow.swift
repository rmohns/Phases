import SwiftUI

extension OpenWindowAction {
  /// Shows the Phases window: "Open Phases…", Settings…, and a relaunch
  /// while running all come through here [D-reopen-shows-window].
  @MainActor
  func showPhasesWindow() {
    // [D-open-here] [Q-activate-switches-space] Come to this Space rather
    // than switching to the window's.
    WindowSpaceMover.moveOnNextActivation(windowID: PhasesWindow.windowID)
    // [D-dock-while-open] [Q-regular-activation-menubar] Regular before
    // activating, so the menu bar comes with the window.
    DockPresence.show()
    self(id: PhasesWindow.windowID)
    NSApp.activate()
  }
}
