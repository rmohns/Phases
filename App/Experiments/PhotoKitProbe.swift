import AppKit
import ImageIO
import Photos
import Security
import UniformTypeIdentifiers

/// Experiment branch `experiment/33-photokit` only; never merged. Issue #33
/// Phase 0 (docs/PLAN-GITHUB-ISSUE-33.md). Launching with
/// `-PhasesPhotoKitProbe <x0…x6>` runs one probe step and quits, without
/// starting the scheduler, so phases, settings and the wallpaper are left
/// alone (except x4, which sets the main display's wallpaper and puts it
/// back).
@main
enum Launcher {
  static func main() {
    if let step = PhotoKitProbe.step {
      PhotoKitProbe.runAndExit(step)
    } else {
      AppDefinition.main()
    }
  }
}

enum PhotoKitProbe {
  static var step: String? { UserDefaults.standard.string(forKey: "PhasesPhotoKitProbe") }
  static var albumTitle: String? { UserDefaults.standard.string(forKey: "PhasesProbeAlbum") }
  static var limit: Int { positive("PhasesProbeLimit") ?? 10 }
  static var seconds: Int { positive("PhasesProbeSeconds") ?? 180 }

  private static func positive(_ key: String) -> Int? {
    let value = UserDefaults.standard.integer(forKey: key)
    return value > 0 ? value : nil
  }

  static let folder = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    .appending(path: "PhasesProbe", directoryHint: .isDirectory)
  static var exportFolder: URL { folder.appending(path: "export", directoryHint: .isDirectory) }

  static func runAndExit(_ step: String) -> Never {
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    Task { @MainActor in
      let report = Report(step: step)
      await run(step, report)
      report.finish()
      exit(0)
    }
    app.run()
    exit(0)
  }

  @MainActor
  private static func run(_ step: String, _ r: Report) async {
    switch step.lowercased() {
    case "x0": x0(r)
    case "x1": await x1(r)
    case "x2": x2(r)
    case "x3": await x3(r)
    case "x4": await x4(r)
    case "x5": await x5(r)
    case "x6": x6(r)
    default: r.line("Unknown step \(step). Use x0…x6.")
    }
  }

  // MARK: X0 sandbox, home, caches, wallpaper store

  @MainActor
  private static func x0(_ r: Report) {
    let fmHome = FileManager.default.homeDirectoryForCurrentUser
    r.line("homeDirectoryForCurrentUser: \(fmHome.path)")
    r.line("NSHomeDirectory(): \(NSHomeDirectory())")
    r.line("real home (getpwuid): \(realHome.path)")
    r.line("caches folder: \(folder.path)")
    let storeTail = "Library/Application Support/com.apple.wallpaper/Store/Index.plist"
    for (label, base) in [("via homeDirectoryForCurrentUser", fmHome), ("via real home", realHome)] {
      let url = base.appending(path: storeTail)
      do {
        let data = try Data(contentsOf: url)
        r.line("wallpaper store \(label): readable, \(data.count) bytes")
      } catch {
        r.line("wallpaper store \(label): NOT readable: \(error.localizedDescription)")
      }
    }
    r.line("Photos status (no request): \(describe(PHPhotoLibrary.authorizationStatus(for: .readWrite)))")
  }

  // MARK: X1 permission

  @MainActor
  private static func x1(_ r: Report) async {
    r.line("status before: \(describe(PHPhotoLibrary.authorizationStatus(for: .readWrite)))")
    NSApp.activate()
    let start = Date()
    let result = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    r.line("request returned \(describe(result)) after \(seconds(since: start))")
    r.line("status after: \(describe(PHPhotoLibrary.authorizationStatus(for: .readWrite)))")
  }

  // MARK: X2 albums and order

  @MainActor
  private static func x2(_ r: Report) {
    guard authorized(r) else { return }
    r.line("== Your albums and folders (Photos sidebar order)")
    walk(PHCollectionList.fetchTopLevelUserCollections(with: nil), depth: 0, r)
    r.line("== Shared albums")
    let shared = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumCloudShared, options: nil)
    shared.enumerateObjects { album, _, _ in r.line(describe(album)) }
    if shared.count == 0 { r.line("(none)") }
    r.line("== Smart albums")
    PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
      .enumerateObjects { album, _, _ in r.line(describe(album)) }

