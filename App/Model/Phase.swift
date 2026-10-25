import Foundation

/// A period of the day with its own set of wallpapers.
struct Phase: Identifiable, Codable, Hashable {
  var id = UUID()
  var name: String
  var trigger: PhaseTrigger
  /// File names (not paths) of the selected images in the library folder.
  var imageNames: [String] = []
  var order: ImageOrder = .inOrder
  var isRotating = false
  var rotation = RotationInterval(value: 30, unit: .minutes)

  /// The rotation interval in seconds, or nil when rotation is off.
  var rotationSeconds: TimeInterval? {
    isRotating ? rotation.seconds : nil
  }
}

enum PhaseTrigger: Codable, Hashable {
  /// Active whenever no timed phase applies. Used for pure rotation.
  case always
  /// Minutes since local midnight.
  case clockTime(minutes: Int)
  /// Civil dawn or dusk, shifted by a signed offset in minutes.
  case solar(SolarEvent, offsetMinutes: Int)

  var kind: TriggerKind {
    switch self {
    case .always: .always
    case .clockTime: .clockTime
    case .solar(.dawn, _): .dawn
    case .solar(.dusk, _): .dusk
    }
  }

  var usesLocation: Bool {
    if case .solar = self { true } else { false }
  }
}

/// Flat list of trigger types, for pickers.
enum TriggerKind: String, CaseIterable, Identifiable {
  case always, clockTime, dawn, dusk

  var id: Self { self }

  var title: String {
    switch self {
    case .always: "Always"
    case .clockTime: "Clock Time"
    case .dawn: "Dawn"
    case .dusk: "Dusk"
    }
  }

  var systemImage: String {
    switch self {
    case .always: "infinity"
    case .clockTime: "clock"
    case .dawn: "sunrise"
    case .dusk: "sunset"
    }
  }
}

enum SolarEvent: String, Codable, Hashable {
  case dawn, dusk
}

enum ImageOrder: String, Codable, CaseIterable, Identifiable {
  case inOrder, random

  var id: Self { self }

  var title: String {
    switch self {
    case .inOrder: "In Order"
    case .random: "Random"
    }
  }
}

struct RotationInterval: Codable, Hashable {
  var value: Int
  var unit: TimeUnit

  var seconds: TimeInterval {
    TimeInterval(max(value, 1)) * unit.seconds
  }
}

enum TimeUnit: String, Codable, CaseIterable, Identifiable {
  case minutes, hours

  var id: Self { self }

  var seconds: TimeInterval {
    switch self {
    case .minutes: 60
    case .hours: 3600
    }
  }

  var title: String {
    switch self {
    case .minutes: "Minutes"
    case .hours: "Hours"
    }
  }
}

extension PhaseTrigger {
  /// Short human-readable description, e.g. "30 min before dusk".
  var summary: String {
    switch self {
    case .always:
      return "Always"
    case .clockTime(let minutes):
      let date = Calendar.current.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: Date()) ?? Date()
      return date.formatted(date: .omitted, time: .shortened)
    case .solar(let event, let offset):
      let name = event == .dawn ? "dawn" : "dusk"
      guard offset != 0 else { return name.capitalized }
      let duration = Duration.seconds(abs(offset) * 60)
        .formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
      return "\(duration) \(offset < 0 ? "before" : "after") \(name)"
    }
  }
}
