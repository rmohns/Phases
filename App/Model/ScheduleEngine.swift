import Foundation

/// Pure scheduling logic: which phase is active, and when the next change is.
struct ScheduleEngine {
  var phases: [Phase]
  var location: SolarCalculator.Coordinate?
  var isDarkMode = false
  var calendar: Calendar = .current

  struct ActivePhase: Equatable {
    var phase: Phase
    /// When this occurrence of the phase began. Nil for an "Always" phase.
    var start: Date?
  }

  /// Phases whose appearance condition matches the current appearance.
  private var eligiblePhases: [Phase] {
    phases.filter { $0.appearance.matches(isDarkMode: isDarkMode) }
  }

  /// Among eligible phases, the one whose start trigger fired most recently at
  /// or before `now`. Falls back to the first eligible "Always" phase.
  func activePhase(at now: Date) -> ActivePhase? {
    let phases = eligiblePhases
    var best: ActivePhase?
    for phase in phases {
      for dayOffset in -2...0 {
        guard let start = occurrence(of: phase.trigger, dayOffset: dayOffset, from: now),
          start <= now
        else { continue }
        if best?.start.map({ start > $0 }) ?? true {
          best = ActivePhase(phase: phase, start: start)
        }
      }
    }
    if let best { return best }
    return phases.first { $0.trigger == .always }.map { ActivePhase(phase: $0, start: nil) }
  }

  /// The next time any eligible timed phase starts, strictly after `now`.
  func nextPhaseStart(after now: Date) -> (phase: Phase, date: Date)? {
    var best: (phase: Phase, date: Date)?
    for phase in eligiblePhases {
      for dayOffset in 0...2 {
        guard let date = occurrence(of: phase.trigger, dayOffset: dayOffset, from: now),
          date > now
        else { continue }
        if best.map({ date < $0.date }) ?? true {
          best = (phase, date)
        }
      }
    }
    return best
  }

  /// The trigger's time on the day `dayOffset` days from `reference`.
  func occurrence(of trigger: PhaseTrigger, dayOffset: Int, from reference: Date) -> Date? {
    guard let day = calendar.date(byAdding: .day, value: dayOffset, to: calendar.startOfDay(for: reference))
    else { return nil }
    switch trigger {
    case .always:
      return nil
    case .clockTime(let minutes):
      return calendar.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: day)
    case .solar(let event, let offsetMinutes):
      guard let location,
        let base = SolarCalculator.time(of: event, on: day, at: location, calendar: calendar)
      else { return nil }
      return base.addingTimeInterval(TimeInterval(offsetMinutes) * 60)
    }
  }

  /// Rotation slots are counted from the phase's start, so a rotation every
  /// 30 minutes from 6:12 pm fires at 6:42, 7:12, … regardless of sleep.
  static func rotationSlot(start: Date, interval: TimeInterval, now: Date) -> Int {
    max(0, Int(floor(now.timeIntervalSince(start) / interval)))
  }

  static func nextRotation(start: Date, interval: TimeInterval, now: Date) -> Date {
    start.addingTimeInterval(TimeInterval(rotationSlot(start: start, interval: interval, now: now) + 1) * interval)
  }
}
