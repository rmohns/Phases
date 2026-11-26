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
    /// From draft 61 only an outside change shows the banner, so the pause
    /// is faked [D-test-outside-change-now] before the window first opens.
    @Test func windowOpenedWhilePausedStartsBelowTheToolbar() async throws {
      let app = try await PhasesApp.launch(opensWindow: false)
      defer { app.quit() }
      // Right after launch Phases may not be listening yet (a single post
      // was lost, 2026-11-24), so post until the menu bar icon says paused
      // [D-menubar-icon-paused], before the window first opens.
      // The item's label is its AX title, "Phases, paused" (the
      // description is empty; checked 2026-11-24).
      try await waitUntil("the faked outside-change pause", timeout: .seconds(10)) {
        let label = app.app.node("AXExtrasMenuBar")?.children.first?.title ?? ""
        if label.contains("paused") { return true }
        app.fakeOutsideChange()
        return false
      }
      try await app.reopenWindow()
      let resume = try await waitFor("the pause banner") { try? app.element("pauseBannerResume") }
      try expectBelowToolbar(resume, "The banner's Resume Wallpaper Changes button", app: app)
      let panel = try #require(try app.sidebarRows().first, "No sidebar rows")
      try expectBelowToolbar(panel, "The branding panel", app: app)
    }

    /// Opening the window while paused by a System Settings change, at a
    /// size where the reason wraps to two lines: the split view laid out
    /// taller than the window and was centered, so its top ran above the
    /// window (EXPERIMENTS.md `[L-pause-banner-rigid-split]`, 2026-11-07).
    /// A menu pause's one-line reason never did it; nor did the default
    /// 960 pt window, where the reason may fit on one line.
    @Test func windowOpenedWhilePausedByOutsideChangeStartsBelowTheToolbar() async throws {
      // [D-window-min-size] The minimum width: the editor at 550 pt (460
      // through draft 62, at 700 pt), where the reason wraps.
      let app = try await PhasesApp.launch(
        opensWindow: false, pausedByOutsideChange: true, windowSize: CGSize(width: 790, height: 600)
      )
      defer { app.quit() }
      try await app.reopenWindow()
      let resume = try await waitFor("the pause banner") { try? app.element("pauseBannerResume") }
      // Let the first layout passes settle; the shift lands after them.
      try await Task.sleep(for: .seconds(1))
      try expectBelowToolbar(resume, "The banner's Resume Wallpaper Changes button", app: app)
      let panel = try #require(try app.sidebarRows().first, "No sidebar rows")
      try expectBelowToolbar(panel, "The branding panel", app: app)
    }

    /// Pausing and resuming with the window open: after about a dozen
    /// toggles the banner stopped appearing (found by the author,
    /// 2026-11-07, on draft 49's first build). From draft 61 only an
    /// outside change shows the banner, so each pause is faked
    /// [D-test-outside-change-now]; resume alternates between the banner's
    /// button and the menu.
    @Test func bannerFollowsTwentyToggles() async throws {
      try await withPhases { app in
        for round in 1...10 {
          app.fakeOutsideChange()
          let resume = try await waitFor("the pause banner, round \(round)", timeout: .seconds(3)) {
            try? app.element("pauseBannerResume")
          }
          try expectBelowToolbar(resume, "Round \(round): the banner's Resume Wallpaper Changes button", app: app)
          if round.isMultiple(of: 2) {
            try await app.click(resume)
          } else {
            try await app.chooseMenuItem("Resume Wallpaper Changes")
          }
          try await waitUntil("the pause banner to go, round \(round)", timeout: .seconds(3)) {
            (try? app.element("pauseBannerResume")) == nil
          }
        }
        let panel = try #require(try app.sidebarRows().first, "No sidebar rows")
        try expectBelowToolbar(panel, "After the toggles, the branding panel", app: app)
      }
    }

    /// [D-window-pause-banner] A pause someone chose shows no banner, from
    /// the menu or the Settings switch. [D-pause-switch-disabled] The
    /// switch is enabled then, and disabled while an outside change's
    /// banner shows; resuming from the banner enables it again. The
    /// outside change lands while the switch's own pause is still on, so
    /// it also covers a manual pause turning into an outside-change one.
    @Test func manualPauseShowsNoBannerAndOutsideChangeDisablesTheSwitch() async throws {
      try await withPhases { app in
        try await app.click(try #require(try app.row(named: "Settings")))
        let pauseSwitch = try await waitFor("the pause switch") { try? app.element("pauseSwitch") }

        try await app.chooseMenuItem("Pause Wallpaper Changes")
        try await Task.sleep(for: .seconds(1))
        #expect((try? app.element("pauseBannerResume")) == nil, "A pause from the menu showed the banner")
        #expect(pauseSwitch.isEnabled, "The switch is disabled after a pause from the menu")
        try await app.chooseMenuItem("Resume Wallpaper Changes")

        try await app.click(pauseSwitch)
        try await Task.sleep(for: .seconds(1))
        #expect((try? app.element("pauseBannerResume")) == nil, "A pause from the Settings switch showed the banner")
        #expect(pauseSwitch.isEnabled, "The switch is disabled after a pause from itself")

        app.fakeOutsideChange()
        let resume = try await waitFor("the pause banner", timeout: .seconds(3)) {
          try? app.element("pauseBannerResume")
        }
        try await waitUntil("the switch to be disabled", timeout: .seconds(3)) { !pauseSwitch.isEnabled }
        try await app.click(resume)
        try await waitUntil("the pause banner to go", timeout: .seconds(3)) {
          (try? app.element("pauseBannerResume")) == nil
        }
        try await waitUntil("the switch to be enabled again", timeout: .seconds(3)) { pauseSwitch.isEnabled }
      }
    }

    private func expectBelowToolbar(_ node: AXNode, _ what: String, app: PhasesApp) throws {
      let top = try #require(try app.window().frame?.minY)
      let nodeTop = try #require(node.frame?.minY, "\(what) has no frame")
      #expect(nodeTop - top >= Self.toolbarHeight, "\(what) starts \(nodeTop - top) pt below the window's top, inside the \(Self.toolbarHeight) pt toolbar")
    }
  }
}
