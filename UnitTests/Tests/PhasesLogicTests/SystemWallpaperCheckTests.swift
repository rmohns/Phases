import Foundation
import Testing
@testable import PhasesLogic

/// [D-aerials-untouched] [D-store-unreadable-safe] [D-restore-file-check]
/// The store is built in memory; file checks use the temporary directory.
struct SystemWallpaperCheckTests {
  private let uuidA = "AAAAAAAA-0000-0000-0000-000000000001"
  private let uuidB = "BBBBBBBB-0000-0000-0000-000000000002"

  private func desktop(_ provider: String, lastSet: Date? = nil, lastUse: Date) -> [String: Any] {
    var entry: [String: Any] = ["Content": ["Choices": [["Provider": provider]]], "LastUse": lastUse]
    entry["LastSet"] = lastSet
    return ["Desktop": entry]
  }

  private func storeData(_ store: [String: Any]) throws -> Data {
    try PropertyListSerialization.data(fromPropertyList: store, format: .binary, options: 0)
  }

  private let image = "com.apple.wallpaper.choice.image"
  private let aerial = "com.apple.wallpaper.choice.aerials"
  private let earlier = Date(timeIntervalSinceReferenceDate: 800_000_000)
  private let later = Date(timeIntervalSinceReferenceDate: 800_000_100)
  private let latest = Date(timeIntervalSinceReferenceDate: 800_000_200)
  /// The provider macOS 27.2 stored for the first Aerial in System
  /// Settings' Aerial row (San Francisco sunset; 2026-11-27, Sandbox
  /// check 2).
  private let aerialDefault = "default"

  // MARK: Reading the store

  @Test func unreadableStoreMakesEveryDisplayUncheckedNotImage() {
    // The sandbox without its exception: the read fails [L-sandbox-x0-paths].
    let kinds = SystemWallpaperCheck.kinds(storeData: nil, displays: [1: uuidA, 2: uuidB])
    #expect(kinds == [1: .unchecked, 2: .unchecked])
  }

  @Test func garbledStoreIsUnchecked() {
    let kinds = SystemWallpaperCheck.kinds(storeData: Data("not a plist".utf8), displays: [1: uuidA])
    #expect(kinds == [1: .unchecked])
  }

  @Test func aerialOnADisplayIsSystem() throws {
    let store: [String: Any] = ["Displays": [uuidA: desktop(aerial, lastUse: later)]]
    let kinds = SystemWallpaperCheck.kinds(storeData: try storeData(store), displays: [1: uuidA])
    #expect(kinds == [1: .system])
  }

  @Test func stillImageIsImage() throws {
    let store: [String: Any] = ["Displays": [uuidA: desktop(image, lastUse: later)]]
    let kinds = SystemWallpaperCheck.kinds(storeData: try storeData(store), displays: [1: uuidA])
    #expect(kinds == [1: .image])
  }

  @Test func withNoLastSetTheMostRecentlyUsedEntryWins() throws {
    let store: [String: Any] = [
      "AllSpacesAndDisplays": desktop(aerial, lastUse: earlier),
      "Spaces": ["S1": ["Displays": [uuidA: desktop(image, lastUse: later)]]],
    ]
    let kinds = SystemWallpaperCheck.kinds(storeData: try storeData(store), displays: [1: uuidA])
    #expect(kinds == [1: .image])
  }

