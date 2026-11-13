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
    #expect(try Self.projectValues(for: "CFBundleShortVersionString") == ["$(MARKETING_VERSION)"])
    #expect(try Self.projectValues(for: "CFBundleVersion") == ["$(CURRENT_PROJECT_VERSION)"])
  }

  /// Every value stored under `key` anywhere in Project.json.
  static func projectValues(for key: String) throws -> [String] {
    let data = try Data(contentsOf: root.appending(path: "Project.json"))
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
    walk(try JSONSerialization.jsonObject(with: data))
    return found
  }
}
