import Foundation

/// Random order's picks. Pure, so the unit tests can reach it. Each display
/// avoids every image it's showing (what Phases last set there, and what's
/// actually on screen, which differs after a Space switch), so a change is
/// never to the same image when another one is available (issue #10).
enum RandomPicker {
  /// One image shown on every display in the group. Prefers one no display
  /// is showing, then one the fewest are showing.
  static func shared(from pool: [String], showing: [Set<String>]) -> String? {
    pool.shuffled().min { lhs, rhs in
      showing.count { $0.contains(lhs) } < showing.count { $0.contains(rhs) }
    }
  }

  /// One image per display, in the order of `showing`. Each display gets one
  /// it isn't showing where possible, then one no other display gets, then
  /// one no display is showing.
  static func perDisplay(from pool: [String], showing: [Set<String>]) -> [String] {
    guard !pool.isEmpty else { return [] }
    let shownAnywhere = showing.reduce(into: Set<String>()) { $0.formUnion($1) }
    var taken: Set<String> = []
    var picks = Array(repeating: "", count: showing.count)
    // Displays showing something choose first, so a display with nothing to
    // avoid doesn't take the one image another display could change to.
    for index in showing.indices.sorted(by: { !showing[$0].isEmpty && showing[$1].isEmpty }) {
      let own = showing[index]
      let candidates = pool.shuffled()
      let rank = { (name: String) -> Int in
        (own.contains(name) ? 4 : 0) + (taken.contains(name) ? 2 : 0) + (shownAnywhere.contains(name) ? 1 : 0)
      }
      // `min` keeps the first of equals, so ties stay random.
      let name = candidates.min { rank($0) < rank($1) }!
      taken.insert(name)
      picks[index] = name
    }
    return picks
  }
}
