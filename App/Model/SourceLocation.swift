import Foundation

/// [D-source-location] A source folder's location as Phases saves and shows
/// it: `~/…` inside the home folder, the full path outside it. "Home" is the
/// user's real home folder, never a sandbox container. No AppKit, so the
/// unit tests can reach it.
enum SourceLocation {
  /// The user's real home folder, from the user database. In a sandboxed
  /// app `homeDirectoryForCurrentUser` points into the app's container
  /// instead (LEARNINGS.md `[L-sandbox-x0-paths]`).
  static let realHome: URL = {
    if let entry = getpwuid(getuid()), let dir = entry.pointee.pw_dir {
      return URL(filePath: String(cString: dir), directoryHint: .isDirectory)
    }
    return FileManager.default.homeDirectoryForCurrentUser
  }()

  /// `~/Pictures/Wallpapers` for a folder in `home`, otherwise its full path.
  static func string(for url: URL, home: URL = realHome) -> String {
    let path = normalized(url.path(percentEncoded: false))
    let homePath = normalized(home.path(percentEncoded: false))
    if path == homePath { return "~" }
    if path.hasPrefix(homePath + "/") {
      return "~" + path.dropFirst(homePath.count)
    }
    return path
  }

  /// The folder a saved location names, with `~` meaning `home`.
  static func url(for location: String, home: URL = realHome) -> URL {
    let path: String
    if location == "~" {
      path = home.path(percentEncoded: false)
    } else if location.hasPrefix("~/") {
      path = normalized(home.path(percentEncoded: false)) + location.dropFirst()
    } else {
      path = location
    }
    return URL(filePath: path, directoryHint: .isDirectory)
  }

  /// Without a trailing slash, except for "/" itself.
  private static func normalized(_ path: String) -> String {
    var path = path
    while path.count > 1, path.hasSuffix("/") { path.removeLast() }
    return path
  }
}
