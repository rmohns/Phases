import Observation
import ServiceManagement

/// [D-login-consent] Wraps SMAppService.mainApp, which registers this app as a standard Login
/// Item. It installs no LaunchAgent plist, daemon, or helper. Nothing here
/// runs unless the user explicitly turns it on and confirms.
@MainActor
@Observable
final class LaunchAtLogin {
  private(set) var isEnabled = false
  private(set) var needsApproval = false
  private(set) var lastError: String?

  init() {
    refresh()
  }

  /// Re-reads the status, in case the user changed it in System Settings.
  func refresh() {
    let status = SMAppService.mainApp.status
    isEnabled = status == .enabled
    needsApproval = status == .requiresApproval
  }

  func enable() {
    do {
      try SMAppService.mainApp.register()
      lastError = nil
    } catch {
      lastError = error.localizedDescription
    }
    refresh()
  }

  func disable() {
    do {
      try SMAppService.mainApp.unregister()
      lastError = nil
    } catch {
      lastError = error.localizedDescription
    }
    refresh()
  }

  func openLoginItemsSettings() {
    SMAppService.openSystemSettingsLoginItems()
  }
}
