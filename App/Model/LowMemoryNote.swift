import Foundation

/// [D-low-memory-note] What the Transition section says on a Mac with
/// little memory. Pure, so the unit tests can reach it [D-tests-unhosted].
enum LowMemoryNote {
  /// 16 GB, as 16 × 1024³ bytes. A 16 GB Mac reports exactly this, so it
  /// gets no note.
  static let threshold: UInt64 = 16 * 1024 * 1024 * 1024

  /// The note under None / Crossfade; nil unless the Mac has less than 16 GB,
  /// Transition is Crossfade, and Reduce Motion is off (with None or Reduce
  /// Motion on, transitions are already off). `footprint` is Phases' own
  /// memory use [D-memory-in-about]; without it the note stops after the
  /// first sentence.
  static func text(
    physicalMemory: UInt64, transitionStyle: TransitionStyle, reducesMotion: Bool, footprint: UInt64?
  ) -> String? {
    guard physicalMemory < threshold, transitionStyle == .crossfade, !reducesMotion else { return nil }
    let suggestion = "You can disable transitions to reduce Phases' memory usage."
    guard let footprint else { return suggestion }
    return "\(suggestion) Current memory use: \(memoryText(bytes: footprint))"
  }

  /// [D-memory-in-about] A memory figure in whole megabytes (1024² bytes,
  /// rounded), e.g. "142 MB". Used by the note and by About's Memory line.
  static func memoryText(bytes: UInt64) -> String {
    let megabyte: UInt64 = 1024 * 1024
    let rounded = (bytes + megabyte / 2) / megabyte
    return "\(rounded) MB"
  }
}
