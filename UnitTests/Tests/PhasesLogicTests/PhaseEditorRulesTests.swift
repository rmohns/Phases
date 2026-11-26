import Foundation
import Testing
@testable import PhasesLogic

/// The phase editor's rules (draft 63, GitHub issue #27).
struct OffsetPartsTests {
  /// `[D-starts-row]` The largest unit that divides evenly.
  @Test func showsTheLargestUnitThatDividesEvenly() {
    let twoHours = OffsetParts(minutes: -120)
    #expect(twoHours.direction == .before && twoHours.value == 2 && twoHours.unit == .hours)
    let ninety = OffsetParts(minutes: 90)
    #expect(ninety.direction == .after && ninety.value == 90 && ninety.unit == .minutes)
    let thirty = OffsetParts(minutes: -30)
    #expect(thirty.direction == .before && thirty.value == 30 && thirty.unit == .minutes)
    #expect(OffsetParts(minutes: 0).direction == .at)
  }

  /// `[D-starts-row]` Parts back to signed minutes.
  @Test func roundTripsToMinutes() {
    for minutes in [-720, -120, -90, -5, 0, 1, 45, 60, 600, 720] {
      #expect(OffsetParts(minutes: minutes).minutes == minutes)
    }
  }

  /// `[D-starts-row]` Limits are 1–720 minutes or 1–12 hours.
  @Test func clampsTypedValuesToTheLimits() {
    var parts = OffsetParts(minutes: -30)
    parts.setValue(900)
    #expect(parts.value == 720 && parts.minutes == -720)
    parts.setValue(0)
    #expect(parts.value == 1)
    parts.setUnit(.hours)
    parts.setValue(20)
    #expect(parts.value == 12 && parts.minutes == -720)
  }

  /// `[D-starts-row]` 30 minutes becomes 12 hours, not half an hour.
  @Test func changingTheUnitKeepsTheNumberClamped() {
    var parts = OffsetParts(minutes: 30)
    parts.setUnit(.hours)
    #expect(parts.value == 12 && parts.minutes == 720)
    var small = OffsetParts(minutes: 2 * 60)
    small.setUnit(.minutes)
    #expect(small.value == 2 && small.minutes == 2)
  }

  /// `[D-starts-row]` "at" is zero; leaving it starts from 30 minutes.
  @Test func atIsZeroAndLeavingItStartsFromThirtyMinutes() {
    var parts = OffsetParts(minutes: -2 * 60)
    parts.setDirection(.at)
    #expect(parts.minutes == 0)
    parts.setDirection(.after)
    #expect(parts.minutes == 30 && parts.unit == .minutes)
    var before = OffsetParts(minutes: 0)
    before.setDirection(.before)
    #expect(before.minutes == -30)
    // Switching between before and after keeps the number.
    var flip = OffsetParts(minutes: -45)
    flip.setDirection(.after)
    #expect(flip.minutes == 45)
  }
}

struct RotationChoiceTests {
  /// `[D-rotation-row]` Off and back on keeps the interval.
  @Test func onlyAtStartTurnsRotationOffAndBackOnKeepsTheInterval() {
    var phase = Phase(name: "P", trigger: .always)
    phase.isRotating = true
    phase.rotation = RotationInterval(value: 2, unit: .hours)
    #expect(phase.rotationChoice == .every(.hours))
    phase.rotationChoice = .onlyAtStart
    #expect(!phase.isRotating && phase.rotationSeconds == nil)
    phase.rotationChoice = .every(.hours)
    #expect(phase.isRotating && phase.rotation == RotationInterval(value: 2, unit: .hours))
    phase.rotationChoice = .every(.minutes)
    #expect(phase.rotation == RotationInterval(value: 2, unit: .minutes))
  }
}

struct StartReadoutTests {
  private let haverhill = SolarCalculator.Coordinate(latitude: 42.776, longitude: -71.077)
  private let longyearbyen = SolarCalculator.Coordinate(latitude: 78.22, longitude: 15.65)
  private let calendar = TestCalendar.newYork

  private func format(_ date: Date) -> String {
    let parts = calendar.dateComponents([.hour, .minute], from: date)
    return String(format: "%02d:%02d", parts.hour!, parts.minute!)
  }

  private func readout(_ trigger: PhaseTrigger, _ day: Date, at coordinate: SolarCalculator.Coordinate?) -> String? {
    StartReadout.text(for: trigger, on: day, at: coordinate, calendar: calendar, format: format)
  }

  /// `[D-start-readout]` "Today 6:12 AM (dawn 6:42 AM)".
  @Test func showsTodaysStartAndTheEvent() throws {
    let day = TestCalendar.date(2026, 11, 25)
    let dawn = try #require(SolarCalculator.time(of: .dawn, on: day, at: haverhill, calendar: calendar))
    let text = readout(.solar(.dawn, offsetMinutes: -30), day, at: haverhill)
    #expect(text == "Today \(format(dawn.addingTimeInterval(-30 * 60))) (dawn \(format(dawn)))")
  }

