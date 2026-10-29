import AppKit
import SwiftUI
import os

// DIAGNOSTIC (temporary): remove once the sidebar-width regression is
// understood (SPEC.md [D-window-helper-order], "Regressed 2026-10-28").
// Read with: log show --last 30m --predicate 'subsystem == "PhasesDiag"'
let diagLog = Logger(subsystem: "PhasesDiag", category: "sidebar")

private func diagID(_ object: AnyObject?) -> String {
  object.map { String(UInt(bitPattern: ObjectIdentifier($0).hashValue) % 100_000) } ?? "nil"
}

/// Placed inside the sidebar of a NavigationSplitView, adjusts the AppKit
/// window around it in a fixed order: first gives the window an empty
/// unified toolbar if SwiftUI made none, then makes the sidebar's split view
/// item non-collapsible within a fixed width range. SwiftUI has no API for
/// either.
struct WindowLayoutConfigurator: NSViewRepresentable {
  var sidebarMinWidth: CGFloat
  var sidebarMaxWidth: CGFloat

  func makeNSView(context: Context) -> ProbeView {
    ProbeView()
  }

  func updateNSView(_ view: ProbeView, context: Context) {
    view.sidebarMinWidth = sidebarMinWidth
    view.sidebarMaxWidth = sidebarMaxWidth
    view.apply()
  }

  final class ProbeView: NSView {
    var sidebarMinWidth: CGFloat = 0
    var sidebarMaxWidth: CGFloat = .greatestFiniteMagnitude

    /// [D-sidebar-limits-watch] The item being held to the limits, and the
    /// event hooks that put them back. No polling.
    private weak var watchedItem: NSSplitViewItem?
    private var itemObservations: [NSKeyValueObservation] = []
    private var resizeObserver: NSObjectProtocol?

    /// DIAGNOSTIC (temporary): last logged split state, to log only changes.
    private var diagLastState = ""

    override func viewDidMoveToWindow() {
      super.viewDidMoveToWindow()
      diagLog.log("probe \(diagID(self), privacy: .public) moved to window \(diagID(self.window), privacy: .public)")
      if window == nil { stopWatching() }
      apply()
    }

    /// [D-window-helper-order] Toolbar first; sidebar limits one run-loop
    /// pass later, after any split view rebuild the toolbar causes.
    func apply() {
      guard let window else {
        diagLog.log("apply: probe \(diagID(self), privacy: .public) has no window")
        return
      }
      installToolbar(in: window)
      DispatchQueue.main.async { [weak self] in
        self?.applySidebarLimits()
      }
    }

    private func installToolbar(in window: NSWindow) {
      // [D-tall-toolbar] An empty toolbar still gets the full unified height.
      if window.toolbar == nil {
        window.toolbar = NSToolbar(identifier: "PhasesWindowToolbar")
      }
      // Icon-only: the default display mode made the bar 66 pt, not 52
      // (fix verified, cause unproven; see SPEC.md).
      window.toolbar?.displayMode = .iconOnly
      window.toolbarStyle = .unified
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
        // DIAGNOSTIC (temporary)
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
      // DIAGNOSTIC (temporary): shows which hook caught each SwiftUI rewrite.
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

    /// DIAGNOSTIC (temporary): logs when the split view's identity or
    /// limits change, or the sidebar's width leaves the allowed range.
    private func diagLogState(splitView: NSSplitView, item: NSSplitViewItem) {
      let width = item.viewController.view.frame.width
      let state = "split=\(diagID(splitView)) item=\(diagID(item)) min=\(item.minimumThickness) max=\(item.maximumThickness) canCollapse=\(item.canCollapse)"
      let outOfRange = width < sidebarMinWidth - 0.5 || width > sidebarMaxWidth + 0.5
      guard state != diagLastState || outOfRange else { return }
      diagLastState = state
      diagLog.log("\(outOfRange ? "OUT OF RANGE " : "", privacy: .public)resize: width=\(width, privacy: .public) \(state, privacy: .public)")
    }
  }
}
