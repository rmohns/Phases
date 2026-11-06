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

  /// `[D-starter-phases]` Morning, Afternoon, Evening on clock times, none
  /// needing a location, and one always active.
  @Test func starterPhasesCoverTheDayWithoutLocation() {
    let starters = Phase.starterPhases
    #expect(starters.map(\.name) == ["Morning", "Afternoon", "Evening"])
    #expect(starters.map(\.trigger) == [.clockTime(minutes: 420), .clockTime(minutes: 720), .clockTime(minutes: 1080)])
    #expect(!starters.contains { $0.trigger.usesLocation })
    let engine = ScheduleEngine(phases: starters, location: nil, isDarkMode: false)
    #expect(engine.activePhase(at: TestCalendar.date(2026, 11, 6, 3, 0))?.phase.name == "Evening")
  }

  /// `[D-duplicate-phase]`
  @Test func duplicateCopiesEverySettingWithANewIDAndName() {
    var original = Phase(name: "Morning", trigger: .solar(.dawn, offsetMinutes: 30))
    original.imageNames = ["a.jpg", "b.jpg"]
    original.displayImageNames = ["display-1": ["c.jpg"]]
    original.order = .random
    original.isRotating = true
    original.rotation = RotationInterval(value: 2, unit: .hours)
    original.appearance = .dark

    let copy = original.duplicate()
    #expect(copy.id != original.id)
    #expect(copy.name == "Morning copy")
    var sameAsOriginal = copy
    sameAsOriginal.id = original.id
    sameAsOriginal.name = original.name
    #expect(sameAsOriginal == original)
  }
}
