import Foundation
import Testing
@testable import PhasesLogic

/// The scheduler's normal check, which screen changes also run
/// `[D-screen-change-no-reroll]` `[D-missed-latest-only]`.
struct WallpaperCheckTests {
  private let phase = UUID()
  private let start = Date(timeIntervalSinceReferenceDate: 800_000_000)

  private func state(slot: Int = 0, steps: Int = 0, images: [String: String] = ["A": "1.jpg"]) -> AppliedState {
    AppliedState(phaseID: phase, phaseStart: start, rotationSlot: slot, manualSteps: steps, imagesByDisplay: images)
  }

  @Test func screenChangeWithEveryImageFittingChangesNothing() {
    // Hiding the Dock: same displays, same images, same slot.
    let action = WallpaperCheck.action(
      applied: state(), phaseID: phase, start: start, slot: 0, pools: ["A": ["1.jpg", "2.jpg"]]
    )
    #expect(action == .nothing)
  }

  @Test func newDisplayWithImagesGetsOne() {
    let action = WallpaperCheck.action(
      applied: state(steps: 2), phaseID: phase, start: start, slot: 0, pools: ["A": ["1.jpg"], "B": ["1.jpg"]]
    )
    #expect(action == .apply(manualSteps: 2))
  }

  @Test func newDisplayWithNothingToShowChangesNothing() {
    let action = WallpaperCheck.action(
      applied: state(), phaseID: phase, start: start, slot: 0, pools: ["A": ["1.jpg"], "B": []]
    )
    #expect(action == .nothing)
  }

  @Test func imageNoLongerInSelectionIsReplaced() {
    let action = WallpaperCheck.action(
      applied: state(), phaseID: phase, start: start, slot: 0, pools: ["A": ["2.jpg"]]
    )
    #expect(action == .apply(manualSteps: 0))
  }

  @Test func missedRotationKeepsChangeNowSteps() {
    let action = WallpaperCheck.action(
      applied: state(slot: 1, steps: 3), phaseID: phase, start: start, slot: 4, pools: ["A": ["1.jpg"]]
    )
    #expect(action == .apply(manualSteps: 3))
  }

  @Test func shiftedStartIsTheSameOccurrence() {
    let action = WallpaperCheck.action(
      applied: state(), phaseID: phase, start: start.addingTimeInterval(600), slot: 0, pools: ["A": ["1.jpg"]]
    )
    #expect(action == .updateStart)
  }

  @Test func differentPhaseOrNoStateApplies() {
    #expect(WallpaperCheck.action(applied: nil, phaseID: phase, start: start, slot: 0, pools: [:]) == .apply(manualSteps: 0))
    #expect(
      WallpaperCheck.action(applied: state(steps: 2), phaseID: UUID(), start: start, slot: 0, pools: ["A": ["1.jpg"]])
        == .apply(manualSteps: 0)
    )
  }
}
