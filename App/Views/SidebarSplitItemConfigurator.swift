import AppKit
import os

// DIAGNOSTIC (temporary): remove after the toolbar/sidebar-width investigation.
let diagLog = Logger(subsystem: "PhasesDiag", category: "layout")
import SwiftUI

/// Placed inside the sidebar of a NavigationSplitView, finds the AppKit split
/// view item that hosts the sidebar and makes it non-collapsible within a
/// fixed width range. SwiftUI has no API to stop a drag from collapsing it.
struct SidebarSplitItemConfigurator: NSViewRepresentable {
  var minWidth: CGFloat
  var maxWidth: CGFloat

  func makeNSView(context: Context) -> ProbeView {
    ProbeView()
  }

  func updateNSView(_ view: ProbeView, context: Context) {
    view.minWidth = minWidth
    view.maxWidth = maxWidth
    view.apply()
  }

  final class ProbeView: NSView {
    var minWidth: CGFloat = 0
    var maxWidth: CGFloat = .greatestFiniteMagnitude

    override func viewDidMoveToWindow() {
      super.viewDidMoveToWindow()
      diagLog.log("sidebar probe moved to window: \(self.window != nil, privacy: .public)")
      apply()
      // DIAGNOSTIC (temporary)
      NotificationCenter.default.addObserver(forName: NSSplitView.didResizeSubviewsNotification, object: nil, queue: .main) { [weak self] note in
        guard let self, let splitView = note.object as? NSSplitView, self.isDescendant(of: splitView) else { return }
        let controller = splitView.delegate as? NSSplitViewController
        let item = controller?.splitViewItems.first
        diagLog.log("split resized: view=\(ObjectIdentifier(splitView).hashValue, privacy: .public) controller=\(controller.map { ObjectIdentifier($0).hashValue } ?? 0, privacy: .public) item=\(item.map { ObjectIdentifier($0).hashValue } ?? 0, privacy: .public) width=\(splitView.subviews.first?.frame.width ?? -1, privacy: .public) min=\(item?.minimumThickness ?? -1, privacy: .public) max=\(item?.maximumThickness ?? -1, privacy: .public) canCollapse=\(item?.canCollapse ?? true, privacy: .public)")
      }
    }

    func apply() {
      var ancestor = superview
      while let view = ancestor, !(view is NSSplitView) {
        ancestor = view.superview
      }
      guard let splitView = ancestor as? NSSplitView,
            let controller = splitView.delegate as? NSSplitViewController,
            let item = controller.splitViewItems.first
      else {
        diagLog.log("sidebar apply: no split view controller found (superview=\(self.superview != nil, privacy: .public))")
        return
      }
      diagLog.log("sidebar apply: controller=\(ObjectIdentifier(controller).hashValue, privacy: .public) item=\(ObjectIdentifier(item).hashValue, privacy: .public) before min=\(item.minimumThickness, privacy: .public) max=\(item.maximumThickness, privacy: .public)")
      // [D-sidebar-always-visible] Dragging stops at the minimum instead of
      // collapsing.
      item.canCollapse = false
      item.canCollapseFromWindowResize = false
      // [D-sidebar-width]
      item.minimumThickness = minWidth
      item.maximumThickness = maxWidth
    }
  }
}
