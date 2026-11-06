import Foundation
import Testing
@testable import PhasesLogic

/// Phase defaults and helpers.
struct PhaseTests {
  /// `[D-new-phase-now]`
  @Test func newPhaseStartsNowRoundedDownToFiveMinutes() {
    let calendar = TestCalendar.newYork
    #expect(PhaseTrigger.clockTime(roundingDown: TestCalendar.date(2026, 11, 6, 14, 37), calendar: calendar)
      == .clockTime(minutes: 14 * 60 + 35))
    #expect(PhaseTrigger.clockTime(roundingDown: TestCalendar.date(2026, 11, 6, 14, 35), calendar: calendar)
      == .clockTime(minutes: 14 * 60 + 35))
    #expect(PhaseTrigger.clockTime(roundingDown: TestCalendar.date(2026, 11, 6, 0, 4), calendar: calendar)
      == .clockTime(minutes: 0))
    #expect(PhaseTrigger.clockTime(roundingDown: TestCalendar.date(2026, 11, 6, 23, 59), calendar: calendar)
      == .clockTime(minutes: 23 * 60 + 55))
  }
}
