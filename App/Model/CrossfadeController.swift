import AppKit

private let diagLog = Diagnostics.logger("cover")

/// [D-fade-in] [D-persistent-cover] Crossfades wallpaper changes (spec
/// "Transitions"). macOS has no transition for app-set wallpapers, so this
/// fades the incoming image in on a click-through window (above the desktop
/// picture, below the desktop icons), sets the real wallpaper behind the
/// now-identical cover, and leaves the cover up while its Space is showing.
///
/// The wallpaper is set at the end, not the start, because macOS picks the
/// menu bar's appearance from the actual wallpaper; setting it early makes
/// the menu bar switch before the screen does [Q-menubar-reads-wallpaper].
/// Keeping the cover up hides macOS's own motion after the change
/// [Q-wallpaper-motion-delay].
@MainActor
final class CrossfadeController {
  /// [D-cover-opacity] Not 1: a fully opaque cover stops the menu bar
  /// restyling for new wallpapers [Q-opaque-cover-freezes-menubar].
  private static let coverOpacity: CGFloat = 0.99

  /// [D-reset-on-quick-return] Leaving a Space this soon after its set may
  /// mean the set reached the arrival Space [Q-set-target-decided-late].
  /// Longer than macOS's 0.5–1.1 s to announce a Space change
  /// [Q-space-notify-after-swipe].
  private static let quickReturnWindow: TimeInterval = 1.5

  private enum CoverState {
    /// Fading in; owned by the running fade.
    case fading
    /// Its wallpaper is set; shown until replaced or its Space stops showing.
    case settled
    /// [D-change-stays-on-its-space] Its fade ended after its Space stopped
    /// showing; the wallpaper is set when that Space shows again.
    case pending
  }

  private final class Cover {
    let window: NSWindow
    let url: URL
    let displayID: CGDirectDisplayID
    var frame: CGRect
    var scale: CGFloat
    var state: CoverState
    /// When its wallpaper was last set [D-reset-on-quick-return].
    var setAt: Date?

    init(window: NSWindow, url: URL, screen: NSScreen, displayID: CGDirectDisplayID, state: CoverState) {
      self.window = window
      self.url = url
      self.displayID = displayID
      self.frame = screen.frame
      self.scale = screen.backingScaleFactor
      self.state = state
    }
  }

  /// One display's part of a running fade.
  private struct FadeEntry {
    var assignment: WallpaperAssignment
    /// Nil when the cover couldn't be made: that screen switches without a
    /// fade when the others finish [D-no-fade-cases].
    var incoming: Cover?
    /// The cover showing when the fade started, removed when it ends.
    var outgoing: Cover?
  }

  /// Every cover, on whichever Space it belongs to [D-cover-per-space].
  private var covers: [Cover] = []
  private var running: [FadeEntry]?
  private var fadeTask: Task<Void, Never>?
  private var observers: [NSObjectProtocol] = []

  init() {
    let center = NSWorkspace.shared.notificationCenter
    observers = [
      center.addObserver(forName: NSWorkspace.activeSpaceDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
        MainActor.assumeIsolated { self?.activeSpaceChanged() }
      },
      // [D-cover-only-for-crossfade] Reduce Motion turns every fade into an
      // instant switch, so the covers have no job left.
      center.addObserver(forName: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
        MainActor.assumeIsolated {
          guard NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else { return }
          self?.removeAllCovers(reason: "Reduce Motion on")
        }
      },
    ]
  }

  /// Applies the assignments. Pass a nil duration for an instant switch.
  func apply(_ assignments: [WallpaperAssignment], duration: TimeInterval?) {
    finishRunningFade()

    // [D-no-fade-cases] [D-cover-only-for-crossfade] None and Reduce Motion:
    // no cover at all; just ask macOS.
    guard let duration, !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else {
      removeAllCovers(reason: "instant switch")
      WallpaperSetter.apply(assignments)
      return
    }

    var entries: [FadeEntry] = []
    for assignment in assignments {
      let screen = assignment.screen
      guard let displayID = screen.displayID else { continue }
      let outgoing = showingCover(on: displayID)
      // [D-no-fade-cases] Not changing: leave the screen and its cover alone.
      let currentURL = outgoing?.url ?? NSWorkspace.shared.desktopImageURL(for: screen)
      if currentURL?.standardizedFileURL == assignment.url.standardizedFileURL { continue }

      let incoming = makeCover(for: screen, displayID: displayID, showing: assignment.url, state: .fading)
      if let incoming {
        incoming.window.alphaValue = 0
        incoming.window.orderFrontRegardless()
        covers.append(incoming)
      }
      entries.append(FadeEntry(assignment: assignment, incoming: incoming, outgoing: outgoing))
    }

    guard entries.contains(where: { $0.incoming != nil }) else {
      running = entries
      completeFade()
      return
    }

    running = entries
    let fading = entries.compactMap { $0.incoming?.window }
    fadeTask = Task { [weak self] in
      await NSAnimationContext.runAnimationGroup { context in
        context.duration = duration
        context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        for window in fading { window.animator().alphaValue = Self.coverOpacity }
      }
      guard !Task.isCancelled, let self else { return }
      self.completeFade()
    }
  }

