import Foundation

/// [D-low-memory-note] What the Transition section says on a Mac with
/// little memory. Pure, so the unit tests can reach it [D-tests-unhosted].
enum LowMemoryNote {
  /// 16 GB, as 16 × 1024³ bytes. A 16 GB Mac reports exactly this, so it
  /// gets no note.
  static let threshold: UInt64 = 16 * 1024 * 1024 * 1024

  /// The note under None / Crossfade; nil unless the Mac has less than 16 GB,
  /// Transition is Crossfade, and Reduce Motion is off (with None or Reduce
  /// Motion on, transitions are already off).
  static func text(physicalMemory: UInt64, transitionStyle: TransitionStyle, reducesMotion: Bool) -> String? {
    guard physicalMemory < threshold, transitionStyle == .crossfade, !reducesMotion else { return nil }
    return "You can disable transitions to reduce Phases' memory usage."
  }
}