  /// `[D-start-readout]` Exactly at dusk: just the time.
  @Test func exactlyAtTheEventShowsOneTime() throws {
    let day = TestCalendar.date(2026, 11, 25)
    let dusk = try #require(SolarCalculator.time(of: .dusk, on: day, at: haverhill, calendar: calendar))
    #expect(readout(.solar(.dusk, offsetMinutes: 0), day, at: haverhill) == "Today \(format(dusk))")
  }

  /// `[D-start-readout]` Far north at midsummer there's no dusk.
  @Test func saysWhenTheEventDoesNotHappenToday() {
    #expect(readout(.solar(.dusk, offsetMinutes: 60), TestCalendar.date(2026, 6, 21), at: longyearbyen) == "No dusk today")
    #expect(readout(.solar(.dawn, offsetMinutes: 0), TestCalendar.date(2026, 12, 21), at: longyearbyen) == "No dawn today")
  }

  /// `[D-starts-row]` `[D-phase-status-inline]` Always explains itself;
  /// a clock time says nothing; no location leaves room for its message.
  @Test func otherTriggersAndNoLocation() {
    let day = TestCalendar.date(2026, 11, 25)
    #expect(readout(.always, day, at: nil) == "Used when no timed phase applies.")
    #expect(readout(.clockTime(minutes: 540), day, at: haverhill) == nil)
    #expect(readout(.solar(.dawn, offsetMinutes: -30), day, at: nil) == nil)
  }
}

struct EditorMessageTests {
  private let location = SolarCalculator.Coordinate(latitude: 42.776, longitude: -71.077)

  /// `[D-phase-status-inline]` Turned off goes under the name row and wins;
  /// location messages go under Starts.
  @Test func eachMessageSitsUnderTheRowThatFixesIt() {
    var dawn = Phase(name: "Dawn", trigger: .solar(.dawn, offsetMinutes: 0))
    let denied = PhaseAvailability(phase: dawn, savedLocation: location, isLocationDenied: true)
    #expect(denied.editorMessage(under: .starts) == .locationOff)
    #expect(denied.editorMessage(under: .name) == nil)
    #expect(DisabledReason.locationOff.offersLocationSettings)

    let noLocation = PhaseAvailability(phase: dawn, savedLocation: nil, isLocationDenied: false)
    #expect(noLocation.editorMessage(under: .starts) == .noLocationYet)
    #expect(!DisabledReason.noLocationYet.offersLocationSettings)

    dawn.isOn = false
    let offAndDenied = PhaseAvailability(phase: dawn, savedLocation: location, isLocationDenied: true)
    #expect(offAndDenied.editorMessage(under: .name) == .turnedOff)
    #expect(offAndDenied.editorMessage(under: .starts) == nil)

    let runs = PhaseAvailability(phase: Phase(name: "C", trigger: .clockTime(minutes: 60)), savedLocation: nil, isLocationDenied: false)
    #expect(runs.editorMessage(under: .name) == nil && runs.editorMessage(under: .starts) == nil)
  }
}

struct DisplayTabsTests {
  private let main = ConnectedDisplay(uuid: "A", name: "Built-in", size: CGSize(width: 1512, height: 982))
  private let portrait = ConnectedDisplay(uuid: "B", name: "Cinema HD", size: CGSize(width: 1080, height: 1920))
  private let ultrawide = ConnectedDisplay(uuid: "C", name: "LG Ultrawide", size: CGSize(width: 3440, height: 1440))

  /// `[D-display-tabs-visibility]` Two or more displays, or one with its own images.
  @Test func rowShowsForSeveralDisplaysOrOneWithItsOwnImages() {
    var phase = Phase(name: "P", trigger: .always)
    #expect(DisplayTabs.tabs(connected: [main], phase: phase) == nil)
    #expect(DisplayTabs.tabs(connected: [], phase: phase) == nil)
    #expect(DisplayTabs.tabs(connected: [main, portrait, ultrawide], phase: phase) == [main, portrait, ultrawide])
    phase.displayImageNames["A"] = []
    #expect(DisplayTabs.tabs(connected: [main], phase: phase) == [main])
  }

  /// `[D-connected-displays-only]` `[D-keep-display-settings]` A
  /// disconnected display has no tab, but its selection is kept.
  @Test func disconnectedDisplaysHaveNoTabButKeepTheirImages() {
    var phase = Phase(name: "P", trigger: .always)
    phase.displayImageNames["B"] = ["s:x.jpg"]
    #expect(DisplayTabs.tabs(connected: [main, ultrawide], phase: phase)?.map(\.uuid) == ["A", "C"])
    #expect(phase.displayImageNames["B"] == ["s:x.jpg"])
  }

