import AppKit
import SwiftUI

/// MOCKUP: one tab for the shared images, then one per display, each drawn
/// in that display's real shape.
struct MockDisplayTabStrip: View {
  var displays: [MockDisplayInfo]
  var sharedCount: Int
  /// Image counts for displays with their own images, by UUID.
  var ownCounts: [String: Int]
  @Binding var selection: MockDisplayTab

  var body: some View {
    HStack(alignment: .top, spacing: 4) {
      tab(.shared, title: "Shared", detail: imageCount(sharedCount), isConnected: true) { isSelected in
        SharedShape(isSelected: isSelected)
      }
      ForEach(displays) { display in
        tab(
          .display(display.uuid),
          title: display.name,
          detail: display.isConnected
            ? ownCounts[display.uuid].map { "Own · \(imageCount($0))" } ?? "Uses Shared"
            : "Not connected",
          isConnected: display.isConnected
        ) { isSelected in
          DisplayShape(aspect: display.aspect, isBuiltIn: display.isBuiltIn, isSelected: isSelected)
        }
      }
    }
  }

  private func imageCount(_ count: Int) -> String {
    count == 1 ? "1 image" : "\(count) images"
  }

  private func tab(
    _ tab: MockDisplayTab,
    title: String,
    detail: String,
    isConnected: Bool,
    @ViewBuilder shape: @escaping (Bool) -> some View
  ) -> some View {
    let isSelected = selection == tab
    return Button {
      selection = tab
    } label: {
      VStack(spacing: 4) {
        shape(isSelected)
          .frame(height: 40)
        Text(title)
          .font(.callout)
          .lineLimit(1)
          .truncationMode(.middle)
        Text(detail)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
      .frame(width: 104)
      .padding(.vertical, 6)
      .background {
        if isSelected {
          RoundedRectangle(cornerRadius: 8)
            .fill(.quaternary)
        }
      }
      .contentShape(.rect)
      .opacity(isConnected ? 1 : 0.5)
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
    .accessibilityValue(detail)
  }
}

/// A display outline in its own aspect ratio; laptops get a base.
private struct DisplayShape: View {
  var aspect: CGFloat
  var isBuiltIn: Bool
  var isSelected: Bool

  var body: some View {
    let height: CGFloat = isBuiltIn ? 30 : 36
    let width = min(max(height * aspect, 18), 96)
    VStack(spacing: 1) {
      RoundedRectangle(cornerRadius: 3)
        .fill(isSelected ? AnyShapeStyle(.tint.opacity(0.25)) : AnyShapeStyle(.background))
        .strokeBorder(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary), lineWidth: 1.5)
        .frame(width: width, height: height)
      if isBuiltIn {
        Capsule()
          .fill(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
          .frame(width: width * 1.2, height: 3)
      }
    }
    .frame(maxHeight: .infinity, alignment: .bottom)
  }
}

/// Two overlapping screens: images every display shares.
private struct SharedShape: View {
  var isSelected: Bool

  var body: some View {
    ZStack {
      screen.offset(x: -7, y: -4)
      screen.offset(x: 7, y: 4)
    }
    .frame(maxHeight: .infinity, alignment: .center)
  }

  private var screen: some View {
    RoundedRectangle(cornerRadius: 3)
      .fill(isSelected ? AnyShapeStyle(.tint.opacity(0.25)) : AnyShapeStyle(.background))
      .strokeBorder(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary), lineWidth: 1.5)
      .background(RoundedRectangle(cornerRadius: 3).fill(.background))
      .frame(width: 40, height: 25)
  }
}

enum MockDisplayTab: Hashable {
  case shared
  case display(String)
}

/// A known display with the shape of its screen, for the tab strip.
struct MockDisplayInfo: Identifiable {
  var uuid: String
  var name: String
  var isConnected: Bool
  var isBuiltIn: Bool
  var aspect: CGFloat

  var id: String { uuid }

  @MainActor static func all(for scheduler: WallpaperScheduler) -> [MockDisplayInfo] {
    scheduler.displaysForPicker.map { known in
      let screen = NSScreen.screens.first { $0.displayUUID == known.uuid }
      let size = screen?.frame.size ?? CGSize(width: 16, height: 10)
      return MockDisplayInfo(
        uuid: known.uuid,
        name: known.name,
        isConnected: scheduler.isConnected(known),
        isBuiltIn: screen?.displayID.map { CGDisplayIsBuiltin($0) != 0 } ?? false,
        aspect: size.width / max(size.height, 1)
      )
    }
  }
}
