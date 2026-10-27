import Foundation

/// What the scheduler last applied, persisted so it can tell after a relaunch
/// or wake whether a phase change or rotation was missed.
struct AppliedState: Codable, Equatable {
  var phaseID: UUID
  /// Start of the phase occurrence (or the rotation anchor for "Always").
  var phaseStart: Date
  var rotationSlot: Int
  /// Extra steps taken with "Change Now" during this phase occurrence.
  var manualSteps: Int
  /// Image last applied to each display, keyed by display UUID.
  var imagesByDisplay: [String: String]
}

extension AppliedState {
  /// Lenient, so state saved by older versions loads; it just triggers one
  /// re-apply because no per-display images are recorded.
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    phaseID = try container.decode(UUID.self, forKey: .phaseID)
    phaseStart = try container.decode(Date.self, forKey: .phaseStart)
    rotationSlot = try container.decode(Int.self, forKey: .rotationSlot)
    manualSteps = try container.decode(Int.self, forKey: .manualSteps)
    imagesByDisplay = try container.decodeIfPresent([String: String].self, forKey: .imagesByDisplay) ?? [:]
  }
}
