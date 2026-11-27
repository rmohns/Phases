import Foundation

/// A period of the day with its own set of wallpapers.
struct Phase: Identifiable, Codable, Hashable {
  var id = UUID()
  var name: String
  var trigger: PhaseTrigger
  /// The Shared selection (All Displays through draft 62), as stored image
  /// names (spec "Image library").
  var imageNames: [String] = []
  /// Separate selections for specific displays, keyed by display UUID. A
  /// display with an entry here draws only from it (spec "Per-display images").
  var displayImageNames: [String: [String]] = [:]
  /// [D-sharing-per-phase] Whether the displays using the Shared images
  /// show the same image or each a different one.
  var displayMode: DisplayMode = .sameOnAll
  var order: ImageOrder = .inOrder
  var isRotating = false
  var rotation = RotationInterval(value: 30, unit: .minutes)
  var appearance: AppearanceCondition = .any
  /// [D-phase-turn-off] False when the user has turned the phase off.
  var isOn = true

  /// The rotation interval in seconds, or nil when rotation is off.
  var rotationSeconds: TimeInterval? {
    isRotating ? rotation.seconds : nil
  }

  /// [D-starter-phases] What a new user starts with: three clock-time
  /// phases covering the day, so one is always active without a location.
  /// They change images every 30 minutes, like a new phase.
  static var starterPhases: [Phase] {
    [
      Phase(name: "Morning", trigger: .clockTime(minutes: 7 * 60), isRotating: true),
      Phase(name: "Afternoon", trigger: .clockTime(minutes: 12 * 60), isRotating: true),
      Phase(name: "Evening", trigger: .clockTime(minutes: 18 * 60), isRotating: true),
    ]
  }

  /// [D-new-phase-now] What + adds: "New Phase", starting at `date`
  /// rounded down to 5 minutes, changing images every 30 minutes.
  static func newPhase(at date: Date, calendar: Calendar = .current) -> Phase {
    Phase(name: "New Phase", trigger: .clockTime(roundingDown: date, calendar: calendar), isRotating: true)
  }

  /// [D-duplicate-phase] Every setting, a new ID, and a Finder-style name.
  func duplicate() -> Phase {
    var copy = self
    copy.id = UUID()
    copy.name = "\(name) copy"
    return copy
  }

  /// Whether `display` draws from its own images in this phase.
  func hasOwnImages(_ display: String) -> Bool {
    displayImageNames[display] != nil
  }

  /// [D-own-images-start-from-shared] Turning own images on starts from a
  /// copy of the Shared selection; turning them off discards them.
  mutating func setOwnImages(_ isOn: Bool, for display: String) {
    displayImageNames[display] = isOn ? imageNames : nil
  }
}

extension Phase {
  /// [D-sharing-per-phase] Through draft 62 display sharing was one app-wide
  /// preference. A phase saved then has no `displayMode`, and takes the
  /// value given here in the decoder's `userInfo`.
  static let legacyDisplayModeKey = CodingUserInfoKey(rawValue: "legacyDisplayMode")!

  /// Decodes saved phases, giving any saved before draft 63 `legacyDisplayMode`.
  static func decodeSaved(_ data: Data, legacyDisplayMode: DisplayMode) throws -> [Phase] {
    let decoder = JSONDecoder()
    decoder.userInfo[legacyDisplayModeKey] = legacyDisplayMode
    return try decoder.decode([Phase].self, from: data)
  }

  /// Decodes leniently so phases saved by older versions (without newer
  /// fields) keep loading.
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(UUID.self, forKey: .id)
    name = try container.decode(String.self, forKey: .name)
    trigger = try container.decode(PhaseTrigger.self, forKey: .trigger)
    imageNames = try container.decodeIfPresent([String].self, forKey: .imageNames) ?? []
    displayImageNames = try container.decodeIfPresent([String: [String]].self, forKey: .displayImageNames) ?? [:]
    displayMode = try container.decodeIfPresent(DisplayMode.self, forKey: .displayMode)
      ?? decoder.userInfo[Self.legacyDisplayModeKey] as? DisplayMode ?? .sameOnAll
    order = try container.decodeIfPresent(ImageOrder.self, forKey: .order) ?? .inOrder
    isRotating = try container.decodeIfPresent(Bool.self, forKey: .isRotating) ?? false
    rotation = try container.decodeIfPresent(RotationInterval.self, forKey: .rotation)
      ?? RotationInterval(value: 30, unit: .minutes)
    appearance = try container.decodeIfPresent(AppearanceCondition.self, forKey: .appearance) ?? .any
    isOn = try container.decodeIfPresent(Bool.self, forKey: .isOn) ?? true
  }
}

/// Restricts a phase to Light or Dark Mode.
enum AppearanceCondition: String, Codable, CaseIterable, Identifiable {
  case any, light, dark

  var id: Self { self }

  var title: String {
    switch self {
    case .any: "Any"
    case .light: "Light"
    case .dark: "Dark"
    }
  }

  /// The phase editor's Use in segments (spec "Light and Dark Mode").
  var editorTitle: String {
    switch self {
    case .any: "Any"
    case .light: "Light Mode"
    case .dark: "Dark Mode"
    }
  }

  var systemImage: String? {
    switch self {
    case .any: nil
    case .light: "sun.max"
    case .dark: "moon"
    }
  }

  func matches(isDarkMode: Bool) -> Bool {
    switch self {
    case .any: true
    case .light: !isDarkMode
    case .dark: isDarkMode
    }
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

  /// [D-new-phase-now] A clock time at `date`, rounded down to 5 minutes.
  static func clockTime(roundingDown date: Date, calendar: Calendar = .current) -> PhaseTrigger {
    let parts = calendar.dateComponents([.hour, .minute], from: date)
    let minutes = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
    return .clockTime(minutes: minutes - minutes % 5)
  }
}

/// Flat list of trigger types, for pickers.
/// [D-starts-row] In the trigger menu's order: Clock Time, Dawn, Dusk,
/// then Always.
enum TriggerKind: String, CaseIterable, Identifiable {
  case clockTime, dawn, dusk, always

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
    // [D-order-row] Read after "Show images".
    case .inOrder: "In Order"
    case .random: "Randomly"
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
    // Lowercase: the editor's rows read as sentences [D-starts-row].
    case .minutes: "minutes"
    case .hours: "hours"
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
