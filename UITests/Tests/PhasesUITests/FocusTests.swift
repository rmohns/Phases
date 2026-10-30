import PhasesUIDriver
import Testing

extension PhasesUITests {
  /// ERRATA.md "Regressions found so far": the initial focus and grid Tab
  /// rows.
  @Suite(.enabled(if: !PhasesUITests.isSlowRun))
  @MainActor
  struct FocusTests {
    /// [D-initial-focus-sidebar] [Q-default-focus-loses] The Name field had
    /// focus with its text selected on open, so any key renamed the phase.
    @Test func typingRightAfterOpenDoesNotRenameThePhase() async throws {
      try await withPhases { app in
        let name = try app.element("phaseName")
        let before = try #require(name.value)
        print("Focused on open: \(app.focusedElement()?.summary ?? "nothing")")
        if let focused = app.focusedElement() {
          #expect(!focused.isInside(name), "The Name field has focus on open")
        }
        try await app.press(.x)
        try await Task.sleep(for: .milliseconds(500))
        #expect(name.value == before, "Typing renamed \(before) to \(name.value ?? "nil")")
      }
    }

    /// [D-initial-focus-sidebar] Closing only hides the window, and it kept
    /// whatever had focus: leave the cursor in the Name field, close,
    /// reopen, and a keypress renamed the phase (hand check, 2026-10-29).
    /// The first-open case can't be driven: Phases is never active when
    /// a test opens its window (see TESTING.md "Layer 2: UI tests").
    @Test func typingAfterReopeningDoesNotRenameThePhase() async throws {
      try await withPhases { app in
        try await app.click(app.element("phaseName"))
        try await waitUntil("the Name field to have focus") {
          (try? app.focusedElement()?.isInside(app.element("phaseName"))) == true
        }
        try await app.closeWindow()
        try await app.reopenWindow()
        let name = try app.element("phaseName")
        let before = try #require(name.value)
        print("Focused on reopen: \(app.focusedElement()?.summary ?? "nothing")")
        try await app.press(.x)
        try await Task.sleep(for: .milliseconds(500))
        #expect(try app.element("phaseName").value == before, "Typing after reopening renamed \(before)")
      }
    }

    /// [D-grid-release-on-close] [D-initial-focus-sidebar] Closed for 2 s,
    /// the window drops its editor pane, so reopening builds a new one; a
    /// new editor must not take focus either [Q-default-focus-loses]. The
    /// test above reopens at once, before the pane is dropped.
    @Test func typingAfterReopeningPastTheReleaseDoesNotRenameThePhase() async throws {
      try await withPhases { app in
        try await app.click(app.element("phaseName"))
        try await waitUntil("the Name field to have focus") {
          (try? app.focusedElement()?.isInside(app.element("phaseName"))) == true
        }
        try await app.closeWindow()
        try await Task.sleep(for: .seconds(2))
        try await app.reopenWindow()
        let name = try app.element("phaseName")
        let before = try #require(name.value)
        print("Focused on reopen after 2 s: \(app.focusedElement()?.summary ?? "nothing")")
        try await app.press(.x)
        try await Task.sleep(for: .milliseconds(500))
        #expect(try app.element("phaseName").value == before, "Typing after reopening renamed \(before)")
      }
    }

    /// [D-grid-one-tab-stop] [Q-lazy-grid-tab] Tab used to visit only the
    /// on-screen thumbnails, then jump away, and never scrolled.
    @Test func gridIsOneTabStopAndArrowsScroll() async throws {
      try await withPhases { app in
        let grid = try app.element("imageGrid")
        var inGrid = false
        for _ in 0..<25 {
          try await app.press(.tab)
          if app.focusedElement()?.isInside(grid) == true {
            inGrid = true
            break
          }
        }
        try #require(inGrid, "Tab never reached the image grid")

        try await app.press(.tab)
        #expect(app.focusedElement()?.isInside(grid) != true, "One Tab didn't leave the grid")

        try await app.press(.tab, shift: true)
        try #require(app.focusedElement()?.isInside(grid) == true, "Shift-Tab didn't return to the grid")

        let top = try #require(grid.frame?.minY)
        for _ in 0..<15 { try await app.press(.downArrow) }
        try await Task.sleep(for: .milliseconds(500))
        let scrolledTop = try #require(grid.frame?.minY)
        #expect(scrolledTop < top - 50, "Arrowing down didn't scroll (grid top \(top) → \(scrolledTop))")
      }
    }
  }
}
