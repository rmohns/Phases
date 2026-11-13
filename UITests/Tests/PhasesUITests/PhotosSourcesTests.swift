import ApplicationServices
import Foundation
import PhasesUIDriver
import Testing

extension PhasesUITests {
  /// [D-photos-sources] [D-photos-permission] Photos albums as image
  /// sources, against the fake Photos library [D-fake-photos]: `Beach` (3),
  /// `Mountains` (2), the folder `Trips` with `Iceland` (2) and `Japan` (1),
  /// `Empty` (none), and the shared album `Family` (2). Each test launches
  /// with the small second folder (4 images) as its one folder source, so
  /// the Photos source is the second row.
  @Suite(.enabled(if: !PhasesUITests.isSlowRun))
  @MainActor
  struct PhotosSourcesTests {
    private typealias Photos = TestImages.Photos
    private static let folderSources = [TestImages.secondFolder]

    private static func withPhotos(
      denied: Bool = false, _ body: @MainActor (PhasesApp) async throws -> Void
    ) async throws {
      try await withPhases(
        imageFolders: folderSources, photosLibrary: Photos.library, photosDenied: denied, body
      )
    }

    /// [D-photos-sources] + › Add Photos Album… lists Beach with its count;
    /// choosing it adds a row named Beach, "3 photos", located "Photos",
    /// and the grid heads its images with "Beach".
    @Test func addingAnAlbumMakesARowAndAHeading() async throws {
      try await Self.withPhotos { app in
        try await Self.openSettings(app)
        try await Self.openAlbumSheet(app)
        _ = try await waitFor("Beach in the album list, with its count") {
          Self.albumRow(app, "\(Photos.beach), \(Photos.beachCount) photos")
        }

        try await Self.chooseAlbum(app, "\(Photos.beach), \(Photos.beachCount) photos")
        let add = try #require(Self.addButton(app), "No Add button in the sheet")
        try #require(add.isEnabled, "Add is disabled with Beach selected")
        try await app.click(add)
        try await Self.waitForSheetToClose(app)

        try await waitUntil("the Beach row") { Self.sourceRow(app, named: Photos.beach) != nil }
        let row = try #require(Self.sourceRow(app, named: Photos.beach))
        #expect(Self.names(app).count == 2, "Rows: \(Self.names(app).map(\.allText))")
        #expect(Self.count(of: row) == "\(Photos.beachCount) photos", "Count: \(Self.count(of: row) ?? "none")")
        #expect(Self.location(of: row) == "Photos", "Location: \(Self.location(of: row) ?? "none"); row shows \(Self.texts(of: row))")

        // The grid: the album's heading, over the 4 + 3 images.
        try await app.click(try #require(try app.row(named: "Morning")))
        _ = try await Self.scrollTo(app, heading: Photos.beach)
        try await waitUntil("the grid to count both sources") {
          Self.selectionText(app)?.contains("of \(TestImages.secondCount + Photos.beachCount) selected") == true
        }
      }
    }

    /// [D-photos-sources] A folder of albums is one source: its count is
    /// every album's photos, its grid heading is the folder's name, and each
    /// album under it is a subheading.
    @Test func addingAFolderOfAlbumsShowsSubheadings() async throws {
      try await Self.withPhotos { app in
        try await Self.openSettings(app)
        try await Self.openAlbumSheet(app)
        try await Self.chooseAlbum(app, "\(Photos.trips), folder")
        try await Self.addChosen(app)

        try await waitUntil("the Trips row") { Self.sourceRow(app, named: Photos.trips) != nil }
        let row = try #require(Self.sourceRow(app, named: Photos.trips))
        #expect(Self.count(of: row) == "\(Photos.tripsCount) photos", "Count: \(Self.count(of: row) ?? "none")")
        #expect(Self.location(of: row) == "Photos", "Location: \(Self.location(of: row) ?? "none"); row shows \(Self.texts(of: row))")

        try await app.click(try #require(try app.row(named: "Morning")))
        _ = try await Self.scrollTo(app, heading: Photos.trips)
        // Both subheadings are realized with the folder's heading's section
        // or one scroll later; look for each, scrolling if need be.
        _ = try await Self.scrollTo(app, heading: Photos.iceland)
        _ = try await Self.scrollTo(app, heading: Photos.japan)
      }
    }

    /// [D-photos-sources] Adding an album that is already a source selects
    /// its row and adds none. The first source is selected in between, so
    /// the selection has to move back.
    @Test func addingAnAlbumAgainSelectsItsRow() async throws {
      try await Self.withPhotos { app in
        try await Self.openSettings(app)
        try await Self.openAlbumSheet(app)
        try await Self.chooseAlbum(app, "\(Photos.beach), \(Photos.beachCount) photos")
        try await Self.addChosen(app)
        try await waitUntil("the Beach row") { Self.sourceRow(app, named: Photos.beach) != nil }
        #expect(Self.names(app).count == 2)

        // Select the folder source, then add Beach again.
        try await app.click(Self.names(app)[0])
        try await waitUntil("Beach to be deselected") { !Self.isSelected(app, named: Photos.beach) }

        try await Self.openAlbumSheet(app)
        try await Self.chooseAlbum(app, "\(Photos.beach), \(Photos.beachCount) photos")
        try await Self.addChosen(app)

        try await waitUntil("Beach's row to be selected") { Self.isSelected(app, named: Photos.beach) }
        #expect(Self.names(app).count == 2, "Adding Beach again made a row: \(Self.names(app).map(\.allText))")
        let row = try #require(Self.sourceRow(app, named: Photos.beach))
        #expect(Self.count(of: row) == "\(Photos.beachCount) photos", "Count: \(Self.count(of: row) ?? "none")")
      }
    }

    /// [D-photos-sources] An album with no photos is listed but can't be
    /// chosen: with it selected (or the click refused), Add stays disabled,
    /// and Cancel leaves the sources as they were.
    @Test func anEmptyAlbumCantBeAdded() async throws {
      try await Self.withPhotos { app in
        try await Self.openSettings(app)
        try await Self.openAlbumSheet(app)
        let empty = try await waitFor("the Empty album in the list") {
          Self.albumRow(app, "\(Photos.empty), 0 photos")
        }
        try await app.click(empty)
        // Give a selection that did take hold time to show in Add.
        try await Task.sleep(for: .milliseconds(500))
        let add = try #require(Self.addButton(app), "No Add button in the sheet")
        #expect(!add.isEnabled, "Add is enabled with the Empty album clicked")

        let cancel = try #require(Self.sheetButton(app, "Cancel"), "No Cancel button in the sheet")
        try await app.click(cancel)
        try await Self.waitForSheetToClose(app)
        #expect(Self.names(app).count == 1, "Rows after Cancel: \(Self.names(app).map(\.allText))")
      }
    }

    /// [D-photos-sources] Shared albums sit under their own "Shared Albums"
    /// heading, below the user's albums, and their Settings row reads
    /// "Shared Album" where a folder's location would be.
    @Test func sharedAlbumsHaveTheirOwnSectionAndLocation() async throws {
      try await Self.withPhotos { app in
        try await Self.openSettings(app)
        try await Self.openAlbumSheet(app)
        let header = try await waitFor("the Shared Albums heading") { Self.sheetText(app, "Shared Albums") }
        let familyLabel = "\(Photos.family), \(Photos.familyCount) photos"
        let family = try await waitFor("the Family album") { Self.albumRow(app, familyLabel) }
        let beach = try #require(Self.albumRow(app, "\(Photos.beach), \(Photos.beachCount) photos"))
        let headerTop = try #require(header.frame?.minY)
        #expect(try #require(family.frame?.minY) > headerTop, "Family isn't under the Shared Albums heading")
        #expect(try #require(beach.frame?.minY) < headerTop, "Beach isn't above the Shared Albums heading")

        try await app.click(family)
        try await Self.addChosen(app)
        try await waitUntil("the Family row") { Self.sourceRow(app, named: Photos.family) != nil }
        let row = try #require(Self.sourceRow(app, named: Photos.family))
        #expect(Self.location(of: row) == "Shared Album", "Location: \(Self.location(of: row) ?? "none"); row shows \(Self.texts(of: row))")
        #expect(Self.count(of: row) == "\(Photos.familyCount) photos", "Count: \(Self.count(of: row) ?? "none")")
      }
    }

    /// [D-photos-permission] With access refused, the sheet says so in place
    /// of the list, and nothing can be added.
    @Test func deniedAccessShowsTheExplanation() async throws {
      try await Self.withPhotos(denied: true) { app in
        try await Self.openSettings(app)
        try await Self.openAlbumSheet(app, expectingList: false)
        let message = "Phases doesn't have access to Photos"
        try await waitUntil("the access message") { Self.sheet(app)?.allText.contains(message) == true }
        #expect(Self.sheet(app)?.allText.contains(message) == true)
        #expect(Self.albumList(app) == nil, "The album list shows although access is denied")
        let add = try #require(Self.addButton(app), "No Add button in the sheet")
        #expect(!add.isEnabled, "Add is enabled with access denied")
      }
    }

    // MARK: - Steps

    private static func openSettings(_ app: PhasesApp) async throws {
      try await app.click(try #require(try app.row(named: "Settings")))
      try await waitUntil("the image source rows") { names(app).count == 1 }
    }

    /// + › Add Photos Album…, by real clicks on the menu; waits for the
    /// sheet's list, unless access is denied and there isn't one.
    private static func openAlbumSheet(_ app: PhasesApp, expectingList: Bool = true) async throws {
      let chosen = try await app.chooseMenuButtonItem("addImageSource", startingWith: "Add Photos Album")
      print("Chose: \(chosen)")
      if expectingList {
        _ = try await waitFor("the album list", timeout: .seconds(10)) { albumList(app) }
      } else {
        _ = try await waitFor("the sheet", timeout: .seconds(10)) { addButton(app) }
      }
    }

    /// Clicks the album's row in the sheet.
    private static func chooseAlbum(_ app: PhasesApp, _ label: String) async throws {
      let row = try await waitFor("the “\(label)” row") { albumRow(app, label) }
      try await app.click(row)
      try await waitUntil("Add to be enabled") { addButton(app)?.isEnabled == true }
    }

    /// Clicks Add and waits for the sheet to close.
    private static func addChosen(_ app: PhasesApp) async throws {
      let add = try #require(addButton(app), "No Add button in the sheet")
      try await app.click(add)
      try await waitForSheetToClose(app)
    }

    private static func waitForSheetToClose(_ app: PhasesApp) async throws {
      try await waitUntil("the album sheet to close") { addButton(app) == nil }
    }

    /// Scrolls the grid with Down until the heading is in AX; the grid is
    /// lazy, so a heading far down only exists once it's near the screen.
    private static func scrollTo(_ app: PhasesApp, heading: String) async throws -> AXNode {
      if let found = element(app, named: heading) { return found }
      try await focusGrid(app)
      for _ in 0..<40 {
        if let found = element(app, named: heading) { return found }
        try await app.press(.downArrow)
      }
      throw UITestFailure("The heading \"\(heading)\" never appeared in the grid; scrolled with Down")
    }

    private static func focusGrid(_ app: PhasesApp) async throws {
      let grid = try app.element("imageGrid")
      // Already there from an earlier scroll: one more Tab would leave it,
      // since the grid is one Tab stop [D-grid-one-tab-stop].
      if app.focusedElement()?.isInside(grid) == true { return }
      for _ in 0..<25 {
        try await app.press(.tab)
        if app.focusedElement()?.isInside(grid) == true { return }
      }
      throw UITestFailure("Tab never reached the image grid")
    }

    // MARK: - Reading

    /// The sheet over the window, or the window if AX doesn't name it.
    private static func sheet(_ app: PhasesApp) -> AXNode? {
      guard let window = try? app.window() else { return nil }
      return window.first { $0.role == "AXSheet" } ?? window
    }

    private static func albumList(_ app: PhasesApp) -> AXNode? {
      (try? app.window())?.first(identifier: "photosAlbumList")
    }

    /// A row in the sheet's list, found by its accessibility label
    /// (`Beach, 3 photos`, `Trips, folder`).
    private static func albumRow(_ app: PhasesApp, _ label: String) -> AXNode? {
      albumList(app)?.first { [$0.label, $0.title, $0.value].contains(label) }
    }

    /// Static text in the sheet, such as a section heading.
    private static func sheetText(_ app: PhasesApp, _ text: String) -> AXNode? {
      sheet(app)?.first { [$0.title, $0.value, $0.label].contains(text) }
    }

    private static func sheetButton(_ app: PhasesApp, _ title: String) -> AXNode? {
      sheet(app)?.first { $0.role == "AXButton" && [$0.title, $0.label].contains(title) }
    }

    /// The sheet's Add button; nil when no sheet is open.
    private static func addButton(_ app: PhasesApp) -> AXNode? {
      sheetButton(app, "Add")
    }

    /// Settings' source names, top to bottom: one per source row.
    private static func names(_ app: PhasesApp) -> [AXNode] {
      let all = (try? app.window().descendants().filter { $0.identifier == "imageFolderName" }) ?? []
      return all.sorted { ($0.frame?.minY ?? 0) < ($1.frame?.minY ?? 0) }
    }

    private static func nameNode(_ app: PhasesApp, named name: String) -> AXNode? {
      names(app).first { [$0.title, $0.value, $0.label].contains(name) }
    }

    /// The smallest element holding the source's name and its count: its row.
    private static func sourceRow(_ app: PhasesApp, named name: String) -> AXNode? {
      var current = nameNode(app, named: name)?.parent
      for _ in 0..<12 {
        guard let node = current else { return nil }
        if node.first(identifier: "imageSourceCount") != nil { return node }
        current = node.parent
      }
      return nil
    }

    /// Whether the source's list row is selected.
    private static func isSelected(_ app: PhasesApp, named name: String) -> Bool {
      var current = nameNode(app, named: name)
      for _ in 0..<12 {
        guard let node = current else { return false }
        if node.role == kAXRowRole { return node.isSelected }
        current = node.parent
      }
      return false
    }

    /// Every string the row shows, one per element.
    private static func texts(of row: AXNode) -> [String] {
      ([row] + row.descendants()).flatMap { [$0.title, $0.value, $0.label].compactMap { $0 } }
    }

    /// The row's location line (`Photos`, `Photos › Trips`, `Shared Album`).
    private static func location(of row: AXNode) -> String? {
      row.first(identifier: "imageSourceLocation").map { $0.value ?? $0.allText }
    }

    private static func count(of row: AXNode) -> String? {
      row.first(identifier: "imageSourceCount").map { $0.value ?? $0.allText }
    }

    /// The first element whose own title, value, or label is exactly `name`:
    /// a source heading or subheading in the grid.
    private static func element(_ app: PhasesApp, named name: String) -> AXNode? {
      try? app.window().first { [$0.title, $0.value, $0.label].contains(name) }
    }

    /// The grid's "N of M selected" text.
    private static func selectionText(_ app: PhasesApp) -> String? {
      try? app.window().first { $0.role == "AXStaticText" && $0.allText.contains(" selected") }?.allText
    }
  }
}
