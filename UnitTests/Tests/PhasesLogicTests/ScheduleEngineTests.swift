import Foundation
import Testing
@testable import PhasesLogic

struct ScheduleEngineTests {
  private let morning = Phase(name: "Morning", trigger: .clockTime(minutes: 7 * 60))
  private let night = Phase(name: "Night", trigger: .clockTime(minutes: 22 * 60))

  private func engine(_ phases: [Phase], isDarkMode: Bool = false) -> ScheduleEngine {
    ScheduleEngine(phases: phases, isDarkMode: isDarkMode, calendar: TestCalendar.newYork)
  }

  @Test func activePhaseIsTheMostRecentStart() {
    let engine = engine([morning, night])
    #expect(engine.activePhase(at: TestCalendar.date(2026, 10, 28, 8))?.phase.id == morning.id)
    #expect(engine.activePhase(at: TestCalendar.date(2026, 10, 28, 23))?.phase.id == night.id)
  }

  @Test func overnightPhaseCarriesPastMidnight() {
    let active = engine([morning, night]).activePhase(at: TestCalendar.date(2026, 10, 28, 2))
    #expect(active?.phase.id == night.id)
    #expect(active?.start == TestCalendar.date(2026, 10, 27, 22))
  }

  @Test func phaseStartsExactlyAtItsTriggerTime() {
    let active = engine([morning, night]).activePhase(at: TestCalendar.date(2026, 10, 28, 7))
    #expect(active?.phase.id == morning.id)
  }

  @Test func alwaysPhaseIsTheFallback() {
    let always = Phase(name: "Always", trigger: .always)
    let active = engine([always]).activePhase(at: TestCalendar.date(2026, 10, 28, 12))
    #expect(active?.phase.id == always.id)
    #expect(active?.start == nil)
  }

  @Test func timedPhaseBeatsAlwaysPhase() {
    let always = Phase(name: "Always", trigger: .always)
    let active = engine([always, morning]).activePhase(at: TestCalendar.date(2026, 10, 28, 12))
    #expect(active?.phase.id == morning.id)
  }

  @Test func appearanceConditionPicksThePhase() {
    let light = Phase(name: "Light", trigger: .always, appearance: .light)
    let dark = Phase(name: "Dark", trigger: .always, appearance: .dark)
    let noon = TestCalendar.date(2026, 10, 28, 12)
    #expect(engine([light, dark], isDarkMode: false).activePhase(at: noon)?.phase.id == light.id)
    #expect(engine([light, dark], isDarkMode: true).activePhase(at: noon)?.phase.id == dark.id)
  }

  @Test func ineligibleTimedPhaseIsSkipped() {
    var darkNight = night
    darkNight.appearance = .dark
    // In Light Mode at 11 pm, Night doesn't qualify, so Morning stays active.
    let active = engine([morning, darkNight], isDarkMode: false).activePhase(at: TestCalendar.date(2026, 10, 28, 23))
    #expect(active?.phase.id == morning.id)
  }

  @Test func noEligiblePhaseMeansNoActivePhase() {
    let dark = Phase(name: "Dark", trigger: .always, appearance: .dark)
    #expect(engine([dark], isDarkMode: false).activePhase(at: TestCalendar.date(2026, 10, 28, 12)) == nil)
  }

  @Test func nextPhaseStartIsTheSoonestAfterNow() {
    let next = engine([morning, night]).nextPhaseStart(after: TestCalendar.date(2026, 10, 28, 8))
    #expect(next?.phase.id == night.id)
    #expect(next?.date == TestCalendar.date(2026, 10, 28, 22))
  }

  @Test func nextPhaseStartRollsToTomorrow() {
    let next = engine([morning, night]).nextPhaseStart(after: TestCalendar.date(2026, 10, 28, 23))
    #expect(next?.phase.id == morning.id)
    #expect(next?.date == TestCalendar.date(2026, 10, 29, 7))
  }

  @Test func solarTriggerWithoutLocationNeverFires() {
    let dusk = Phase(name: "Dusk", trigger: .solar(.dusk, offsetMinutes: 0))
    #expect(engine([dusk]).activePhase(at: TestCalendar.date(2026, 10, 28, 23)) == nil)
  }

  // MARK: Rotation [D-missed-latest-only]

  @Test func rotationSlotCountsWholeIntervalsSinceStart() {
    let start = TestCalendar.date(2026, 10, 28, 18, 12)
    let now = start.addingTimeInterval(95 * 60)
    #expect(ScheduleEngine.rotationSlot(start: start, interval: 30 * 60, now: now) == 3)
  }

  @Test func rotationSlotIsZeroBeforeStart() {
    let start = TestCalendar.date(2026, 10, 28, 18, 12)
    #expect(ScheduleEngine.rotationSlot(start: start, interval: 30 * 60, now: start.addingTimeInterval(-60)) == 0)
  }

  @Test func missedRotationsJumpToTheLatestSlot_DMissedLatestOnly() {
    // Asleep from 6:20 pm to 9:05 pm with 30-minute rotation from 6:12 pm:
    // the slot is the one that would be showing now, and the clock stays
    // aligned to the original schedule.
    let start = TestCalendar.date(2026, 10, 28, 18, 12)
    let wake = TestCalendar.date(2026, 10, 28, 21, 5)
    #expect(ScheduleEngine.rotationSlot(start: start, interval: 30 * 60, now: wake) == 5)
    #expect(ScheduleEngine.nextRotation(start: start, interval: 30 * 60, now: wake) == TestCalendar.date(2026, 10, 28, 21, 12))
  }
}
