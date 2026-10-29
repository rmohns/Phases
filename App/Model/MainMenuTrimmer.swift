import AppKit
import os

// [D-diagnostics-switch] Off unless diagnostics are switched on at launch.
private let diagLog = Diagnostics.logger("menu")

/// [D-app-menu] [Q-view-menu-fullscreen] Removes the View menu that's left
/// holding only Enter Full Screen once SwiftUI's sidebar and toolbar items
/// are gone. Workaround: ERRATA.md "View menu removal".
@MainActor
final class MainMenuTrimmer {
  static let shared = MainMenuTrimmer()

  private var mainMenuObservation: NSKeyValueObservation?
  private var addItemObserver: NSObjectProtocol?

  /// Trims now and keeps trimming whenever the menu bar changes. Event-driven,
  /// no polling. Safe to call more than once.
  func start() {
    trimSoon()
    guard mainMenuObservation == nil else { return }
    mainMenuObservation = NSApp.observe(\.mainMenu) { _, _ in
      MainActor.assumeIsolated { MainMenuTrimmer.shared.trimSoon() }
    }
    // Items added to the menu bar, or to one of its menus (macOS adds Enter
    // Full Screen to the View menu after SwiftUI builds it).
    addItemObserver = NotificationCenter.default.addObserver(
      forName: NSMenu.didAddItemNotification, object: nil, queue: .main
    ) { note in
      MainActor.assumeIsolated {
        guard let menu = note.object as? NSMenu, let mainMenu = NSApp.mainMenu,
              menu === mainMenu || menu.supermenu === mainMenu
        else { return }
        MainMenuTrimmer.shared.trimSoon()
      }
    }
  }

  /// A pass later, so the menu isn't changed while it's being built.
  private func trimSoon() {
    DispatchQueue.main.async { [weak self] in self?.trim() }
  }

  private func trim() {
    guard let mainMenu = NSApp.mainMenu else { return }
    for item in mainMenu.items where Self.holdsOnlyFullScreen(item.submenu) {
      diagLog.log("removing menu \(item.title, privacy: .public)")
      mainMenu.removeItem(item)
    }
  }

  /// Picked by contents, not title, so it works in any language.
  private static func holdsOnlyFullScreen(_ menu: NSMenu?) -> Bool {
    guard let menu, menu !== NSApp.windowsMenu, menu !== NSApp.helpMenu else { return false }
    let items = menu.items.filter { !$0.isSeparatorItem }
    return !items.isEmpty && items.allSatisfy { $0.action == #selector(NSWindow.toggleFullScreen(_:)) }
  }
}