    guard let album = findAlbum(r) else { return }
    r.line("== First \(limit) images in \"\(album.localizedTitle ?? "")\", default fetch order")
    listAssets(images(in: album, sortedByDate: false), r)
    r.line("== Same album sorted by creation date")
    listAssets(images(in: album, sortedByDate: true), r)
    r.line("Compare the first list with the album's order in Photos.")
  }

  private static func walk(_ collections: PHFetchResult<PHCollection>, depth: Int, _ r: Report) {
    let indent = String(repeating: "  ", count: depth)
    collections.enumerateObjects { collection, _, _ in
      if let list = collection as? PHCollectionList {
        r.line("\(indent)[folder] \(list.localizedTitle ?? "(untitled)")")
        walk(PHCollection.fetchCollections(in: list, options: nil), depth: depth + 1, r)
      } else if let album = collection as? PHAssetCollection {
        r.line(indent + describe(album))
      }
    }
  }

  private static func describe(_ album: PHAssetCollection) -> String {
    let all = PHAsset.fetchAssets(in: album, options: nil).count
    let imageCount = images(in: album, sortedByDate: false).count
    return "\(album.localizedTitle ?? "(untitled)") — type \(album.assetCollectionType.rawValue)/\(album.assetCollectionSubtype.rawValue), \(imageCount) images of \(all) items"
  }

  private static func listAssets(_ assets: PHFetchResult<PHAsset>, _ r: Report) {
    for index in 0..<min(limit, assets.count) {
      let asset = assets[index]
      let name = PHAssetResource.assetResources(for: asset).first?.originalFilename ?? "?"
      r.line("\(index + 1). \(name)  created \(asset.creationDate.map(stamp) ?? "?")  \(asset.pixelWidth)×\(asset.pixelHeight)  id \(asset.localIdentifier)")
    }
  }

  // MARK: X3 writing photos to disk

  @MainActor
  private static func x3(_ r: Report) async {
    guard authorized(r), let album = findAlbum(r) else { return }
    try? FileManager.default.createDirectory(at: exportFolder, withIntermediateDirectories: true)
    let assets = images(in: album, sortedByDate: false)
    r.line("Exporting the first \(min(limit, assets.count)) images to \(exportFolder.path)")
    for index in 0..<min(limit, assets.count) {
      let asset = assets[index]
      let resources = PHAssetResource.assetResources(for: asset)
      let name = resources.first?.originalFilename ?? "?"
      r.line("--- \(index + 1). \(name)  \(asset.pixelWidth)×\(asset.pixelHeight)")
      r.line("resources: " + resources.map { "\(resourceType($0.type)) \($0.uniformTypeIdentifier)" }.joined(separator: ", "))
      if asset.mediaSubtypes.contains(.photoLive) { r.line("Live Photo") }

      let local = await requestData(asset, network: false, timeout: 30)
      r.line("local copy (network off): \(local.summary)")
      var result = local
      if local.data == nil {
        result = await requestData(asset, network: true, timeout: 180)
        r.line("with download: \(result.summary)")
      }
      if resources.contains(where: { $0.type == .fullSizePhoto }) {
        let original = await requestData(asset, network: false, version: .original, timeout: 30)
        r.line("edited photo; original version (network off): \(original.summary)")
      }
      guard let data = result.data else { continue }
      let ext = result.uti.flatMap { UTType($0)?.preferredFilenameExtension } ?? "dat"
      let file = exportFolder.appending(path: "\(safe(asset.localIdentifier)).\(ext)")
      do {
        try data.write(to: file)
        r.line("wrote \(file.lastPathComponent), \(pixelSize(of: file))")
      } catch {
        r.line("write failed: \(error.localizedDescription)")
      }
    }
  }

  private struct DataResult {
    var data: Data?
    var uti: String?
    var info: [AnyHashable: Any]
    var elapsed: TimeInterval
    var progressSteps: Int
    var timedOut: Bool

    var summary: String {
      let time = String(format: "%.2f s", elapsed)
      let inCloud = (info[PHImageResultIsInCloudKey] as? Bool) == true ? ", in cloud" : ""
      let error = (info[PHImageErrorKey] as? Error).map { ", error: \($0.localizedDescription)" } ?? ""
      let cancelled = (info[PHImageCancelledKey] as? Bool) == true ? ", cancelled" : ""
      let timeout = timedOut ? ", TIMED OUT" : ""
      let size = data.map { ", \($0.count / 1024) KB \(uti ?? "?")" } ?? ", no data"
      return "\(time)\(size)\(inCloud)\(error)\(cancelled)\(timeout), \(progressSteps) progress callbacks"
    }
  }

  private final class Once: @unchecked Sendable {
    private let lock = NSLock()
    private var done = false
    var progressSteps = 0
    func claim() -> Bool {
      lock.lock(); defer { lock.unlock() }
      if done { return false }
      done = true
      return true
    }
    func tick() { lock.lock(); progressSteps += 1; lock.unlock() }
  }

  private static func requestData(
    _ asset: PHAsset, network: Bool, version: PHImageRequestOptionsVersion = .current, timeout: TimeInterval
  ) async -> DataResult {
    let options = PHImageRequestOptions()
    options.version = version
    options.deliveryMode = .highQualityFormat
    options.isNetworkAccessAllowed = network
    let once = Once()
    options.progressHandler = { _, _, _, _ in once.tick() }
    let start = Date()
    return await withCheckedContinuation { continuation in
      let id = PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, uti, _, info in
        guard once.claim() else { return }
        continuation.resume(returning: DataResult(
          data: data, uti: uti, info: info ?? [:], elapsed: Date().timeIntervalSince(start),
          progressSteps: once.progressSteps, timedOut: false))
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
        guard once.claim() else { return }
        PHImageManager.default().cancelImageRequest(id)
        continuation.resume(returning: DataResult(
          data: nil, uti: nil, info: [:], elapsed: timeout, progressSteps: once.progressSteps, timedOut: true))
      }
    }
  }

  // MARK: X4 a cached file as the wallpaper

  @MainActor
  private static func x4(_ r: Report) async {
    guard let screen = NSScreen.screens.first, let uuid = screen.displayUUID else {
      r.line("No main display found.")
      return
    }
    let files = (try? FileManager.default.contentsOfDirectory(at: exportFolder, includingPropertiesForKeys: nil)) ?? []
    guard let file = files.filter({ UTType(filenameExtension: $0.pathExtension)?.conforms(to: .image) == true })
      .sorted(by: { $0.lastPathComponent < $1.lastPathComponent }).first
    else {
      r.line("No exported image in \(exportFolder.path). Run x3 first in this build.")
      return
    }
    guard let before = latestChoice(displayUUID: uuid) else {
      r.line("Can't read the wallpaper store, so can't tell whether the main display shows an Aerial or other system wallpaper. Stopping without changing anything.")
      return
    }
    r.line("store before: provider \(before.provider)")
    guard before.provider == "com.apple.wallpaper.choice.image" else {
      r.line("Main display shows a system wallpaper (\(before.provider)); setting a file would lose it. Stopping without changing anything.")
      return
    }
    let workspace = NSWorkspace.shared
    let originalURL = workspace.desktopImageURL(for: screen)
    let options = workspace.desktopImageOptions(for: screen) ?? [:]
    r.line("original wallpaper: \(originalURL?.path ?? "none")")
    r.line("setting: \(file.path)")
    do {
      try workspace.setDesktopImageURL(file, for: screen, options: options)
      r.line("set: no error")
    } catch {
      r.line("set FAILED: \(error.localizedDescription)")
      return
    }
    try? await Task.sleep(for: .seconds(3))
    r.line("desktopImageURL now: \(workspace.desktopImageURL(for: screen)?.path ?? "none")")
    if let after = latestChoice(displayUUID: uuid) {
      r.line("store after: provider \(after.provider)")
      r.line("store entry: \(after.dump)")
    } else {
      r.line("store after: not readable")
    }
    r.line("Holding 20 s so you can look at the main display…")
    try? await Task.sleep(for: .seconds(20))
    guard let originalURL else {
      r.line("No original URL to put back.")
      return
    }
    do {
      try workspace.setDesktopImageURL(originalURL, for: screen, options: options)
      r.line("put back the original: no error")
    } catch {
      r.line("putting back the original FAILED: \(error.localizedDescription). Original was \(originalURL.path)")
    }
  }

  private struct Choice {
    var provider: String
    var dump: String
  }

  /// The most recently used desktop choice that applies to the display, read
  /// from the real home's wallpaper store (same walk as
  /// SystemWallpaperInspector, which reads through homeDirectoryForCurrentUser).
  private static func latestChoice(displayUUID: String) -> Choice? {
    let url = realHome.appending(path: "Library/Application Support/com.apple.wallpaper/Store/Index.plist")
    guard let data = try? Data(contentsOf: url),
      let store = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
    else { return nil }
    var containers: [Any?] = [store["AllSpacesAndDisplays"]]
    containers.append((store["Displays"] as? [String: Any])?[displayUUID])
    for case let space as [String: Any] in (store["Spaces"] as? [String: Any])?.values ?? [:].values {
      containers.append(space["Default"])
      containers.append((space["Displays"] as? [String: Any])?[displayUUID])
    }
    let entries: [(Date, [String: Any])] = containers.compactMap { container in
      guard let desktop = (container as? [String: Any])?["Desktop"] as? [String: Any],
        let content = desktop["Content"] as? [String: Any],
        let choice = (content["Choices"] as? [[String: Any]])?.first
      else { return nil }
      let lastUse = desktop["LastUse"] as? Date ?? desktop["LastSet"] as? Date ?? .distantPast
      return (lastUse, choice)
    }
    guard let latest = entries.max(by: { $0.0 < $1.0 })?.1 else { return nil }
    var dump = String(describing: latest)
    if let config = latest["Configuration"] as? Data,
      let plist = try? PropertyListSerialization.propertyList(from: config, format: nil) {
      dump += " Configuration: \(plist)"
    }
    return Choice(provider: latest["Provider"] as? String ?? "?", dump: String(dump.prefix(3000)))
  }

  // MARK: X5 change observer

  @MainActor
  private static func x5(_ r: Report) async {
    guard authorized(r), let album = findAlbum(r) else { return }
    let observer = ChangeLogger(album: album, assets: images(in: album, sortedByDate: false), report: r)
    PHPhotoLibrary.shared().register(observer)
    r.line("Watching \"\(album.localizedTitle ?? "")\" (\(observer.assets.count) images) for \(seconds) s. Add or remove a photo in Photos now.")
    try? await Task.sleep(for: .seconds(seconds))
    PHPhotoLibrary.shared().unregisterChangeObserver(observer)
    r.line("Stopped. \(observer.changeCount) change notifications in all.")
  }

  private final class ChangeLogger: NSObject, PHPhotoLibraryChangeObserver, @unchecked Sendable {
    let album: PHAssetCollection
    var assets: PHFetchResult<PHAsset>
    let report: Report
    var changeCount = 0

    init(album: PHAssetCollection, assets: PHFetchResult<PHAsset>, report: Report) {
      self.album = album
      self.assets = assets
      self.report = report
    }

    func photoLibraryDidChange(_ change: PHChange) {
      DispatchQueue.main.async { [self] in
        changeCount += 1
        let active = NSApp.isActive ? "active" : "in the background"
        guard let details = change.changeDetails(for: assets) else {
          report.line("change #\(changeCount) (Phases \(active)): nothing in this album")
          return
        }
        assets = details.fetchResultAfterChanges
        report.line("change #\(changeCount) (Phases \(active)): inserted \(details.insertedObjects.count), removed \(details.removedObjects.count), changed \(details.changedObjects.count), now \(assets.count) images")
      }
    }
  }

  // MARK: X6 stable IDs

  @MainActor
  private static func x6(_ r: Report) {
    guard authorized(r), let album = findAlbum(r) else { return }
    let assets = images(in: album, sortedByDate: false)
    let ids = (0..<min(limit, assets.count)).map { assets[$0].localIdentifier }
    let mappings = PHPhotoLibrary.shared().cloudIdentifierMappings(forLocalIdentifiers: ids)
    let lines = ids.map { id -> String in
      let cloud: String
      switch mappings[id] {
      case .success(let value): cloud = value.stringValue
      case .failure(let error): cloud = "error: \(error.localizedDescription)"
      case nil: cloud = "none"
      }
      return "\(id)\t\(cloud)"
    }
    let record = folder.appending(path: "x6-ids.txt")
    if let previous = try? String(contentsOf: record, encoding: .utf8) {
      let old = previous.split(separator: "\n").map(String.init)
      let same = zip(old, lines).filter { $0 == $1 }.count
      r.line("Compared with the last run's record: \(same) of \(lines.count) identical (local ID and cloud ID).")
      for (a, b) in zip(old, lines) where a != b { r.line("was: \(a)\nnow: \(b)") }
    } else {
      r.line("No earlier record; this run saves one.")
    }
    lines.forEach { r.line($0) }
    try? lines.joined(separator: "\n").write(to: record, atomically: true, encoding: .utf8)
  }

  // MARK: Helpers

  static var realHome: URL {
    guard let entry = getpwuid(getuid()), let dir = entry.pointee.pw_dir else {
      return FileManager.default.homeDirectoryForCurrentUser
    }
    return URL(filePath: String(cString: dir), directoryHint: .isDirectory)
  }

  private static func authorized(_ r: Report) -> Bool {
    let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    r.line("Photos status: \(describe(status))")
    if status == .authorized || status == .limited { return true }
    r.line("Not authorized. Run x1 first.")
    return false
  }

  private static func findAlbum(_ r: Report) -> PHAssetCollection? {
    guard let title = albumTitle else {
      r.line("No album given. Add -PhasesProbeAlbum \"<album name>\".")
      return nil
    }
    var found: PHAssetCollection?
    func search(_ collections: PHFetchResult<PHCollection>) {
      collections.enumerateObjects { collection, _, stop in
        if let album = collection as? PHAssetCollection, album.localizedTitle == title {
          found = album
          stop.pointee = true
        } else if let list = collection as? PHCollectionList {
          search(PHCollection.fetchCollections(in: list, options: nil))
          if found != nil { stop.pointee = true }
        }
      }
    }
    search(PHCollectionList.fetchTopLevelUserCollections(with: nil))
    for type in [PHAssetCollectionType.album, .smartAlbum] where found == nil {
      PHAssetCollection.fetchAssetCollections(with: type, subtype: .any, options: nil)
        .enumerateObjects { album, _, stop in
          if album.localizedTitle == title { found = album; stop.pointee = true }
        }
    }
    if found == nil { r.line("No album named \"\(title)\".") }
    return found
  }

  private static func images(in album: PHAssetCollection, sortedByDate: Bool) -> PHFetchResult<PHAsset> {
    let options = PHFetchOptions()
    options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
    if sortedByDate { options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)] }
    return PHAsset.fetchAssets(in: album, options: options)
  }

  private static func describe(_ status: PHAuthorizationStatus) -> String {
    switch status {
    case .notDetermined: "not determined"
    case .restricted: "restricted"
    case .denied: "denied"
    case .authorized: "authorized"
    case .limited: "limited"
    @unknown default: "unknown (\(status.rawValue))"
    }
  }

  private static func resourceType(_ type: PHAssetResourceType) -> String {
    switch type {
    case .photo: "photo"
    case .fullSizePhoto: "fullSizePhoto(edited)"
    case .alternatePhoto: "alternatePhoto"
    case .adjustmentData: "adjustmentData"
    case .adjustmentBasePhoto: "adjustmentBasePhoto"
    case .pairedVideo: "pairedVideo(Live)"
    case .fullSizePairedVideo: "fullSizePairedVideo"
    default: "type\(type.rawValue)"
    }
  }

  private static func pixelSize(of file: URL) -> String {
    guard let source = CGImageSourceCreateWithURL(file as CFURL, nil),
      let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
    else { return "unreadable as an image" }
    return "\(props[kCGImagePropertyPixelWidth] ?? "?")×\(props[kCGImagePropertyPixelHeight] ?? "?")"
  }

  private static func safe(_ id: String) -> String {
    id.replacingOccurrences(of: "/", with: "_")
  }

  private static func seconds(since start: Date) -> String {
    String(format: "%.1f s", Date().timeIntervalSince(start))
  }

  static func stamp(_ date: Date) -> String {
    date.formatted(.iso8601.year().month().day().time(includingFractionalSeconds: false))
  }

  /// Lines go to stdout and, at the end, to `PhasesProbe/<step>-<time>.txt`
  /// in Caches, plus `latest.txt`.
  final class Report: @unchecked Sendable {
    private let step: String
    private var lines: [String] = []

    init(step: String) {
      self.step = step
      line("Phases PhotoKit probe \(step) at \(Date().formatted())")
      line("build \(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") ?? "?"), cdhash \(Self.cdhash), at \(Bundle.main.bundlePath)")
      let container = ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"]
      line("sandboxed: \(container.map { "yes (\($0))" } ?? "no")")
    }

    func line(_ text: String) {
      print(text)
      lines.append(text)
    }

    func finish() {
      try? FileManager.default.createDirectory(at: PhotoKitProbe.folder, withIntermediateDirectories: true)
      let name = "\(step)-\(Int(Date().timeIntervalSince1970)).txt"
      let text = lines.joined(separator: "\n") + "\n"
      try? text.write(to: PhotoKitProbe.folder.appending(path: name), atomically: true, encoding: .utf8)
      try? text.write(to: PhotoKitProbe.folder.appending(path: "latest.txt"), atomically: true, encoding: .utf8)
    }

    /// The running code's cdhash, so a report says which build it came from.
    private static var cdhash: String {
      var code: SecCode?
      guard SecCodeCopySelf([], &code) == errSecSuccess, let code else { return "?" }
      var staticCode: SecStaticCode?
      guard SecCodeCopyStaticCode(code, [], &staticCode) == errSecSuccess, let staticCode else { return "?" }
      var info: CFDictionary?
      guard SecCodeCopySigningInformation(staticCode, SecCSFlags(rawValue: kSecCSSigningInformation), &info) == errSecSuccess,
        let dict = info as? [String: Any], let hash = dict[kSecCodeInfoUnique as String] as? Data
      else { return "?" }
      return hash.prefix(8).map { String(format: "%02x", $0) }.joined()
    }
  }
}
