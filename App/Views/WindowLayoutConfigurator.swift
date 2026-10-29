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

    /// DIAGNOSTIC (temporary): last logged split state, to log only changes.
    private var diagLastState = ""
    private var diagObserver: NSObjectProtocol?

    override func viewDidMoveToWindow() {
      super.viewDidMoveToWindow()
      diagLog.log("probe \(diagID(self), privacy: .public) moved to window \(diagID(self.window), privacy: .public)")
      apply()
      diagWatchResizes()
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
        // DIAGNOSTIC (temporary): the silent skip suspected in SPEC.md.
        let split = ancestor as? NSSplitView
        diagLog.error("SKIPPED limits: probe \(diagID(self), privacy: .public) window=\(diagID(self.window), privacy: .public) superview=\(self.superview != nil, privacy: .public) splitView=\(diagID(split), privacy: .public) delegate=\(split.map { String(describing: type(of: $0.delegate as AnyObject)) } ?? "n/a", privacy: .public)")
        return
      }
      diagLog.log("applying limits: probe \(diagID(self), privacy: .public) window=\(diagID(self.window), privacy: .public) split=\(diagID(splitView), privacy: .public) controller=\(diagID(controller), privacy: .public) item=\(diagID(item), privacy: .public) before min=\(item.minimumThickness, privacy: .public) max=\(item.maximumThickness, privacy: .public)")
      // [D-sidebar-always-visible] Dragging stops at the minimum instead of
      // collapsing.
      item.canCollapse = false
      item.canCollapseFromWindowResize = false
      // [D-sidebar-width]
      item.minimumThickness = sidebarMinWidth
      item.maximumThickness = sidebarMaxWidth
    }

    /// DIAGNOSTIC (temporary): logs the sidebar's split view whenever its
    /// identity or limits change, or its width leaves the allowed range.
    private func diagWatchResizes() {
      guard diagObserver == nil, window != nil else { return }
      diagObserver = NotificationCenter.default.addObserver(
        forName: NSSplitView.didResizeSubviewsNotification, object: nil, queue: .main
      ) { [weak self] note in
        MainActor.assumeIsolated {
          guard let self, let splitView = note.object as? NSSplitView, self.isDescendant(of: splitView) else { return }
          let controller = splitView.delegate as? NSSplitViewController
          let item = controller?.splitViewItems.first
          let width = splitView.subviews.first?.frame.width ?? -1
          let state = "split=\(diagID(splitView)) controller=\(diagID(controller)) item=\(diagID(item)) min=\(item?.minimumThickness ?? -1) max=\(item?.maximumThickness ?? -1) canCollapse=\(item?.canCollapse ?? true)"
          let outOfRange = width < self.sidebarMinWidth - 0.5 || width > self.sidebarMaxWidth + 0.5
          guard state != self.diagLastState || outOfRange else { return }
          self.diagLastState = state
          diagLog.log("\(outOfRange ? "OUT OF RANGE " : "", privacy: .public)resize: probe \(diagID(self), privacy: .public) width=\(width, privacy: .public) \(state, privacy: .public)")
        }
      }
    }
  }
}
