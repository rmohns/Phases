import Foundation
import PhasesUIDriver
import Testing

/// All UI tests, one at a time: they share the screen, the mouse, and the
/// keyboard [D-ui-test-runner]. `swift test` runs the fast suites;
/// `PHASES_UI_SLOW=1 swift test` runs only the slow one.
@Suite(.serialized)
@MainActor
struct PhasesUITests {
  nonisolated static let isSlowRun = ProcessInfo.processInfo.environment["PHASES_UI_SLOW"] == "1"
}

/// Launches a test-mode Phases [D-ui-test-mode], runs `body`, and always
/// quits it.
@MainActor
func withPhases(_ body: @MainActor (PhasesApp) async throws -> Void) async throws {
  let app = try await PhasesApp.launch()
  defer { app.quit() }
  try await body(app)
}

/// Drags the divider far both ways; the sidebar stays 240–320 pt
/// [D-sidebar-width] [D-sidebar-always-visible] [D-sidebar-limits-watch].
///
/// Switches the detail pane first: the limits escaped only after the
/// window had been used (hand check, 2026-10-29), and switching between
/// Settings and a phase is the suspected trigger for SwiftUI's rewrite
/// `[Q-split-item-rewrite]` (a guess).
@MainActor
func expectSidebarLimitsHold(_ app: PhasesApp) async throws {
  for name in ["Settings", "Afternoon", "Settings", "Morning"] {
    try await app.click(try #require(try app.row(named: name), "No \(name) row"))
    try await Task.sleep(for: .milliseconds(600))
  }
  try await Task.sleep(for: .seconds(2))
  try await app.dragDivider(toWindowX: 20)
  let narrow = try app.sidebarWidth()
  try await app.dragDivider(toWindowX: 700)
  let wide = try app.sidebarWidth()
  try await app.dragDivider(toWindowX: 20)
  let narrowAgain = try app.sidebarWidth()
  #expect((239...241).contains(narrow), "Dragged far left: sidebar is \(narrow) pt, expected 240")
  #expect((319...321).contains(wide), "Dragged far right: sidebar is \(wide) pt, expected 320")
  #expect((239...241).contains(narrowAgain), "Dragged back left: sidebar is \(narrowAgain) pt, expected 240")
}
