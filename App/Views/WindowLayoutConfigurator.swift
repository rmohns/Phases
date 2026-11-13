import AppKit
import SwiftUI
import os

// [D-diagnostics-switch] Off unless diagnostics are switched on at launch.
private let diagLog = Diagnostics.logger("sidebar")

private func diagID(_ object: AnyObject?) -> String { Diagnostics.id(object) }

/// Placed inside the sidebar of a NavigationSplitView, adjusts the AppKit
/// window around it in a fixed order: first gives the window an empty
/// unified toolbar if SwiftUI made none, then makes the sidebar's split view
/// item non-collapsible within a fixed width range. SwiftUI has no API for
/// either [Q-no-items-no-toolbar] [Q-sidebar-collapse]. Workarounds:
/// ERRATA.md "Tall toolbar" and "Sidebar limits". Also keeps Phases in the
/// Dock until the window closes [D-dock-while-open], and reports the window
/// opening and closing [D-grid-release-on-close].
struct WindowLayoutConfigurator: NSViewRepresentable {
  var sidebarMinWidth: CGFloat
  var sidebarMaxWidth: CGFloat
  /// Called when the window becomes key, which opening it always does.
  var onOpen: () -> Void = {}
  /// Called when the window is about to close.
  var onClose: () -> Void = {}

  func makeNSView(context: Context) -> ProbeView {
    ProbeView()
  }

  func updateNSView(_ view: ProbeView, context: Context) {
    view.sidebarMinWidth = sidebarMinWidth
    view.sidebarMaxWidth = sidebarMaxWidth
    view.onOpen = onOpen
    view.onClose = onClose
    view.apply()
  }

  final class ProbeView: NSView {
    var sidebarMinWidth: CGFloat = 0
    var sidebarMaxWidth: CGFloat = .greatestFiniteMagnitude
    var onOpen: () -> Void = {}
    var onClose: () -> Void = {}

    /// [D-sidebar-limits-watch] [Q-split-item-rewrite] The item being held to the limits, and the
    /// event hooks that put them back. No polling.
    private weak var watchedItem: NSSplitViewItem?
    private var itemObservations: [NSKeyValueObservation] = []
    private var resizeObserver: NSObjectProtocol?

    /// [D-dock-while-open] The window whose closing drops the Dock icon.
    /// Kept when this view leaves the window, so a close still counts.
    private weak var closeWatchedWindow: NSWindow?
    private var closeObserver: NSObjectProtocol?
    private var keyObserver: NSObjectProtocol?

    /// Diagnostics: last logged split state, to log only changes.
    private var diagLastState = ""

    deinit {
      if let closeObserver { NotificationCenter.default.removeObserver(closeObserver) }
      if let keyObserver { NotificationCenter.default.removeObserver(keyObserver) }
    }

    override func viewDidMoveToWindow() {
      super.viewDidMoveToWindow()
      diagLog.log("probe \(diagID(self), privacy: .public) moved to window \(diagID(self.window), privacy: .public)")
      if window == nil { stopWatching() }
      if let window { showInDock(while: window) }
      apply()
    }

    /// [D-dock-while-open] Regular app while the window is open; accessory
    /// again when it closes. Minimizing doesn't post willClose.
    private func showInDock(while window: NSWindow) {
      DockPresence.show()
      guard window !== closeWatchedWindow else { return }
      if let closeObserver { NotificationCenter.default.removeObserver(closeObserver) }
      if let keyObserver { NotificationCenter.default.removeObserver(keyObserver) }
      closeWatchedWindow = window
      closeObserver = NotificationCenter.default.addObserver(
        forName: NSWindow.willCloseNotification, object: window, queue: .main
      ) { [weak self] _ in
        MainActor.assumeIsolated {
          // [D-close-stays-here] Hand off first, so macOS doesn't pick an
          // app on another Space [Q-accessory-focus-handoff].
          FocusHandoff.toCurrentSpace()
          DockPresence.hide()
          self?.onClose()
        }
      }
      keyObserver = NotificationCenter.default.addObserver(
        forName: NSWindow.didBecomeKeyNotification, object: window, queue: .main
      ) { [weak self] _ in
        MainActor.assumeIsolated {
          self?.onOpen()
          self?.logScrollViews(when: "became key")
        }
      }
    }

