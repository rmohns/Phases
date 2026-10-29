import Foundation
import Testing
@testable import PhasesLogic

struct AppVersionTests {
  /// [D-version-in-settings] The draft shown in Settings matches SPEC.md.
  @Test func specDraftMatchesSpecTitle() throws {
    let spec = URL(filePath: #filePath)
      .deletingLastPathComponent()  // PhasesLogicTests
      .deletingLastPathComponent()  // Tests
      .deletingLastPathComponent()  // UnitTests
      .deletingLastPathComponent()  // project root
      .appending(path: "SPEC.md")
    let title = try #require(try String(contentsOf: spec, encoding: .utf8).split(separator: "\n").first)
    // Title ends "(draft 24)".
    let draft = try #require(title.components(separatedBy: "(draft ").last?.prefix { $0.isNumber })
    #expect(Int(draft) == AppVersion.specDraft)
  }
}
