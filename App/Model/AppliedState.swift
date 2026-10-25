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
  /// Image file names last applied, one per display.
  var imageNames: [String]
}
