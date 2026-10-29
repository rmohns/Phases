import SwiftUI

/// [D-app-menu] The menu bar shown while the Phases window is open, trimmed
/// to what applies. Quit, Hide, About, File › Close, Edit, and Window come
/// from SwiftUI's defaults.
struct PhasesCommands: Commands {
  @FocusedValue(\.sidebarSelection) private var selection
  @Environment(\.openWindow) private var openWindow

  var body: some Commands {
    // [D-one-window] Settings is a sidebar item, not its own window.
    CommandGroup(replacing: .appSettings) {
      Button("Settings…") {
        openWindow(id: PhasesWindow.windowID)
        selection?.wrappedValue = .settings
      }
      .keyboardShortcut(",")
    }
    // [D-sidebar-always-visible] No Show/Hide Sidebar; with the toolbar
    // items gone too, nothing is left for the View menu.
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
