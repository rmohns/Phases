import AppKit
import SwiftUI

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

    override func viewDidMoveToWindow() {
      super.viewDidMoveToWindow()
      apply()
    }

    /// [D-window-helper-order] Toolbar first; sidebar limits one run-loop
    /// pass later, after any split view rebuild the toolbar causes.
    func apply() {
      guard let window else { return }
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
      else { return }
      // [D-sidebar-always-visible] Dragging stops at the minimum instead of
      // collapsing.
      item.canCollapse = false
      item.canCollapseFromWindowResize = false
      // [D-sidebar-width]
      item.minimumThickness = sidebarMinWidth
      item.maximumThickness = sidebarMaxWidth
    }
  }
}