    /// Diagnostics: last logged scroll state, to log only changes.
    private var diagLastScroll = ""

    /// [D-window-pause-banner] Diagnostics only: each scroll view's top
    /// inset and scroll position, for telling a shifted layout from a
    /// scroll position that's off (EXPERIMENTS.md
    /// `[L-pause-banner-stack-still-shifts]`). Logged on events this view
    /// already gets, and only when the state changed.
    private func logScrollViews(when event: String) {
      guard Diagnostics.isEnabled, let window, let content = window.contentView else { return }
      var scrollViews: [NSScrollView] = []
      func collect(_ view: NSView) {
        if let scroll = view as? NSScrollView { scrollViews.append(scroll) }
        view.subviews.forEach(collect)
      }
      collect(content)
      let state = scrollViews.map { scroll -> String in
        let frame = scroll.convert(scroll.bounds, to: nil)
        return "x=\(Int(frame.minX)) w=\(Int(frame.width)) inset=\(scroll.contentInsets.top) auto=\(scroll.automaticallyAdjustsContentInsets) y=\(scroll.contentView.bounds.origin.y)"
      }.joined(separator: " | ")
      let full = "title area \(window.frame.height - window.contentLayoutRect.height) pt; scroll views: \(state)"
      guard full != diagLastScroll else { return }
      diagLastScroll = full
      diagLog.log("scroll (\(event, privacy: .public)): \(full, privacy: .public)")
    }

    /// [D-window-helper-order] Toolbar first; sidebar limits one run-loop
    /// pass later, after any split view rebuild the toolbar causes.
    func apply() {
      guard let window else {
        diagLog.log("apply: probe \(diagID(self), privacy: .public) has no window")
        return
      }
      installToolbar(in: window)
      logScrollViews(when: "apply")
      DispatchQueue.main.async { [weak self] in
        self?.applySidebarLimits()
        self?.logScrollViews(when: "after limits")
      }
    }

    private func installToolbar(in window: NSWindow) {
      // [D-tall-toolbar] [Q-no-items-no-toolbar] An empty toolbar still gets
      // the full unified height.
      if window.toolbar == nil {
        window.toolbar = NSToolbar(identifier: "PhasesWindowToolbar")
      }
      // [Q-empty-toolbar-66pt] Icon-only: the default display mode made the
      // bar 66 pt, not 52 (fix verified, cause unproven).
      window.toolbar?.displayMode = .iconOnly
      window.toolbarStyle = .unified
      // [D-window-pause-banner] For telling a lost toolbar from a lost
      // safe area when content draws under the title bar.
      diagLog.log("toolbar installed: title area \(window.frame.height - window.contentLayoutRect.height, privacy: .public) pt")
    }

    private func applySidebarLimits() {
      var ancestor = superview
      while let view = ancestor, !(view is NSSplitView) {
        ancestor = view.superview
      }
      guard let splitView = ancestor as? NSSplitView,
            let controller = splitView.delegate as? NSSplitViewController,
            let item = controller.splitViewItems.first
      else {
        diagLog.error("SKIPPED limits: probe \(diagID(self), privacy: .public) superview=\(self.superview != nil, privacy: .public)")
        return
      }
      diagLog.log("applying limits: probe \(diagID(self), privacy: .public) split=\(diagID(splitView), privacy: .public) controller=\(diagID(controller), privacy: .public) item=\(diagID(item), privacy: .public) before min=\(item.minimumThickness, privacy: .public) max=\(item.maximumThickness, privacy: .public)")
      enforceLimits(on: item, reason: "initial")
      watch(item)
      watchResizes(of: splitView)
    }

