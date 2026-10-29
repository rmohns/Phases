import Foundation

/// [D-version-in-settings] What tells one build of Phases from another.
enum AppVersion {
  /// The SPEC.md draft this build was made against. Bump with the spec's
  /// title; a unit test checks they match.
  static let specDraft = 24

  /// "1.0 (1)": the app's version and build number.
  static var versionAndBuild: String {
    let info = Bundle.main.infoDictionary ?? [:]
    let version = info["CFBundleShortVersionString"] as? String ?? "?"
    let build = info["CFBundleVersion"] as? String ?? "?"
    return "\(version) (\(build))"
  }

  /// When this copy of the app was built: its executable's modification date.
  static var buildDate: Date? {
    guard let url = Bundle.main.executableURL else { return nil }
    return (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
  }
}
