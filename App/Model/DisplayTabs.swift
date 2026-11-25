import Foundation

/// A connected display as the phase editor's tabs need it.
struct ConnectedDisplay: Equatable, Identifiable {
  var uuid: String
  var name: String
  /// The display's size in points as currently arranged, so a rotated
  /// display is taller than it is wide.
  var size: CGSize

  var id: String { uuid }
}

/// [D-display-tabs] Which display tabs the phase editor shows, and what
/// each says. `connected` is in macOS's display order, main display first;
/// only connected displays get a tab [D-connected-displays-only].
enum DisplayTabs {
  /// [D-display-tabs-visibility] The display tabs after Shared, or nil when
  /// the row is hidden: shown for two or more displays, or for one that has
  /// its own images in this phase.
  static func tabs(connected: [ConnectedDisplay], phase: Phase) -> [ConnectedDisplay]? {
    if connected.count > 1 { return connected }
    if let only = connected.first, phase.displayImageNames[only.uuid] != nil { return connected }
    return nil
  }

  /// The tab to show: the chosen display while it has a tab, otherwise
  /// Shared (nil), as when it disconnects with the editor open.
  static func selection(_ chosen: String?, among tabs: [ConnectedDisplay]?) -> String? {
    guard let chosen, tabs?.contains(where: { $0.uuid == chosen }) == true else { return nil }
    return chosen
  }

  /// Shared's caption: its selection count, the same number the count line shows.
  static func sharedCaption(count: Int) -> String {
    images(count)
  }

  /// "Uses Shared", or "Own · 1 image" with the count of its own images.
  static func caption(ownCount: Int?) -> String {
    guard let ownCount else { return "Uses Shared" }
    return "Own · \(images(ownCount))"
  }

  /// [D-sharing-per-phase] The checkbox is dimmed unless at least two
  /// connected displays use the Shared images in this phase.
  static func sharingApplies(connected: [ConnectedDisplay], phase: Phase) -> Bool {
    connected.filter { phase.displayImageNames[$0.uuid] == nil }.count >= 2
  }

  /// [D-display-tab-shapes] The outline for a display: its aspect ratio at
  /// one height, narrowed to fit `maxWidth` when it's very wide.
  static func outlineSize(for size: CGSize, height: CGFloat, maxWidth: CGFloat) -> CGSize {
    guard size.width > 0, size.height > 0 else { return CGSize(width: height * 16 / 10, height: height) }
    let width = height * size.width / size.height
    if width <= maxWidth { return CGSize(width: width, height: height) }
    return CGSize(width: maxWidth, height: maxWidth * size.height / size.width)
  }

  private static func images(_ count: Int) -> String {
    count == 1 ? "1 image" : "\(count) images"
  }
}
