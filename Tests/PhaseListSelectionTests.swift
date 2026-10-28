import Foundation
import Testing

/// Selection after deleting a phase `[D-delete-selects-next]`.
struct PhaseListSelectionTests {
  private let a = UUID(), b = UUID(), c = UUID()

  @Test func selectsThePhaseThatTakesItsPlace() {
    #expect(PhaseListSelection.afterDeleting(b, from: [a, b, c]) == c)
    #expect(PhaseListSelection.afterDeleting(a, from: [a, b, c]) == b)
  }

  @Test func selectsThePhaseAboveWhenTheLastIsDeleted() {
    #expect(PhaseListSelection.afterDeleting(c, from: [a, b, c]) == b)
  }

  @Test func selectsNothingWhenNoPhasesAreLeft() {
    #expect(PhaseListSelection.afterDeleting(a, from: [a]) == nil)
  }
}
