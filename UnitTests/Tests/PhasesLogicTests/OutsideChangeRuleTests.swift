import Foundation
import Testing
@testable import PhasesLogic

/// [D-outside-change-rule]
struct OutsideChangeRuleTests {
  let display = "37D8832A-2D66-02CA-B9F7-8F30A301B230"
  let t0 = Date(timeIntervalSinceReferenceDate: 800_000_000)

  func image(_ name: String, setAt date: Date, display: String? = nil) -> WallpaperStoreEntry {
    WallpaperStoreEntry(displayUUID: display ?? self.display, isImage: true, fileName: name, lastSet: date)
  }

  @Test func pickInSystemSettingsCounts() {
    let old = ["space/A/\(display)": image("Canyon.png", setAt: t0)]
    let new = ["space/A/\(display)": image("Ergo.jpg", setAt: t0 + 60)]
    let changes = OutsideChangeRule.changes(from: old, to: new, ownSets: [], now: t0 + 61)
    #expect(changes == [OutsideChange(displayUUID: display, fileName: "Ergo.jpg", isImage: true)])
  }

  @Test func phasesOwnSetDoesNotCount() {
    let old = ["space/A/\(display)": image("Canyon.png", setAt: t0)]
    let new = ["space/A/\(display)": image("Ergo.jpg", setAt: t0 + 60)]
    let own = [OwnWallpaperSet(displayUUID: display, fileName: "Ergo.jpg", date: t0 + 59.75)]
    #expect(OutsideChangeRule.changes(from: old, to: new, ownSets: own, now: t0 + 60.1).isEmpty)
  }

  @Test func oldOwnSetOfTheSameImageCountsAgain() {
    let old = ["space/A/\(display)": image("Canyon.png", setAt: t0)]
    let new = ["space/A/\(display)": image("Ergo.jpg", setAt: t0 + 600)]
    let own = [OwnWallpaperSet(displayUUID: display, fileName: "Ergo.jpg", date: t0 + 60)]
    #expect(OutsideChangeRule.changes(from: old, to: new, ownSets: own, now: t0 + 600).count == 1)
  }

  @Test func ownSetOnAnotherDisplayDoesNotExcuse() {
    let old = ["space/A/\(display)": image("Canyon.png", setAt: t0)]
    let new = ["space/A/\(display)": image("Ergo.jpg", setAt: t0 + 60)]
    let own = [OwnWallpaperSet(displayUUID: "OTHER", fileName: "Ergo.jpg", date: t0 + 59.75)]
    #expect(OutsideChangeRule.changes(from: old, to: new, ownSets: own, now: t0 + 60).count == 1)
  }

  /// Opening or quitting System Settings and switching Spaces only touch
  /// "last used" (`[L-store-watch]`), which the reading leaves out.
  @Test func unchangedLastSetDoesNotCount() {
    let entries = ["space/A/\(display)": image("Canyon.png", setAt: t0), "space/B/\(display)": image("Ergo.jpg", setAt: t0)]
    #expect(OutsideChangeRule.changes(from: entries, to: entries, ownSets: [], now: t0 + 60).isEmpty)
  }

  @Test func aerialPickCounts() {
    let old = ["space/A/\(display)": image("Canyon.png", setAt: t0)]
    let aerial = WallpaperStoreEntry(displayUUID: display, isImage: false, fileName: nil, lastSet: t0 + 60)
    let changes = OutsideChangeRule.changes(from: old, to: ["space/A/\(display)": aerial], ownSets: [], now: t0 + 61)
    #expect(changes == [OutsideChange(displayUUID: display, fileName: nil, isImage: false)])
  }

  @Test func twoEntriesForOnePickReportOnce() {
    let old = ["space/A/\(display)": image("Canyon.png", setAt: t0), "space/A/default": image("Canyon.png", setAt: t0, display: nil)]
    var new = old
    new["space/A/\(display)"] = image("Ergo.jpg", setAt: t0 + 60)
    new["space/A/default"] = WallpaperStoreEntry(displayUUID: nil, isImage: true, fileName: "Ergo.jpg", lastSet: t0 + 60)
    let changes = OutsideChangeRule.changes(from: old, to: new, ownSets: [], now: t0 + 61)
    #expect(changes.count == 2)
    #expect(changes.contains { $0.displayUUID == nil })
  }

  @Test func newEntryCounts() {
    let old = ["space/A/\(display)": image("Canyon.png", setAt: t0)]
    var new = old
    new["space/B/\(display)"] = image("Ergo.jpg", setAt: t0 + 60)
    #expect(OutsideChangeRule.changes(from: old, to: new, ownSets: [], now: t0 + 61).count == 1)
  }

  /// Issue #29: a new Space (Mission Control's +, or an app going full
  /// screen) gets entries copied from the display, keeping its old
  /// "last set" time (`[L-new-space-pauses]`).
  @Test func newSpaceCopyingTheDisplayDoesNotCount() {
    let old = [
      "display/\(display)": image("Neon.jpg", setAt: t0),
      "space/A/\(display)": image("Neon.jpg", setAt: t0),
    ]
    var new = old
    new["space/B/default"] = image("Neon.jpg", setAt: t0, display: nil)
    new["space/B/\(display)"] = image("Neon.jpg", setAt: t0)
    #expect(OutsideChangeRule.changes(from: old, to: new, ownSets: [], now: t0 + 3600).isEmpty)
  }

  /// A pick on a Space that's new since the last reading stamps the
  /// current time, which is newer than anything already in the store.
  @Test func pickOnANewSpaceCounts() {
    let old = ["space/A/\(display)": image("Neon.jpg", setAt: t0)]
    var new = old
    new["space/B/\(display)"] = image("Ergo.jpg", setAt: t0 + 3600)
    let changes = OutsideChangeRule.changes(from: old, to: new, ownSets: [], now: t0 + 3601)
    #expect(changes == [OutsideChange(displayUUID: display, fileName: "Ergo.jpg", isImage: true)])
  }

  @Test func unreadableEarlierReadingCountsNothing() {
    let new = ["space/A/\(display)": image("Ergo.jpg", setAt: t0 + 60)]
    #expect(OutsideChangeRule.changes(from: [:], to: new, ownSets: [], now: t0 + 61).isEmpty)
  }

  @Test func readerFindsEntriesAndFileNames() throws {
    let configuration = try PropertyListSerialization.data(
      fromPropertyList: ["type": "imageFile", "url": ["relative": "file:///Users/me/Pictures/Ergo%20Proxy.jpg"]],
      format: .binary, options: 0)
    func desktop(_ provider: String, _ config: Data?, _ date: Date) -> [String: Any] {
      var choice: [String: Any] = ["Provider": provider]
      if let config { choice["Configuration"] = config }
      return ["Desktop": ["Content": ["Choices": [choice]], "LastSet": date, "LastUse": date]]
    }
    let store: [String: Any] = [
      "AllSpacesAndDisplays": desktop(WallpaperStoreReader.imageProvider, configuration, t0),
      "Spaces": ["SPACE": ["Default": desktop("default", nil, t0), "Displays": [display: desktop("com.apple.wallpaper.choice.aerials", nil, t0 + 5)]]],
    ]
    let entries = WallpaperStoreReader.entries(in: store)
    #expect(entries["all"] == WallpaperStoreEntry(displayUUID: nil, isImage: true, fileName: "Ergo Proxy.jpg", lastSet: t0))
    #expect(entries["space/SPACE/default"]?.isImage == false)
    #expect(entries["space/SPACE/\(display)"] == WallpaperStoreEntry(displayUUID: display, isImage: false, fileName: nil, lastSet: t0 + 5))
  }
}