    /// Sets the limits, touching only values that differ, so re-entering
    /// from the observers below stops after one pass.
    private func enforceLimits(on item: NSSplitViewItem, reason: String) {
      // [D-sidebar-always-visible] Dragging stops at the minimum instead of
      // collapsing.
      let collapses = item.canCollapse || item.canCollapseFromWindowResize
      // [D-sidebar-width]
      let wrongWidths = item.minimumThickness != sidebarMinWidth || item.maximumThickness != sidebarMaxWidth
      guard collapses || wrongWidths else { return }
      // Diagnostics: shows which hook caught each SwiftUI rewrite.
      diagLog.log("RESTORING limits (\(reason, privacy: .public)): item=\(diagID(item), privacy: .public) found min=\(item.minimumThickness, privacy: .public) max=\(item.maximumThickness, privacy: .public) canCollapse=\(item.canCollapse, privacy: .public)")
      if item.canCollapse { item.canCollapse = false }
      if item.canCollapseFromWindowResize { item.canCollapseFromWindowResize = false }
      if item.minimumThickness != sidebarMinWidth { item.minimumThickness = sidebarMinWidth }
      if item.maximumThickness != sidebarMaxWidth { item.maximumThickness = sidebarMaxWidth }
    }

    /// [D-sidebar-limits-watch] Key-value observers fire only when something
    /// sets these properties; idle cost is zero.
    private func watch(_ item: NSSplitViewItem) {
      guard item !== watchedItem else { return }
      watchedItem = item
      let restore: (NSSplitViewItem, String) -> Void = { [weak self] item, key in
        MainActor.assumeIsolated { self?.enforceLimits(on: item, reason: "observer: \(key)") }
      }
      itemObservations = [
        item.observe(\.minimumThickness) { item, _ in restore(item, "minimumThickness") },
        item.observe(\.maximumThickness) { item, _ in restore(item, "maximumThickness") },
        item.observe(\.canCollapse) { item, _ in restore(item, "canCollapse") },
        item.observe(\.canCollapseFromWindowResize) { item, _ in restore(item, "canCollapseFromWindowResize") },
      ]
    }

    /// [D-sidebar-limits-watch] Backstop: fires only while this split view
    /// resizes. Re-checks the limits, and re-attaches the observers if
    /// SwiftUI has swapped in a new item.
    private func watchResizes(of splitView: NSSplitView) {
      if let resizeObserver { NotificationCenter.default.removeObserver(resizeObserver) }
      resizeObserver = NotificationCenter.default.addObserver(
        forName: NSSplitView.didResizeSubviewsNotification, object: splitView, queue: .main
      ) { [weak self, weak splitView] _ in
        MainActor.assumeIsolated {
          guard let self, let splitView,
                let item = (splitView.delegate as? NSSplitViewController)?.splitViewItems.first
          else { return }
          if item !== self.watchedItem {
            diagLog.log("NEW ITEM seen on resize: \(diagID(item), privacy: .public) (was \(diagID(self.watchedItem), privacy: .public))")
            self.watch(item)
          }
          self.enforceLimits(on: item, reason: "resize backstop")
          self.diagLogState(splitView: splitView, item: item)
        }
      }
    }

    private func stopWatching() {
      itemObservations = []
      watchedItem = nil
      if let resizeObserver { NotificationCenter.default.removeObserver(resizeObserver) }
      resizeObserver = nil
    }

    /// Diagnostics: logs when the split view's identity or limits change,
    /// or the sidebar's width leaves the allowed range.
    private func diagLogState(splitView: NSSplitView, item: NSSplitViewItem) {
      guard Diagnostics.isEnabled else { return }
      let width = item.viewController.view.frame.width
      let state = "split=\(diagID(splitView)) item=\(diagID(item)) min=\(item.minimumThickness) max=\(item.maximumThickness) canCollapse=\(item.canCollapse)"
      let outOfRange = width < sidebarMinWidth - 0.5 || width > sidebarMaxWidth + 0.5
      guard state != diagLastState || outOfRange else { return }
      diagLastState = state
      diagLog.log("\(outOfRange ? "OUT OF RANGE " : "", privacy: .public)resize: width=\(width, privacy: .public) \(state, privacy: .public)")
    }
  }
}
