import AppKit
import PhasesUIDriver
import Testing

extension PhasesUITests {
  /// EXPERIMENT [X-click-state], not for main: does a synthetic click on an
  /// image grid tile toggle it? Run alone with
  /// `swift test --filter ClickStateTests`, with and without
  /// `PHASES_CLICK_STATE=1`.
  @Suite(.enabled(if: !PhasesUITests.isSlowRun))
  @MainActor
  struct ClickStateTests {
    /// Launches exactly as the tests do, then holds the window open for
    /// Robert to look at. Sends no clicks on the grid.
    @Test func holdOpenForALook() async throws {
      try await withPhases { app in
        let window = try #require(try app.window().frame)
        print("[X-click-state] holding open; window \(window)")
        let shot = Process()
        shot.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        shot.arguments = ["-x", "-R\(Int(window.minX)),\(Int(window.minY)),\(Int(window.width)),\(Int(window.height))", "/tmp/phases-click-state-window.png"]
        try shot.run()
        shot.waitUntilExit()
        try await Task.sleep(for: .seconds(180))
      }
    }

    @Test func clickingATileTogglesIt() async throws {
      try await withPhases { app in
        var size = CGSize(width: 751, height: 1050)
        let resized = AXUIElementSetAttributeValue(
          try app.window().element, kAXSizeAttribute as CFString, AXValueCreate(.cgSize, &size)!)
        print("[X-click-state] resize: \(resized.rawValue)")
        try await Task.sleep(for: .seconds(1))
        let grid = try app.element("imageGrid")
        let windowFrame = try #require(try app.window().frame)
        func tile() throws -> AXNode {
          try #require(
            grid.descendants().first { node in
              node.role == "AXButton" && (node.label?.isEmpty == false)
                && node.frame.map { windowFrame.insetBy(dx: 20, dy: 20).contains($0) } == true
            },
            "No tile visible in the grid")
        }
        @MainActor func dump(_ when: String) {
          print("[X-click-state] window \(windowFrame); grid frame \(grid.frame.map { "\($0)" } ?? "nil")")
          print("[X-click-state] grid \(when): focused \(app.focusedElement()?.summary ?? "nothing")")
          for node in grid.descendants().filter({ $0.label?.isEmpty == false }).prefix(6) {
            print("[X-click-state]   \(node.role ?? "?") \(node.label ?? "") selected \(node.isSelected) frame \(node.frame.map { "\($0)" } ?? "nil")")
          }
        }
        func tile(named name: String) throws -> AXNode {
          try #require(grid.descendants().first { $0.label == name }, "Tile \(name) gone")
        }
        // Scroll the detail pane with the wheel, over the Name field, until a
        // whole tile is inside the window.
        for attempt in 1...8 {
          if (try? tile()) != nil { break }
          try await app.scroll(app.element("phaseName"), lines: 5)
          print("[X-click-state] scrolled 5 lines (\(attempt))")
        }
        dump("before")
        let first = try tile()
        let name = first.label ?? "?"
        let before = first.isSelected
        print("[X-click-state] tile \(first.summary) selected before: \(before)")

        try await app.click(first)
        try await Task.sleep(for: .milliseconds(800))
        dump("after click 1")
        let afterOne = try tile(named: name)
        let selectedAfterOne = afterOne.isSelected  // AX reads are live; keep the value
        print("[X-click-state] after click 1: \(afterOne.label ?? "?") selected \(selectedAfterOne)")

        try await Task.sleep(for: .seconds(1))  // past any double-click interval
        try await app.click(afterOne)
        try await Task.sleep(for: .milliseconds(800))
        dump("after click 2")
        let afterTwo = try tile(named: name)
        print("[X-click-state] after click 2: \(afterTwo.label ?? "?") selected \(afterTwo.isSelected)")

        #expect(selectedAfterOne != before, "Click 1 didn't toggle \(name)")
        #expect(afterTwo.isSelected == before, "Click 2 didn't toggle \(name) back")
      }
    }
  }
}
