import Testing
@testable import PhasesLogic

/// Which launches open the window on their own `[D-first-launch-shows-window]`.
struct FirstLaunchTests {
  @Test func nothingSavedIsAFirstLaunch() {
    #expect(FirstLaunch.isFirstLaunch(
      hasRecordedLaunch: false, hasSavedSettings: false, isUITestMode: false, testForcesFirstLaunch: false))
  }

  @Test func aRecordedLaunchIsNot() {
    #expect(!FirstLaunch.isFirstLaunch(
      hasRecordedLaunch: true, hasSavedSettings: false, isUITestMode: false, testForcesFirstLaunch: false))
  }

  /// Updating from a version that never recorded launches.
  @Test func settingsFromAnEarlierVersionAreNot() {
    #expect(!FirstLaunch.isFirstLaunch(
      hasRecordedLaunch: false, hasSavedSettings: true, isUITestMode: false, testForcesFirstLaunch: false))
  }

  @Test func testModeOnlyWithItsSwitch() {
    #expect(!FirstLaunch.isFirstLaunch(
      hasRecordedLaunch: false, hasSavedSettings: false, isUITestMode: true, testForcesFirstLaunch: false))
    #expect(FirstLaunch.isFirstLaunch(
      hasRecordedLaunch: true, hasSavedSettings: true, isUITestMode: true, testForcesFirstLaunch: true))
  }
}
