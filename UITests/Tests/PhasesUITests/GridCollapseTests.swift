import Foundation
import PhasesUIDriver
import Testing

extension PhasesUITests {
  /// [D-grid-collapse] [D-grid-collapse-saved] Collapsible grid headings
  /// (draft 64, GitHub issue #37). A heading is one AX element: its label
  /// is the name, its value "Expanded" or "Collapsed, <count>", and its
  /// identifier `gridHeading` [D-ui-test-ids]. A collapsed section's images
  /// leave the grid, so they leave AX too.
  @Suite(.enabled(if: !PhasesUITests.isSlowRun))
  @MainActor
  struct GridCollapseTests {
    private static let folders = [TestImages.folder, TestImages.secondFolder]
    private static let total = TestImages.count + TestImages.secondCount

    /// Clicking a heading folds its images away and shows its count;
    /// clicking again brings them back.
    @Test func clickingAHeadingFoldsItsImagesAndShowsItsCount() async throws {
      try await withPhases(imageFolders: Self.folders) { app in
        let heading = try await Self.heading(app, TestImages.folderName)
        #expect(heading.value == "Expanded", "Value: \(heading.value ?? "nil")")
        _ = try await waitFor("the first image") { Self.element(app, named: "Test Image 01.png") }

        try await app.click(heading)
        try await waitUntil("the first source to collapse") {
          Self.element(app, named: "Test Image 01.png") == nil
            && Self.headingValue(app, TestImages.folderName) == "Collapsed, \(TestImages.count) images"
        }
        // Folded, the second source's heading is near the top, so it's in AX.
        _ = try await Self.heading(app, TestImages.secondFolderName)

        try await app.click(try await Self.heading(app, TestImages.folderName))
        _ = try await waitFor("the first image to come back") { Self.element(app, named: "Test Image 01.png") }
        #expect(Self.headingValue(app, TestImages.folderName) == "Expanded")
      }
    }

    /// [D-grid-one-tab-stop] From the keyboard: ← from the first image moves
    /// to its heading; Space, ←, and → fold and unfold it; → on the open
    /// heading moves back to the first image.
    @Test func keyboardFoldsAndUnfoldsAHeading() async throws {
      try await withPhases(imageFolders: Self.folders) { app in
        let name = TestImages.folderName
        try await Self.focusGrid(app)
        try await app.press(.leftArrow)

        try await app.press(.space)
        try await waitUntil("Space to collapse the heading") { Self.headingValue(app, name)?.hasPrefix("Collapsed") == true }
        try await app.press(.space)
        try await waitUntil("Space to expand the heading") { Self.headingValue(app, name) == "Expanded" }
        try await app.press(.leftArrow)
        try await waitUntil("← to collapse the heading") { Self.headingValue(app, name)?.hasPrefix("Collapsed") == true }
        try await app.press(.rightArrow)
        try await waitUntil("→ to expand the heading") { Self.headingValue(app, name) == "Expanded" }

        // → on an open heading moves on, to the first image.
        try await app.press(.rightArrow)
        try await app.press(.space)
        try await waitUntil("1 of \(Self.total) selected") {
          Self.selectionText(app)?.contains("1 of \(Self.total) selected") == true
        }
        let first = try #require(Self.element(app, named: "Test Image 01.png"))
        #expect(first.isSelected, "→ from the open heading didn't land on the first image")
      }
    }

    /// Select All covers collapsed images too, and the collapsed heading
    /// counts what's selected in it (author, 2026-11-26).
    @Test func selectAllIncludesCollapsedImages() async throws {
      try await withPhases(imageFolders: Self.folders) { app in
        try await app.click(try await Self.heading(app, TestImages.folderName))
        try await waitUntil("the first source to collapse") {
          Self.headingValue(app, TestImages.folderName)?.hasPrefix("Collapsed") == true
        }
        let selectAll = try await waitFor("the Select All button") {
          try? app.window().first { $0.role == "AXButton" && $0.allText.contains("Select All") }
        }
        try await app.click(selectAll)
        try await waitUntil("\(Self.total) of \(Self.total) selected") {
          Self.selectionText(app)?.contains("\(Self.total) of \(Self.total) selected") == true
        }
        let count = "Collapsed, \(TestImages.count) of \(TestImages.count) selected"
        try await waitUntil("the heading to say \(count)") { Self.headingValue(app, TestImages.folderName) == count }
      }
    }

