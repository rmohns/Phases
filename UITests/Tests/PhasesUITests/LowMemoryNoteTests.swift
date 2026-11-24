import Foundation
import PhasesUIDriver
import Testing

extension PhasesUITests {
  /// [D-low-memory-note] The Transition section suggests turning
  /// transitions off on a Mac with less than 16 GB. The Mac's memory is
  /// faked per launch [D-test-memory-size]. Crossfade is the default
  /// style, and test mode never forces Reduce Motion, so if Reduce Motion
  /// is on for the Mac running these tests, the note legitimately hides and
  /// the 8 GB test fails: turn Reduce Motion off first.
  @Suite(.enabled(if: !PhasesUITests.isSlowRun))
  @MainActor
  struct LowMemoryNoteTests {
    @Test func noteShowsOnAnEightGigabyteMac() async throws {
      let app = try await PhasesApp.launch(memoryGB: 8)
      defer { app.quit() }
      try await app.click(try #require(try app.row(named: "Settings")))
      _ = try await waitFor("the low-memory note") { try? app.element("lowMemoryNote") }
    }

    @Test func noteIsAbsentOnAThirtyTwoGigabyteMac() async throws {
      let app = try await PhasesApp.launch(memoryGB: 32)
      defer { app.quit() }
      try await app.click(try #require(try app.row(named: "Settings")))
      // Settings has drawn once its image sources list is there; only then
      // does a missing note mean anything.
      _ = try await waitFor("Settings to appear") { try? app.element("imageSources") }
      try await Task.sleep(for: .seconds(1))
      #expect((try? app.element("lowMemoryNote")) == nil, "The low-memory note shows on a 32 GB Mac")
    }
  }
}
