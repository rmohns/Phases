import AppKit

/// One display's new wallpaper.
struct WallpaperAssignment {
  var screen: NSScreen
  var url: URL
}

/// Applies images to the current Space on each display.
@MainActor
enum WallpaperSetter {
  /// Keeps each screen's existing fill/scaling options.
  ///
  /// [D-no-focus-steal] Never activates Phases to force a menu bar restyle;
  /// that would steal focus from the user's app.
  static func apply(_ assignments: [WallpaperAssignment]) {
    for assignment in assignments {
      let options = NSWorkspace.shared.desktopImageOptions(for: assignment.screen) ?? [:]
      do {
        try NSWorkspace.shared.setDesktopImageURL(assignment.url, for: assignment.screen, options: options)
      } catch {
        NSLog("Phases: couldn't set \(assignment.url.lastPathComponent) on \(assignment.screen.localizedName): \(error)")
      }
    }
  }
}
