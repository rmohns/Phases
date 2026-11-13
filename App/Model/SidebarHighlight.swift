/// [D-active-badge] Whether a sidebar row has the colored selection highlight,
/// rather than the grey one or none. SwiftUI doesn't tell the row
/// [Q-tint-on-highlight], so the row works it out from state Phases owns.
enum SidebarHighlight {
  static func isColored(isSelected: Bool, windowInFront: Bool, sidebarFocused: Bool) -> Bool {
    isSelected && windowInFront && sidebarFocused
  }
}
