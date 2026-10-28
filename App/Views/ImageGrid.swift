import SwiftUI

/// Thumbnail grid of the library folder. Click toggles an image; Shift-click
/// selects the range from the last clicked image. From the keyboard the grid
/// is a single Tab stop with an arrow-key cursor `[D-grid-one-tab-stop]`.
struct ImageGrid: View {
  var library: ImageLibrary
  @Binding var selection: [String]
  /// The editor's scroll view, used to keep the keyboard cursor visible.
  var scrollProxy: ScrollViewProxy?
  @State private var anchor: String?
  /// The image the arrow keys move and Space toggles.
  @State private var cursor: String?
  @State private var columnCount = 1
  @FocusState private var isFocused: Bool

  private static let minimumCellWidth: CGFloat = 112
  private static let spacing: CGFloat = 12
  private let columns = [GridItem(.adaptive(minimum: minimumCellWidth), spacing: spacing)]

  var body: some View {
    if library.folderURL == nil {
      Text("Choose an image folder in Settings.")
        .foregroundStyle(.secondary)
    } else if library.imageNames.isEmpty {
      Text("No JPEG, PNG, HEIC, or TIFF images in this folder.")
        .foregroundStyle(.secondary)
    } else {
      HStack {
        Text("\(selectedCount) of \(library.imageNames.count) selected")
          .foregroundStyle(.secondary)
        Spacer()
        Button("Select All") { selection = library.imageNames }
        Button("Select None") { selection = [] }
      }

      if !missing.isEmpty {
        HStack {
          Label(
            missing.count == 1 ? "1 selected image is missing" : "\(missing.count) selected images are missing",
            systemImage: "exclamationmark.triangle"
          )
          .foregroundStyle(.orange)
          Spacer()
          Button("Remove Missing") { selection.removeAll { missing.contains($0) } }
        }
      }

      let groups = library.groups
      LazyVGrid(columns: columns, alignment: .leading, spacing: Self.spacing) {
        ForEach(groups, id: \.folder) { group in
          Section {
            ForEach(group.names, id: \.self) { name in
              cell(for: name)
            }
          } header: {
            if groups.count > 1 {
              Label(group.folder.isEmpty ? "Top Level" : group.folder, systemImage: "folder")
                .font(.headline)
                .padding(.top, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
          }
        }
      }
      .onGeometryChange(for: Int.self) { proxy in
        // Matches how `.adaptive` columns fit the width.
        max(1, Int((proxy.size.width + Self.spacing) / (Self.minimumCellWidth + Self.spacing)))
      } action: { columnCount = $0 }
      .padding(.vertical, 4)
      // [D-grid-one-tab-stop] The grid, not each image, takes focus; the
      // cursor ring below stands in for the focus ring.
      .focusable()
      .focused($isFocused)
      .focusEffectDisabled()
      .onChange(of: isFocused) {
        if isFocused, cursor.map(library.contains) != true {
          cursor = library.imageNames.first
        }
      }
      .onMoveCommand { direction in
        guard let cursor else { return }
        let navigation = ImageGridNavigation(groups: groups, columns: columnCount)
        self.cursor = navigation.destination(from: cursor, direction)
      }
      .onKeyPress(keys: [.space]) { press in
        guard let cursor else { return .ignored }
        toggle(cursor, extendingRange: press.modifiers.contains(.shift))
        return .handled
      }
      .onChange(of: cursor) {
        guard isFocused, let cursor else { return }
        scrollProxy?.scrollTo(cursor)
      }
      .accessibilityElement(children: .contain)
      .accessibilityLabel("Images")
    }
  }

  private func cell(for name: String) -> some View {
    let isSelected = selection.contains(name)
    return ThumbnailCell(
      library: library,
      name: name,
      isSelected: isSelected,
      showsCursor: isFocused && cursor == name
    )
    .id(name)
    .onTapGesture {
      cursor = name
      isFocused = true
      toggle(name, extendingRange: NSEvent.modifierFlags.contains(.shift))
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(name)
    .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    .accessibilityAction { toggle(name, extendingRange: false) }
  }

  private var selectedCount: Int {
    selection.filter(library.contains).count
  }

  private var missing: [String] {
    selection.filter { !library.contains($0) }
  }

  private func toggle(_ name: String, extendingRange: Bool) {
    let names = library.imageNames
    if extendingRange, let anchor,
      let from = names.firstIndex(of: anchor), let to = names.firstIndex(of: name)
    {
      let range = names[min(from, to)...max(from, to)]
      let shouldSelect = selection.contains(anchor)
      if shouldSelect {
        selection.append(contentsOf: range.filter { !selection.contains($0) })
      } else {
        selection.removeAll { range.contains($0) }
      }
    } else if let index = selection.firstIndex(of: name) {
      selection.remove(at: index)
    } else {
      selection.append(name)
    }
    anchor = name
  }
}

private struct ThumbnailCell: View {
  var library: ImageLibrary
  var name: String
  var isSelected: Bool
  /// Whether the grid's keyboard cursor is on this image.
  var showsCursor: Bool
  @State private var image: NSImage?
  @Environment(\.displayScale) private var displayScale

  var body: some View {
    VStack(spacing: 4) {
      Color.secondary.opacity(0.15)
        .aspectRatio(16 / 10, contentMode: .fit)
        .overlay {
          if let image {
            Image(nsImage: image)
              .resizable()
              .scaledToFill()
          } else {
            ProgressView()
              .controlSize(.small)
          }
        }
        .clipShape(.rect(cornerRadius: 6))
        .overlay {
          RoundedRectangle(cornerRadius: 6)
            .strokeBorder(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.separator), lineWidth: isSelected ? 3 : 1)
        }
        .overlay {
          if showsCursor {
            RoundedRectangle(cornerRadius: 9)
              .strokeBorder(Color(nsColor: .keyboardFocusIndicatorColor), lineWidth: 3)
              .padding(-4)
          }
        }
        .overlay(alignment: .topTrailing) {
          if isSelected {
            Image(systemName: "checkmark.circle.fill")
              .symbolRenderingMode(.palette)
              .foregroundStyle(.white, .tint)
              .font(.title3)
              .padding(5)
          }
        }

      Text(ImageLibrary.fileName(of: name))
        .font(.caption)
        .lineLimit(1)
        .truncationMode(.middle)
        .foregroundStyle(isSelected ? .primary : .secondary)
    }
    .contentShape(.rect)
    .task(id: name) {
      image = await library.thumbnail(for: name, size: CGSize(width: 200, height: 125), scale: displayScale)
    }
  }
}
