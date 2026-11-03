import SwiftUI

/// The menu bar icon. Also opens the window on a relaunch while running
/// [D-reopen-shows-window]: it's the one view alive while the window is
/// closed.
struct MenuBarLabel: View {
  @Environment(\.openWindow) private var openWindow

  var body: some View {
    Image(nsImage: Self.icon)
      .accessibilityLabel("Phases")
      .onReceive(NotificationCenter.default.publisher(for: .phasesRelaunched)) { _ in
        openWindow.showPhasesWindow()
      }
  }

  /// [D-menubar-icon] Solid shapes, drawn at 20 pt as a template so macOS
  /// colors it for light and dark menu bars.
  private static let icon: NSImage = {
    let image = NSImage(named: "MenuBarIcon") ?? NSImage()
    image.size = NSSize(width: 20, height: 20)
    image.isTemplate = true
    return image
  }()
}
