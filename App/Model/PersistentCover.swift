import AppKit

/// EXPERIMENT, branch `spike/persistent-cover` only; never merges. See
/// docs/X-PERSISTENT-COVER.md.
///
/// Keeps a cover on every screen for as long as Phases runs, and sets the
/// real wallpaper behind it for the things that read it (menu bar text
/// [Q-menubar-reads-wallpaper], lock screen, widgets). Off unless launched
/// with `-PhasesPersistentCover A` or `B`.
@MainActor
final class PersistentCover {
  /// A: one window per screen; each change fades a new image layer in
  /// inside it. B: each change fades in a new window and removes the old
  /// one. [Q-menubar-bg-follows-window] may treat them differently.
  enum Variant: String { case a = "A", b = "B" }
  /// When the real wallpaper is set: at the end of the fade, or halfway.
  enum Timing: String { case end, mid }

  /// Launch arguments, so they last one launch only.
  static let variant = UserDefaults.standard.string(forKey: "PhasesPersistentCover")
    .flatMap { Variant(rawValue: $0.uppercased()) }
  static let timing = UserDefaults.standard.string(forKey: "PhasesWallpaperTiming")
    .flatMap { Timing(rawValue: $0.lowercased()) } ?? .end

  private struct Cover {
    var window: NSWindow
    var url: URL
  }

  /// What a running fade still has to finish.
  private struct RunningFade {
    var assignments: [WallpaperAssignment]
    var fadingWindows: [NSWindow] = []
    var fadingLayers: [CALayer] = []
    var retiringWindows: [NSWindow] = []
    var retiringLayers: [CALayer] = []
  }

  private let variant: Variant
  private var covers: [CGDirectDisplayID: Cover] = [:]
  private var running: RunningFade?
  private var fadeTask: Task<Void, Never>?
  private var spaceObserver: NSObjectProtocol?
  private let log = Diagnostics.logger("spike")

