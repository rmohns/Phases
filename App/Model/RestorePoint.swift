import AppKit

/// The wallpaper each display had before Phases changed anything, restored
/// when Phases quits. Saved to disk so a crash or Force Quit doesn't cause
/// Phases' own wallpaper to be recorded as the original on the next launch.
struct RestorePoint: Codable, Equatable {
  var displays: [DisplayWallpaper]

  struct DisplayWallpaper: Codable, Equatable {
    var displayID: CGDirectDisplayID
    var imageURL: URL?
    /// True for Aerials and other non-image wallpapers, which can't be put back
    /// through the public API. These displays are left alone on quit.
    var isSystemWallpaper: Bool
    var scaling: Int?
    var allowsClipping: Bool?
    /// sRGB components of the fill color, if any.
    var fillColor: [Double]?
  }

  @MainActor
  static func capture() -> RestorePoint {
    let workspace = NSWorkspace.shared
    let screens = NSScreen.screens.compactMap { screen in screen.displayID.map { (screen, $0) } }
    let system = SystemWallpaperInspector.displaysWithSystemWallpaper(screens.map(\.1))
    return RestorePoint(displays: screens.map { screen, displayID in
      let options = workspace.desktopImageOptions(for: screen) ?? [:]
      let color = (options[.fillColor] as? NSColor)?.usingColorSpace(.sRGB)
      return DisplayWallpaper(
        displayID: displayID,
        imageURL: workspace.desktopImageURL(for: screen),
        isSystemWallpaper: system.contains(displayID),
        scaling: (options[.imageScaling] as? NSNumber)?.intValue,
        allowsClipping: (options[.allowClipping] as? NSNumber)?.boolValue,
        fillColor: color.map { [$0.redComponent, $0.greenComponent, $0.blueComponent, $0.alphaComponent] }
      )
    })
  }

  /// Displays whose original wallpaper couldn't be restored.
  var systemWallpaperCount: Int {
    displays.filter(\.isSystemWallpaper).count
  }

  @MainActor
  func restore() {
    for screen in NSScreen.screens {
      guard let displayID = screen.displayID,
        let original = displays.first(where: { $0.displayID == displayID }),
        !original.isSystemWallpaper,
        let url = original.imageURL,
        FileManager.default.fileExists(atPath: url.path(percentEncoded: false))
      else { continue }

      var options: [NSWorkspace.DesktopImageOptionKey: Any] = [:]
      if let scaling = original.scaling { options[.imageScaling] = scaling }
      if let allowsClipping = original.allowsClipping { options[.allowClipping] = allowsClipping }
      if let c = original.fillColor, c.count == 4 {
        options[.fillColor] = NSColor(srgbRed: c[0], green: c[1], blue: c[2], alpha: c[3])
      }
      try? NSWorkspace.shared.setDesktopImageURL(url, for: screen, options: options)
    }
  }
}
