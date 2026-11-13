import Foundation

/// [D-version-in-settings] What tells one build of Phases from another.
enum AppVersion {
  /// The SPEC.md draft this build was made against: the build number, set
  /// as `CURRENT_PROJECT_VERSION` in Project.json. A unit test checks it
  /// against the spec's title.
  static var specDraft: String {
    Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
  }

  /// "0.1 (47)": the app's version and build number.
  static var versionAndBuild: String {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    return "\(version) (\(specDraft))"
  }

  /// When this copy of the app was built: its executable's modification date.
  static var buildDate: Date? {
    guard let url = Bundle.main.executableURL else { return nil }
    return (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
  }
}
