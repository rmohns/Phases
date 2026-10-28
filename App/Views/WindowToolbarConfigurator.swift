import AppKit
import SwiftUI

/// Placed in a window's content, gives the hosting NSWindow an empty unified
/// toolbar when SwiftUI hasn't made one. SwiftUI drops the toolbar entirely
/// when there are no items, which leaves a short title bar.
struct WindowToolbarConfigurator: NSViewRepresentable {
  func makeNSView(context: Context) -> ProbeView {
    ProbeView()
  }

  func updateNSView(_ view: ProbeView, context: Context) {
    view.apply()
  }

  final class ProbeView: NSView {
    override func viewDidMoveToWindow() {
      super.viewDidMoveToWindow()
      apply()
    }

    func apply() {
      guard let window else { return }
      // DIAGNOSTIC (temporary)
      diagLog.log("toolbar apply BEFORE: toolbar=\(window.toolbar?.identifier ?? "nil", privacy: .public) items=\(window.toolbar?.items.count ?? -1, privacy: .public) style=\(window.toolbarStyle.rawValue, privacy: .public) titlebarHeight=\(window.frame.height - window.contentLayoutRect.height, privacy: .public)")
      // [D-tall-toolbar] An empty toolbar still gets the full unified height.
      if window.toolbar == nil {
        window.toolbar = NSToolbar(identifier: "PhasesWindowToolbar")
      }
      window.toolbarStyle = .unified
      diagLog.log("toolbar apply AFTER: toolbar=\(window.toolbar?.identifier ?? "nil", privacy: .public) style=\(window.toolbarStyle.rawValue, privacy: .public) titlebarHeight=\(window.frame.height - window.contentLayoutRect.height, privacy: .public)")
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak window] in
        guard let window else { return }
        diagLog.log("toolbar +1s: toolbar=\(window.toolbar?.identifier ?? "nil", privacy: .public) items=\(window.toolbar?.items.count ?? -1, privacy: .public) style=\(window.toolbarStyle.rawValue, privacy: .public) titlebarHeight=\(window.frame.height - window.contentLayoutRect.height, privacy: .public) accessories=\(window.titlebarAccessoryViewControllers.count, privacy: .public)")
      }
    }
  }
}
