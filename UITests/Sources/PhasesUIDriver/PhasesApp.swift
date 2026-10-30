import AppKit
import ApplicationServices

/// One test-mode instance of Phases [D-ui-test-mode], driven through the AX
/// API with real mouse and key events [D-ui-test-runner].
@MainActor
public final class PhasesApp {
  public let running: NSRunningApplication
  public let app: AXNode
  private let savedLayout: SavedLayout

  private init(running: NSRunningApplication, savedLayout: SavedLayout) {
    self.running = running
    self.savedLayout = savedLayout
    app = .application(pid: running.processIdentifier)
  }

  // MARK: - Launch and quit

  /// Launches a new instance in test mode and waits for its window. A
  /// Phases the author is already running is left alone.
  public static func launch() async throws -> PhasesApp {
    guard AXIsProcessTrusted() else {
      throw UITestFailure("The app running these tests needs Accessibility permission (System Settings › Privacy & Security › Accessibility).")
    }
    let configuration = NSWorkspace.OpenConfiguration()
    configuration.createsNewApplicationInstance = true
    configuration.activates = true
    configuration.arguments = [
      "-PhasesUITestMode", "YES",
      "-PhasesUITestImages", TestImages.folder.path(percentEncoded: false),
      "-ApplePersistenceIgnoreState", "YES",
    ]
    let url = try appURL()
    // [D-ui-test-mode] AppKit keeps the window frame and sidebar layout in
    // the normal settings, outside test mode's store. Clear them so every
    // launch starts from the defaults, and put the author's back on quit.
    let savedLayout = SavedLayout.clear(for: Bundle(url: url)?.bundleIdentifier ?? "")
    let running: NSRunningApplication
    do {
      running = try await NSWorkspace.shared.openApplication(at: url, configuration: configuration)
    } catch {
      savedLayout.restore()
      throw error
    }
    let phases = PhasesApp(running: running, savedLayout: savedLayout)
    do {
      try await phases.openWindowFromMenuBar()
      _ = try await waitFor("the Phases window", timeout: .seconds(15)) { phases.windowIfOpen }
      try await phases.bringToFront()
      // Let the deferred initial focus [D-initial-focus-sidebar] and the
      // first layout pass settle.
      try await Task.sleep(for: .seconds(1))
    } catch {
      phases.quit()
      throw error
    }
    return phases
  }

  /// Force-quits (nothing to save in test mode), waits for the process to
  /// end, then restores the author's window layout.
  public func quit() {
    running.forceTerminate()
    let deadline = Date().addingTimeInterval(5)
    while !running.isTerminated, Date() < deadline {
      RunLoop.current.run(until: Date().addingTimeInterval(0.05))
    }
    savedLayout.restore()
  }

  /// Closes the window with its close button. Phases then hands focus to
  /// another app [D-close-stays-here]; the window is hidden, not destroyed.
  public func closeWindow() async throws {
    let window = try window()
    guard let close = window.children.first(where: { $0.string(kAXSubroleAttribute) == kAXCloseButtonSubrole }) else {
      throw UITestFailure("No close button; window has: \(window.children.map(\.summary))")
    }
    try await click(close)
    try await waitUntil("the window to close") { windowIfOpen == nil }
  }

  /// Reopens the window from the menu bar, as on launch.
  public func reopenWindow() async throws {
    try await openWindowFromMenuBar()
    _ = try await waitFor("the Phases window", timeout: .seconds(10)) { windowIfOpen }
    try await bringToFront()
    try await Task.sleep(for: .seconds(1))
  }

