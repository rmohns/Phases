import Foundation

/// What the scheduler's normal check does with what's already applied. Pure,
/// so the unit tests can test it. Screen changes run this same check
/// [D-screen-change-no-reroll].
enum WallpaperCheck {
  enum Action: Equatable {
    /// A new phase occurrence or a rotation due: the next images
    /// [D-in-order-remembers].
    case advance
    /// Same occurrence and slot, but a display shows an image that isn't in
    /// its selection (or nothing): replace just those.
    case repair
    /// Same images; only record the occurrence's shifted start.
    case updateStart
    case nothing
  }

  /// - Parameter pools: each connected display's available images.
  static func action(
    applied state: AppliedState?, phaseID: UUID, start: Date, slot: Int, pools: [String: [String]]
  ) -> Action {
    guard let state, isSameOccurrence(state, phaseID: phaseID, start: start) else {
      return .advance
    }
    // [D-missed-latest-only] However many rotations were missed, one change.
    if state.rotationSlot != slot { return .advance }
    if !imagesStillSelected(state, pools: pools) { return .repair }
    return state.phaseStart != start ? .updateStart : .nothing
  }

  /// A phase occurs at most once a day, so a small shift in its start time
  /// (a location update nudging dusk) is still the same occurrence.
  static func isSameOccurrence(_ state: AppliedState, phaseID: UUID, start: Date) -> Bool {
    state.phaseID == phaseID && abs(state.phaseStart.timeIntervalSince(start)) < 6 * 3600
  }

  /// Whether every connected display shows an image from its current pool,
  /// and displays with no image have nothing to show. Catches edited
  /// selections, deleted files, and newly connected displays.
  static func imagesStillSelected(_ state: AppliedState, pools: [String: [String]]) -> Bool {
    for (uuid, pool) in pools {
      if let shown = state.imagesByDisplay[uuid] {
        if !pool.contains(shown) { return false }
      } else if !pool.isEmpty {
        return false
      }
    }
    return true
  }
}
