import Foundation

/// [D-record-after-wait] The saved record of what's showing, and a change
/// waiting on photos. Only `saved` is persisted, so a crash during the wait
/// loses just the pending change. Pure, so the unit tests can test it.
struct ChangeRecord: Equatable {
  /// What's on screen; the only part that's saved.
  var saved: AppliedState?
  /// A change that has picked its images but isn't showing yet.
  var pending: AppliedState?

  /// What the checks compare against: the pending change if there is one,
  /// so a check during the wait doesn't start a second change for the same
  /// slot [D-screen-change-no-reroll].
  var current: AppliedState? { pending ?? saved }

  /// A change starts: its picks wait in memory. A newer change replaces an
  /// older one still waiting.
  mutating func begin(_ change: AppliedState) {
    pending = change
  }

  /// The change shows. `shown` is what each display got: a replacement
  /// image, or nil for a display that keeps its wallpaper, whose record
  /// keeps the planned pick so later checks don't apply again
  /// [D-photos-fetch-ahead].
  mutating func finish(shown: [String: String?]) {
    guard var state = pending else { return }
    for (uuid, name) in shown {
      if let name { state.imagesByDisplay[uuid] = name }
    }
    saved = state
    pending = nil
  }

  /// The waiting change stands down (Pause, or its phase stopped running);
  /// the record still names what's on screen.
  mutating func dropPending() {
    pending = nil
  }

  /// Records a shifted phase start on whichever change the checks see.
  mutating func updateStart(_ start: Date) {
    if pending != nil {
      pending?.phaseStart = start
    } else {
      saved?.phaseStart = start
    }
  }
}
