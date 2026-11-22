import Foundation
import Testing
@testable import PhasesLogic

/// [D-follow-links] [D-scan-each-folder-once] Each test builds a folder in
/// the temporary directory; nothing outside it is touched.
struct FolderScanTests {
  private let root: URL
  private let fm = FileManager.default

  init() throws {
    root = fm.temporaryDirectory.appending(path: "FolderScanTests-\(UUID().uuidString)", directoryHint: .isDirectory)
    try fm.createDirectory(at: root, withIntermediateDirectories: true)
  }

  // MARK: Helpers

  /// The folder Phases scans, inside `root` so links can point outside it.
  private var library: URL { root.appending(path: "Library", directoryHint: .isDirectory) }

  private func folder(_ path: String, in base: URL? = nil) throws -> URL {
    let url = (base ?? library).appending(path: path, directoryHint: .isDirectory)
    try fm.createDirectory(at: url, withIntermediateDirectories: true)
    return url
  }

  @discardableResult
  private func image(_ path: String, in base: URL? = nil) throws -> URL {
    let url = (base ?? library).appending(path: path)
    try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data().write(to: url)
    return url
  }

  private func symlink(_ path: String, to destination: String) throws {
    try fm.createSymbolicLink(atPath: library.appending(path: path).path(percentEncoded: false), withDestinationPath: destination)
  }

  private func alias(_ path: String, to target: URL) throws {
    let data = try target.bookmarkData(options: .suitableForBookmarkFile, includingResourceValuesForKeys: nil, relativeTo: nil)
    try URL.writeBookmarkData(data, to: library.appending(path: path))
  }

  private func names(subfolders: Bool = true) -> [String] {
    FolderScan.items(in: library, includesSubfolders: subfolders).map(\.name)
  }

  private func cleanUp() { try? fm.removeItem(at: root) }

  // MARK: Plain folders

  @Test func plainFolderListsTopLevelFirst() throws {
    defer { cleanUp() }
    try image("b.png")
    try image("Winter/snow.jpg")
    try image("a.png")
    try image("notes.txt")
    #expect(names() == ["a.png", "b.png", "Winter/snow.jpg"])
    #expect(names(subfolders: false) == ["a.png", "b.png"])
  }

  // MARK: [D-follow-links]

  @Test func symlinkToImageIsListedUnderItsOwnName() throws {
    defer { cleanUp() }
    try image("real.png")
    try symlink("_link.png", to: "real.png")
    #expect(names() == ["_link.png", "real.png"])
  }

  @Test func aliasToImageIsListedAndPointsAtTheRealFile() throws {
    defer { cleanUp() }
    let real = try image("real.png", in: root)
    try folder("")
    try alias("_alias.png", to: real)
    let items = FolderScan.items(in: library, includesSubfolders: false)
    #expect(items.map(\.name) == ["_alias.png"])
    #expect(items.first?.url.resolvingSymlinksInPath() == real.resolvingSymlinksInPath())
  }

  @Test func symlinkedFolderCountsAsASubfolder() throws {
    defer { cleanUp() }
    let outside = try folder("Outside", in: root)
    try image("snow.jpg", in: outside)
    try folder("")
    try symlink("Linked", to: outside.path(percentEncoded: false))
    #expect(names() == ["Linked/snow.jpg"])
    #expect(names(subfolders: false) == [])
  }

  @Test func aliasedFolderCountsAsASubfolder() throws {
    defer { cleanUp() }
    let outside = try folder("Outside", in: root)
    let snow = try image("snow.jpg", in: outside)
    try folder("")
    try alias("Aliased", to: outside)
    let items = FolderScan.items(in: library, includesSubfolders: true)
    #expect(items.map(\.name) == ["Aliased/snow.jpg"])
    // The file system won't follow an alias inside a path, so the URL must
    // be the real one.
    #expect(items.first?.url.resolvingSymlinksInPath() == snow.resolvingSymlinksInPath())
    #expect(names(subfolders: false) == [])
  }

  @Test func brokenLinksAreSkipped() throws {
    defer { cleanUp() }
    try image("real.png")
    try symlink("broken.png", to: "nowhere.png")
    #expect(names() == ["real.png"])
  }

  @Test func hiddenLinksAndLinksToPackagesAreSkipped() throws {
    defer { cleanUp() }
    try image("real.png")
    try symlink(".hidden.png", to: "real.png")
    let package = try folder("Thing.app", in: root)
    try image("inside.png", in: package)
    try symlink("App", to: package.path(percentEncoded: false))
    #expect(names() == ["real.png"])
  }

  // MARK: [D-scan-each-folder-once]

  @Test func linkToTheChosenFolderAddsNothing() throws {
    defer { cleanUp() }
    try image("a.png")
    try symlink("Self", to: ".")
    try alias("SelfAlias", to: library)
    #expect(names() == ["a.png"])
  }

