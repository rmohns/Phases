import AppKit
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
      apply()
    }

    func apply() {
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
      item.minimumThickness = minWidth
      item.maximumThickness = maxWidth
    }
  }
}
