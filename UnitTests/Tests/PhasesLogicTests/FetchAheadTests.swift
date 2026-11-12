import Foundation
import Testing
@testable import PhasesLogic

/// [D-photos-fetch-ahead]
struct FetchAheadTests {
  // MARK: Lead

  @Test func leadIsTwoMinutesWithNoRotationOrALongOne() {
    #expect(FetchAhead.lead(rotationInterval: nil) == 120)
    #expect(FetchAhead.lead(rotationInterval: 3600) == 120)
    #expect(FetchAhead.lead(rotationInterval: 240) == 120)
  }

  @Test func leadIsHalfAShortRotationInterval() {
    #expect(FetchAhead.lead(rotationInterval: 60) == 30)
    #expect(FetchAhead.lead(rotationInterval: 100) == 50)
  }

  @Test func fetchDateIsTheLeadBeforeTheChangeButNeverBeforeNow() {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let change = now.addingTimeInterval(600)
    #expect(FetchAhead.fetchDate(forChangeAt: change, rotationInterval: nil, now: now) == change.addingTimeInterval(-120))
    #expect(FetchAhead.fetchDate(forChangeAt: change, rotationInterval: 60, now: now) == change.addingTimeInterval(-30))
    // The change is 10 s away: the lead has already passed.
    let soon = now.addingTimeInterval(10)
    #expect(FetchAhead.fetchDate(forChangeAt: soon, rotationInterval: nil, now: now) == now)
    // The change is in the past.
    #expect(FetchAhead.fetchDate(forChangeAt: now.addingTimeInterval(-5), rotationInterval: 60, now: now) == now)
  }

  // MARK: Replacement

  private let pool = ["A", "B", "C", "D"]

  @Test func inOrderTakesTheNextOnHandImageAfterTheFailedOne() {
    let next = FetchAhead.replacement(for: "B", in: pool, onHand: ["A", "C", "D"], order: .inOrder, showing: [])
    #expect(next == "C")
  }

  @Test func inOrderWrapsAround() {
    let next = FetchAhead.replacement(for: "D", in: pool, onHand: ["A", "B"], order: .inOrder, showing: [])
    #expect(next == "A")
  }

  @Test func inOrderSkipsImagesNotOnHand() {
    // C is not on hand: from B the next on-hand one is D.
    #expect(FetchAhead.replacement(for: "B", in: pool, onHand: ["A", "D"], order: .inOrder, showing: []) == "D")
    // From C, D and A are not on hand: wraps to B.
    #expect(FetchAhead.replacement(for: "C", in: pool, onHand: ["B"], order: .inOrder, showing: []) == "B")
  }

  @Test func nothingElseOnHandGivesNil() {
    for order in ImageOrder.allCases {
      #expect(FetchAhead.replacement(for: "B", in: pool, onHand: [], order: order, showing: []) == nil)
      // Only the failed image itself is on hand.
      #expect(FetchAhead.replacement(for: "B", in: pool, onHand: ["B"], order: order, showing: []) == nil)
      // Something is on hand, but not in the pool.
      #expect(FetchAhead.replacement(for: "B", in: pool, onHand: ["Z"], order: order, showing: []) == nil)
      #expect(FetchAhead.replacement(for: "A", in: ["A"], onHand: ["A"], order: order, showing: []) == nil)
    }
  }

  @Test func randomReturnsAnOnHandImageOtherThanTheFailedOne() {
    for _ in 0..<200 {
      let pick = FetchAhead.replacement(for: "B", in: pool, onHand: ["A", "B", "D"], order: .random, showing: [])
      #expect(pick == "A" || pick == "D")
    }
  }

  @Test func randomAvoidsTheShowingImageWhenAnotherExists() {
    for _ in 0..<200 {
      let pick = FetchAhead.replacement(for: "B", in: pool, onHand: ["A", "C", "D"], order: .random, showing: ["A"])
      #expect(pick == "C" || pick == "D")
    }
  }

  @Test func randomUsesTheShowingImageWhenItIsTheOnlyOneOnHand() {
    for _ in 0..<200 {
      #expect(FetchAhead.replacement(for: "B", in: pool, onHand: ["A"], order: .random, showing: ["A"]) == "A")
    }
  }
}
