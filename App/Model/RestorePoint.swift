import AppKit

private let diagLog = Diagnostics.logger("restore")

/// The wallpaper each display had before Phases changed anything, restored
/// when Phases quits. Saved to disk so a crash or Force Quit doesn't cause
/// Phases' own wallpaper to be recorded as the original on the next launch.
struct RestorePoint: Codable, Equatable {
  var displays: [DisplayWallpaper]

  struct DisplayWallpaper: Codable, Equatable {
    var displayID: CGDirectDisplayID
    var imageURL: URL?
    /// True for anything Quit must leave alone: Aerials and other non-image
    /// wallpapers, which can't be put back through the public API, and
    /// (from draft 58) wallpapers that couldn't be checked
    /// [D-store-unreadable-safe]. Kept so records stay readable by older
    /// builds, which then leave unchecked displays alone too.
    var isSystemWallpaper: Bool
    /// Draft 58 and later. Nil in records saved earlier.
    var kind: WallpaperKind?
    var scaling: Int?
    var allowsClipping: Bool?
    /// sRGB components of the fill color, if any.
    var fillColor: [Double]?

    /// The kind, for records from any draft.
    var wallpaperKind: WallpaperKind {
      kind ?? (isSystemWallpaper ? .system : .image)
    }
  }

  @MainActor
  static func capture() -> RestorePoint {
    let workspace = NSWorkspace.shared
    let screens = NSScreen.screens.compactMap { screen in screen.displayID.map { (screen, $0) } }
    let kinds = SystemWallpaperInspector.kinds(screens.map(\.1))
    return RestorePoint(displays: screens.map { screen, displayID in
      let options = workspace.desktopImageOptions(for: screen) ?? [:]
      let color = (options[.fillColor] as? NSColor)?.usingColorSpace(.sRGB)
      // [D-store-unreadable-safe] No answer counts as unchecked.
      let kind = kinds[displayID] ?? .unchecked
      return DisplayWallpaper(
        displayID: displayID,
        imageURL: workspace.desktopImageURL(for: screen),
        isSystemWallpaper: kind != .image,
        kind: kind,
        scaling: (options[.imageScaling] as? NSNumber)?.intValue,
        allowsClipping: (options[.allowClipping] as? NSNumber)?.boolValue,
        fillColor: color.map { [$0.redComponent, $0.greenComponent, $0.blueComponent, $0.alphaComponent] }
      )
    })
  }

  /// [D-outside-change-pauses] This record with the given displays' entries
  /// taken from `fresh`: a wallpaper picked outside Phases becomes that
  /// display's original.
  func replacing(_ displayIDs: Set<CGDirectDisplayID>, from fresh: RestorePoint) -> RestorePoint {
    var result = self
    for display in fresh.displays where displayIDs.contains(display.displayID) {
      result.displays.removeAll { $0.displayID == display.displayID }
      result.displays.append(display)
    }
    return result
  }

  /// Displays whose original wallpaper couldn't be restored.
  var systemWallpaperCount: Int {
    displays.filter(\.isSystemWallpaper).count
  }

  @MainActor
  func restore() {
    // [D-ui-test-mode] Backstop: test mode never records a restore point.
    guard !UITestMode.isOn else { return }
    for screen in NSScreen.screens {
      guard let displayID = screen.displayID,
        let original = displays.first(where: { $0.displayID == displayID })
      else { continue }
      let path = original.imageURL?.path(percentEncoded: false)
      // [D-aerials-untouched] [D-store-unreadable-safe] [D-restore-file-check]
      let action = SystemWallpaperCheck.restoreAction(
        kind: original.wallpaperKind,
        imagePath: path,
        file: path.map(SystemWallpaperCheck.fileState(atPath:)) ?? .missing
      )
      guard action == .restore, let url = original.imageURL else {
        if case .leaveAlone(let reason) = action {
          diagLog.log("display \(displayID) left alone on quit: \(reason.rawValue, privacy: .public)")
        }
        continue
      }

      var options: [NSWorkspace.DesktopImageOptionKey: Any] = [:]
      if let scaling = original.scaling { options[.imageScaling] = scaling }
      if let allowsClipping = original.allowsClipping { options[.allowClipping] = allowsClipping }
      if let c = original.fillColor, c.count == 4 {
        options[.fillColor] = NSColor(srgbRed: c[0], green: c[1], blue: c[2], alpha: c[3])
      }
      do {
        try NSWorkspace.shared.setDesktopImageURL(url, for: screen, options: options)
        diagLog.log("display \(displayID) restored: \(url.lastPathComponent, privacy: .public)")
      } catch {
        diagLog.log("display \(displayID) restore failed: \(error.localizedDescription, privacy: .public)")
      }
    }
  }
}
