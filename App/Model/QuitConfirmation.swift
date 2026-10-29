import AppKit

/// [D-quit-confirm] Asks before Quit Phases, since ⌘Q is easy to press
/// meaning "close the window".
@MainActor
enum QuitConfirmation {
  /// Shows the alert, unless the person has turned it off, and records
  /// "Don't ask again".
  static func ask(scheduler: WallpaperScheduler) -> QuitChoice {
    guard scheduler.asksBeforeQuitting else { return .quit }

    let alert = NSAlert()
    alert.messageText = "Quit Phases?"
    alert.informativeText = [
      "Your wallpaper will stop changing on schedule.",
      scheduler.restoresWallpaperOnQuit
        ? "The wallpaper you had before Phases started will be put back."
        : "The current wallpaper will stay.",
      "To keep Phases running in the menu bar, close its window instead.",
    ].joined(separator: " ")
    alert.addButton(withTitle: "Quit")
    alert.addButton(withTitle: "Keep in Menu Bar")
    // NSAlert gives a button titled "Cancel" the Esc key.
    alert.addButton(withTitle: "Cancel")
    alert.showsSuppressionButton = true
    alert.suppressionButton?.title = "Don't ask again"

    switch alert.runModal() {
    case .alertFirstButtonReturn:
      if alert.suppressionButton?.state == .on { scheduler.asksBeforeQuitting = false }
      return .quit
    case .alertSecondButtonReturn:
      return .keepInMenuBar
    default:
      return .cancel
    }
  }
}

/// The answer to "Quit Phases?".
enum QuitChoice {
  case quit
  /// Close the window; Phases keeps running in the menu bar.
  case keepInMenuBar
  case cancel
}