  /// Opens the window the way the author does: a real click on the menu
  /// bar item, then on Open Phases…. AX presses opened it without
  /// activating Phases the way a click does, which skipped the focus bug
  /// its test guards (2026-10-29).
  private func openWindowFromMenuBar() async throws {
    let item = try await waitFor("Phases' menu bar item", timeout: .seconds(10)) {
      app.node("AXExtrasMenuBar")?.children.first
    }
    // Active before the window appears, as after a person's click: macOS
    // picks a window's first focus when it first becomes key
    // [D-initial-focus-sidebar]. Best effort; the click may do it anyway.
    try? await bringToFront()
    try await requireWideMenuBar(item)
    try await clickOwnElement(item, what: "the menu bar item")
    let open = try await waitFor("Open Phases… in the menu", timeout: .seconds(5)) {
      item.first { $0.role == kAXMenuItemRole && $0.title == "Open Phases…" }
    }
    try await clickOwnElement(open, what: "Open Phases…")
  }

  /// [D-ui-menubar-wide] Narrow displays can run out of menu bar room and
  /// hide Phases' item, so its menu is only used on a display at least
  /// 1200 pt wide. If the item is on a narrower one, moves the pointer to a
  /// wide display (the active menu bar can follow it) and looks again. No
  /// wide display at all means the setup is wrong: fail and say so aloud.
  private func requireWideMenuBar(_ item: AXNode) async throws {
    let minimumWidth: CGFloat = 1200
    var count: UInt32 = 0
    var ids = [CGDirectDisplayID](repeating: 0, count: 16)
    CGGetActiveDisplayList(16, &ids, &count)
    let displays = ids.prefix(Int(count)).map(CGDisplayBounds)
    guard let wide = displays.first(where: { $0.width >= minimumWidth }) else {
      let message = "No display is at least \(Int(minimumWidth)) points wide; Phases' menu bar item can't be relied on"
      let say = Process()
      say.executableURL = URL(filePath: "/usr/bin/say")
      say.arguments = ["Robert, the UI tests need a display at least 1200 points wide, and none is connected."]
      try? say.run()
      throw UITestFailure(message)
    }
    func itemDisplay() -> CGRect? {
      guard let frame = item.frame else { return nil }
      return displays.first { $0.contains(CGPoint(x: frame.midX, y: frame.midY)) }
    }
    if let display = itemDisplay(), display.width >= minimumWidth { return }
    try await SyntheticInput.move(to: CGPoint(x: wide.midX, y: wide.midY))
    guard let display = itemDisplay(), display.width >= minimumWidth else {
      throw UITestFailure(
        "Phases' menu bar item is on a display narrower than \(Int(minimumWidth)) points (\(itemDisplay().map { "\($0)" } ?? "none")), and moving the pointer to \(wide) didn't move it; make a wide display's menu bar active"
      )
    }
  }

  /// [D-ui-test-runner] For clicks outside the window (menu bar, menu):
  /// clicks only if the point belongs to this test instance, so a hidden
  /// item `[Q-bartender-menubar]` can't turn into a click on another app.
  private func clickOwnElement(_ node: AXNode, what: String) async throws {
    guard let frame = node.frame else { throw UITestFailure("No frame for \(what)") }
    let point = CGPoint(x: frame.midX, y: frame.midY)
    var hit: AXUIElement?
    var pid: pid_t = 0
    guard AXUIElementCopyElementAtPosition(AXUIElementCreateSystemWide(), Float(point.x), Float(point.y), &hit) == .success,
      let hit, AXUIElementGetPid(hit, &pid) == .success, pid == running.processIdentifier
    else {
      throw UITestFailure("\(what) at \(point) isn't this test instance's (hidden by a menu bar manager?); sent no click")
    }
    try await SyntheticInput.click(at: point)
  }

