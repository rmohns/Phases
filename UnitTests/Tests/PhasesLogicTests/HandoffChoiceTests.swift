import Testing
@testable import PhasesLogic

/// [D-close-stays-here] Which app gets focus when the Phases window closes.
struct HandoffChoiceTests {
  let phases: Int32 = 100
  let finder: Int32 = 1

  func window(_ pid: Int32, layer: Int = 0, alpha: Double = 1, size: Double = 400) -> HandoffChoice.Window {
    .init(ownerPID: pid, layer: layer, alpha: alpha, width: size, height: size)
  }

  @Test func frontmostOtherAppWins() {
    let windows = [window(phases), window(200), window(300)]
    #expect(HandoffChoice.target(windows: windows, excluding: phases, finderPID: finder) == 200)
  }

  @Test func finderWhenNoOtherWindow() {
    #expect(HandoffChoice.target(windows: [window(phases)], excluding: phases, finderPID: finder) == finder)
  }

  @Test func skipsMenuBarOverlaysAndTinyWindows() {
    let windows = [window(400, layer: 25), window(500, alpha: 0), window(600, size: 10), window(700)]
    #expect(HandoffChoice.target(windows: windows, excluding: phases, finderPID: finder) == 700)
  }

  @Test func nilWithoutFinderOrWindows() {
    #expect(HandoffChoice.target(windows: [], excluding: phases, finderPID: nil) == nil)
  }
}
