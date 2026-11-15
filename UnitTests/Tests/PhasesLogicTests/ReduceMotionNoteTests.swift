import Testing
@testable import PhasesLogic

/// [D-reduce-motion-note] The Transition section follows Reduce Motion.
struct ReduceMotionNoteTests {
  @Test func reduceMotionOnShowsNote() {
    #expect(ReduceMotionNote.text(reducesMotion: true) == "Transitions are off because Reduce Motion is on in System Settings.")
  }

  @Test func reduceMotionOffShowsNoNote() {
    #expect(ReduceMotionNote.text(reducesMotion: false) == nil)
  }

  @Test func controlsDimmedOnlyWhileReduceMotionIsOn() {
    #expect(ReduceMotionNote.controlsEnabled(reducesMotion: false))
    #expect(!ReduceMotionNote.controlsEnabled(reducesMotion: true))
  }
}
