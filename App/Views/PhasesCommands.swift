import SwiftUI

/// [D-app-menu] The menu bar shown while the Phases window is open, trimmed
/// to what applies. Quit, Hide, About, File › Close, Edit, and Window come
/// from SwiftUI's defaults.
struct PhasesCommands: Commands {
  var scheduler: WallpaperScheduler
  @FocusedValue(\.sidebarSelection) private var selection
  @Environment(\.openWindow) private var openWindow
  @Environment(\.dismissWindow) private var dismissWindow

  var body: some Commands {
    // [D-quit-confirm] Only this menu item asks; logout and shutdown don't.
    CommandGroup(replacing: .appTermination) {
      Button("Quit Phases") {
        switch QuitConfirmation.ask(scheduler: scheduler) {
        case .quit: NSApp.terminate(nil)
        case .keepInMenuBar: dismissWindow(id: PhasesWindow.windowID)
        case .cancel: break
        }
      }
      .keyboardShortcut("q")
    }
    // [D-one-window] Settings is a sidebar item, not its own window.
    CommandGroup(replacing: .appSettings) {
      Button("Settings…") {
        openWindow(id: PhasesWindow.windowID)
        selection?.wrappedValue = .settings
      }
      .keyboardShortcut(",")
    }
    // [D-sidebar-always-visible] No Show/Hide Sidebar; with the toolbar
    // items gone too, nothing is left for the View menu, but macOS keeps it
    // for Enter Full Screen [Q-view-menu-fullscreen]; MainMenuTrimmer removes it.
    CommandGroup(replacing: .sidebar) {}
    CommandGroup(replacing: .toolbar) {}
    // No help book, so no "Phases Help".
    CommandGroup(replacing: .help) {}
  }
}

extension FocusedValues {
  /// The Phases window's sidebar selection, for Settings… in the app menu.
  @Entry var sidebarSelection: Binding<SidebarItem?>?
}
