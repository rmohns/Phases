import Foundation
import Testing

struct AppVersionTests {
  static let root = URL(filePath: #filePath)
    .deletingLastPathComponent()  // PhasesLogicTests
    .deletingLastPathComponent()  // Tests
    .deletingLastPathComponent()  // UnitTests
    .deletingLastPathComponent()  // project root

  /// [D-version-in-settings] The build number, which Settings and the About
  /// panel show as the spec draft, matches SPEC.md's title.
  @Test func buildNumberMatchesSpecTitle() throws {
    let spec = Self.root.appending(path: "docs/SPEC.md")
    let title = try #require(try String(contentsOf: spec, encoding: .utf8).split(separator: "\n").first)
    // Title ends "(draft 47)".
    let draft = try #require(title.components(separatedBy: "(draft ").last?.prefix { $0.isNumber })
    #expect(try Self.projectValues(for: "CURRENT_PROJECT_VERSION") == [String(draft)])
  }

  /// [D-version-in-settings] The Info.plist repeats neither number, so the
  /// build settings are the only place they're set.
  @Test func infoPlistTakesVersionFromBuildSettings() throws {
    let data = try Data(contentsOf: Self.root.appending(path: "App/Info.plist"))
    let plist = try #require(PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any])
    #expect(plist["CFBundleShortVersionString"] as? String == "$(MARKETING_VERSION)")
    #expect(plist["CFBundleVersion"] as? String == "$(CURRENT_PROJECT_VERSION)")
    #expect(try Self.projectValues(for: "CFBundleShortVersionString").isEmpty)
    #expect(try Self.projectValues(for: "CFBundleVersion").isEmpty)
  }

  /// Every value stored under `key` anywhere in the Xcode project
  /// [D-xcode-project]. Its `project.xcproj` is JSON with trailing commas,
  /// so it's read as JSON5.
  static func projectValues(for key: String) throws -> [String] {
    let data = try Data(contentsOf: root.appending(path: "Phases.xcodeproj/project.xcproj"))
    var found: [String] = []
    func walk(_ node: Any) {
      if let dict = node as? [String: Any] {
        for (k, v) in dict {
          if k == key, let s = v as? String { found.append(s) }
          walk(v)
        }
      } else if let array = node as? [Any] {
        array.forEach(walk)
      }
    }
    walk(try JSONSerialization.jsonObject(with: data, options: .json5Allowed))
    return found
  }
}