  /// Ends any fade in progress immediately. Covers stay up.
  func finishRunningFade() {
    fadeTask?.cancel()
    fadeTask = nil
    completeFade()
  }

  /// [D-cover-only-for-crossfade] [D-cover-pause-quit] Takes every cover
  /// down: crossfades turned off, or Quit (after any restore). Pending
  /// changes are dropped; their Spaces keep the image they had.
  func removeAllCovers(reason: String) {
    finishRunningFade()
    guard !covers.isEmpty else { return }
    diagLog.log("removing \(self.covers.count) cover(s): \(reason, privacy: .public)")
    for cover in covers { Self.discard(cover) }
    covers.removeAll()
  }

  /// [D-cover-follows-displays] Redraws, resizes, or removes covers after a
  /// display change. Only real geometry changes count: Dock and menu bar
  /// changes send the same notification [Q-screen-params-notification].
  func screensChanged() {
    let screens = Dictionary(NSScreen.screens.compactMap { s in s.displayID.map { ($0, s) } }, uniquingKeysWith: { a, _ in a })
    let affected = covers.filter { cover in
      guard let screen = screens[cover.displayID] else { return true }
      return screen.frame != cover.frame || screen.backingScaleFactor != cover.scale
    }
    guard !affected.isEmpty else { return }
    finishRunningFade()

    for cover in affected {
      guard let screen = screens[cover.displayID] else {
        diagLog.log("cover \(Diagnostics.id(cover.window), privacy: .public) removed: display \(cover.displayID) gone")
        remove(cover)
        continue
      }
      if cover.window.isOnActiveSpace {
        // Showing: draw it again at the new size, on this Space.
        let replacement = makeCover(for: screen, displayID: cover.displayID, showing: cover.url, state: cover.state)
        if let replacement {
          replacement.window.alphaValue = Self.coverOpacity
          replacement.window.orderFrontRegardless()
          covers.append(replacement)
        }
        diagLog.log("cover \(Diagnostics.id(cover.window), privacy: .public) redrawn on \(cover.displayID) as \(Diagnostics.id(replacement?.window), privacy: .public)")
        remove(cover)
      } else {
        // On another Space: a new window would land on this one, so stretch
        // the existing one instead. Redrawn properly by its next change.
        cover.window.setFrame(screen.frame, display: false)
        cover.window.contentView?.layer?.contentsScale = screen.backingScaleFactor
        cover.frame = screen.frame
        cover.scale = screen.backingScaleFactor
        diagLog.log("cover \(Diagnostics.id(cover.window), privacy: .public) resized on \(cover.displayID) (other Space)")
      }
    }
  }

  // MARK: - Fades

  private func completeFade() {
    guard let entries = running else { return }
    running = nil
    var toSet: [WallpaperAssignment] = []
    for entry in entries {
      if let incoming = entry.incoming {
        incoming.window.alphaValue = Self.coverOpacity
        // [D-change-stays-on-its-space] macOS sets the wallpaper only on the
        // Space showing; if this cover's Space has gone, hold the change.
        if incoming.window.isOnActiveSpace {
          incoming.state = .settled
          incoming.setAt = Date()
          toSet.append(entry.assignment)
        } else {
          incoming.state = .pending
          diagLog.log("cover \(Diagnostics.id(incoming.window), privacy: .public) pending on \(incoming.displayID): Space left mid-fade, \(incoming.url.lastPathComponent, privacy: .public)")
        }
      } else {
        toSet.append(entry.assignment)
      }
    }
    WallpaperSetter.apply(toSet)
    for entry in entries {
      if let outgoing = entry.outgoing { remove(outgoing) }
    }
  }

  // MARK: - Spaces

