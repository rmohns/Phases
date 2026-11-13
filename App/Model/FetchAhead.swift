import Foundation

/// [D-photos-fetch-ahead] When to fetch photos ahead of a scheduled change,
/// how long a change waits for one, and what a display shows instead when
/// a photo can't be fetched. Pure, so the unit tests can reach it.
enum FetchAhead {
  /// How far ahead of a scheduled change its photos are picked and fetched.
  static let lead: TimeInterval = 2 * 60
  /// How long a change waits for a photo still being fetched.
  static let waitLimit: TimeInterval = 30

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
  /// `failed`, wrapping; Random any one on hand, avoiding what the display
  /// is showing where it can. Nil if nothing is on hand: the display keeps
  /// its wallpaper.
  static func replacement(
    for failed: String, in pool: [String], onHand: Set<String>, order: ImageOrder, showing: Set<String>
  ) -> String? {
    let usable = pool.filter { $0 != failed && onHand.contains($0) }
    guard !usable.isEmpty else { return nil }
    switch order {
    case .inOrder:
      // [D-in-order-remembers] Never what the display is showing, unless
      // it's the only one on hand.
      let start = pool.firstIndex(of: failed) ?? (pool.count - 1)
      let after = (1...pool.count).map { pool[(start + $0) % pool.count] }.filter(usable.contains)
      return after.first { !showing.contains($0) } ?? after.first
    case .random:
      return RandomPicker.shared(from: usable, showing: [showing])
    }
  }
}
