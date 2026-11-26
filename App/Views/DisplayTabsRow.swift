import SwiftUI

/// [D-display-tabs] Shared, a divider, then a tab for each connected display.
/// Shared stays put while the display tabs scroll sideways, with the edge
/// faded on any side that has tabs out of view. One Tab stop; the arrow keys
/// move between tabs.
struct DisplayTabsRow: View {
  var displays: [ConnectedDisplay]
  var sharedCount: Int
  /// The count of each display's own images; absent when it uses Shared.
  var ownCounts: [String: Int]
  /// The chosen display, or nil for Shared.
  @Binding var selection: String?
  @FocusState private var isFocused: Bool
  @State private var hiddenEdges: Edge.Set = []

  private static let tabWidth: CGFloat = 104
  private static let outlineHeight: CGFloat = 32

  var body: some View {
    // Top-aligned, so a tab whose name wraps to two lines keeps its
    // outline and name level with its neighbours' (Phase editor checks,
    // 2026-11-25).
    HStack(alignment: .top, spacing: 6) {
      tab(for: nil)
      Divider()
        .frame(height: 64)
        .padding(.top, 12)
      ScrollViewReader { proxy in
        ScrollView(.horizontal) {
          HStack(alignment: .top, spacing: 6) {
            ForEach(displays) { display in
              tab(for: display).id(display.uuid)
            }
          }
        }
        .scrollIndicators(.never)
        .onScrollGeometryChange(for: Edge.Set.self) { geometry in
          var edges: Edge.Set = []
          if geometry.contentOffset.x > 1 { edges.insert(.leading) }
          if geometry.contentOffset.x + geometry.containerSize.width < geometry.contentSize.width - 1 {
            edges.insert(.trailing)
          }
          return edges
        } action: { hiddenEdges = $1 }
        .mask {
          HStack(spacing: 0) {
            LinearGradient(colors: [.clear, .black], startPoint: .leading, endPoint: .trailing)
              .frame(width: hiddenEdges.contains(.leading) ? 24 : 0)
            Color.black
            LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing)
              .frame(width: hiddenEdges.contains(.trailing) ? 24 : 0)
          }
        }
        .onChange(of: selection) {
          guard let selection else { return }
          // Centered, so the chosen tab never stops under an edge's fade;
          // scrolled only far enough, it sat half faded (Phase editor
          // checks, 2026-11-25). At either end the row can't scroll past
          // its content, and that edge has no fade.
          withAnimation(.smooth) { proxy.scrollTo(selection, anchor: .center) }
        }
      }
    }
    .padding(2)
    .focusable()
    .focused($isFocused)
    .onMoveCommand { direction in
      let order: [String?] = [nil] + displays.map(\.uuid)
      guard let index = order.firstIndex(of: selection) else { return }
      switch direction {
      case .left where index > 0: selection = order[index - 1]
      case .right where index < order.count - 1: selection = order[index + 1]
      default: break
      }
    }
    .accessibilityRepresentation {
      Picker("Display", selection: $selection) {
        Text("Shared, \(DisplayTabs.sharedCaption(count: sharedCount))").tag(nil as String?)
        ForEach(displays) { display in
          Text("\(display.name), \(DisplayTabs.caption(ownCount: ownCounts[display.uuid]))").tag(Optional(display.uuid))
        }
      }
      .pickerStyle(.radioGroup)
    }
    // [D-ui-test-ids]
    .accessibilityIdentifier("displayTabs")
  }

  private func tab(for display: ConnectedDisplay?) -> some View {
    let uuid = display?.uuid
    let isSelected = selection == uuid
    return VStack(spacing: 3) {
      Group {
        if let display {
          let size = DisplayTabs.outlineSize(for: display.size, height: Self.outlineHeight, maxWidth: Self.tabWidth - 24)
          RoundedRectangle(cornerRadius: 3)
            .strokeBorder(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary), lineWidth: 1.5)
            .frame(width: size.width, height: size.height)
        } else {
          SharedIcon()
        }
      }
      .frame(height: Self.outlineHeight + 4)

      Text(display?.name ?? "Shared")
        .font(.callout)
        .lineLimit(2)
        .multilineTextAlignment(.center)
        .truncationMode(.tail)
        .help(display?.name ?? "Shared")
      Text(display.map { DisplayTabs.caption(ownCount: ownCounts[$0.uuid]) } ?? DisplayTabs.sharedCaption(count: sharedCount))
        .font(.caption2)
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
    .frame(width: Self.tabWidth)
    .frame(minHeight: 76, alignment: .top)
    .padding(.vertical, 6)
    .background {
      if isSelected {
        RoundedRectangle(cornerRadius: 8)
          .fill(.quaternary)
          .overlay {
            if isFocused {
              RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color(nsColor: .keyboardFocusIndicatorColor), lineWidth: 2)
            }
          }
      }
    }
    .contentShape(.rect)
    .onTapGesture {
      selection = uuid
      isFocused = true
    }
  }
}

/// Shared's picture: two overlapping screens in the accent color.
private struct SharedIcon: View {
  var body: some View {
    ZStack(alignment: .topLeading) {
      screen
      screen.offset(x: 10, y: 8)
    }
    .frame(width: 52, height: 34, alignment: .topLeading)
  }

  private var screen: some View {
    RoundedRectangle(cornerRadius: 3)
      .fill(.tint.opacity(0.25))
      .strokeBorder(.tint, lineWidth: 1.5)
      .background(RoundedRectangle(cornerRadius: 3).fill(Color(nsColor: .windowBackgroundColor)))
      .frame(width: 42, height: 26)
  }
}