  /// [D-cover-per-space] A settled cover whose Space stopped showing goes;
  /// that Space keeps the same image as its real wallpaper.
  /// [D-change-stays-on-its-space] A pending cover whose Space is showing
  /// again gets its wallpaper set.
  /// [D-reset-on-quick-return] A settled cover left within
  /// `quickReturnWindow` of its set goes back to pending instead.
  private func activeSpaceChanged() {
    for cover in covers {
      switch cover.state {
      case .fading:
        continue
      case .settled where !cover.window.isOnActiveSpace:
        if let setAt = cover.setAt, Date().timeIntervalSince(setAt) < Self.quickReturnWindow {
          cover.state = .pending
          diagLog.log("cover \(Diagnostics.id(cover.window), privacy: .public) pending again on \(cover.displayID): Space left \(Date().timeIntervalSince(setAt), format: .fixed(precision: 2)) s after the set, \(cover.url.lastPathComponent, privacy: .public)")
          continue
        }
        diagLog.log("cover \(Diagnostics.id(cover.window), privacy: .public) removed on \(cover.displayID): Space left")
        remove(cover)
      case .pending where cover.window.isOnActiveSpace:
        guard let screen = NSScreen.screens.first(where: { $0.displayID == cover.displayID }) else {
          remove(cover)
          continue
        }
        // Any older cover still showing on this display is now underneath.
        for other in covers where other !== cover && other.displayID == cover.displayID
          && other.state == .settled && other.window.isOnActiveSpace
        {
          remove(other)
        }
        cover.state = .settled
        cover.setAt = Date()
        WallpaperSetter.apply([WallpaperAssignment(screen: screen, url: cover.url)])
        diagLog.log("cover \(Diagnostics.id(cover.window), privacy: .public) back on its Space; wallpaper set on \(cover.displayID): \(cover.url.lastPathComponent, privacy: .public)")
      default:
        continue
      }
    }
  }

  /// The settled or pending cover on the Space now showing on a display.
  private func showingCover(on displayID: CGDirectDisplayID) -> Cover? {
    covers.last { $0.displayID == displayID && $0.state != .fading && $0.window.isOnActiveSpace }
  }

  private func remove(_ cover: Cover) {
    Self.discard(cover)
    covers.removeAll { $0 === cover }
  }

  private static func discard(_ cover: Cover) {
    cover.window.orderOut(nil)
    // [D-cover-iosurface] The buffer goes with the cover, even if AppKit
    // holds on to the window a while longer.
    cover.window.contentView?.layer?.contents = nil
  }

  // MARK: - Cover windows

  private func makeCover(for screen: NSScreen, displayID: CGDirectDisplayID, showing url: URL, state: CoverState) -> Cover? {
    let options = NSWorkspace.shared.desktopImageOptions(for: screen) ?? [:]
    let scaling = (options[.imageScaling] as? NSNumber).flatMap { NSImageScaling(rawValue: $0.uintValue) }
      ?? .scaleProportionallyUpOrDown
    let allowsClipping = (options[.allowClipping] as? NSNumber)?.boolValue ?? true
    let gravity = Self.gravity(for: scaling, allowsClipping: allowsClipping)

    // Centered images are shown at their own size; everything else only needs
    // enough pixels to fill the screen.
    let maxPixels = gravity == .center ? nil : max(screen.frame.width, screen.frame.height) * screen.backingScaleFactor
    // [D-no-screenshots] Drawn from the file; no Screen Recording permission.
    // [D-cover-iosurface] One tagged surface, shown without a copy.
    guard let surface = CoverSurface.make(from: url, maxPixelSize: maxPixels) else {
      diagLog.log("cover: no surface for \(url.lastPathComponent, privacy: .public)")
      return nil
    }

    let window = NSWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
    // [D-cover-level] Above the desktop picture, below the desktop icons.
    window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)
    // [D-cover-per-space] No .canJoinAllSpaces: the cover stays on the Space
    // it was made on, so each Space keeps its own wallpaper.
    window.collectionBehavior = [.stationary, .ignoresCycle]
    window.ignoresMouseEvents = true
    window.hasShadow = false
    window.isOpaque = false
    window.backgroundColor = .clear
    window.isReleasedWhenClosed = false

    let view = NSView(frame: NSRect(origin: .zero, size: screen.frame.size))
    view.wantsLayer = true
    view.autoresizingMask = [.width, .height]
    if let layer = view.layer {
      layer.contents = surface
      layer.contentsGravity = gravity
      layer.contentsScale = screen.backingScaleFactor
      layer.masksToBounds = true
      layer.backgroundColor = (options[.fillColor] as? NSColor)?.cgColor ?? NSColor.black.cgColor
    }
    window.contentView = view
    diagLog.log("cover \(Diagnostics.id(window), privacy: .public) made on \(displayID): \(url.lastPathComponent, privacy: .public)")
    return Cover(window: window, url: url, screen: screen, displayID: displayID, state: state)
  }

  /// Matches macOS's wallpaper modes: Fill Screen, Fit to Screen, Stretch, Center.
  private static func gravity(for scaling: NSImageScaling, allowsClipping: Bool) -> CALayerContentsGravity {
    switch scaling {
    case .scaleAxesIndependently: .resize
    case .scaleNone: .center
    default: allowsClipping ? .resizeAspectFill : .resizeAspect
    }
  }
}