  @Test func loopBetweenTwoFoldersEnds() throws {
    defer { cleanUp() }
    let a = try folder("A", in: root)
    let b = try folder("B", in: root)
    try image("a.png", in: a)
    try image("b.png", in: b)
    try fm.createSymbolicLink(at: a.appending(path: "ToB"), withDestinationURL: b)
    try fm.createSymbolicLink(at: b.appending(path: "ToA"), withDestinationURL: a)
    try folder("")
    try symlink("Start", to: a.path(percentEncoded: false))
    #expect(names() == ["Start/a.png", "Start/ToB/b.png"])
  }

  @Test func directPathWinsOverALink() throws {
    defer { cleanUp() }
    try image("Zebra/z.png")
    // "Apple" sorts before "Zebra", but the direct path still names it.
    try symlink("Apple", to: "Zebra")
    #expect(names() == ["Zebra/z.png"])
  }

  @Test func firstLinkInDisplayOrderNamesAFolderOnlyLinksReach() throws {
    defer { cleanUp() }
    let outside = try folder("Outside", in: root)
    try image("o.png", in: outside)
    try folder("")
    try symlink("Second", to: outside.path(percentEncoded: false))
    try symlink("First", to: outside.path(percentEncoded: false))
    #expect(names() == ["First/o.png"])
  }

  @Test func twoLinksToOneImageListItTwice() throws {
    defer { cleanUp() }
    try image("real.png")
    try symlink("one.png", to: "real.png")
    try symlink("two.png", to: "real.png")
    #expect(names() == ["one.png", "real.png", "two.png"])
  }

  // MARK: [D-links-outside-refused]

  /// A folder outside the library that nobody may enter (mode 000),
  /// standing in for the sandbox refusing a link's target. Restored before
  /// clean-up so it can be deleted.
  private func lockedFolder() throws -> URL {
    let locked = try folder("Locked", in: root)
    try image("hidden.png", in: locked)
    try folder("Inner", in: locked)
    try image("Inner/deep.png", in: locked)
    try fm.setAttributes([.posixPermissions: 0o000], ofItemAtPath: locked.path(percentEncoded: false))
    return locked
  }

  private func unlock(_ url: URL) {
    try? fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path(percentEncoded: false))
  }

  @Test func linkToAnImageItCantReadIsSkippedAndNamed() throws {
    let locked = try lockedFolder()
    defer { unlock(locked); cleanUp() }
    try image("real.png")
    try symlink("_out.png", to: locked.appending(path: "hidden.png").path(percentEncoded: false))
    let result = FolderScan.scan(library, includesSubfolders: true)
    #expect(result.items.map(\.name) == ["real.png"])
    #expect(result.refused == ["_out.png"])
  }

  @Test func linkToAFolderItCantListIsSkippedAndNamed() throws {
    let locked = try lockedFolder()
    defer { unlock(locked); cleanUp() }
    try image("real.png")
    try symlink("Out", to: locked.path(percentEncoded: false))
    let result = FolderScan.scan(library, includesSubfolders: true)
    #expect(result.items.map(\.name) == ["real.png"])
    #expect(result.refused == ["Out"])
  }

  @Test func brokenLinkIsSkippedButNotCalledRefused() throws {
    defer { cleanUp() }
    try image("real.png")
    try symlink("gone.png", to: root.appending(path: "nowhere.png").path(percentEncoded: false))
    let result = FolderScan.scan(library, includesSubfolders: true)
    #expect(result.items.map(\.name) == ["real.png"])
    #expect(result.refused.isEmpty)
  }

  @Test func sourceFolderItCantListIsRefusedAsTheFolder() throws {
    let locked = try lockedFolder()
    defer { unlock(locked); cleanUp() }
    let result = FolderScan.scan(locked, includesSubfolders: true)
    #expect(result.items.isEmpty)
    #expect(result.refused == [""])
    #expect(!FolderScan.canList(locked))
  }

  @Test func permissionErrorsAreToldFromOthers() {
    #expect(FolderScan.isNotPermitted(NSError(domain: NSPOSIXErrorDomain, code: Int(EPERM))))
    #expect(FolderScan.isNotPermitted(NSError(domain: NSCocoaErrorDomain, code: NSFileReadNoPermissionError)))
    let wrapped = NSError(
      domain: NSCocoaErrorDomain, code: NSFileReadUnknownError,
      userInfo: [NSUnderlyingErrorKey: NSError(domain: NSPOSIXErrorDomain, code: Int(EACCES))]
    )
    #expect(FolderScan.isNotPermitted(wrapped))
    #expect(!FolderScan.isNotPermitted(NSError(domain: NSCocoaErrorDomain, code: NSFileReadNoSuchFileError)))
  }
}
