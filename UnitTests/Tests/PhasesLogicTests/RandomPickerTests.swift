import Testing
@testable import PhasesLogic

/// Random order never changes a display to an image it's showing when
/// another is available (issue #10). Picks are random, so each case runs
/// many times.
struct RandomPickerTests {
  private let runs = 500

  @Test func twoDisplaysTwoImagesBothChange() {
    // Different picks per display, the old fallback's worst case: about
    // half of all changes kept one display's image.
    for _ in 0..<runs {
      #expect(RandomPicker.perDisplay(from: ["A", "B"], showing: [["A"], ["B"]]) == ["B", "A"])
    }
  }

  @Test func twoDisplaysThreeImagesBothChange() {
    for _ in 0..<runs {
      let picks = RandomPicker.perDisplay(from: ["A", "B", "C"], showing: [["A"], ["B"]])
      #expect(picks[0] != "A" && picks[1] != "B" && picks[0] != picks[1])
    }
  }

  @Test func avoidsEveryImageADisplayMayBeShowing() {
    // After a Space switch: Phases last set A, the Space shows B.
    for _ in 0..<runs {
      #expect(RandomPicker.perDisplay(from: ["A", "B", "C"], showing: [["A", "B"]]) == ["C"])
      #expect(RandomPicker.shared(from: ["A", "B", "C"], showing: [["A", "B"]]) == "C")
    }
  }

  @Test func sharedAvoidsWhatAnySharingDisplayShows() {
    for _ in 0..<runs {
      #expect(RandomPicker.shared(from: ["A", "B", "C"], showing: [["A"], ["B"]]) == "C")
    }
  }

  @Test func sharedPrefersTheImageFewestDisplaysShow() {
    for _ in 0..<runs {
      #expect(RandomPicker.shared(from: ["A", "B"], showing: [["A"], ["A"], ["B"]]) == "B")
    }
  }

  @Test func displayWithNothingShowingDoesNotTakeTheOnlyChange() {
    // A newly connected display shouldn't take B, the only image the other
    // display can change to.
    for _ in 0..<runs {
      #expect(RandomPicker.perDisplay(from: ["A", "B"], showing: [[], ["A"]]) == ["A", "B"])
    }
  }

  @Test func singleImageStaysPut() {
    #expect(RandomPicker.perDisplay(from: ["A"], showing: [["A"], ["A"]]) == ["A", "A"])
    #expect(RandomPicker.shared(from: ["A"], showing: [["A"]]) == "A")
  }

  @Test func emptyPoolPicksNothing() {
    #expect(RandomPicker.perDisplay(from: [], showing: [["A"]]).isEmpty)
    #expect(RandomPicker.shared(from: [], showing: [["A"]]) == nil)
  }

  @Test func picksStayDistinctWhenThereAreEnough() {
    for _ in 0..<runs {
      let picks = RandomPicker.perDisplay(from: ["A", "B", "C", "D"], showing: [[], [], []])
      #expect(Set(picks).count == 3)
    }
  }
}