  @Test func anAerialPickOutranksOlderStillsUsedSince() throws {
    // [Q-store-kind-lastset] Regression, Sandbox check 2 (2026-11-27): an
    // Aerial picked on the display, and other Spaces' still-image entries
    // whose LastUse macOS moved later (as a pick on another display does).
    // Ranked by LastUse, the stills won and Quit put a still frame over
    // the Aerial.
    let store: [String: Any] = [
      "Displays": [uuidA: desktop(aerialDefault, lastSet: later, lastUse: later)],
      "Spaces": [
        "": [
          "Default": desktop(image, lastSet: earlier, lastUse: latest),
          "Displays": [uuidA: desktop(image, lastSet: earlier, lastUse: latest)],
        ],
        "S2": ["Default": desktop(image, lastSet: earlier, lastUse: latest)],
      ],
    ]
    let readings = SystemWallpaperCheck.readings(storeData: try storeData(store), displays: [1: uuidA])
    #expect(readings[1]?.kind == .system)
    #expect(readings[1]?.decidedBy?.place == "Displays")
    #expect(readings[1]?.entryCount == 4)
  }

  @Test func anotherDisplaysPickInTheSpaceDefaultDoesNotDecide() throws {
    // [Q-store-kind-lastset] Regression, Sandbox check 2 run 4
    // (2026-11-27): a still picked on display A, then an Aerial on display
    // B. macOS stamps the Space's Default with B's pick, later than A's
    // own entry; ranked together, A read as a system wallpaper.
    let store: [String: Any] = [
      "Displays": [
        uuidA: desktop(image, lastSet: earlier, lastUse: later),
        uuidB: desktop(aerialDefault, lastSet: later, lastUse: later),
      ],
      "Spaces": [
        "S1": [
          "Default": desktop(aerialDefault, lastSet: later, lastUse: later),
          "Displays": [uuidB: desktop(aerialDefault, lastSet: later, lastUse: later)],
        ]
      ],
    ]
    let readings = SystemWallpaperCheck.readings(storeData: try storeData(store), displays: [1: uuidA, 2: uuidB])
    #expect(readings[1]?.kind == .image)
    #expect(readings[1]?.decidedBy?.place == "Displays")
    #expect(readings[2]?.kind == .system)
  }

  @Test func aSpaceDefaultDecidesWhenTheDisplayHasNoEntryOfItsOwn() throws {
    let store: [String: Any] = [
      "AllSpacesAndDisplays": desktop(image, lastSet: earlier, lastUse: earlier),
      "Spaces": ["S1": ["Default": desktop(aerial, lastSet: later, lastUse: later)]],
    ]
    let readings = SystemWallpaperCheck.readings(storeData: try storeData(store), displays: [1: uuidA])
    #expect(readings[1]?.kind == .system)
    #expect(readings[1]?.decidedBy?.place == "Space S1 Default")
  }

  @Test func lastUseBreaksATieInLastSet() throws {
    let store: [String: Any] = [
      "Displays": [uuidA: desktop(aerialDefault, lastSet: later, lastUse: later)],
      "Spaces": ["S1": ["Displays": [uuidA: desktop(image, lastSet: later, lastUse: latest)]]],
    ]
    let kinds = SystemWallpaperCheck.kinds(storeData: try storeData(store), displays: [1: uuidA])
    #expect(kinds == [1: .image])
  }

  @Test func knownLimitAStillPickedLaterOnAnotherSpaceWins() throws {
    // [Q-store-kind-lastset] Accepted limit (author, 2026-11-27): the store
    // doesn't say which Space is showing, so a still picked later on
    // another Space outranks an Aerial picked earlier on this one. This
    // test pins the limit down; it is not a bug to fix.
    let store: [String: Any] = [
      "Spaces": [
        "Showing": ["Displays": [uuidA: desktop(aerial, lastSet: earlier, lastUse: latest)]],
        "Other": ["Displays": [uuidA: desktop(image, lastSet: later, lastUse: later)]],
      ]
    ]
    let kinds = SystemWallpaperCheck.kinds(storeData: try storeData(store), displays: [1: uuidA])
    #expect(kinds == [1: .image])
  }

  @Test func displayWithNoEntryIsUnchecked() throws {
    let store: [String: Any] = ["Displays": [uuidA: desktop(image, lastUse: later)]]
    let kinds = SystemWallpaperCheck.kinds(storeData: try storeData(store), displays: [1: uuidA, 2: uuidB])
    #expect(kinds == [1: .image, 2: .unchecked])
  }

