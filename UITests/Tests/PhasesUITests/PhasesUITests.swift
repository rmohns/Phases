import AppKit
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
/// quits it. `imageFolders` are its image sources, in order. `photosLibrary`
/// is a fake Photos library [D-fake-photos], and `photosDenied` makes it
/// refuse access; without a library, test mode has no Photos at all.
/// `windowSize` opens the window at that size instead of the default.
@MainActor
func withPhases(
  imageFolders: [URL] = [TestImages.folder], photosLibrary: URL? = nil, photosDenied: Bool = false,
  windowSize: CGSize? = nil,
  _ body: @MainActor (PhasesApp) async throws -> Void
) async throws {
  let app = try await PhasesApp.launch(
    imageFolders: imageFolders, windowSize: windowSize,
    photosLibrary: photosLibrary, photosDenied: photosDenied
  )
  defer { app.quit() }
  try await body(app)
}

/// The window size for `expectSidebarLimitsHold` (GitHub issue #49). The
/// sidebar can only reach its 320 pt maximum if the detail pane keeps its
/// 460 pt minimum beside it [D-sidebar-width] [D-window-min-size], so the
/// window needs at least 780 pt; at the 700 pt minimum the divider can't
/// move right at all. Aims for 1000 pt, narrower on a narrow screen (a
/// portrait monitor, say), and throws if the screen can't fit 780.
/// `SavedLayout.setWindowSize` puts the window 100 pt in from the left of
/// the main screen's visible frame, so that much is taken off.
@MainActor
func sidebarLimitsWindowSize() throws -> CGSize {
  let needed: CGFloat = 780
  let preferred: CGFloat = 1000
  guard let screen = NSScreen.main?.visibleFrame else {
    throw UITestFailure("No main screen to size the window for.")
  }
  let room = screen.width - 100
  guard room >= needed else {
    throw UITestFailure(
      "The active screen is \(Int(screen.width)) pt wide; the sidebar limits test needs room for a \(Int(needed)) pt window (\(Int(needed) + 100) pt of screen). Move focus to a wider screen."
    )
  }
  return CGSize(width: min(preferred, room), height: 680)
}

/// Drags the divider far both ways; the sidebar stays 240–320 pt
/// [D-sidebar-width] [D-sidebar-always-visible] [D-sidebar-limits-watch].
/// Launch with `windowSize: sidebarLimitsWindowSize()`: in a narrower
/// window the sidebar can't widen to 320 (issue #49).
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
