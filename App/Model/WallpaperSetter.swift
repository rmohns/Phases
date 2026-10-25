import AppKit

/// Applies images to the current Space on each display.
@MainActor
enum WallpaperSetter {
  /// Sets `urls[i]` on screen `i`, reusing the last URL if there are fewer
  /// URLs than screens. Keeps each screen's existing fill/scaling options.
  static func apply(_ urls: [URL]) {
    guard let fallback = urls.last else { return }
    for (index, screen) in NSScreen.screens.enumerated() {
      let url = index < urls.count ? urls[index] : fallback
      let options = NSWorkspace.shared.desktopImageOptions(for: screen) ?? [:]
      do {
        try NSWorkspace.shared.setDesktopImageURL(url, for: screen, options: options)
      } catch {
        NSLog("Wallpaper Scheduler: couldn't set \(url.lastPathComponent) on \(screen.localizedName): \(error)")
      }
    }
  }
}
