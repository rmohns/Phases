import Foundation
import PhasesUIDriver
import Testing

extension PhasesUITests {
  /// [D-image-sources] [D-source-names] Several image folders at once. Each
  /// test launches with two sources: the 60-image folder, then the small
  /// second folder (4 images, plus 2 in a subfolder).
  @Suite(.enabled(if: !PhasesUITests.isSlowRun))
  @MainActor
  struct ImageSourcesTests {
    private static let folders = [TestImages.folder, TestImages.secondFolder]

    /// [D-image-sources] Each source has its own heading over its images,
    /// in source order. The grid is lazy, so the second heading only exists
    /// in AX once it has scrolled near the screen: arrow down until it does.
    @Test func eachSourceHasAHeadingInOrder() async throws {
      try await withPhases(imageFolders: Self.folders) { app in
        let first = try await waitFor("the first source's heading") {
          Self.element(app, named: TestImages.folderName)
        }
        let firstImage = try await waitFor("the first image") { Self.element(app, named: "Test Image 01.png") }
        let firstTop = try #require(first.frame?.minY)
        let firstImageTop = try #require(firstImage.frame?.minY)
        #expect(firstTop < firstImageTop, "The first heading (\(firstTop)) isn't above its first image (\(firstImageTop))")

        try await Self.focusGrid(app)
        var second: AXNode?
        for _ in 0..<40 {
          second = Self.element(app, named: TestImages.secondFolderName)
          if second != nil { break }
          try await app.press(.downArrow)
        }
        let heading = try #require(second, "The second source's heading never appeared; scrolled with Down")

        // Whatever of the neighbors is on screen now: the heading sits below
        // the first source's last image and above the second's first.
        let headingTop = try #require(heading.frame?.minY)
        if let lastOfFirst = Self.element(app, named: "Test Image 60.png"), let top = lastOfFirst.frame?.minY {
          #expect(headingTop > top, "The second heading (\(headingTop)) isn't below the first source's last image (\(top))")
        }
        // Realized with the heading, since they share its section; required,
        // so the order check can't be skipped silently.
        let firstOfSecond = try #require(
          Self.element(app, named: "Second Image 01.png"), "Second Image 01.png isn't in the grid with its heading"
        )
        let secondTop = try #require(firstOfSecond.frame?.minY)
        #expect(headingTop < secondTop, "The second heading (\(headingTop)) isn't above the second source's first image (\(secondTop))")
      }
    }

    /// [D-grid-one-tab-stop] Left and right step through the images in
    /// order, across sources: Right from the first source's last image
    /// lands on the second source's first. The cursor is only drawn, not in
    /// AX, so Space toggles the image under it and the cell's selected state
    /// shows where it was.
    @Test func arrowKeysCrossSources() async throws {
      try await withPhases(imageFolders: Self.folders) { app in
        try await Self.focusGrid(app)
        // Focusing puts the cursor on the first image; walk to the 60th.
        for _ in 0..<(TestImages.count - 1) { try await app.press(.rightArrow) }
        try await app.press(.rightArrow)
        try await app.press(.space)
        let landed = try await waitFor("Second Image 01.png to be selected") {
          Self.element(app, named: "Second Image 01.png").flatMap { $0.isSelected ? $0 : nil }
        }
        #expect(landed.isSelected)
        let last = try #require(Self.element(app, named: "Test Image 60.png"), "Test Image 60.png isn't in the grid")
        #expect(!last.isSelected, "Right stayed on Test Image 60.png instead of crossing to the second source")
        try await waitUntil("1 of 64 selected") { Self.selectionText(app)?.contains("1 of 64 selected") == true }
      }
    }

    /// Select All covers every source: 60 + 4 images, subfolders off.
    @Test func selectAllSelectsBothSources() async throws {
      try await withPhases(imageFolders: Self.folders) { app in
        let selectAll = try await waitFor("the Select All button") {
          try? app.window().first { $0.role == "AXButton" && $0.allText.contains("Select All") }
        }
        try await app.click(selectAll)
        try await waitUntil("64 of 64 selected") {
          Self.selectionText(app)?.contains("64 of 64 selected") == true
        }
      }
    }

    /// Settings lists one row per source with its own count; Include
    /// subfolders belongs to its row.
    @Test func settingsRowsCountPerSourceAndTogglePerRow() async throws {
      try await withPhases(imageFolders: Self.folders) { app in
        try await app.click(try #require(try app.row(named: "Settings")))
        try await waitUntil("the image source rows") { Self.counts(app).count == 2 }
        #expect(Self.countTexts(app) == ["\(TestImages.count) images", "\(TestImages.secondCount) images"],
          "Counts: \(Self.countTexts(app))")

        let toggles = Self.subfolderToggles(app)
        try #require(toggles.count == 2, "Include subfolders toggles: \(toggles.map(\.summary))")
        try await app.click(toggles[1])
        let expected = ["\(TestImages.count) images", "\(TestImages.secondCount + TestImages.nestedCount) images"]
        try await waitUntil("the second row to count its subfolder") { Self.countTexts(app) == expected }
        #expect(Self.countTexts(app) == expected, "Counts: \(Self.countTexts(app))")
      }
    }

    // MARK: - Helpers

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

    /// The first element whose own title, value, or label is exactly `name`:
    /// a source heading, or an image cell (labelled with its path).
    private static func element(_ app: PhasesApp, named name: String) -> AXNode? {
      try? app.window().first { [$0.title, $0.value, $0.label].contains(name) }
    }

    /// The grid's "N of M selected" text.
    private static func selectionText(_ app: PhasesApp) -> String? {
      try? app.window().first { $0.role == "AXStaticText" && $0.allText.contains(" selected") }?.allText
    }

    /// Settings' count elements, top to bottom: one per source row.
    private static func counts(_ app: PhasesApp) -> [AXNode] {
      let all = (try? app.window().descendants().filter { $0.identifier == "imageSourceCount" }) ?? []
      return all.sorted { ($0.frame?.minY ?? 0) < ($1.frame?.minY ?? 0) }
    }

    private static func countTexts(_ app: PhasesApp) -> [String] {
      counts(app).map { $0.value ?? $0.allText }
    }

    /// Each row's Include subfolders toggle, top to bottom.
    private static func subfolderToggles(_ app: PhasesApp) -> [AXNode] {
      let all = (try? app.window().descendants().filter {
        ($0.role == "AXCheckBox" || $0.role == "AXSwitch") && $0.allText.contains("Include subfolders")
      }) ?? []
      return all.sorted { ($0.frame?.minY ?? 0) < ($1.frame?.minY ?? 0) }
    }
  }
}
