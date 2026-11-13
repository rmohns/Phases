import Testing
@testable import PhasesLogic

/// When a row has the colored highlight, so "Active" switches to the row's
/// text color `[D-active-badge]`.
struct SidebarHighlightTests {
  @Test func coloredOnlyWhenSelectedInFrontAndFocused() {
    #expect(SidebarHighlight.isColored(isSelected: true, windowInFront: true, sidebarFocused: true))
  }

  /// Each case seen grey (or unselected) on the experiment build.
  @Test func greyOrNoneOtherwise() {
    #expect(!SidebarHighlight.isColored(isSelected: false, windowInFront: true, sidebarFocused: true))
    #expect(!SidebarHighlight.isColored(isSelected: true, windowInFront: true, sidebarFocused: false))
    #expect(!SidebarHighlight.isColored(isSelected: true, windowInFront: false, sidebarFocused: true))
  }
}
