import Foundation
import Testing

/// [D-sandbox-entitlements] [D-debug-test-folder] The two entitlements
/// files, and which configuration signs with which.
struct EntitlementsTests {
  static let exceptionKey = "com.apple.security.temporary-exception.files.home-relative-path.read-only"
  static let testFolder = "/Library/Caches/PhasesUITests/"

  static func entitlements(_ name: String) throws -> [String: Any] {
    let data = try Data(contentsOf: AppVersionTests.root.appending(path: "App/\(name)"))
    return try #require(PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any])
  }

  /// Debug's file is Release's plus exactly the one test folder, so the
  /// shipping sandbox and the tested one can't drift apart.
  @Test func debugIsReleasePlusTheTestFolder() throws {
    let release = try Self.entitlements("Phases.entitlements")
    var debug = try Self.entitlements("Phases-Debug.entitlements")
    let releasePaths = try #require(release[Self.exceptionKey] as? [String])
    let debugPaths = try #require(debug[Self.exceptionKey] as? [String])
    #expect(debugPaths == releasePaths + [Self.testFolder])
    debug[Self.exceptionKey] = releasePaths
    #expect(NSDictionary(dictionary: debug).isEqual(to: release))
  }

  /// Release never reads the test folder.
  @Test func releaseCantReadTheTestFolder() throws {
    let release = try Self.entitlements("Phases.entitlements")
    #expect((release[Self.exceptionKey] as? [String])?.contains(Self.testFolder) == false)
  }

  /// Debug signs with the Debug file, Release with the shipping one.
  @Test func eachConfigurationSignsWithItsFile() throws {
    let text = try String(
      contentsOf: AppVersionTests.root.appending(path: "Phases.xcodeproj/project.xcproj"), encoding: .utf8)
    let pairs = text.matches(of: #/"CODE_SIGN_ENTITLEMENTS(\[[^\]]*\])?"\s*:\s*"([^"]*)"/#)
      .map { "\($0.output.1 ?? "")=\($0.output.2)" }
    #expect(
      Set(pairs) == [
        "[config=Debug]=App/Phases-Debug.entitlements",
        "[config=Release]=App/Phases.entitlements",
      ])
  }
}
