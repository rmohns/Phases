import Foundation
import UniformTypeIdentifiers

/// Finds the images in the wallpaper folder, following symlinks and Finder
/// aliases [D-follow-links] and scanning each folder at most once
/// [D-scan-each-folder-once]. File system only, no AppKit, so the unit tests
/// can reach it.
enum FolderScan {
  /// One image: its path within the source folder [D-source-names] and where to read it.
  /// The URL differs from folder + name when an alias is on the way, since
  /// the file system follows symlinks in a path but not aliases.
  struct Item: Equatable {
    var name: String
    var url: URL
  }

  static let supportedTypes: [UTType] = [.jpeg, .png, .heic, .tiff]

  /// What a scan found.
  struct Result: Equatable {
    /// The folder's images in display order.
    var items: [Item]
    /// [D-links-outside-refused] Links, aliases, and folders macOS wouldn't
    /// let Phases read ("not permitted"), by their name in the source; ""
    /// is the source folder itself. Skipped like any item that can't be
    /// opened [D-follow-links]; the caller logs them. In the sandbox, a
    /// link pointing outside the source lands here.
    var refused: [String]
  }

  /// The folder's images in display order.
  static func items(in folder: URL, includesSubfolders: Bool) -> [Item] {
    scan(folder, includesSubfolders: includesSubfolders).items
  }

  static func scan(_ folder: URL, includesSubfolders: Bool) -> Result {
    var scan = Scan(includesSubfolders: includesSubfolders)
    guard let rootID = FolderID(folder) else { return Result(items: [], refused: []) }
    scan.visited.insert(rootID)
    // The real tree first, so every folder reachable directly is claimed
    // before any link can name it.
    scan.walk(folder, prefix: "")
    while !scan.pendingLinks.isEmpty {
      scan.pendingLinks.sort { inDisplayOrder($0.name, $1.name) }
      scan.follow(scan.pendingLinks.removeFirst())
    }
    return Result(
      items: scan.items.sorted { inDisplayOrder($0.name, $1.name) },
      refused: scan.refused.sorted { inDisplayOrder($0, $1) }
    )
  }

  /// Whether a folder's contents can be listed. [D-sandboxed] A folder
  /// found only by its saved location can't be, in the sandbox.
  static func canList(_ folder: URL) -> Bool {
    (try? FileManager.default.contentsOfDirectory(atPath: folder.path(percentEncoded: false))) != nil
  }

  /// [D-links-outside-refused] Whether an error is macOS refusing access
  /// (the sandbox, or a privacy or file permission), as opposed to the
  /// item being missing or broken.
  static func isNotPermitted(_ error: Error) -> Bool {
    let error = error as NSError
    if error.domain == NSCocoaErrorDomain,
      [NSFileReadNoPermissionError, NSFileWriteNoPermissionError].contains(error.code)
    {
      return true
    }
    if error.domain == NSPOSIXErrorDomain, [Int(EPERM), Int(EACCES)].contains(error.code) {
      return true
    }
    if let underlying = error.userInfo[NSUnderlyingErrorKey] as? Error {
      return isNotPermitted(underlying)
    }
    return false
  }

  /// Top-level files first, then each subfolder, sorted the way Finder
  /// sorts them.
  static func inDisplayOrder(_ lhs: String, _ rhs: String) -> Bool {
    let l = folder(of: lhs), r = folder(of: rhs)
    if l != r {
      if l.isEmpty || r.isEmpty { return l.isEmpty }
      return l.localizedStandardCompare(r) == .orderedAscending
    }
    return lhs.localizedStandardCompare(rhs) == .orderedAscending
  }

  /// The subfolder part of a relative path, or "" for a top-level file.
  static func folder(of name: String) -> String {
    (name as NSString).deletingLastPathComponent
  }

  /// Whether two URLs are the same folder on disk, however each was reached
  /// (a symlink, a different spelling) [D-image-sources].
  static func isSameFolder(_ lhs: URL, _ rhs: URL) -> Bool {
    guard let l = FolderID(lhs), let r = FolderID(rhs) else { return false }
    return l == r
  }
}

private struct Link {
  var url: URL
  var name: String
}

/// Where a folder really is: its volume and file number, the same however
/// it was reached.
private struct FolderID: Hashable {
  var device: Int32
  var inode: UInt64

  init?(_ url: URL) {
    var info = stat()
    guard stat(url.path(percentEncoded: false), &info) == 0 else { return nil }
    device = info.st_dev
    inode = info.st_ino
  }
}

private struct Scan {
  var includesSubfolders: Bool
  var visited: Set<FolderID> = []
  var items: [FolderScan.Item] = []
  var pendingLinks: [Link] = []
  /// [D-links-outside-refused]
  var refused: [String] = []

  private static let keys: Set<URLResourceKey> = [
    .isHiddenKey, .isAliasFileKey, .isDirectoryKey, .isPackageKey, .contentTypeKey,
  ]
  /// Longest chain of links to links that gets followed.
  private static let maxLinkHops = 8

  init(includesSubfolders: Bool) {
    self.includesSubfolders = includesSubfolders
  }

  /// Lists a folder's images and real subfolders; links wait in
  /// `pendingLinks` until the real tree is done.
  mutating func walk(_ folder: URL, prefix: String) {
    let children: [URL]
    do {
      children = try FileManager.default.contentsOfDirectory(
        at: folder,
        includingPropertiesForKeys: Array(Self.keys),
        options: []
      )
    } catch {
      if FolderScan.isNotPermitted(error) { refused.append(String(prefix.dropLast())) }
      return
    }
    for child in children {
      guard let values = try? child.resourceValues(forKeys: Self.keys), values.isHidden != true else { continue }
      let name = prefix + child.lastPathComponent
      // isAliasFile is true for symlinks as well as Finder aliases.
      if values.isAliasFile == true {
        pendingLinks.append(Link(url: child, name: name))
      } else {
        add(child, values: values, name: name)
      }
    }
  }

  mutating func follow(_ link: Link) {
    var target = link.url
    for _ in 0..<Self.maxLinkHops {
      // [D-links-outside-refused] Each step that can fail tells "not
      // permitted" (logged by the caller) from missing or broken (skipped
      // quietly, as before).
      do {
        target = try URL(resolvingAliasFileAt: target, options: [.withoutUI, .withoutMounting])
        let values = try target.resourceValues(forKeys: Self.keys)
        if values.isAliasFile == true { continue }
        if values.isHidden == true { return }
        // A refused privacy-protected image still reports its type, so check
        // it can actually be opened.
        if values.isDirectory != true { try FileHandle(forReadingFrom: target).close() }
        add(target, values: values, name: link.name)
      } catch {
        if FolderScan.isNotPermitted(error) { refused.append(link.name) }
      }
      return
    }
  }

  private mutating func add(_ url: URL, values: URLResourceValues, name: String) {
    if values.isDirectory == true {
      guard includesSubfolders, values.isPackage != true,
        let id = FolderID(url), visited.insert(id).inserted
      else { return }
      walk(url, prefix: name + "/")
    } else if let type = values.contentType,
      FolderScan.supportedTypes.contains(where: { type.conforms(to: $0) })
    {
      items.append(FolderScan.Item(name: name, url: url))
    }
  }
}