  init(variant: Variant) {
    self.variant = variant
    log.info("persistent cover on, variant \(variant.rawValue, privacy: .public), timing \(Self.timing.rawValue, privacy: .public)")
    spaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
      forName: NSWorkspace.activeSpaceDidChangeNotification, object: nil, queue: .main
    ) { [weak self] _ in
      MainActor.assumeIsolated { self?.syncSpace() }
    }
    // Cover what's showing now, so the cover is up before the first change.
    Task { @MainActor [weak self] in self?.coverCurrentWallpapers() }
  }

  func apply(_ assignments: [WallpaperAssignment], duration: TimeInterval?) {
    finishRunningFade()

    // [D-no-fade-cases] None and Reduce Motion: switch the cover, then the wallpaper.
    guard let duration, !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else {
      for assignment in assignments { replaceInstantly(assignment) }
      setWallpaper(assignments, reason: "instant")
      return
    }

    var fade = RunningFade(assignments: assignments)
    for assignment in assignments {
      guard let id = assignment.screen.displayID, covers[id]?.url != assignment.url else { continue }
      guard let image = Self.image(assignment.url, for: assignment.screen) else {
        // Unreadable file: that screen switches without a fade.
        replaceInstantly(assignment)
        continue
      }
      if variant == .a, let cover = covers[id], let root = cover.window.contentView?.layer {
        let layer = Self.imageLayer(image, for: assignment.screen, in: root.bounds)
        layer.opacity = 0
        fade.retiringLayers += root.sublayers ?? []
        root.addSublayer(layer)
        fade.fadingLayers.append(layer)
        covers[id]?.url = assignment.url
      } else {
        let window = Self.makeWindow(image, for: assignment.screen)
        window.alphaValue = 0
        window.orderFrontRegardless()
        log.info("cover window \(Diagnostics.id(window), privacy: .public) created on \(id)")
        if let old = covers[id] { fade.retiringWindows.append(old.window) }
        covers[id] = Cover(window: window, url: assignment.url)
        fade.fadingWindows.append(window)
      }
    }

    running = fade
    let windows = fade.fadingWindows
    let layers = fade.fadingLayers
    NSAnimationContext.runAnimationGroup { context in
      context.duration = duration
      context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
      for window in windows { window.animator().alphaValue = 1 }
    }
    for layer in layers {
      let animation = CABasicAnimation(keyPath: "opacity")
      animation.fromValue = 0
      animation.toValue = 1
      animation.duration = duration
      animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
      layer.opacity = 1
      layer.add(animation, forKey: "fade")
    }

    fadeTask = Task { [weak self] in
      if Self.timing == .mid {
        try? await Task.sleep(for: .seconds(duration / 2))
        guard !Task.isCancelled, let self else { return }
        self.setPendingWallpaper(reason: "mid-fade")
        try? await Task.sleep(for: .seconds(duration / 2))
      } else {
        try? await Task.sleep(for: .seconds(duration))
      }
      guard !Task.isCancelled, let self else { return }
      self.completeFade()
    }
  }

  /// Ends any fade in progress immediately. The covers stay up.
  func finishRunningFade() {
    fadeTask?.cancel()
    fadeTask = nil
    completeFade()
  }

  private func completeFade() {
    guard let fade = running else { return }
    for window in fade.fadingWindows { window.alphaValue = 1 }
    for layer in fade.fadingLayers { layer.removeAnimation(forKey: "fade") }
    setPendingWallpaper(reason: "end of fade")
    for layer in fade.retiringLayers { layer.removeFromSuperlayer() }
    for window in fade.retiringWindows {
      window.orderOut(nil)
      log.info("cover window \(Diagnostics.id(window), privacy: .public) removed")
    }
    running = nil
  }

  private func setPendingWallpaper(reason: String) {
    guard let assignments = running?.assignments else { return }
    running?.assignments = []
    setWallpaper(assignments, reason: reason)
  }

  private func setWallpaper(_ assignments: [WallpaperAssignment], reason: String) {
    guard !assignments.isEmpty else { return }
    WallpaperSetter.apply(assignments)
    for assignment in assignments {
      log.info("wallpaper set (\(reason, privacy: .public)) on \(assignment.screen.displayID ?? 0): \(assignment.url.lastPathComponent, privacy: .public)")
    }
  }

  /// Shows the image on the screen's cover at once, without a fade.
  private func replaceInstantly(_ assignment: WallpaperAssignment) {
    guard let id = assignment.screen.displayID, covers[id]?.url != assignment.url,
      let image = Self.image(assignment.url, for: assignment.screen)
    else { return }
    if variant == .a, let cover = covers[id], let root = cover.window.contentView?.layer {
      root.sublayers?.forEach { $0.removeFromSuperlayer() }
      root.addSublayer(Self.imageLayer(image, for: assignment.screen, in: root.bounds))
      covers[id]?.url = assignment.url
    } else {
      let window = Self.makeWindow(image, for: assignment.screen)
      window.orderFrontRegardless()
      covers[id]?.window.orderOut(nil)
      covers[id] = Cover(window: window, url: assignment.url)
      log.info("cover window \(Diagnostics.id(window), privacy: .public) created on \(id) (instant)")
    }
  }

  private func coverCurrentWallpapers() {
    for screen in NSScreen.screens {
      guard let id = screen.displayID, covers[id] == nil,
        let url = NSWorkspace.shared.desktopImageURL(for: screen)
      else { continue }
      replaceInstantly(WallpaperAssignment(screen: screen, url: url))
    }
  }

  /// On arriving at a Space, sets its real wallpaper to match the cover if
  /// it's out of date. Invisible, since the cover is on top.
  private func syncSpace() {
    log.info("active Space changed")
    guard running == nil else { return }
    for screen in NSScreen.screens {
      guard let id = screen.displayID, let cover = covers[id] else { continue }
      let current = NSWorkspace.shared.desktopImageURL(for: screen)
      guard current?.standardizedFileURL != cover.url.standardizedFileURL else { continue }
      log.info("Space on \(id) shows \(current?.lastPathComponent ?? "nil", privacy: .public); syncing")
      setWallpaper([WallpaperAssignment(screen: screen, url: cover.url)], reason: "Space sync")
    }
  }

  // MARK: - Drawing

  private static func image(_ url: URL, for screen: NSScreen) -> CGImage? {
    let gravity = gravity(for: screen)
    let maxPixels = gravity == .center ? nil : max(screen.frame.width, screen.frame.height) * screen.backingScaleFactor
    return CrossfadeController.loadImage(url, maxPixelSize: maxPixels)
  }

  private static func gravity(for screen: NSScreen) -> CALayerContentsGravity {
    let options = NSWorkspace.shared.desktopImageOptions(for: screen) ?? [:]
    let scaling = (options[.imageScaling] as? NSNumber).flatMap { NSImageScaling(rawValue: $0.uintValue) }
      ?? .scaleProportionallyUpOrDown
    let allowsClipping = (options[.allowClipping] as? NSNumber)?.boolValue ?? true
    return CrossfadeController.gravity(for: scaling, allowsClipping: allowsClipping)
  }

  private static func imageLayer(_ image: CGImage, for screen: NSScreen, in bounds: CGRect) -> CALayer {
    let layer = CALayer()
    layer.frame = bounds
    layer.contents = image
    layer.contentsGravity = gravity(for: screen)
    layer.contentsScale = screen.backingScaleFactor
    layer.masksToBounds = true
    let fill = NSWorkspace.shared.desktopImageOptions(for: screen)?[.fillColor] as? NSColor
    layer.backgroundColor = fill?.cgColor ?? NSColor.black.cgColor
    return layer
  }

  /// Same window as the crossfade cover [D-cover-level].
  private static func makeWindow(_ image: CGImage, for screen: NSScreen) -> NSWindow {
    let window = NSWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
    window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)
    window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
    window.ignoresMouseEvents = true
    window.hasShadow = false
    window.isOpaque = false
    window.backgroundColor = .clear
    window.isReleasedWhenClosed = false
    let view = NSView(frame: NSRect(origin: .zero, size: screen.frame.size))
    view.wantsLayer = true
    if let root = view.layer {
      root.addSublayer(imageLayer(image, for: screen, in: root.bounds))
    }
    window.contentView = view
    return window
  }
}
