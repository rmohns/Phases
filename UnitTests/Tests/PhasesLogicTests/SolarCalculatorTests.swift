import Foundation
import Testing
@testable import PhasesLogic

/// Expected times are recalled almanac values for the Boston area; see
/// SPEC.md "Testing" for why the tolerance is ±10 minutes.
struct SolarCalculatorTests {
  private let haverhill = SolarCalculator.Coordinate(latitude: 42.776, longitude: -71.077)
  private let longyearbyen = SolarCalculator.Coordinate(latitude: 78.22, longitude: 15.65)
  private let tolerance: TimeInterval = 10 * 60

  private func time(_ event: SolarEvent, _ day: Date, at coordinate: SolarCalculator.Coordinate) -> Date? {
    SolarCalculator.time(of: event, on: day, at: coordinate, calendar: TestCalendar.newYork)
  }

  @Test func summerSolsticeDawnAndDusk() throws {
    let day = TestCalendar.date(2026, 6, 21)
    let dawn = try #require(time(.dawn, day, at: haverhill))
    let dusk = try #require(time(.dusk, day, at: haverhill))
    #expect(abs(dawn.timeIntervalSince(TestCalendar.date(2026, 6, 21, 4, 32))) <= tolerance)
    #expect(abs(dusk.timeIntervalSince(TestCalendar.date(2026, 6, 21, 21, 0))) <= tolerance)
  }

  @Test func winterSolsticeDawnAndDusk() throws {
    let day = TestCalendar.date(2026, 12, 21)
    let dawn = try #require(time(.dawn, day, at: haverhill))
    let dusk = try #require(time(.dusk, day, at: haverhill))
    #expect(abs(dawn.timeIntervalSince(TestCalendar.date(2026, 12, 21, 6, 40))) <= tolerance)
    #expect(abs(dusk.timeIntervalSince(TestCalendar.date(2026, 12, 21, 16, 45))) <= tolerance)
  }

  @Test func resultFallsInsideTheRequestedLocalDay() throws {
    let day = TestCalendar.date(2026, 10, 28, 15)
    let start = TestCalendar.newYork.startOfDay(for: day)
    for event in [SolarEvent.dawn, .dusk] {
      let date = try #require(time(event, day, at: haverhill))
      #expect(date >= start && date < start.addingTimeInterval(86_400))
    }
  }

  @Test func noCivilTwilightInPolarSummer() {
    // The sun never drops 6° below the horizon at midsummer in Svalbard.
    #expect(time(.dusk, TestCalendar.date(2026, 6, 21), at: longyearbyen) == nil)
  }

  @Test func noCivilTwilightInPolarWinter() {
    // The sun never rises to 6° below the horizon at midwinter in Svalbard.
    #expect(time(.dawn, TestCalendar.date(2026, 12, 21), at: longyearbyen) == nil)
  }
}
