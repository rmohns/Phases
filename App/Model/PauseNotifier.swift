import UserNotifications

private let diagLog = Diagnostics.logger("store")

/// [D-outside-change-notice] The one notification when Phases pauses for a
/// wallpaper picked elsewhere, with a Resume action. Permission is asked the
/// first time it's needed, not at launch.
@MainActor
final class PauseNotifier: NSObject, UNUserNotificationCenterDelegate {
  nonisolated private static let category = "outsideChangePause"
  nonisolated private static let resumeAction = "resume"

  /// Called when Resume is chosen in the notification.
  var onResume: (() -> Void)?

  private var center: UNUserNotificationCenter { .current() }

  override init() {
    super.init()
    center.delegate = self
    let resume = UNNotificationAction(identifier: Self.resumeAction, title: "Resume")
    center.setNotificationCategories([
      UNNotificationCategory(identifier: Self.category, actions: [resume], intentIdentifiers: [])
    ])
  }

  func notifyPaused() {
    Task {
      do {
        guard try await center.requestAuthorization(options: [.alert]) else {
          diagLog.log("notification not allowed")
          return
        }
        let content = UNMutableNotificationContent()
        content.title = "Phases paused"
        content.body = "You chose a new wallpaper in System Settings. Phases won't change it until you resume."
        content.categoryIdentifier = Self.category
        try await center.add(UNNotificationRequest(identifier: Self.category, content: content, trigger: nil))
      } catch {
        diagLog.log("notification failed: \(error.localizedDescription, privacy: .public)")
      }
    }
  }

  /// Takes the notification away once Phases is no longer paused for it.
  func withdraw() {
    center.removeDeliveredNotifications(withIdentifiers: [Self.category])
  }

  nonisolated func userNotificationCenter(
    _ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse
  ) async {
    guard response.actionIdentifier == Self.resumeAction else { return }
    await MainActor.run { onResume?() }
  }

  /// Shown even while Phases' window is in front.
  nonisolated func userNotificationCenter(
    _ center: UNUserNotificationCenter, willPresent notification: UNNotification
  ) async -> UNNotificationPresentationOptions {
    [.banner]
  }
}
