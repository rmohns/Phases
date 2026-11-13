import Foundation
import Testing
@testable import PhasesLogic

/// The scheduler's normal check, which screen changes also run
/// `[D-screen-change-no-reroll]` `[D-missed-latest-only]`.
struct WallpaperCheckTests {
  private let phase = UUID()
  private let start = Date(timeIntervalSinceReferenceDate: 800_000_000)

  private func state(slot: Int = 0, images: [String: String] = ["A": "1.jpg"]) -> AppliedState {
    AppliedState(phaseID: phase, phaseStart: start, rotationSlot: slot, imagesByDisplay: images)
  }

  @Test func screenChangeWithEveryImageStillSelectedChangesNothing() {
    // Hiding the Dock: same displays, same images, same slot.
    let action = WallpaperCheck.action(
      applied: state(), phaseID: phase, start: start, slot: 0, pools: ["A": ["1.jpg", "2.jpg"]]
    )
    #expect(action == .nothing)
  }

  @Test func newDisplayWithImagesGetsOne() {
    let action = WallpaperCheck.action(
      applied: state(), phaseID: phase, start: start, slot: 0, pools: ["A": ["1.jpg"], "B": ["1.jpg"]]
    )
    #expect(action == .repair)
  }

  @Test func relaunchAfterARestoringQuitRepairsWithinTheSameRotation() {
    // Quit restored the original and forgot what Phases showed
    // [D-restore-on-quit]; a relaunch in the same minute puts it back.
    let action = WallpaperCheck.action(
      applied: state(images: [:]), phaseID: phase, start: start, slot: 0, pools: ["A": ["1.jpg", "2.jpg"]]
    )
    #expect(action == .repair)
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
    #expect(action == .repair)
  }

  @Test func missedRotationsMakeOneAdvance() {
    let action = WallpaperCheck.action(
      applied: state(slot: 1), phaseID: phase, start: start, slot: 4, pools: ["A": ["1.jpg"]]
    )
    #expect(action == .advance)
  }

  @Test func shiftedStartIsTheSameOccurrence() {
    let action = WallpaperCheck.action(
      applied: state(), phaseID: phase, start: start.addingTimeInterval(600), slot: 0, pools: ["A": ["1.jpg"]]
    )
    #expect(action == .updateStart)
  }

  @Test func differentPhaseOrNoStateApplies() {
    #expect(WallpaperCheck.action(applied: nil, phaseID: phase, start: start, slot: 0, pools: [:]) == .advance)
    #expect(
      WallpaperCheck.action(applied: state(), phaseID: UUID(), start: start, slot: 0, pools: ["A": ["1.jpg"]])
        == .advance
    )
  }
}
