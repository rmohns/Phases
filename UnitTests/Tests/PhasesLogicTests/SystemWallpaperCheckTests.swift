import Foundation
import Testing
@testable import PhasesLogic

/// [D-aerials-untouched] [D-store-unreadable-safe] [D-restore-file-check]
/// The store is built in memory; file checks use the temporary directory.
struct SystemWallpaperCheckTests {
  private let uuidA = "AAAAAAAA-0000-0000-0000-000000000001"
  private let uuidB = "BBBBBBBB-0000-0000-0000-000000000002"

  private func desktop(_ provider: String, lastUse: Date) -> [String: Any] {
    ["Desktop": ["Content": ["Choices": [["Provider": provider]]], "LastUse": lastUse]]
  }

  private func storeData(_ store: [String: Any]) throws -> Data {
    try PropertyListSerialization.data(fromPropertyList: store, format: .binary, options: 0)
  }

  private let image = "com.apple.wallpaper.choice.image"
  private let aerial = "com.apple.wallpaper.choice.aerials"
  private let earlier = Date(timeIntervalSinceReferenceDate: 800_000_000)
  private let later = Date(timeIntervalSinceReferenceDate: 800_000_100)

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

  @Test func mostRecentlyUsedEntryWins() throws {
    let store: [String: Any] = [
      "AllSpacesAndDisplays": desktop(aerial, lastUse: earlier),
      "Spaces": ["S1": ["Displays": [uuidA: desktop(image, lastUse: later)]]],
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
