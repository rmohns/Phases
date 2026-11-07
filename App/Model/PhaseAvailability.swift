import Foundation

/// [D-phase-cant-run] Whether a phase can run, and if not, why. The schedule
/// and the sidebar share this rule, so the flag never disagrees with what runs.
/// Any reason disables a phase the same way: the sidebar shows only the status
/// [D-row-status-not-cause], and the schedule skips it. A new reason is a new
/// `DisabledReason` case plus a check in `init`.
enum PhaseAvailability: Equatable {
  case runs
  case disabled(DisabledReason)

  init(phase: Phase, savedLocation: SolarCalculator.Coordinate?, isLocationDenied: Bool) {
    // [D-phase-turn-off] Turned off wins over any other reason.
    if !phase.isOn {
      self = .disabled(.turnedOff)
    } else if phase.trigger.usesLocation
      && Self.usableLocation(saved: savedLocation, isDenied: isLocationDenied) == nil {
      self = .disabled(isLocationDenied ? .locationOff : .noLocationYet)
    } else {
      self = .runs
    }
  }

  var isDisabled: Bool {
    if case .disabled = self { true } else { false }
  }

  /// [D-row-status-not-cause] The sidebar row's status; nil when the phase
  /// runs. A phase the user turned off reads "Off" [D-phase-turn-off].
  var rowStatus: String? {
    switch self {
    case .runs: nil
    case .disabled(.turnedOff): "Off"
    case .disabled: "Phase disabled"
    }
  }

  /// Whether the row's status carries a warning symbol: not for a phase
  /// the user turned off, which is a choice, not a problem.
  var rowShowsWarning: Bool {
    isDisabled && self != .disabled(.turnedOff)
  }

  /// Sentence for the phase editor naming the cause; nil when the phase runs.
  var editorMessage: String? {
    if case .disabled(let reason) = self { reason.editorMessage } else { nil }
  }

  /// [D-denied-means-off] While access is denied the schedule ignores the
  /// saved location; it's kept so turning access back on works at once.
  static func usableLocation(saved: SolarCalculator.Coordinate?, isDenied: Bool) -> SolarCalculator.Coordinate? {
    isDenied ? nil : saved
  }

  /// The phases the schedule may use: every phase that isn't disabled.
  static func runnablePhases(
    _ phases: [Phase], savedLocation: SolarCalculator.Coordinate?, isLocationDenied: Bool
  ) -> [Phase] {
    phases.filter {
      !PhaseAvailability(phase: $0, savedLocation: savedLocation, isLocationDenied: isLocationDenied).isDisabled
    }
  }
}

/// Why a phase can't run. Shown only in the phase editor [D-row-status-not-cause].
enum DisabledReason: Equatable {
  /// The user turned the phase off [D-phase-turn-off].
  case turnedOff
  /// Location access is denied or restricted.
  case locationOff
  /// Access was never granted and no location has been saved yet.
  case noLocationYet

  var editorMessage: String {
    switch self {
    case .turnedOff: "This phase is turned off, so it's skipped."
    case .locationOff: "Location access is off, so this phase is skipped."
    case .noLocationYet: "No location yet, so this phase is skipped."
    }
  }
}
