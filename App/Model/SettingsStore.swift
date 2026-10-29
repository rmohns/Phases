import Foundation

/// Where Phases keeps its settings: the standard defaults, or in test mode
/// a separate store erased at launch, so UI tests never read or change the
/// user's phases [D-ui-test-mode].
enum SettingsStore {
  static let defaults: UserDefaults = {
    guard UITestMode.isOn else { return .standard }
    let name = (Bundle.main.bundleIdentifier ?? "Phases") + ".uitest"
    UserDefaults.standard.removePersistentDomain(forName: name)
    return UserDefaults(suiteName: name) ?? .standard
  }()
}