  /// `PHASES_APP`, or the newest Debug build Bitrig made for this project.
  private static func appURL() throws -> URL {
    if let path = ProcessInfo.processInfo.environment["PHASES_APP"] {
      return URL(filePath: path, directoryHint: .isDirectory)
    }
    // UITests/Sources/PhasesUIDriver/PhasesApp.swift → project folder.
    let project = URL(filePath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
      .deletingLastPathComponent().deletingLastPathComponent()
    let builds = project.deletingLastPathComponent().deletingLastPathComponent()
      .appending(path: "Builds/\(project.lastPathComponent)/Apps/Debug/Phases.app")
    let fm = FileManager.default
    let candidates = (try? fm.contentsOfDirectory(at: builds, includingPropertiesForKeys: [.contentModificationDateKey])) ?? []
    let newest = candidates
      .map { $0.appending(path: "Phases.app") }
      .filter { fm.fileExists(atPath: $0.path(percentEncoded: false)) }
      .max { modified($0) < modified($1) }
    guard let newest else {
      throw UITestFailure("No built Phases.app under \(builds.path(percentEncoded: false)); build first, or set PHASES_APP.")
    }
    return newest
  }

  private static func modified(_ url: URL) -> Date {
    (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
  }

  // MARK: - Reading the window

  /// The Phases window. Found by role, not title: the title follows the
  /// selection ("Afternoon", "Settings").
  private var windowIfOpen: AXNode? {
    app.nodes(kAXWindowsAttribute).first { $0.string(kAXSubroleAttribute) == kAXStandardWindowSubrole }
  }

  public func window() throws -> AXNode {
    guard let window = windowIfOpen else { throw UITestFailure("The Phases window isn't open") }
    return window
  }

  public func element(_ identifier: String) throws -> AXNode {
    guard let node = try window().first(identifier: identifier) else {
      throw UITestFailure("No element with accessibility identifier \"\(identifier)\" [D-ui-test-ids]")
    }
    return node
  }

  public func focusedElement() -> AXNode? {
    app.node(kAXFocusedUIElementAttribute)
  }

  /// The divider between the sidebar and the detail pane.
  public func splitter() throws -> AXNode {
    let window = try window()
    let windowFrame = window.frame ?? .zero
    let splitters = window.descendants().filter { $0.role == kAXSplitterRole }
    guard let splitter = splitters
      .filter({ ($0.frame?.minX ?? 0) > windowFrame.minX + 20 })
      .min(by: { ($0.frame?.minX ?? 0) < ($1.frame?.minX ?? 0) })
    else {
      throw UITestFailure("No sidebar divider found; window has: \(window.children.map(\.summary))")
    }
    return splitter
  }

  /// From the window's left edge to the divider: the sidebar runs the full
  /// window height [D-sidebar-width].
  public func sidebarWidth() throws -> CGFloat {
    guard let windowFrame = try window().frame, let divider = try splitter().frame else {
      throw UITestFailure("Couldn't read the window or divider frame")
    }
    return divider.minX - windowFrame.minX
  }

  /// The sidebar's rows: the branding panel, Settings, and the phases.
  public func sidebarRows() throws -> [AXNode] {
    let sidebar = try element("sidebar")
    let outline = sidebar.role == kAXOutlineRole ? sidebar
      : sidebar.first { $0.role == kAXOutlineRole || $0.role == kAXTableRole } ?? sidebar
    let rows = outline.nodes(kAXRowsAttribute)
    return rows.isEmpty ? outline.descendants(maxDepth: 3).filter { $0.role == kAXRowRole } : rows
  }

  public func row(named name: String) throws -> AXNode? {
    try sidebarRows().first { $0.allText.contains(name) }
  }

  public func selectedRowText() throws -> String? {
    try sidebarRows().first(where: \.isSelected)?.allText
  }

  // MARK: - Driving the window

  /// [D-ui-test-runner] Every input goes through here: no click or key
  /// unless the test instance is frontmost.
  private func ensureFrontmost() async throws {
    if NSWorkspace.shared.frontmostApplication?.processIdentifier != running.processIdentifier {
      try await bringToFront()
    }
    guard NSWorkspace.shared.frontmostApplication?.processIdentifier == running.processIdentifier else {
      throw UITestFailure("Test instance of Phases isn't frontmost; sent no input")
    }
  }

  /// Phases can't take focus on its own at launch: macOS's cooperative
  /// activation only hands it over when the active app yields. Tries the AX
  /// frontmost attribute, then NSRunningApplication, then LaunchServices.
  private func bringToFront() async throws {
    let isFront = { NSWorkspace.shared.frontmostApplication?.processIdentifier == self.running.processIdentifier }
    let attempts: [() -> Void] = [
      { AXUIElementSetAttributeValue(self.app.element, kAXFrontmostAttribute as CFString, kCFBooleanTrue) },
      { self.running.activate() },
      {
        guard let url = self.running.bundleURL else { return }
        let open = Process()
        open.executableURL = URL(filePath: "/usr/bin/open")
        open.arguments = ["-a", url.path(percentEncoded: false)]
        try? open.run()
        open.waitUntilExit()
      },
    ]
    for (index, attempt) in attempts.enumerated() {
      attempt()
      if (try? await waitUntil("Phases to come to the front", timeout: .seconds(1.5), isFront)) != nil {
        print("Phases brought to the front by attempt \(index + 1) of \(attempts.count)")
        return
      }
    }
    throw UITestFailure("Couldn't bring the test instance of Phases to the front")
  }

  private func center(of node: AXNode) throws -> CGPoint {
    guard let frame = node.frame else { throw UITestFailure("No frame for \(node.summary)") }
    guard try window().frame?.contains(CGPoint(x: frame.midX, y: frame.midY)) == true else {
      throw UITestFailure("\(node.summary) is outside the window; sent no click")
    }
    return CGPoint(x: frame.midX, y: frame.midY)
  }

  public func click(_ node: AXNode) async throws {
    try await ensureFrontmost()
    try await SyntheticInput.click(at: try center(of: node))
  }

  /// Drags the sidebar divider so it ends `x` points from the window's left
  /// edge (the window may stop it short).
  public func dragDivider(toWindowX x: CGFloat) async throws {
    try await ensureFrontmost()
    let start = try center(of: try splitter())
    guard let windowFrame = try window().frame else { throw UITestFailure("No window frame") }
    try await SyntheticInput.drag(from: start, to: CGPoint(x: windowFrame.minX + x, y: start.y))
  }

  public func press(_ key: SyntheticInput.Key, shift: Bool = false) async throws {
    try await ensureFrontmost()
    try await SyntheticInput.press(key, shift: shift)
  }

  // MARK: - Screenshots

  /// Saves the window to `UITests/Screenshots/` for the author to review.
  /// Needs Screen Recording permission for the app running the tests.
  @discardableResult
  public func screenshot(_ name: String) throws -> URL {
    let info = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] ?? []
    let ours = info.filter {
      ($0[kCGWindowOwnerPID as String] as? pid_t) == running.processIdentifier
        && ($0[kCGWindowLayer as String] as? Int) == 0
    }
    let area: ([String: Any]) -> CGFloat = { entry in
      let bounds = entry[kCGWindowBounds as String] as? [String: CGFloat] ?? [:]
      return (bounds["Width"] ?? 0) * (bounds["Height"] ?? 0)
    }
    guard let windowID = ours.max(by: { area($0) < area($1) })?[kCGWindowNumber as String] as? Int else {
      throw UITestFailure("Couldn't find the Phases window to capture")
    }
    let folder = URL(filePath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
      .deletingLastPathComponent().appending(path: "Screenshots", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    let stamp = Date().formatted(.iso8601.year().month().day().time(includingFractionalSeconds: false))
      .replacingOccurrences(of: ":", with: "")
    let url = folder.appending(path: "\(stamp) \(name).png")
    let capture = Process()
    capture.executableURL = URL(filePath: "/usr/sbin/screencapture")
    capture.arguments = ["-x", "-o", "-l\(windowID)", url.path(percentEncoded: false)]
    try capture.run()
    capture.waitUntilExit()
    guard capture.terminationStatus == 0, FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else {
      throw UITestFailure("screencapture failed; does the test runner have Screen Recording permission?")
    }
    return url
  }
}
