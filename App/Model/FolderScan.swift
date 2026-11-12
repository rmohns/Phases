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

  /// The folder's images in display order.
  static func items(in folder: URL, includesSubfolders: Bool) -> [Item] {
    var scan = Scan(includesSubfolders: includesSubfolders)
    guard let rootID = FolderID(folder) else { return [] }
    scan.visited.insert(rootID)
    // The real tree first, so every folder reachable directly is claimed
    // before any link can name it.
    scan.walk(folder, prefix: "")
    while !scan.pendingLinks.isEmpty {
      scan.pendingLinks.sort { inDisplayOrder($0.name, $1.name) }
      scan.follow(scan.pendingLinks.removeFirst())
    }
    return scan.items.sorted { inDisplayOrder($0.name, $1.name) }
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
    guard let children = try? FileManager.default.contentsOfDirectory(
      at: folder,
      includingPropertiesForKeys: Array(Self.keys),
      options: []
    ) else { return }
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
      guard let resolved = try? URL(resolvingAliasFileAt: target, options: [.withoutUI, .withoutMounting]) else {
        return
      }
      target = resolved
      guard let values = try? target.resourceValues(forKeys: Self.keys) else { return }  // broken
      if values.isAliasFile == true { continue }
      if values.isHidden == true { return }
      // A refused privacy-protected image still reports its type, so check
      // it can actually be opened.
      if values.isDirectory != true, (try? FileHandle(forReadingFrom: target).close()) == nil { return }
      add(target, values: values, name: link.name)
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
