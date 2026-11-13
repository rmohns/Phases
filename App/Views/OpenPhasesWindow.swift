import SwiftUI

extension OpenWindowAction {
  /// Shows the Phases window: "Open Phases…", Settings…, a relaunch while
  /// running, and a click on the pause notification all come through here
  /// [D-reopen-shows-window] [D-notice-opens-window].
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
