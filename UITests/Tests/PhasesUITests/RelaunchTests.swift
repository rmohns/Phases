import PhasesUIDriver
import Testing

extension PhasesUITests {
  /// [D-reopen-shows-window] Launching Phases while it runs shows the
  /// window.
  @Suite(.enabled(if: !PhasesUITests.isSlowRun))
  @MainActor
  struct RelaunchTests {
    /// [Q-reopen-ignores-closed-window] With the window closed, a relaunch
    /// made Phases active and showed nothing (GitHub issue #13).
    @Test func relaunchWithTheWindowClosedShowsIt() async throws {
      try await withPhases { app in
        try await app.closeWindow()
        try await waitUntil("the Dock icon to go") { !app.hasDockIcon }
        try app.relaunch()
        try await app.waitForWindow()
        #expect(app.hasDockIcon, "The window came back without a Dock icon")
      }
    }
  }
}
