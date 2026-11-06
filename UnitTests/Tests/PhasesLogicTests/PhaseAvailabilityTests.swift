import Foundation
import Testing
@testable import PhasesLogic

/// [D-phase-cant-run] [D-denied-means-off] [D-row-status-not-cause]
struct PhaseAvailabilityTests {
  private let haverhill = SolarCalculator.Coordinate(latitude: 42.776, longitude: -71.077)
  private let always = Phase(name: "Always", trigger: .always)
  private let clock = Phase(name: "Morning", trigger: .clockTime(minutes: 7 * 60))
  private let dawn = Phase(name: "Dawn", trigger: .solar(.dawn, offsetMinutes: 0))

  private func availability(_ phase: Phase, saved: SolarCalculator.Coordinate?, denied: Bool) -> PhaseAvailability {
    PhaseAvailability(phase: phase, savedLocation: saved, isLocationDenied: denied)
  }

  @Test func nonSolarPhasesAlwaysRun() {
    #expect(availability(always, saved: nil, denied: true) == .runs)
    #expect(availability(clock, saved: nil, denied: true) == .runs)
  }

  /// [D-phase-turn-off] Turned off disables any phase, and wins over a
  /// missing location.
  @Test func turnedOffPhasesNeverRun() {
    var off = clock
    off.isOn = false
    #expect(availability(off, saved: haverhill, denied: false) == .disabled(.turnedOff))
    var offDawn = dawn
    offDawn.isOn = false
    #expect(availability(offDawn, saved: nil, denied: true) == .disabled(.turnedOff))
    #expect(PhaseAvailability.runnablePhases([clock, off], savedLocation: nil, isLocationDenied: false) == [clock])
  }

  /// [D-row-status-not-cause] [D-phase-turn-off] "Off" with no warning for a
  /// turned-off phase; "Phase disabled" with one for anything else.
  @Test func rowStatusSetsTurnedOffApart() {
    #expect(PhaseAvailability.runs.rowStatus == nil)
    #expect(!PhaseAvailability.runs.rowShowsWarning)
    #expect(PhaseAvailability.disabled(.turnedOff).rowStatus == "Off")
    #expect(!PhaseAvailability.disabled(.turnedOff).rowShowsWarning)
    #expect(PhaseAvailability.disabled(.locationOff).rowStatus == "Phase disabled")
    #expect(PhaseAvailability.disabled(.locationOff).rowShowsWarning)
    #expect(PhaseAvailability.disabled(.noLocationYet).rowShowsWarning)
  }

  /// [D-phase-turn-off] Phases saved before the switch existed load as on.
  @Test func olderSavedPhasesLoadAsOn() throws {
    var saved = try JSONSerialization.jsonObject(with: JSONEncoder().encode(clock)) as! [String: Any]
    saved.removeValue(forKey: "isOn")
    let data = try JSONSerialization.data(withJSONObject: saved)
    #expect(try JSONDecoder().decode(Phase.self, from: data).isOn)
  }

  @Test func solarPhaseRunsWithASavedLocation() {
    #expect(availability(dawn, saved: haverhill, denied: false) == .runs)
  }

  @Test func deniedOverridesASavedLocation() {
    #expect(availability(dawn, saved: haverhill, denied: true) == .disabled(.locationOff))
    #expect(availability(dawn, saved: nil, denied: true) == .disabled(.locationOff))
  }

  @Test func undecidedWithNoLocationIsNoLocationYet() {
    #expect(availability(dawn, saved: nil, denied: false) == .disabled(.noLocationYet))
  }

  @Test func onlyDisabledPhasesHaveAnEditorMessage() {
    #expect(PhaseAvailability.runs.editorMessage == nil)
    #expect(!PhaseAvailability.runs.isDisabled)
    #expect(PhaseAvailability.disabled(.locationOff).isDisabled)
    #expect(PhaseAvailability.disabled(.locationOff).editorMessage == DisabledReason.locationOff.editorMessage)
  }

  @Test func runnablePhasesDropsOnlyDisabledOnes() {
    let runnable = PhaseAvailability.runnablePhases([always, clock, dawn], savedLocation: haverhill, isLocationDenied: true)
    #expect(runnable.map(\.id) == [always.id, clock.id])
  }

  /// The schedule skips a dawn phase while access is denied, even with a
  /// saved location: the bug that `[D-denied-means-off]` fixed.
  @Test func deniedDawnPhaseNeverBecomesActive() {
    let noon = TestCalendar.date(2026, 10, 28, 12)
    func active(isDenied: Bool) -> Phase.ID? {
      ScheduleEngine(
        phases: PhaseAvailability.runnablePhases([always, dawn], savedLocation: haverhill, isLocationDenied: isDenied),
        location: PhaseAvailability.usableLocation(saved: haverhill, isDenied: isDenied),
        calendar: TestCalendar.newYork
      ).activePhase(at: noon)?.phase.id
    }
    #expect(active(isDenied: false) == dawn.id)
    #expect(active(isDenied: true) == always.id)
  }
}
