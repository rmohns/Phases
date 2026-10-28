import Foundation

/// Which phase the sidebar selects after a change to the phase list.
enum PhaseListSelection {
  /// The phase to select after deleting `id` from `ordered` (the time-sorted
  /// list before the delete) `[D-delete-selects-next]`: the one that takes the
  /// deleted phase's place, or the one above if it was last. Nil when no
  /// phases are left.
  static func afterDeleting(_ id: Phase.ID, from ordered: [Phase.ID]) -> Phase.ID? {
    let index = ordered.firstIndex(of: id) ?? 0
    let remaining = ordered.filter { $0 != id }
    guard !remaining.isEmpty else { return nil }
    return remaining[min(index, remaining.count - 1)]
  }
}