  /// `[D-display-tabs]` A chosen display that disconnects falls back to Shared.
  @Test func selectionFallsBackToShared() {
    let tabs = [main, portrait]
    #expect(DisplayTabs.selection("B", among: tabs) == "B")
    #expect(DisplayTabs.selection("C", among: tabs) == nil)
    #expect(DisplayTabs.selection("A", among: nil) == nil)
    #expect(DisplayTabs.selection(nil, among: tabs) == nil)
  }

  /// `[D-display-tabs]` Captions.
  @Test func captions() {
    #expect(DisplayTabs.sharedCaption(count: 18) == "18 images")
    #expect(DisplayTabs.sharedCaption(count: 1) == "1 image")
    #expect(DisplayTabs.caption(ownCount: nil) == "Uses Shared")
    #expect(DisplayTabs.caption(ownCount: 1) == "Own · 1 image")
    #expect(DisplayTabs.caption(ownCount: 0) == "Own · 0 images")
  }

  /// `[D-display-tab-shapes]` One height, real proportions, capped width.
  @Test func outlinesKeepTheDisplaysProportions() {
    let standard = DisplayTabs.outlineSize(for: main.size, height: 32, maxWidth: 80)
    #expect(standard.height == 32 && abs(standard.width - 32 * 1512 / 982) < 0.01)
    let tall = DisplayTabs.outlineSize(for: portrait.size, height: 32, maxWidth: 80)
    #expect(tall.height == 32 && tall.width < tall.height)
    let wide = DisplayTabs.outlineSize(for: ultrawide.size, height: 32, maxWidth: 60)
    #expect(wide.width == 60 && abs(wide.height - 60 * 1440 / 3440) < 0.01)
  }

  /// `[D-sharing-per-phase]` The checkbox applies only with two or more
  /// connected displays using Shared.
  @Test func sharingAppliesWithTwoDisplaysUsingShared() {
    var phase = Phase(name: "P", trigger: .always)
    #expect(DisplayTabs.sharingApplies(connected: [main, portrait], phase: phase))
    #expect(!DisplayTabs.sharingApplies(connected: [main], phase: phase))
    phase.displayImageNames["B"] = []
    #expect(!DisplayTabs.sharingApplies(connected: [main, portrait], phase: phase))
    #expect(DisplayTabs.sharingApplies(connected: [main, portrait, ultrawide], phase: phase))
  }
}

struct DisplaySharingTests {
  /// `[D-sharing-per-phase]` Phases saved before draft 63 take the old
  /// app-wide preference; saved ones keep their own.
  @Test func olderPhasesTakeTheAppWidePreference() throws {
    let old = #"[{"id":"7F1C2E7E-3E7B-4C1E-9C1D-3E2C6F6B9A11","name":"Old","trigger":{"always":{}}}]"#
    let upgraded = try Phase.decodeSaved(Data(old.utf8), legacyDisplayMode: .differentPerDisplay)
    #expect(upgraded.first?.displayMode == .differentPerDisplay)
    let plain = try Phase.decodeSaved(Data(old.utf8), legacyDisplayMode: .sameOnAll)
    #expect(plain.first?.displayMode == .sameOnAll)

    var saved = Phase(name: "New", trigger: .always)
    saved.displayMode = .sameOnAll
    let data = try JSONEncoder().encode([saved])
    let reloaded = try Phase.decodeSaved(data, legacyDisplayMode: .differentPerDisplay)
    #expect(reloaded.first?.displayMode == .sameOnAll)
  }

  /// `[D-sharing-per-phase]` `[D-duplicate-phase]` New phases share one
  /// image; a duplicate copies its phase's setting.
  @Test func newPhasesShareAndDuplicatesCopy() {
    var phase = Phase(name: "P", trigger: .always)
    #expect(phase.displayMode == .sameOnAll)
    phase.displayMode = .differentPerDisplay
    #expect(phase.duplicate().displayMode == .differentPerDisplay)
  }

  /// `[D-own-images-start-from-shared]` Own images start as a copy of
  /// Shared; turning them off discards them.
  @Test func ownImagesStartFromShared() {
    var phase = Phase(name: "P", trigger: .always)
    phase.imageNames = ["s:a.jpg", "s:b.jpg"]
    phase.setOwnImages(true, for: "B")
    #expect(phase.displayImageNames["B"] == ["s:a.jpg", "s:b.jpg"])
    #expect(phase.hasOwnImages("B"))
    phase.setOwnImages(false, for: "B")
    #expect(!phase.hasOwnImages("B"))
  }
}
