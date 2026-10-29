import AppKit
import ImageIO

/// [D-fade-in] Crossfades wallpaper changes (spec "Transitions"). macOS has no transition for
/// app-set wallpapers, so this fades the incoming image in over the old
/// wallpaper using a click-through window (above the desktop picture, below
/// the desktop icons), then sets the real wallpaper behind the now-identical
/// cover and removes it.
///
/// The wallpaper is set at the end, not the start, because macOS picks the
/// menu bar's appearance from the actual wallpaper; setting it early makes
/// the menu bar switch before the screen does [Q-menubar-reads-wallpaper].
@MainActor
final class CrossfadeController {
  /// [D-cover-settle] Time for macOS to finish drawing the new wallpaper,
  /// including its own brief motion, before the cover goes
  /// [Q-wallpaper-motion-delay].
  private static let settleDelay: Duration = .milliseconds(1500)

  private var covers: [NSWindow] = []
  private var fadeTask: Task<Void, Never>?
  /// Wallpaper to set when the running fade completes or is interrupted.
  private var pendingAssignments: [WallpaperAssignment]?

  /// Applies the assignments. Pass a nil duration for an instant switch.
  func apply(_ assignments: [WallpaperAssignment], duration: TimeInterval?) {
    finishRunningFade()

    // [D-no-fade-cases] None, Reduce Motion, unreadable file, unchanged screen.
    guard let duration, !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else {
      WallpaperSetter.apply(assignments)
      return
    }

    for assignment in assignments {
      let screen = assignment.screen
      if let current = NSWorkspace.shared.desktopImageURL(for: screen),
        current.standardizedFileURL == assignment.url.standardizedFileURL
      { continue }
      if let cover = makeCover(for: screen, showing: assignment.url) {
        cover.alphaValue = 0
        cover.orderFrontRegardless()
        covers.append(cover)
      }
    }

    guard !covers.isEmpty else {
      WallpaperSetter.apply(assignments)
      return
    }

    pendingAssignments = assignments
    let fading = covers
    fadeTask = Task { [weak self] in
      await NSAnimationContext.runAnimationGroup { context in
        context.duration = duration
        context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        for cover in fading { cover.animator().alphaValue = 1 }
      }
      guard !Task.isCancelled, let self else { return }
      self.setPendingWallpaper()
      try? await Task.sleep(for: Self.settleDelay)
      guard !Task.isCancelled else { return }
      self.removeCovers()
    }
  }

  /// Ends any fade in progress immediately: sets its wallpaper, removes covers.
  func finishRunningFade() {
    fadeTask?.cancel()
    fadeTask = nil
    setPendingWallpaper()
    removeCovers()
  }

  private func setPendingWallpaper() {
    guard let assignments = pendingAssignments else { return }
    pendingAssignments = nil
    WallpaperSetter.apply(assignments)
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
    // [D-no-screenshots] Drawn from the file; no Screen Recording permission.
    guard let image = Self.loadImage(url, maxPixelSize: maxPixels) else { return nil }

    let window = NSWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
    // [D-cover-level] Above the desktop picture, below the desktop icons.
    window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)
    window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
    window.ignoresMouseEvents = true
    window.hasShadow = false
    window.isOpaque = false
    window.backgroundColor = .clear
    window.isReleasedWhenClosed = false

    let view = NSView(frame: NSRect(origin: .zero, size: screen.frame.size))
    view.wantsLayer = true
    if let layer = view.layer {
      layer.contents = image
      layer.contentsGravity = gravity
      layer.contentsScale = screen.backingScaleFactor
      layer.masksToBounds = true
      layer.backgroundColor = (options[.fillColor] as? NSColor)?.cgColor ?? NSColor.black.cgColor
    }
    window.contentView = view
    return window
  }

  /// Matches macOS's wallpaper modes: Fill Screen, Fit to Screen, Stretch, Center.
  private static func gravity(for scaling: NSImageScaling, allowsClipping: Bool) -> CALayerContentsGravity {
    switch scaling {
    case .scaleAxesIndependently: .resize
    case .scaleNone: .center
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
