import Foundation

/// [D-ui-test-mode] One launch for UI tests that touches nothing real: no
/// wallpaper changes, a throwaway settings store seeded with fixed phases,
/// and an image folder chosen by the test harness. Launch arguments only,
/// so it can't leak into normal use.
enum UITestMode {
  static let isOn = UserDefaults.standard.bool(forKey: "PhasesUITestMode")

  /// `-PhasesUITestFirstLaunch YES` makes a test-mode launch a first launch
  /// [D-first-launch-shows-window]; otherwise test mode never is.
  static let forcesFirstLaunch = UserDefaults.standard.bool(forKey: "PhasesUITestFirstLaunch")

  /// The harness's image folders, from `-PhasesUITestImages <path>` or a
  /// list, `-PhasesUITestImages '("<path 1>", "<path 2>")'`, in that order
  /// [D-image-sources].
  static var imageFolders: [URL] {
    let defaults = UserDefaults.standard
    let paths = defaults.stringArray(forKey: "PhasesUITestImages")
      ?? defaults.string(forKey: "PhasesUITestImages").map { [$0] }
      ?? []
    return paths.map { URL(filePath: $0, directoryHint: .isDirectory) }
  }

  /// The harness's folders as sources, with fixed IDs (`TESTSRC2`,
  /// `TESTSRC3`, …) and no bookmarks. Never saved.
  static var imageSources: [ImageSource] {
    imageFolders.prefix(8).enumerated().map { index, url in
      ImageSource(id: "TESTSRC\(index + 2)", bookmark: nil, location: SourceLocation.string(for: url))
    }
  }

  /// [D-fake-photos] The fake Photos library's folder, from
  /// `-PhasesUITestPhotos <path>`. Without it, test mode has no Photos
  /// library at all and never asks for access.
  static var photosFolder: URL? {
    UserDefaults.standard.string(forKey: "PhasesUITestPhotos").map { URL(filePath: $0, directoryHint: .isDirectory) }
  }

  /// `-PhasesUITestPhotosDenied YES`: the fake library refuses access.
  static let photosRefused = UserDefaults.standard.bool(forKey: "PhasesUITestPhotosDenied")

  /// Three clock-time phases, in order through the day, so tests can
  /// delete a middle one [D-delete-selects-next].
  static var fixturePhases: [Phase] {
    [
      Phase(name: "Morning", trigger: .clockTime(minutes: 7 * 60)),
      Phase(name: "Afternoon", trigger: .clockTime(minutes: 12 * 60)),
      Phase(name: "Evening", trigger: .clockTime(minutes: 18 * 60)),
    ]
  }
}