  @Test func displayWithoutAUUIDIsUnchecked() throws {
    let store: [String: Any] = ["AllSpacesAndDisplays": desktop(image, lastUse: later)]
    let kinds = SystemWallpaperCheck.kinds(storeData: try storeData(store), displays: [1: nil])
    #expect(kinds == [1: .unchecked])
  }

  // MARK: What Quit does

  @Test func quitLeavesAnUncheckedDisplayAlone() {
    let action = SystemWallpaperCheck.restoreAction(kind: .unchecked, imagePath: "/x.heic", file: .exists)
    #expect(action == .leaveAlone(.unchecked))
  }

  @Test func quitLeavesAnAerialAlone() {
    let action = SystemWallpaperCheck.restoreAction(kind: .system, imagePath: "/DefaultDesktop.heic", file: .exists)
    #expect(action == .leaveAlone(.systemWallpaper))
  }

  @Test func quitRestoresAnImageThatExists() {
    #expect(SystemWallpaperCheck.restoreAction(kind: .image, imagePath: "/x.jpg", file: .exists) == .restore)
  }

  @Test func quitRestoresAnImageItIsNotAllowedToLookAt() {
    // Sandboxed, outside every source: macOS can still set it
    // [L-sandbox-x4-container-wallpaper].
    #expect(SystemWallpaperCheck.restoreAction(kind: .image, imagePath: "/x.jpg", file: .unknown) == .restore)
  }

  @Test func quitSkipsAnImageThatIsGone() {
    let action = SystemWallpaperCheck.restoreAction(kind: .image, imagePath: "/x.jpg", file: .missing)
    #expect(action == .leaveAlone(.fileMissing))
  }

  @Test func quitSkipsWhenNoImageWasRecorded() {
    #expect(SystemWallpaperCheck.restoreAction(kind: .image, imagePath: nil, file: .missing) == .leaveAlone(.noImage))
  }

  // MARK: File state

  @Test func fileStateTellsMissingFromNotAllowed() throws {
    let fm = FileManager.default
    let root = fm.temporaryDirectory.appending(path: "SystemWallpaperCheckTests-\(UUID().uuidString)", directoryHint: .isDirectory)
    let locked = root.appending(path: "Locked", directoryHint: .isDirectory)
    try fm.createDirectory(at: locked, withIntermediateDirectories: true)
    let file = root.appending(path: "here.jpg")
    try Data([1]).write(to: file)
    let hidden = locked.appending(path: "inside.jpg")
    try Data([1]).write(to: hidden)
    // No search permission on the folder: stat of the file inside fails
    // with EACCES, standing in for the sandbox's refusal.
    try fm.setAttributes([.posixPermissions: 0o000], ofItemAtPath: locked.path(percentEncoded: false))
    defer {
      try? fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: locked.path(percentEncoded: false))
      try? fm.removeItem(at: root)
    }

    #expect(SystemWallpaperCheck.fileState(atPath: file.path(percentEncoded: false)) == .exists)
    #expect(SystemWallpaperCheck.fileState(atPath: root.appending(path: "gone.jpg").path(percentEncoded: false)) == .missing)
    #expect(SystemWallpaperCheck.fileState(atPath: hidden.path(percentEncoded: false)) == .unknown)
  }

  @Test func storeIsFoundInTheRealHomeNotTheContainer() {
    // [Q-sandbox-container-home]
    let home = URL(filePath: "/Users/someone", directoryHint: .isDirectory)
    #expect(
      SystemWallpaperCheck.storeFile(home: home).path(percentEncoded: false)
        == "/Users/someone/Library/Application Support/com.apple.wallpaper/Store/Index.plist"
    )
    #expect(SystemWallpaperCheck.storeFolder().path(percentEncoded: false).hasPrefix(SourceLocation.realHome.path(percentEncoded: false)))
  }
}