    /// ⇧-click ranges skip images in collapsed sections (author,
    /// 2026-11-26). Three sources: Nested (2 images), the second folder (4,
    /// collapsed), the big folder (60). Nested Image 01 to Test Image 01
    /// covers 3 showing images; without the rule it would take 7.
    @Test func shiftClickRangeSkipsCollapsedImages() async throws {
      let nested = TestImages.secondFolder.appending(path: TestImages.nestedFolderName, directoryHint: .isDirectory)
      let folders = [nested, TestImages.secondFolder, TestImages.folder]
      let total = TestImages.nestedCount + TestImages.secondCount + TestImages.count
      try await withPhases(imageFolders: folders) { app in
        try await app.click(try await Self.heading(app, TestImages.secondFolderName))
        try await waitUntil("the second folder to collapse") {
          Self.headingValue(app, TestImages.secondFolderName)?.hasPrefix("Collapsed") == true
        }
        let start = try await waitFor("Nested Image 01.png") { Self.element(app, named: "Nested Image 01.png") }
        try await app.click(start)
        try await waitUntil("1 of \(total) selected") { Self.selectionText(app)?.contains("1 of \(total) selected") == true }
        let end = try await waitFor("Test Image 01.png") { Self.element(app, named: "Test Image 01.png") }
        try await app.click(end, modifiers: [.shift])
        try await waitUntil("3 of \(total) selected") { Self.selectionText(app)?.contains(" of \(total) selected") == true }
        #expect(Self.selectionText(app)?.contains("3 of \(total) selected") == true,
          "The range took collapsed images: \(Self.selectionText(app) ?? "nil")")
        #expect(Self.headingValue(app, TestImages.secondFolderName) == "Collapsed, \(TestImages.secondCount) images",
          "The collapsed folder's images were selected: \(Self.headingValue(app, TestImages.secondFolderName) ?? "nil")")
      }
    }

    /// [D-grid-collapse-saved] A collapsed heading stays collapsed after the
    /// window closes and opens again. (After quitting isn't testable here:
    /// test mode erases its settings at launch [D-ui-test-mode].)
    @Test func collapsedHeadingStaysAfterTheWindowCloses() async throws {
      try await withPhases(imageFolders: Self.folders) { app in
        try await app.click(try await Self.heading(app, TestImages.folderName))
        try await waitUntil("the first source to collapse") {
          Self.headingValue(app, TestImages.folderName)?.hasPrefix("Collapsed") == true
        }
        try await app.closeWindow()
        try await waitUntil("the Dock icon to go") { !app.hasDockIcon }
        try app.relaunch()
        try await app.waitForWindow()
        _ = try await Self.heading(app, TestImages.folderName)
        #expect(Self.headingValue(app, TestImages.folderName)?.hasPrefix("Collapsed") == true,
          "Reopened expanded: \(Self.headingValue(app, TestImages.folderName) ?? "nil")")
        #expect(Self.element(app, named: "Test Image 01.png") == nil, "The collapsed source's images are showing")
      }
    }

    // MARK: - Helpers

    private static func heading(_ app: PhasesApp, _ name: String) async throws -> AXNode {
      try await waitFor("the heading \"\(name)\"") {
        try? app.window().first { $0.identifier == "gridHeading" && $0.label == name }
      }
    }

    private static func headingValue(_ app: PhasesApp, _ name: String) -> String? {
      (try? app.window().first { $0.identifier == "gridHeading" && $0.label == name })?.value
    }

    /// Tabs until the image grid has focus [D-grid-one-tab-stop]; the
    /// cursor then starts on the first image.
    private static func focusGrid(_ app: PhasesApp) async throws {
      let grid = try app.element("imageGrid")
      for _ in 0..<25 {
        try await app.press(.tab)
        if app.focusedElement()?.isInside(grid) == true { return }
      }
      throw UITestFailure("Tab never reached the image grid")
    }

    /// An image cell, labelled with its path.
    private static func element(_ app: PhasesApp, named name: String) -> AXNode? {
      try? app.window().first { $0.identifier != "gridHeading" && [$0.title, $0.value, $0.label].contains(name) }
    }

    /// The image header's "N of M selected", not a collapsed heading's.
    private static func selectionText(_ app: PhasesApp) -> String? {
      try? app.window().first {
        $0.role == "AXStaticText" && $0.identifier != "gridHeading" && $0.allText.contains(" selected")
      }?.allText
    }
  }
}
