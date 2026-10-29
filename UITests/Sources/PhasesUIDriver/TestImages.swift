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
    let url = FileManager.default.temporaryDirectory
      .appending(path: "PhasesUITests", directoryHint: .isDirectory)
      .appending(path: folderName, directoryHint: .isDirectory)
    try? FileManager.default.removeItem(at: url)
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    for index in 0..<count {
      let name = String(format: "Test Image %02d.png", index + 1)
      try? png(hue: Double(index) / Double(count))?.write(to: url.appending(path: name))
    }
    return url
  }()

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
