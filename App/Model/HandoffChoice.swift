import Foundation

/// [D-close-stays-here] Which app gets focus when the Phases window closes:
/// the owner of the frontmost ordinary window on the current Space, or
/// Finder if there's none. Pure, so it's unit-tested.
enum HandoffChoice {
  /// One entry from the on-screen window list, front to back.
  struct Window {
    var ownerPID: Int32
    var layer: Int
    var alpha: Double
    var width: Double
    var height: Double
  }

  /// Smaller windows are helpers and overlays, not something to hand off to.
  static let minimumSide = 50.0

  static func target(windows: [Window], excluding ownPID: Int32, finderPID: Int32?) -> Int32? {
    let candidate = windows.first {
      $0.ownerPID != ownPID && $0.layer == 0 && $0.alpha > 0
        && $0.width >= minimumSide && $0.height >= minimumSide
    }
    return candidate?.ownerPID ?? finderPID
  }
}
