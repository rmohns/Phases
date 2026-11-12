import ApplicationServices
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

    /// [D-sidebar-footer-style] The − button answered only a click on its
    /// glyph (found by the author, 2026-11-12). Its label is now a 24 × 23 pt
    /// cell, all of it clickable: click 3 pt in from its top-left corner,
    /// well off the glyph. The second source is used by no phase, so removing
    /// it asks nothing.
    @Test func removeButtonWholeCellIsClickable() async throws {
      try await withPhases(imageFolders: Self.folders) { app in
        try await app.click(try #require(try app.row(named: "Settings")))
        try await waitUntil("the image source rows") { Self.names(app).count == 2 }

        // Select the second source by clicking its name.
        try await app.click(Self.names(app)[1])
        let remove = try await waitFor("the Remove Folder button to be enabled") {
          (try? app.element("removeImageSource")).flatMap { $0.isEnabled ? $0 : nil }
        }

        // The point must be off the glyph, so the cell's frame has to be the
        // whole cell and not just the symbol.
        let frame = try #require(remove.frame, "No frame for \(remove.summary)")
        try #require(frame.width >= 22 && frame.height >= 21, "The − button's frame isn't its whole cell: \(remove.summary)")

        try await app.click(remove, insetFromTopLeft: CGPoint(x: 3, y: 3))
        try await waitUntil("the second source to be removed") { Self.names(app).count == 1 }
        #expect(Self.names(app).first?.allText.contains(TestImages.folderName) == true,
          "The wrong source was removed; left: \(Self.names(app).map(\.allText))")
      }
    }

    /// [D-undo-remove-source] A source removed with a click on − comes back
    /// with Edit › Undo, in its old place, and Redo removes it again. No
    /// keys: the author asked that undo work without keyboard input
    /// (2026-11-12). ⌘Z is that menu item's key equivalent, so the menu is
    /// the route it takes too.
    @Test func undoPutsBackASourceRemovedWithTheMouse() async throws {
      try await withPhases(imageFolders: Self.folders) { app in
        try await app.click(try #require(try app.row(named: "Settings")))
        try await waitUntil("the image source rows") { Self.names(app).count == 2 }
        // Remove the first source, so putting it back in place is visible.
        try await app.click(Self.names(app)[0])
        let remove = try await waitFor("the Remove Folder button to be enabled") {
          (try? app.element("removeImageSource")).flatMap { $0.isEnabled ? $0 : nil }
        }
        try await app.click(remove)
        try await waitUntil("the first source to be removed") { Self.names(app).count == 1 }

        try await Self.chooseEditMenuItem(app, startingWith: "Undo Remove")
        try await waitUntil("the source to come back") { Self.names(app).count == 2 }
        #expect(Self.names(app).first?.allText.contains(TestImages.folderName) == true,
          "The source didn't come back in first place: \(Self.names(app).map(\.allText))")

        try await Self.chooseEditMenuItem(app, startingWith: "Redo Remove")
        try await waitUntil("redo to remove it again") { Self.names(app).count == 1 }
      }
    }

    /// Opens the Edit menu and presses an item, all through AX, no keys.
    /// Opening first matters: a closed menu's items keep the title and
    /// enabled state from when it last opened, so Redo read as disabled
    /// right after an undo (LEARNINGS.md `[L-closed-menu-stale]`).
    private static func chooseEditMenuItem(_ app: PhasesApp, startingWith prefix: String) async throws {
      let bar = try #require(app.app.node("AXMenuBar"), "No menu bar")
      let edit = try #require(bar.children.first { $0.title == "Edit" }, "No Edit menu")
      #expect(edit.perform(kAXPressAction) == .success, "Opening the Edit menu failed")
      try await Task.sleep(for: .milliseconds(500))
      let items = edit.descendants().filter { $0.role == "AXMenuItem" }
      print("Edit menu: \(items.map { "\($0.title ?? "?")\($0.isEnabled ? "" : " (disabled)")" })")
      let item = try #require(
        items.first { ($0.title ?? "").hasPrefix(prefix) },
        "No Edit menu item starting “\(prefix)”"
      )
      #expect(item.isEnabled, "“\(item.title ?? prefix)” is disabled")
      #expect(item.perform(kAXPressAction) == .success, "Pressing “\(item.title ?? prefix)” failed")
    }

    /// [D-image-sources] Tab went into the source list and never came out:
    /// every row's Include subfolders switch was a Tab stop (found by the
    /// author, 2026-11-12). The list is one stop now: from a click in it,
    /// two Tabs (one would do; the second allows a stop on the list's own
    /// edge) must leave it.
    @Test func tabLeavesTheSourceList() async throws {
      try await withPhases(imageFolders: Self.folders) { app in
        try await app.click(try #require(try app.row(named: "Settings")))
        try await waitUntil("the image source rows") { Self.names(app).count == 2 }
        let list = try app.element("imageSources")

        // Click the first source so the list has keyboard focus.
        try await app.click(Self.names(app)[0])
        try await waitUntil("the source list to have focus") { app.focusedElement()?.isInside(list) == true }

        var focused: AXNode?
        for _ in 0..<2 {
          try await app.press(.tab)
          focused = app.focusedElement()
          if let focused, !focused.isInside(list) { break }
        }
        let after = try #require(focused, "Nothing has keyboard focus after Tab")
        #expect(!after.isInside(list), "Two Tabs left focus inside the source list: \(after.summary)")
      }
    }

    // MARK: - Helpers

    /// Settings' source names, top to bottom: one per source row.
    private static func names(_ app: PhasesApp) -> [AXNode] {
      let all = (try? app.window().descendants().filter { $0.identifier == "imageFolderName" }) ?? []
      return all.sorted { ($0.frame?.minY ?? 0) < ($1.frame?.minY ?? 0) }
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
