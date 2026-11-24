import Testing
@testable import PhasesLogic

/// [D-low-memory-note] The Transition section suggests turning transitions
/// off on a Mac with less than 16 GB, only while they're on, with Phases'
/// own memory use [D-memory-in-about].
struct LowMemoryNoteTests {
  private static let gigabyte: UInt64 = 1024 * 1024 * 1024
  private static let megabyte: UInt64 = 1024 * 1024
  private static let suggestion = "You can disable transitions to reduce Phases' memory usage."

  private static func note(
    _ memory: UInt64, _ style: TransitionStyle = .crossfade, reducesMotion: Bool = false, footprint: UInt64? = nil
  ) -> String? {
    LowMemoryNote.text(physicalMemory: memory, transitionStyle: style, reducesMotion: reducesMotion, footprint: footprint)
  }

  @Test func eightGigabytesCrossfadeShowsNoteWithMemoryUse() {
    #expect(Self.note(8 * Self.gigabyte, footprint: 142 * Self.megabyte)
      == "\(Self.suggestion) Current memory use: 142 MB")
  }

  @Test func unreadableFootprintEndsAfterTheSuggestion() {
    #expect(Self.note(8 * Self.gigabyte, footprint: nil) == Self.suggestion)
  }

  @Test func thresholdIsSixteenGibibytes() {
    #expect(LowMemoryNote.threshold == 16 * Self.gigabyte)
  }

  @Test func exactlySixteenGigabytesShowsNoNote() {
    #expect(Self.note(16 * Self.gigabyte) == nil)
  }

  @Test func oneByteUnderSixteenGigabytesShowsNote() {
    #expect(Self.note(16 * Self.gigabyte - 1) == Self.suggestion)
  }

  @Test func moreThanSixteenGigabytesShowsNoNote() {
    #expect(Self.note(16 * Self.gigabyte + 1) == nil)
    #expect(Self.note(32 * Self.gigabyte) == nil)
  }

  @Test func transitionNoneShowsNoNote() {
    #expect(Self.note(8 * Self.gigabyte, .none) == nil)
  }

  @Test func reduceMotionShowsNoNote() {
    #expect(Self.note(8 * Self.gigabyte, reducesMotion: true) == nil)
  }

  /// [D-memory-in-about] Whole megabytes of 1024² bytes, rounded.
  @Test func memoryTextRoundsToWholeMegabytes() {
    #expect(LowMemoryNote.memoryText(bytes: 142 * Self.megabyte) == "142 MB")
    #expect(LowMemoryNote.memoryText(bytes: 142 * Self.megabyte + Self.megabyte / 2 - 1) == "142 MB")
    #expect(LowMemoryNote.memoryText(bytes: 142 * Self.megabyte + Self.megabyte / 2) == "143 MB")
    #expect(LowMemoryNote.memoryText(bytes: 0) == "0 MB")
  }
}
