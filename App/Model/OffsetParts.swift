import Foundation

/// [D-starts-row] A dawn or dusk offset as the Starts row shows it:
/// "[30] [minutes] [before]", or "[at]" for exactly at the event. The
/// offset itself is stored in signed minutes on `PhaseTrigger.solar`.
struct OffsetParts: Equatable {
  enum Direction: String, CaseIterable, Identifiable {
    case before, after, at

    var id: Self { self }

    var title: String { rawValue }
  }

  var direction: Direction
  /// Always within `range(for: unit)`; ignored when `direction` is `.at`.
  private(set) var value: Int
  private(set) var unit: TimeUnit

  /// The number shown when the row leaves "at".
  static let startingMinutes = 30

  /// Shows `minutes` in the largest unit that divides it evenly, so 120 is
  /// "2 hours" and 90 is "90 minutes". Zero is "at".
  init(minutes: Int) {
    let magnitude = abs(minutes)
    if magnitude == 0 {
      direction = .at
      value = Self.startingMinutes
      unit = .minutes
    } else {
      direction = minutes < 0 ? .before : .after
      if magnitude % 60 == 0 {
        unit = .hours
        value = Self.clamp(magnitude / 60, to: .hours)
      } else {
        unit = .minutes
        value = Self.clamp(magnitude, to: .minutes)
      }
    }
  }

  /// Signed minutes to store: negative before, positive after, zero at.
  var minutes: Int {
    let magnitude = value * (unit == .hours ? 60 : 1)
    switch direction {
    case .at: return 0
    case .before: return -magnitude
    case .after: return magnitude
    }
  }

  /// The offset limits, −12 h to +12 h (spec "Start triggers").
  static func range(for unit: TimeUnit) -> ClosedRange<Int> {
    switch unit {
    case .minutes: 1...720
    case .hours: 1...12
    }
  }

  static func step(for unit: TimeUnit) -> Int {
    unit == .minutes ? 5 : 1
  }

  /// A typed or stepped number; past the limit it becomes the limit.
  mutating func setValue(_ newValue: Int) {
    value = Self.clamp(newValue, to: unit)
  }

  /// Keeps the number, clamped: 30 minutes becomes 12 hours, not half an hour.
  mutating func setUnit(_ newUnit: TimeUnit) {
    unit = newUnit
    value = Self.clamp(value, to: newUnit)
  }

  /// Leaving "at" starts from 30 minutes.
  mutating func setDirection(_ newDirection: Direction) {
    if direction == .at && newDirection != .at {
      unit = .minutes
      value = Self.startingMinutes
    }
    direction = newDirection
  }

  private static func clamp(_ value: Int, to unit: TimeUnit) -> Int {
    let range = range(for: unit)
    return min(max(value, range.lowerBound), range.upperBound)
  }
}
