import Foundation

/// [D-start-readout] [D-starts-row] The secondary line under the Starts row.
enum StartReadout {
  /// nil when there's nothing to say: a clock time, or a dawn or dusk phase
  /// with no usable location, where the location message shows instead
  /// [D-phase-status-inline].
  static func text(
    for trigger: PhaseTrigger,
    on day: Date,
    at coordinate: SolarCalculator.Coordinate?,
    calendar: Calendar = .current,
    format: (Date) -> String = { $0.formatted(date: .omitted, time: .shortened) }
  ) -> String? {
    switch trigger {
    case .always:
      return "Used when no timed phase applies."
    case .clockTime:
      return nil
    case .solar(let event, let offset):
      guard let coordinate else { return nil }
      let name = event == .dawn ? "dawn" : "dusk"
      guard let base = SolarCalculator.time(of: event, on: day, at: coordinate, calendar: calendar) else {
        return "No \(name) today"
      }
      guard offset != 0 else { return "Today \(format(base))" }
      let start = base.addingTimeInterval(TimeInterval(offset * 60))
      return "Today \(format(start)) (\(name) \(format(base)))"
    }
  }
}
