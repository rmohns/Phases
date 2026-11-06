import SwiftUI

/// The menu bar icon. Also opens the window on a relaunch while running
/// [D-reopen-shows-window] and on the first launch
/// [D-first-launch-shows-window]: it's the one view alive while the window
/// is closed.
struct MenuBarLabel: View {
  var isPaused: Bool
  var isFirstLaunch: Bool
  @Environment(\.openWindow) private var openWindow

  var body: some View {
    Image(nsImage: isPaused ? Self.pausedIcon : Self.icon)
      .accessibilityLabel(isPaused ? "Phases, paused" : "Phases")
      // Runs once, when the icon first appears at launch.
      .task {
        // EXPERIMENT ONLY [Q-launch-activate-refused]
        if isFirstLaunch { await FirstLaunchExperiment.open(openWindow) }
      }
      .onReceive(NotificationCenter.default.publisher(for: .phasesRelaunched)) { _ in
        openWindow.showPhasesWindow()
      }
  }

  private static let size = NSSize(width: 20, height: 20)

  /// [D-menubar-icon] Solid shapes, drawn at 20 pt as a template so macOS
  /// colors it for light and dark menu bars.
  private static let icon: NSImage = {
    let image = NSImage(named: "MenuBarIcon") ?? NSImage()
    image.size = size
    image.isTemplate = true
    return image
  }()

  /// [D-menubar-icon-paused] The icon with a pause badge (two bars) at its
  /// lower right, cut out of the icon so it reads at menu bar size.
  private static let pausedIcon: NSImage = {
    let image = NSImage(size: size, flipped: false) { rect in
      icon.draw(in: rect)
      let badge = NSRect(x: 11, y: 0, width: 9, height: 9)
      NSGraphicsContext.current?.compositingOperation = .clear
      NSBezierPath(ovalIn: badge.insetBy(dx: -1.5, dy: -1.5)).fill()
      NSGraphicsContext.current?.compositingOperation = .sourceOver
      NSColor.black.setFill()
      for x in [badge.minX + 2, badge.minX + 5] {
        NSBezierPath(roundedRect: NSRect(x: x, y: badge.minY + 1.5, width: 2, height: 6), xRadius: 0.75, yRadius: 0.75).fill()
      }
      return true
    }
    image.isTemplate = true
    return image
  }()
}
