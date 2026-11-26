import PhasesUIDriver
import Testing

extension PhasesUITests {
  /// The redesigned phase editor (draft 63, GitHub issue #27; TESTING.md
  /// "Phase editor tests"). Multi-display behavior is the Phase editor
  /// checks, by hand [D-editor-checks].
  @Suite(.enabled(if: !PhasesUITests.isSlowRun))
  @MainActor
  struct PhaseEditorTests {
    /// [D-name-row] The pencil starts editing with the name selected;
    /// Return saves and the sidebar follows; Escape puts the name back.
    @Test func nameEditsInPlace() async throws {
      try await withPhases { app in
        let before = try #require(try app.element("phaseName").value)

        try await clickPencil(app)
        try await waitUntil("the name field to have focus") {
          (try? app.focusedElement()?.isInside(app.element("phaseName"))) == true
        }
        try await app.press(.x)
        try await app.press(.returnKey)
        try await waitUntil("the name to be saved as “x”") {
          (try? app.element("phaseName").value) == "x"
        }
        #expect(try app.selectedRowText()?.contains("x") == true, "The sidebar row didn't follow the new name")
        #expect(try app.row(named: before) == nil, "The sidebar still shows \(before)")

        try await clickPencil(app)
        try await waitUntil("the name field to have focus again") {
          (try? app.focusedElement()?.isInside(app.element("phaseName"))) == true
        }
        try await app.press(.y)
        try await waitUntil("the name to read “y” while editing") {
          (try? app.element("phaseName").value) == "y"
        }
        try await app.press(.escape)
        try await waitUntil("Escape to put back “x”") {
          (try? app.element("phaseName").value) == "x"
        }
      }
    }

    /// [D-starts-row] The row's controls change with the trigger, and "at"
    /// hides the number.
    @Test func startsRowFollowsTheTrigger() async throws {
      try await withPhases { app in
        #expect((try? app.element("startTime")) != nil, "A clock-time phase shows no time field")

        // A clock-time phase has no offset, so Dawn starts "at" dawn, with
        // no number [D-starts-row].
        try await app.chooseMenuButtonItem("startTrigger", startingWith: "Dawn")
        try await waitUntil("the before/after/at menu to show") { (try? app.element("offsetDirection")) != nil }
        #expect((try? app.element("startTime")) == nil, "The time field stayed for a dawn phase")
        #expect((try? app.element("offsetValue")) == nil, "“at” dawn shows a number")

        try await app.chooseMenuButtonItem("offsetDirection", startingWith: "before")
        try await waitUntil("the number to come back at 30") {
          (try? app.element("offsetValue").value) == "30"
        }

        try await app.chooseMenuButtonItem("startTrigger", startingWith: "Clock Time")
        try await waitUntil("the time field to come back") { (try? app.element("startTime")) != nil }
      }
    }

    /// The pencil is hidden from accessibility on purpose (VoiceOver sees
    /// one Name field, [D-name-row]), so it's found by where it sits: 8 pt
    /// after the name field, about 20 pt wide.
    private func clickPencil(_ app: PhasesApp) async throws {
      try await app.click(rightOf: app.element("phaseName"), by: 18)
    }

    /// [D-rotation-row] "Only when the phase starts" hides the number;
    /// minutes brings it back with the same value.
    @Test func rotationTurnsOffAndBackOn() async throws {
      try await withPhases { app in
        if (try? app.element("rotationValue")) == nil {
          try await app.chooseMenuButtonItem("rotationChoice", startingWith: "minutes")
        }
        let value = try await waitFor("the rotation number", timeout: .seconds(5)) {
          try? app.element("rotationValue").value
        }

        try await app.chooseMenuButtonItem("rotationChoice", startingWith: "Only when")
        try await waitUntil("the number to hide") { (try? app.element("rotationValue")) == nil }

        try await app.chooseMenuButtonItem("rotationChoice", startingWith: "minutes")
        try await waitUntil("the number to come back as \(value)") {
          (try? app.element("rotationValue").value) == value
        }
      }
    }

    /// [D-image-header] Scrolled well down the grid, the header stays
    /// pinned at the top and the grid scrolls up under it.
    @Test func imageHeaderPinsWhileTheGridScrolls() async throws {
      try await withPhases { app in
        let header = try app.element("imageHeader")
        let grid = try app.element("imageGrid")
        let headerTop = try #require(header.frame?.minY)

        var inGrid = false
        for _ in 0..<25 {
          try await app.press(.tab)
          if app.focusedElement()?.isInside(grid) == true {
            inGrid = true
            break
          }
        }
        try #require(inGrid, "Tab never reached the image grid")
        for _ in 0..<15 { try await app.press(.downArrow) }
        try await Task.sleep(for: .milliseconds(500))

        let pinnedTop = try #require(header.frame?.minY)
        let gridTop = try #require(grid.frame?.minY)
        let windowTop = try #require(try app.window().frame?.minY)
        #expect(pinnedTop < headerTop - 50, "The header didn't move up with the settings (\(headerTop) → \(pinnedTop))")
        #expect(pinnedTop > windowTop + 40, "The header scrolled up under the toolbar (top \(pinnedTop), window \(windowTop))")
        #expect(gridTop < pinnedTop, "The grid didn't scroll up under the header (grid \(gridTop), header \(pinnedTop))")

        try await Task.sleep(for: .milliseconds(500))
        #expect(header.frame?.minY == pinnedTop, "The header moved while pinned")
      }
    }
  }
}
