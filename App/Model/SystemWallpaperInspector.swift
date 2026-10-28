import CoreGraphics
import Foundation

/// [D-aerials-untouched] Reads (never writes) macOS's wallpaper store to tell whether a display is
/// showing an image or a system wallpaper such as an Aerial. The public API
/// only reports a file path, which for Aerials is a still frame.
///
/// The store format is undocumented, so this is best-effort: for each display
/// it takes the most recently used desktop entry and checks its provider.
enum SystemWallpaperInspector {
  private static let storeURL = FileManager.default.homeDirectoryForCurrentUser
    .appending(path: "Library/Application Support/com.apple.wallpaper/Store/Index.plist")
  private static let imageProvider = "com.apple.wallpaper.choice.image"

  /// Display IDs whose current wallpaper isn't a plain image. Returns an empty
  /// set if the store can't be read.
  static func displaysWithSystemWallpaper(_ displayIDs: [CGDirectDisplayID]) -> Set<CGDirectDisplayID> {
    guard let data = try? Data(contentsOf: storeURL),
      let store = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
    else { return [] }

    var result: Set<CGDirectDisplayID> = []
    for displayID in displayIDs {
      guard let uuid = DisplayIdentity.uuid(for: displayID) else { continue }
      let entries = desktopEntries(in: store, displayUUID: uuid)
      let latest = entries.max { $0.lastUse < $1.lastUse }
      if let provider = latest?.provider, provider != imageProvider {
        result.insert(displayID)
      }
    }
    return result
  }

  private struct DesktopEntry {
    var provider: String
    var lastUse: Date
  }

  /// Every desktop configuration that could apply to the display: all-displays,
  /// per-display, and per-Space settings.
  private static func desktopEntries(in store: [String: Any], displayUUID: String) -> [DesktopEntry] {
    var containers: [Any?] = [store["AllSpacesAndDisplays"]]
    containers.append((store["Displays"] as? [String: Any])?[displayUUID])
    for case let space as [String: Any] in (store["Spaces"] as? [String: Any])?.values ?? [:].values {
      containers.append(space["Default"])
      containers.append((space["Displays"] as? [String: Any])?[displayUUID])
    }
    return containers.compactMap { container in
      guard let desktop = (container as? [String: Any])?["Desktop"] as? [String: Any],
        let content = desktop["Content"] as? [String: Any],
        let choice = (content["Choices"] as? [[String: Any]])?.first,
        let provider = choice["Provider"] as? String
      else { return nil }
      let lastUse = desktop["LastUse"] as? Date ?? desktop["LastSet"] as? Date ?? .distantPast
      return DesktopEntry(provider: provider, lastUse: lastUse)
    }
  }
}
