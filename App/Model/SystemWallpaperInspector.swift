import CoreGraphics
import Foundation

private let diagLog = Diagnostics.logger("restore")

/// [D-aerials-untouched] Reads (never writes) macOS's wallpaper store to tell whether a display is
/// showing an image or a system wallpaper such as an Aerial. The public API
/// only reports a file path, which for Aerials is a still frame. The
/// decisions are in `SystemWallpaperCheck`, which the unit tests reach.
enum SystemWallpaperInspector {
  /// Each display's wallpaper kind. [D-store-unreadable-safe] Every display
  /// is `.unchecked` if the store can't be read.
  static func kinds(_ displayIDs: [CGDirectDisplayID]) -> [CGDirectDisplayID: WallpaperKind] {
    // [Q-sandbox-container-home] The real home; the sandbox exception
    // [D-sandbox-entitlements] lets Phases read it there.
    let url = SystemWallpaperCheck.storeFile()
    let data: Data?
    do {
      data = try Data(contentsOf: url)
    } catch {
      diagLog.log("can't read the wallpaper store: \(error.localizedDescription, privacy: .public)")
      data = nil
    }
    let displays = Dictionary(displayIDs.map { ($0, DisplayIdentity.uuid(for: $0)) }, uniquingKeysWith: { a, _ in a })
    return SystemWallpaperCheck.kinds(storeData: data, displays: displays)
  }
}
