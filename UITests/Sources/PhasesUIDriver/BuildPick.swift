import Foundation

/// [D-ui-test-build-pick] Which Bitrig build the UI tests launch, and the
/// check that it's the build the project describes. Pure, so the unit tests
/// reach it too (`UnitTests/Sources/PhasesLogic` links to this file).
public enum BuildPick {
  /// When Bitrig made a build, from its folder's name: milliseconds since
  /// 1970, a dash, then an ID, as in `1795549462628-BB5DB1F9`. Nil for a
  /// name in any other form.
  public static func buildTime(folderName: String) -> Date? {
    let parts = folderName.split(separator: "-", maxSplits: 1)
    guard parts.count == 2, let millis = Int64(parts[0]), millis > 0 else { return nil }
    return Date(timeIntervalSince1970: Double(millis) / 1000)
  }

  /// The newest build folder by the time in its name. File dates can't
  /// tell builds apart: Bitrig gives every `Phases.app` bundle one date,
  /// and an unchanged executable keeps an earlier build's date (GitHub
  /// issue #47). Folders whose names carry no time are ignored.
  public static func newest(folderNames: [String]) -> String? {
    folderNames
      .compactMap { name in buildTime(folderName: name).map { (name, $0) } }
      .max { $0.1 < $1.1 }?
      .0
  }

  /// `CURRENT_PROJECT_VERSION` from the text of `project.xcproj` (Xcode
  /// 27's JSON-like format, which allows trailing commas, so it's read by
  /// pattern, not parsed). Nil unless it's set and every place that sets
  /// it agrees.
  public static func projectVersion(projectFileText: String) -> String? {
    // #/…/# because bare /…/ regex literals need Swift 6 mode here.
    let pattern = #/"CURRENT_PROJECT_VERSION"\s*:\s*"([^"]*)"/#
    let values = Set(projectFileText.matches(of: pattern).map { String($0.output.1) })
    return values.count == 1 ? values.first : nil
  }

  /// Why a build can't be tested, or nil if it can: its build number
  /// (`CFBundleVersion`) must match the project's.
  public static func versionMismatch(built: String?, project: String?) -> String? {
    guard let project else {
      return "Couldn't read CURRENT_PROJECT_VERSION from the project, so the build can't be checked."
    }
    guard let built else {
      return "The build has no CFBundleVersion; the project says \(project)."
    }
    guard built == project else {
      return "The newest build is number \(built), but the project says \(project). Build again first."
    }
    return nil
  }
}
