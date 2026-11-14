import Foundation
import Testing
@testable import PhasesLogic

/// What's saved, and when, for a change waiting on photos
/// `[D-record-after-wait]` (issue #36).
struct ChangeRecordTests {
  private let phase = UUID()
  private let start = Date(timeIntervalSinceReferenceDate: 800_000_000)

  private func state(slot: Int, images: [String: String]) -> AppliedState {
    AppliedState(phaseID: phase, phaseStart: start, rotationSlot: slot, imagesByDisplay: images)
  }

  /// Slot 0 shows 1.jpg; the rotation to slot 1 picks a photo not yet fetched.
  private func waiting() -> ChangeRecord {
    var record = ChangeRecord(saved: state(slot: 0, images: ["A": "1.jpg"]))
    record.begin(state(slot: 1, images: ["A": "photo"]))
    return record
  }

  @Test func savedRecordIsUnchangedDuringTheWait() {
    // A crash now loses only the pending change; the next launch sees slot 0
    // and makes the change again.
    let record = waiting()
    #expect(record.saved == state(slot: 0, images: ["A": "1.jpg"]))
    let action = WallpaperCheck.action(
      applied: record.saved, phaseID: phase, start: start, slot: 1, pools: ["A": ["1.jpg", "photo"]]
    )
    #expect(action == .advance)
  }

  @Test func checkDuringTheWaitAppliesNothing() {
    // A screen change or wake during the wait [D-screen-change-no-reroll].
    let action = WallpaperCheck.action(
      applied: waiting().current, phaseID: phase, start: start, slot: 1, pools: ["A": ["1.jpg", "photo"]]
    )
    #expect(action == .nothing)
  }

  @Test func changeIsSavedWhenItShows() {
    var record = waiting()
    record.finish(shown: ["A": "photo"])
    #expect(record.saved == state(slot: 1, images: ["A": "photo"]))
    #expect(record.pending == nil)
  }

  @Test func replacementIsSavedInPlaceOfTheMissingPhoto() {
    var record = waiting()
    record.finish(shown: ["A": "2.jpg"])
    #expect(record.saved == state(slot: 1, images: ["A": "2.jpg"]))
  }

  @Test func displayKeepingItsWallpaperRecordsThePlannedPick() {
    // [D-photos-fetch-ahead] Nothing on hand: later checks mustn't apply again.
    var record = waiting()
    record.finish(shown: ["A": nil])
    #expect(record.saved == state(slot: 1, images: ["A": "photo"]))
  }

  @Test func newerChangeReplacesOneStillWaiting() {
    var record = waiting()
    record.begin(state(slot: 2, images: ["A": "other"]))
    #expect(record.pending == state(slot: 2, images: ["A": "other"]))
    #expect(record.saved == state(slot: 0, images: ["A": "1.jpg"]))
  }

  @Test func droppingThePendingChangeLeavesWhatsShowing() {
    // Pause during the wait: resuming must apply again, not trust the picks.
    var record = waiting()
    record.dropPending()
    #expect(record.current == state(slot: 0, images: ["A": "1.jpg"]))
    record.finish(shown: ["A": "photo"])
    #expect(record.saved == state(slot: 0, images: ["A": "1.jpg"]))
  }

  @Test func shiftedStartGoesToTheChangeTheChecksSee() {
    let later = start.addingTimeInterval(60)
    var record = waiting()
    record.updateStart(later)
    #expect(record.pending?.phaseStart == later)
    #expect(record.saved?.phaseStart == start)

    var idle = ChangeRecord(saved: state(slot: 0, images: ["A": "1.jpg"]))
    idle.updateStart(later)
    #expect(idle.saved?.phaseStart == later)
  }
}
