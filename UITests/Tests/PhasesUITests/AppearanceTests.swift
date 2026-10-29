import PhasesUIDriver
import Testing

extension PhasesUITests {
  /// ERRATA.md "Regressions found so far": visual-only rows. Geometry is
  /// checked; what can only be seen is saved as screenshots for review.
  @Suite(.enabled(if: !PhasesUITests.isSlowRun))
  @MainActor
  struct AppearanceTests {
    /// [D-tall-toolbar] [Q-empty-toolbar-66pt] [Q-no-items-no-toolbar] The
    /// title bar went short, then 66 pt; it should be 52 pt. AX shows no
    /// toolbar element, so this measures a stand-in: the window title's
    /// text, which starts at the window's top and spans the toolbar's
    /// height (52 pt, matching AppKit's measure, 2026-10-29).
    @Test func toolbarIs52PointsTall() async throws {
      try await withPhases { app in
        let window = try app.window()
        let top = try #require(window.frame?.minY)
        let title = try #require(
          window.children.first { $0.role == "AXStaticText" && abs(($0.frame?.minY ?? -99) - top) <= 1 },
          "No title text at the window's top; window has: \(window.children.map(\.summary))"
        )
        let height = try #require(title.frame?.height)
        #expect((51...53).contains(height), "Toolbar is \(height) pt, expected 52")
      }
    }

    /// [D-brand-layout] The tagline was cut off after its first line.
    /// Screenshot only: the panel's AX label is fixed text.
    @Test func brandingPanelScreenshot() async throws {
      try await withPhases { app in
        let url = try app.screenshot("branding tagline")
        print("Review: \(url.path(percentEncoded: false))")
      }
    }

    /// Long folder names were truncated badly; they should truncate in the
    /// middle. AX reports the full name; the look needs the screenshot. A
    /// long name also pushed Choose… out of the row (found 2026-10-29); the
    /// button must keep its full width (about 75 pt).
    @Test func imageFolderNameScreenshot() async throws {
      try await withPhases { app in
        let settings = try #require(try app.row(named: "Settings"))
        try await app.click(settings)
        let folder = try await waitFor("the image folder name") { try? app.element("imageFolderName") }
        #expect(folder.allText.contains(TestImages.folderName), "Folder name in AX: \(folder.allText)")
        let url = try app.screenshot("image folder name")
        print("Review: \(url.path(percentEncoded: false))")
        let window = try app.window()
        let choose = try #require(
          window.first { $0.role == "AXButton" && $0.allText.contains("Choose") },
          "No Choose… button; buttons: \(window.descendants().filter { $0.role == "AXButton" }.map(\.summary))"
        )
        let width = try #require(choose.frame?.width)
        #expect(width >= 60, "Choose… is squeezed to \(width) pt")
      }
    }
  }
}
