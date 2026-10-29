import PhasesUIDriver
import Testing

extension PhasesUITests {
  /// ERRATA.md "Regressions found so far": the sidebar collapse and width
  /// limit rows.
  @Suite(.enabled(if: !PhasesUITests.isSlowRun))
  @MainActor
  struct SidebarTests {
    /// [D-sidebar-always-visible] [Q-sidebar-collapse] Dragging past the
    /// minimum used to collapse the sidebar with no way back.
    @Test func dividerDraggedFarLeftKeepsSidebarOpen() async throws {
      try await withPhases { app in
        try await app.dragDivider(toWindowX: 20)
        let width = try app.sidebarWidth()
        #expect(width >= 239, "Sidebar shrank to \(width) pt; minimum is 240")
      }
    }

    /// [D-window-helper-order] [D-sidebar-limits-watch] Limits right after
    /// opening. The slow suite checks them again after SwiftUI's rewrite.
    @Test func dividerStaysWithin240To320() async throws {
      try await withPhases { app in
        try await expectSidebarLimitsHold(app)
      }
    }
  }

  /// [D-sidebar-limits-watch] [Q-split-item-rewrite] SwiftUI rewrote the
  /// limits 1.5–28 s after the window opened, so wait past that, on several
  /// launches: the bug was intermittent.
  @Suite(.enabled(if: PhasesUITests.isSlowRun, "Set PHASES_UI_SLOW=1 to run"))
  @MainActor
  struct SlowSidebarTests {
    @Test(arguments: 1...3)
    func limitsHoldAfterSwiftUIRewrite(launch: Int) async throws {
      try await withPhases { app in
        try await Task.sleep(for: .seconds(30))
        try await expectSidebarLimitsHold(app)
      }
    }
  }
}
