import Foundation
import PhasesUIDriver
import Testing

extension PhasesUITests {
  /// [D-window-pause-banner] The pause banner shows while paused, under the
  /// toolbar, and goes away on resume.
  @Suite(.enabled(if: !PhasesUITests.isSlowRun))
  @MainActor
  struct PauseBannerTests {
    /// [D-tall-toolbar] Below this, content sits under the toolbar.
    static let toolbarHeight: CGFloat = 52

    /// Opening the window for the first time while paused drew everything
    /// shifted up under the toolbar: the branding panel under the traffic
    /// lights, the banner under the title (found by the author,
    /// 2026-11-07, on draft 49's first build).
    @Test func windowOpenedWhilePausedStartsBelowTheToolbar() async throws {
      let app = try await PhasesApp.launch(opensWindow: false)
      defer { app.quit() }
      try await app.chooseMenuItem("Pause Schedule")
      try await app.reopenWindow()
      let resume = try await waitFor("the pause banner") { try? app.element("pauseBannerResume") }
      try expectBelowToolbar(resume, "The banner's Resume Schedule button", app: app)
      let panel = try #require(try app.sidebarRows().first, "No sidebar rows")
      try expectBelowToolbar(panel, "The branding panel", app: app)
    }

    /// Opening the window while paused by a System Settings change, at a
    /// size where the reason wraps to two lines: the split view laid out
    /// taller than the window and was centered, so its top ran above the
    /// window (LEARNINGS.md `[L-pause-banner-rigid-split]`, 2026-11-07).
    /// A menu pause's one-line reason never did it; nor did the default
    /// 960 pt window, where the reason may fit on one line.
    @Test func windowOpenedWhilePausedByOutsideChangeStartsBelowTheToolbar() async throws {
      // [D-window-min-size] The minimum width: the editor at 460 pt, where
      // the reason wraps.
      let app = try await PhasesApp.launch(
        opensWindow: false, pausedByOutsideChange: true, windowSize: CGSize(width: 700, height: 600)
      )
      defer { app.quit() }
      try await app.reopenWindow()
      let resume = try await waitFor("the pause banner") { try? app.element("pauseBannerResume") }
      // Let the first layout passes settle; the shift lands after them.
      try await Task.sleep(for: .seconds(1))
      try expectBelowToolbar(resume, "The banner's Resume Schedule button", app: app)
      let panel = try #require(try app.sidebarRows().first, "No sidebar rows")
      try expectBelowToolbar(panel, "The branding panel", app: app)
    }

    /// Toggling from the menu with the window open: after about a dozen
    /// toggles the banner stopped appearing (found by the author,
    /// 2026-11-07, on draft 49's first build).
    @Test func bannerFollowsTwentyToggles() async throws {
      try await withPhases { app in
        for round in 1...10 {
          try await app.chooseMenuItem("Pause Schedule")
          let resume = try await waitFor("the pause banner, round \(round)", timeout: .seconds(3)) {
            try? app.element("pauseBannerResume")
          }
          try expectBelowToolbar(resume, "Round \(round): the banner's Resume Schedule button", app: app)
          try await app.chooseMenuItem("Resume Schedule")
          try await waitUntil("the pause banner to go, round \(round)", timeout: .seconds(3)) {
            (try? app.element("pauseBannerResume")) == nil
          }
        }
        let panel = try #require(try app.sidebarRows().first, "No sidebar rows")
        try expectBelowToolbar(panel, "After the toggles, the branding panel", app: app)
      }
    }

    private func expectBelowToolbar(_ node: AXNode, _ what: String, app: PhasesApp) throws {
      let top = try #require(try app.window().frame?.minY)
      let nodeTop = try #require(node.frame?.minY, "\(what) has no frame")
      #expect(nodeTop - top >= Self.toolbarHeight, "\(what) starts \(nodeTop - top) pt below the window's top, inside the \(Self.toolbarHeight) pt toolbar")
    }
  }
}
