import Foundation

/// [D-photos-fetch-ahead] When to fetch photos ahead of a scheduled change,
/// how long a change waits for one, and what a display shows instead when
/// a photo can't be fetched. Pure, so the unit tests can reach it.
enum FetchAhead {
  /// How far ahead of a scheduled change its photos are picked and fetched.
  static let lead: TimeInterval = 2 * 60
  /// How long a change waits for a photo still being fetched.
  static let waitLimit: TimeInterval = 30
  /// How long a fetch may go unanswered before it's given up on and asked
  /// again, in case a PhotoKit request never calls back (a possibility the
  /// 2026-11-12 review raised; not seen here).
  static let giveUpAfter: TimeInterval = 5 * 60

  /// The lead for a phase: 2 minutes, or half its rotation interval if
  /// that's shorter.
  static func lead(rotationInterval: TimeInterval?) -> TimeInterval {
    guard let rotationInterval, rotationInterval > 0 else { return lead }
    return min(lead, rotationInterval / 2)
  }

  /// When to fetch for a change at `change`; never before `now`.
  static func fetchDate(forChangeAt change: Date, rotationInterval: TimeInterval?, now: Date) -> Date {
    max(now, change.addingTimeInterval(-lead(rotationInterval: rotationInterval)))
  }

  /// What a display shows instead of `failed`, a photo that couldn't be
  /// fetched: another image from the same `pool` that's on hand, chosen the
  /// way the phase's order would. In order takes the next one on hand after
  /// `failed`, wrapping, never what the display is showing unless it's the
  /// only one; Random any one on hand, avoiding what the display is showing
  /// where it can. Nil if nothing is on hand: the display keeps its
  /// wallpaper. `isOnHand` is asked only until an answer is found, since
  /// asking about a photo costs a PhotoKit lookup and a pool can hold
  /// thousands.
  static func replacement(
    for failed: String, in pool: [String], isOnHand: (String) -> Bool, order: ImageOrder, showing: Set<String>
  ) -> String? {
    guard !pool.isEmpty else { return nil }
    let candidates: [String]
    switch order {
    case .inOrder:
      let start = pool.firstIndex(of: failed) ?? (pool.count - 1)
      candidates = (1...pool.count).map { pool[(start + $0) % pool.count] }
    case .random:
      candidates = pool.shuffled()
    }
    var showingOnHand: String?
    for candidate in candidates where candidate != failed {
      if showing.contains(candidate) {
        // [D-in-order-remembers] Only if nothing else is on hand.
        if showingOnHand == nil, isOnHand(candidate) { showingOnHand = candidate }
        continue
      }
      if isOnHand(candidate) { return candidate }
    }
    return showingOnHand
  }

  static func replacement(
    for failed: String, in pool: [String], onHand: Set<String>, order: ImageOrder, showing: Set<String>
  ) -> String? {
    replacement(for: failed, in: pool, isOnHand: onHand.contains, order: order, showing: showing)
  }
}
