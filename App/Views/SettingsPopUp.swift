import AppKit
import SwiftUI

/// [D-editor-popups] A real AppKit pop-up button that looks like System
/// Settings' own [Q-settings-popup-look]. AppKit draws the rounded box and
/// chevron under the pointer and opens the menu over the control; Phases
/// adds only the resting chevron in its circle, which macOS 26 and later
/// leave out.
struct SettingsPopUp<Value: Hashable>: View {
  typealias Item = PopUpItem<Value>

  /// What the menu sets, for VoiceOver ("Trigger", "Change images").
  var title: String
  @Binding var selection: Value
  var items: [Item]
  @State private var isHovering = false

  var body: some View {
    PopUpButton(title: title, selection: $selection, items: items)
      .fixedSize()
      // On the pixels where AppKit draws its chevron under the pointer
      // (measured by Claude, 2026-11-26), so nothing moves as the pointer
      // arrives; the circle matches System Settings' (20 pt, the box's
      // gray). It takes no clicks, so every point of the control opens
      // the menu.
      .overlay(alignment: .trailing) {
        Image(systemName: "chevron.up.chevron.down")
          .font(.system(size: 11, weight: .semibold))
          .frame(width: 20, height: 20)
          .background(Circle().fill(.fill.tertiary))
          .padding(.trailing, 3.5)
          .opacity(isHovering ? 0 : 1)
          .allowsHitTesting(false)
          .accessibilityHidden(true)
      }
      .onHover { isHovering = $0 }
  }
}

/// One line of a `SettingsPopUp` menu.
enum PopUpItem<Value: Hashable> {
  case choice(Value, title: String, systemImage: String? = nil)
  case separator
}

private struct PopUpButton<Value: Hashable>: NSViewRepresentable {
  var title: String
  @Binding var selection: Value
  var items: [PopUpItem<Value>]

  func makeCoordinator() -> Coordinator { Coordinator() }

  func makeNSView(context: Context) -> FittingPopUpButton {
    let button = FittingPopUpButton(frame: .zero, pullsDown: false)
    // Together these give System Settings' box under the pointer and
    // nothing at rest (Apple Developer Forums thread 788097; verified by
    // Claude, 2026-11-26) [Q-settings-popup-look].
    button.bezelStyle = .flexiblePush
    button.showsBorderOnlyWhileMouseInside = true
    button.target = context.coordinator
    button.action = #selector(Coordinator.chose(_:))
    return button
  }

  func updateNSView(_ button: FittingPopUpButton, context: Context) {
    context.coordinator.choose = { index in
      if case .choice(let value, _, _) = items[index] { selection = value }
    }
    button.removeAllItems()
    for item in items {
      switch item {
      case .choice(let value, let title, let systemImage):
        let menuItem = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        if let systemImage {
          menuItem.image = NSImage(systemSymbolName: systemImage, accessibilityDescription: nil)
        }
        button.menu?.addItem(menuItem)
        if value == selection { button.select(menuItem) }
      case .separator:
        button.menu?.addItem(.separator())
      }
    }
    button.setAccessibilityLabel(title)
    button.invalidateIntrinsicContentSize()
  }

  final class Coordinator: NSObject {
    var choose: (Int) -> Void = { _ in }
    @objc func chose(_ sender: NSPopUpButton) { choose(sender.indexOfSelectedItem) }
  }
}

/// A pop-up button as wide as its current choice. AppKit's is as wide as
/// its longest choice, so this takes the difference off; Change images
/// showing "minutes" was otherwise as wide as "Only when the phase starts"
/// (author, 2026-11-25) [D-editor-popups].
private final class FittingPopUpButton: NSPopUpButton {
  override var intrinsicContentSize: NSSize {
    var size = super.intrinsicContentSize
    let font = self.font ?? .systemFont(ofSize: NSFont.systemFontSize)
    let widths = itemArray.filter { !$0.isSeparatorItem }.map {
      ($0.title as NSString).size(withAttributes: [.font: font]).width
    }
    if let widest = widths.max(), let selected = selectedItem {
      let width = (selected.title as NSString).size(withAttributes: [.font: font]).width
      size.width -= (widest - width).rounded(.down)
    }
    return size
  }
}
