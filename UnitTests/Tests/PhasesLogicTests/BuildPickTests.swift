import Foundation
import Testing
@testable import PhasesLogic

/// [D-ui-test-build-pick] How the UI test driver picks the build to launch
/// (GitHub issue #47).
struct BuildPickTests {
  @Test func readsTheTimeInAFolderName() throws {
    let time = try #require(BuildPick.buildTime(folderName: "1795549462628-BB5DB1F9"))
    #expect(time == Date(timeIntervalSince1970: 1_795_549_462.628))
  }

  @Test func ignoresNamesWithoutATime() {
    #expect(BuildPick.buildTime(folderName: ".DS_Store") == nil)
    #expect(BuildPick.buildTime(folderName: "Phases.app") == nil)
    #expect(BuildPick.buildTime(folderName: "1795549462628") == nil)
    #expect(BuildPick.buildTime(folderName: "abc-BB5DB1F9") == nil)
  }

  /// #47: the three builds of 2026-11-24, whose file dates couldn't tell
  /// them apart, listed in an order where directory order would pick wrong.
  @Test func picksTheNewestByFolderName() {
    let folders = ["1795550148580-722DE915", "1795549462628-BB5DB1F9", "1795550139491-CD79C20B"]
    #expect(BuildPick.newest(folderNames: folders) == "1795550148580-722DE915")
    #expect(BuildPick.newest(folderNames: folders.reversed()) == "1795550148580-722DE915")
    #expect(BuildPick.newest(folderNames: [".DS_Store"] + folders) == "1795550148580-722DE915")
    #expect(BuildPick.newest(folderNames: [".DS_Store"]) == nil)
    #expect(BuildPick.newest(folderNames: []) == nil)
  }

  /// Compares the number, so a 13-digit time beats a 12-digit one.
  @Test func comparesTimesAsNumbersNotText() {
    #expect(BuildPick.newest(folderNames: ["999999999999-A", "1000000000000-B"]) == "1000000000000-B")
  }

  @Test func readsTheProjectVersion() {
    let text = """
      "build-settings": {
        "CURRENT_PROJECT_VERSION": "61",
        "MARKETING_VERSION": "0.1",
      },
      """
    #expect(BuildPick.projectVersion(projectFileText: text) == "61")
    #expect(BuildPick.projectVersion(projectFileText: "{}") == nil)
    let disagreeing = text + #"  "CURRENT_PROJECT_VERSION": "60","#
    #expect(BuildPick.projectVersion(projectFileText: disagreeing) == nil)
  }

  /// The real project file reads, and gives the number AppVersionTests
  /// checks against SPEC.md's title.
  @Test func readsTheRealProjectFile() throws {
    let project = AppVersionTests.root.appending(path: "Phases.xcodeproj/project.xcproj")
    let version = BuildPick.projectVersion(projectFileText: try String(contentsOf: project, encoding: .utf8))
    #expect(try AppVersionTests.projectValues(for: "CURRENT_PROJECT_VERSION") == [try #require(version)])
  }

  @Test func refusesABuildWhoseNumberDiffers() {
    #expect(BuildPick.versionMismatch(built: "61", project: "61") == nil)
    #expect(BuildPick.versionMismatch(built: "59", project: "61")?.contains("number 59") == true)
    #expect(BuildPick.versionMismatch(built: nil, project: "61") != nil)
    #expect(BuildPick.versionMismatch(built: "61", project: nil) != nil)
  }
}
