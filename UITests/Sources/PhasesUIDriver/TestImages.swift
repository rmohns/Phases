import AppKit

/// A folder of plain colored PNGs for test mode's image folder
/// [D-ui-test-mode]. Its long name exercises the folder name's middle
/// truncation in Settings.
public enum TestImages {
  /// About 150 characters: too long for the Settings row at any likely
  /// window width, so the middle truncation shows.
  public static let folderName =
    "Phases UI Test Images in a Folder With a Deliberately Long Name So That the Settings Row Has to Truncate It in the Middle Even in a Wide Window"
  public static let count = 60

  /// Creates the folder once per run, in the temporary directory.
  public static let folder: URL = {
    let url = makeFolder(named: folderName)
    for index in 0..<count {
      let name = String(format: "Test Image %02d.png", index + 1)
      try? png(hue: Double(index) / Double(count))?.write(to: url.appending(path: name))
    }
    return url
  }()

  /// A second, small folder for the multi-source tests [D-image-sources]:
  /// `secondCount` images at its top level and `nestedCount` more in a
  /// subfolder named `nestedFolderName`, so it has `secondCount` images
  /// with subfolders off and `secondCount + nestedCount` with them on.
  public static let secondFolderName = "Phases UI Test Second Folder"
  public static let secondCount = 4
  public static let nestedFolderName = "Nested"
  public static let nestedCount = 2

  /// Made once per run, in the same temporary parent as `folder`. Hues are
  /// spread so the images are told apart at a glance.
  public static let secondFolder: URL = {
    let url = makeFolder(named: secondFolderName)
    for index in 0..<secondCount {
      let name = String(format: "Second Image %02d.png", index + 1)
      try? png(hue: 0.05 + Double(index) * 0.25)?.write(to: url.appending(path: name))
    }
    let nested = url.appending(path: nestedFolderName, directoryHint: .isDirectory)
    try? FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
    for index in 0..<nestedCount {
      let name = String(format: "Nested Image %02d.png", index + 1)
      try? png(hue: 0.15 + Double(index) * 0.5)?.write(to: nested.appending(path: name))
    }
    return url
  }()

  /// [D-fake-photos] The fake Photos library for the Photos sources tests,
  /// for `-PhasesUITestPhotos`. Each subfolder is an album, a subfolder
  /// of subfolders is a folder of albums, and `Shared` holds shared albums:
  /// `Beach` (3), `Mountains` (2), `Trips` holding `Iceland` (2) and
  /// `Japan` (1), `Empty` (none), and `Shared/Family` (2).
  public enum Photos {
    public static let beach = "Beach"
    public static let beachCount = 3
    public static let mountains = "Mountains"
    public static let mountainsCount = 2
    public static let trips = "Trips"
    public static let iceland = "Iceland"
    public static let icelandCount = 2
    public static let japan = "Japan"
    public static let japanCount = 1
    /// What the Trips folder holds in all.
    public static let tripsCount = icelandCount + japanCount
    public static let empty = "Empty"
    public static let family = "Family"
    public static let familyCount = 2

    /// Made once per run, in the same temporary parent as `folder`.
    public static let library: URL = {
      let root = TestImages.makeFolder(named: "Phases UI Test Photos Library")
      func album(_ path: [String], count: Int, hue: Double) {
        var url = root
        for part in path { url = url.appending(path: part, directoryHint: .isDirectory) }
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        for index in 0..<count {
          let name = String(format: "%@ %02d.png", path.last ?? "Photo", index + 1)
          try? TestImages.png(hue: hue + Double(index) * 0.07)?.write(to: url.appending(path: name))
        }
      }
      album([beach], count: beachCount, hue: 0.55)
      album([mountains], count: mountainsCount, hue: 0.35)
      album([trips, iceland], count: icelandCount, hue: 0.5)
      album([trips, japan], count: japanCount, hue: 0.95)
      album([empty], count: 0, hue: 0)
      album(["Shared", family], count: familyCount, hue: 0.1)
      return root
    }()
  }

  /// An empty folder with this name under the run's temporary parent.
  private static func makeFolder(named name: String) -> URL {
    let url = FileManager.default.temporaryDirectory
      .appending(path: "PhasesUITests", directoryHint: .isDirectory)
      .appending(path: name, directoryHint: .isDirectory)
    try? FileManager.default.removeItem(at: url)
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
  }

  private static func png(hue: Double) -> Data? {
    guard let rep = NSBitmapImageRep(
      bitmapDataPlanes: nil, pixelsWide: 160, pixelsHigh: 100, bitsPerSample: 8, samplesPerPixel: 4,
      hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    ) else { return nil }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSColor(hue: hue, saturation: 0.6, brightness: 0.85, alpha: 1).setFill()
    NSRect(x: 0, y: 0, width: 160, height: 100).fill()
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])
  }
}
