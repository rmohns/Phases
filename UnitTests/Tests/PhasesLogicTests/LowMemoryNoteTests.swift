import Testing
@testable import PhasesLogic

/// [D-low-memory-note] The Transition section suggests turning transitions
/// off on a Mac with less than 16 GB, only while they're on.
struct LowMemoryNoteTests {
  private static let gigabyte: UInt64 = 1024 * 1024 * 1024
  private static let expectedText = "You can disable transitions to reduce Phases' memory usage."

  @Test func eightGigabytesCrossfadeShowsNote() {
    let note = LowMemoryNote.text(physicalMemory: 8 * Self.gigabyte, transitionStyle: .crossfade, reducesMotion: false)
    #expect(note == Self.expectedText)
  }

  @Test func thresholdIsSixteenGibibytes() {
    #expect(LowMemoryNote.threshold == 16 * Self.gigabyte)
  }

  @Test func exactlySixteenGigabytesShowsNoNote() {
    let note = LowMemoryNote.text(physicalMemory: 16 * Self.gigabyte, transitionStyle: .crossfade, reducesMotion: false)
    #expect(note == nil)
  }

  @Test func oneByteUnderSixteenGigabytesShowsNote() {
    let note = LowMemoryNote.text(physicalMemory: 16 * Self.gigabyte - 1, transitionStyle: .crossfade, reducesMotion: false)
    #expect(note == Self.expectedText)
  }

  @Test func moreThanSixteenGigabytesShowsNoNote() {
    #expect(LowMemoryNote.text(physicalMemory: 16 * Self.gigabyte + 1, transitionStyle: .crossfade, reducesMotion: false) == nil)
    #expect(LowMemoryNote.text(physicalMemory: 32 * Self.gigabyte, transitionStyle: .crossfade, reducesMotion: false) == nil)
  }

  @Test func transitionNoneShowsNoNote() {
    let note = LowMemoryNote.text(physicalMemory: 8 * Self.gigabyte, transitionStyle: .none, reducesMotion: false)
    #expect(note == nil)
  }

  @Test func reduceMotionShowsNoNote() {
    let note = LowMemoryNote.text(physicalMemory: 8 * Self.gigabyte, transitionStyle: .crossfade, reducesMotion: true)
    #expect(note == nil)
  }
}
