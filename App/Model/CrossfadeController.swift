import AppKit
import ImageIO

/// Crossfades wallpaper changes. macOS has no transition for app-set
/// wallpapers, so this covers each screen with a click-through window showing
/// the outgoing image (above the desktop picture, below the desktop icons),
/// sets the new wallpaper behind it, then fades the cover out.
@MainActor
final class CrossfadeController {
  /// Time for macOS to finish drawing the new wallpaper before fading.
  private static let settleDelay: Duration = .milliseconds(500)

  private var covers: [NSWindow] = []
  private var fadeTask: Task<Void, Never>?
  /// Wallpaper waiting to be set once the covers are on screen.
  private var pendingURLs: [URL]?

  /// Applies `urls` (one per screen, as in `WallpaperSetter.apply`). Pass a nil
  /// duration for an instant switch. `phasesURLs` are images Phases set itself,
  /// which are known to be plain images rather than system wallpapers.
  func apply(_ urls: [URL], duration: TimeInterval?, phasesURLs: Set<URL>) {
    finishRunningFade()

    guard let duration, !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion,
      let fallback = urls.last
    else {
      WallpaperSetter.apply(urls)
      return
    }

    let screens = NSScreen.screens
    let systemWallpaperDisplays = SystemWallpaperInspector.displaysWithSystemWallpaper(
      screens.compactMap(\.displayID)
    )
    for (index, screen) in screens.enumerated() {
      let incoming = index < urls.count ? urls[index] : fallback
      guard let outgoing = NSWorkspace.shared.desktopImageURL(for: screen),
        outgoing.standardizedFileURL != incoming.standardizedFileURL
      else { continue }
      // Skip Aerials: their reported URL is only a still frame.
      if !phasesURLs.contains(outgoing), let id = screen.displayID, systemWallpaperDisplays.contains(id) {
        continue
      }
      if let cover = makeCover(for: screen, showing: outgoing) {
        cover.orderFrontRegardless()
        covers.append(cover)
      }
    }

    guard !covers.isEmpty else {
      WallpaperSetter.apply(urls)
      return
    }

    // Set the new wallpaper only once the covers are actually on screen;
    // setting it sooner can show the new image before the fade starts.
    pendingURLs = urls
    let fading = covers
    fadeTask = Task { [weak self] in
      await Self.waitUntilOnScreen(fading)
      guard !Task.isCancelled, let self else { return }
      self.setPendingWallpaper()
      try? await Task.sleep(for: Self.settleDelay)
      guard !Task.isCancelled else { return }
      await NSAnimationContext.runAnimationGroup { context in
        context.duration = duration
        context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        for cover in fading { cover.animator().alphaValue = 0 }
      }
      guard !Task.isCancelled else { return }
      self.removeCovers()
    }
  }

  /// Ends any fade in progress immediately.
  func finishRunningFade() {
    fadeTask?.cancel()
    fadeTask = nil
    setPendingWallpaper()
    removeCovers()
  }

  private func setPendingWallpaper() {
    guard let urls = pendingURLs else { return }
    pendingURLs = nil
    WallpaperSetter.apply(urls)
  }

  /// Polls the window server until every cover reports on screen, then waits
  /// one more frame so it has been composited. Gives up after ~250 ms.
  private static func waitUntilOnScreen(_ windows: [NSWindow]) async {
    let numbers = Set(windows.map { CGWindowID($0.windowNumber) })
    for _ in 0..<15 {
      let info = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] ?? []
      let onScreen = Set(info.compactMap { $0[kCGWindowNumber as String] as? CGWindowID })
      if numbers.isSubset(of: onScreen) { break }
      try? await Task.sleep(for: .milliseconds(16))
    }
    try? await Task.sleep(for: .milliseconds(16))
  }

  private func removeCovers() {
    for cover in covers { cover.orderOut(nil) }
    covers.removeAll()
  }

  // MARK: - Cover windows

  private func makeCover(for screen: NSScreen, showing url: URL) -> NSWindow? {
    let options = NSWorkspace.shared.desktopImageOptions(for: screen) ?? [:]
    let scaling = (options[.imageScaling] as? NSNumber).flatMap { NSImageScaling(rawValue: $0.uintValue) }
      ?? .scaleProportionallyUpOrDown
    let allowsClipping = (options[.allowClipping] as? NSNumber)?.boolValue ?? true
    let gravity = Self.gravity(for: scaling, allowsClipping: allowsClipping)

    // Centered images are shown at their own size; everything else only needs
    // enough pixels to fill the screen.
    let maxPixels = gravity == .center ? nil : max(screen.frame.width, screen.frame.height) * screen.backingScaleFactor
    guard let image = Self.loadImage(url, maxPixelSize: maxPixels) else { return nil }

    let window = CoverWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
    window.animationBehavior = .none
    window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)
    window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
    window.ignoresMouseEvents = true
    window.hasShadow = false
    window.isOpaque = false
    window.backgroundColor = .clear
    window.isReleasedWhenClosed = false

    let view = NSView(frame: NSRect(origin: .zero, size: screen.frame.size))
    view.wantsLayer = true
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    defer { CATransaction.commit() }
    if let layer = view.layer {
      layer.contents = image
      layer.contentsGravity = gravity
      layer.contentsScale = screen.backingScaleFactor
      layer.masksToBounds = true
      layer.backgroundColor = (options[.fillColor] as? NSColor)?.cgColor ?? NSColor.black.cgColor
    }
    window.contentView = view
    window.setFrame(screen.frame, display: true)
    return window
  }

  /// Matches macOS's wallpaper modes: Fill Screen, Fit to Screen, Stretch, Center.
  private static func gravity(for scaling: NSImageScaling, allowsClipping: Bool) -> CALayerContentsGravity {
    switch scaling {
    case .scaleAxesIndependently: .resize
    case .scaleNone: .center
    case .scaleProportionallyDown: allowsClipping ? .resizeAspectFill : .resizeAspect
    default: allowsClipping ? .resizeAspectFill : .resizeAspect
    }
  }

  private static func loadImage(_ url: URL, maxPixelSize: CGFloat?) -> CGImage? {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
    guard let maxPixelSize else { return CGImageSourceCreateImageAtIndex(source, 0, nil) }
    let options: [CFString: Any] = [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceCreateThumbnailWithTransform: true,
      kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
    ]
    return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
  }
}

/// A borderless window that keeps exactly the frame it's given. Normal windows
/// are pushed out from under the menu bar, which would shrink the cover.
private final class CoverWindow: NSWindow {
  override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
    frameRect
  }

  override var canBecomeKey: Bool { false }
  override var canBecomeMain: Bool { false }
}
