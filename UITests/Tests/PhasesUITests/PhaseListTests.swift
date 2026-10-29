import PhasesUIDriver
import Testing

extension PhasesUITests {
  /// ERRATA.md "Regressions found so far": the − button and delete
  /// selection rows. Test mode reseeds Morning, Afternoon, and Evening at
  /// every launch [D-ui-test-mode].
  @Suite(.enabled(if: !PhasesUITests.isSlowRun))
  @MainActor
  struct PhaseListTests {
    /// [D-sidebar-footer-view] [Q-safe-area-inset-refresh] − started
    /// disabled and never re-enabled once a phase was selected. Adds a phase
    /// and deletes that one, leaving the fixtures alone.
    @Test func deleteRemovesANewlyAddedPhase() async throws {
      try await withPhases { app in
        try await app.click(app.element("addPhase"))
        try await waitUntil("New Phase to be added and selected") {
          (try? app.row(named: "New Phase"))??.isSelected == true
        }
        let delete = try app.element("deletePhase")
        #expect(delete.isEnabled, "Delete Phase is disabled with a phase selected")
        try await app.click(delete)
        try await waitUntil("New Phase to be deleted") {
          (try? app.row(named: "New Phase")) == .some(nil)
        }
        for name in ["Morning", "Afternoon", "Evening"] {
          #expect(try app.row(named: name) != nil, "\(name) went missing")
        }
      }
    }

    /// [D-delete-selects-next] Deleting used to select the first phase.
    @Test func deletingAMiddlePhaseSelectsTheOneBelow() async throws {
      try await withPhases { app in
        let afternoon = try #require(try app.row(named: "Afternoon"))
        try await app.click(afternoon)
        try await waitUntil("Afternoon to be selected") {
          (try? app.selectedRowText())??.contains("Afternoon") == true
        }
        try await app.click(app.element("deletePhase"))
        try await waitUntil("Afternoon to be deleted") {
          (try? app.row(named: "Afternoon")) == .some(nil)
        }
        let selected = try app.selectedRowText() ?? "nothing"
        #expect(selected.contains("Evening"), "Selected after delete: \(selected)")
      }
    }
  }
}
