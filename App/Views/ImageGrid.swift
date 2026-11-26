import SwiftUI

/// Thumbnail grid of the library folder. Click toggles an image; Shift-click
/// selects the range from the last clicked image. Headings collapse
/// `[D-grid-collapse]`. From the keyboard the grid is a single Tab stop
/// with an arrow-key cursor `[D-grid-one-tab-stop]`.
struct ImageGrid: View {
  var library: ImageLibrary
  @Binding var selection: [String]
  /// The editor's scroll view, used to keep the keyboard cursor visible.
  var scrollProxy: ScrollViewProxy?
  @State private var anchor: String?
  /// The image or heading the arrow keys move and Space acts on.
  @State private var cursor: GridOutline.Item?
  /// The column kept while the cursor passes over headings
  /// [D-grid-one-tab-stop]; nil while it's on an image.
  @State private var cursorColumn: Int?
  @State private var columnCount = 1
  @FocusState private var isFocused: Bool

  private static let minimumCellWidth: CGFloat = 112
  private static let spacing: CGFloat = 12
  private let columns = [GridItem(.adaptive(minimum: minimumCellWidth), spacing: spacing)]

  var body: some View {
    // Missing images, the count, and Select All / Select None are in the
    // pinned image header [D-image-header].
    if library.sources.isEmpty {
      Text("Add an image folder or Photos album in Settings.")
        .foregroundStyle(.secondary)
    } else if library.names.isEmpty {
      Text(emptyMessage)
        .foregroundStyle(.secondary)
    } else {
      let outline = library.outline
      LazyVGrid(columns: columns, alignment: .leading, spacing: Self.spacing) {
        ForEach(outline.sections.indices, id: \.self) { index in
          let section = outline.sections[index]
          Section {
            ForEach(section.names, id: \.self) { name in
              cell(for: name)
            }
          } header: {
            header(for: section, isFirst: index == 0, in: outline)
          }
        }
      }
      .onGeometryChange(for: Int.self) { proxy in
        // Matches how `.adaptive` columns fit the width.
        max(1, Int((proxy.size.width + Self.spacing) / (Self.minimumCellWidth + Self.spacing)))
      } action: { columnCount = $0 }
      .padding(.vertical, 4)
      // [D-grid-one-tab-stop] [Q-lazy-grid-tab] The grid, not each image,
      // takes focus; the
      // cursor ring below stands in for the focus ring.
      .focusable()
      .focused($isFocused)
      .focusEffectDisabled()
      .onChange(of: isFocused) {
        if isFocused, cursor.flatMap(outline.showing) == nil {
          // The first image that shows, else the first heading.
          cursor = outline.visibleNames.first.map(GridOutline.Item.image) ?? outline.items.first
          cursorColumn = nil
        }
      }
      .onChange(of: library.collapsedHeadings) {
        // [D-grid-one-tab-stop] Folding away the cursor's section moves
        // the cursor to the heading that hid it.
        let outline = library.outline
        if let cursor, let showing = outline.showing(cursor), showing != cursor {
          self.cursor = showing
          cursorColumn = nil
        }
      }
      // ⌥← and ⌥→ come as key presses, not move commands.
      .onKeyPress(keys: [.leftArrow, .rightArrow]) { press in
        guard press.modifiers.contains(.option), case .heading = cursor else { return .ignored }
        move(press.key == .leftArrow ? .left : .right, in: outline, option: true)
        return .handled
      }
      .onMoveCommand { direction in
        move(direction, in: outline, option: false)
      }
      .onKeyPress(keys: [.space]) { press in
        switch cursor {
        case .image(let name):
          toggle(name, extendingRange: press.modifiers.contains(.shift))
        case .heading(let heading):
          toggleHeading(heading, in: outline, all: false)
        case nil:
          return .ignored
        }
        return .handled
      }
      .onChange(of: cursor) {
        guard isFocused, let cursor else { return }
        scrollProxy?.scrollTo(cursor)
      }
      .accessibilityElement(children: .contain)
      .accessibilityLabel("Images")
      // [D-ui-test-ids]
      .accessibilityIdentifier("imageGrid")
    }
  }

  /// [D-image-sources] The source's heading over its first section, even
  /// with one source; subheadings under it when the source has subfolders
  /// (or albums). [D-grid-collapse] Each one collapses.
  @ViewBuilder
  private func header(for section: GridOutline.Section, isFirst: Bool, in outline: GridOutline) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      if let heading = section.sourceHeading {
        headingLine(heading, in: outline)
          .padding(.top, isFirst ? 0 : 12)
      }
      if let heading = section.subheading {
        headingLine(heading, in: outline)
          .padding(.top, section.sourceHeading == nil ? 8 : 0)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  /// [D-grid-collapse] The triangle, the symbol and name, and when
  /// collapsed, its count. Clicking anywhere on the line toggles it.
  private func headingLine(_ heading: GridOutline.Heading, in outline: GridOutline) -> some View {
    let source = library.source(withID: heading.sourceID)
    let isCollapsed = outline.isCollapsed(heading)
    let title = headingTitle(heading, source: source)
    let count = isCollapsed ? countText(heading, source: source, in: outline) : nil
    let item = GridOutline.Item.heading(heading)
    return HStack(alignment: .firstTextBaseline, spacing: 6) {
      Image(systemName: "chevron.right")
        .font(.caption.weight(.bold))
        .foregroundStyle(.secondary)
        .rotationEffect(.degrees(isCollapsed ? 0 : 90))
        .animation(.snappy, value: isCollapsed)
        .frame(width: 12)
      Group {
        if heading.isSource {
          Label(title, systemImage: source?.kind.symbolName ?? "folder")
            .font(.title3.weight(.semibold))
        } else {
          Label {
            Text(title)
          } icon: {
            // An album of a Photos folder, or a subfolder.
            Image(systemName: source?.kind == .photosFolder ? "rectangle.stack" : "folder")
          }
          .font(.headline)
          .foregroundStyle(.secondary)
        }
      }
      if let count {
        Text(count)
          .font(.callout)
          .foregroundStyle(.secondary)
      }
    }
    .padding(.horizontal, 4)
    .padding(.vertical, 2)
    .overlay {
      if isFocused && cursor == item {
        RoundedRectangle(cornerRadius: 6)
          .strokeBorder(Color(nsColor: .keyboardFocusIndicatorColor), lineWidth: 3)
      }
    }
    .padding(.horizontal, -4)
    .help(heading.isSource ? (source?.location ?? "") : "")
    .frame(maxWidth: .infinity, alignment: .leading)
    .contentShape(.rect)
    .id(item)
    .onTapGesture {
      cursor = item
      cursorColumn = nil
      isFocused = true
      toggleHeading(heading, in: outline, all: NSEvent.modifierFlags.contains(.option))
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(title)
    .accessibilityValue(count.map { "Collapsed, \($0)" } ?? "Expanded")
    .accessibilityAddTraits(.isHeader)
    .accessibilityAction { toggleHeading(heading, in: outline, all: false) }
    // [D-ui-test-ids]
    .accessibilityIdentifier("gridHeading")
  }

  private func headingTitle(_ heading: GridOutline.Heading, source: ImageSource?) -> String {
    guard let folder = heading.folder else { return source.map(library.displayName) ?? "" }
    return folder.isEmpty ? "Top Level" : folder
  }

  /// "12 of 80 selected", or "80 images" ("80 photos") with none selected.
  private func countText(_ heading: GridOutline.Heading, source: ImageSource?, in outline: GridOutline) -> String {
    let names = outline.names(under: heading)
    let selected = Set(selection)
    let selectedCount = names.filter(selected.contains).count
    if selectedCount > 0 { return "\(selectedCount) of \(names.count) selected" }
    let noun = source?.isPhotos == true ? "photo" : "image"
    return "\(names.count) \(noun)\(names.count == 1 ? "" : "s")"
  }

  /// [D-grid-collapse] ⌥ on a source heading folds its subheadings too.
  private func toggleHeading(_ heading: GridOutline.Heading, in outline: GridOutline, all: Bool) {
    let headings = all ? outline.headingAndSubheadings(of: heading) : [heading]
    library.setCollapsed(headings, !outline.isCollapsed(heading))
  }

  /// [D-grid-one-tab-stop] An arrow key: move the cursor, or on a heading,
  /// collapse or expand it.
  private func move(_ direction: MoveCommandDirection, in outline: GridOutline, option: Bool) {
    guard let cursor else { return }
    let navigation = ImageGridNavigation(outline: outline, columns: columnCount)
    switch navigation.outcome(from: cursor, direction, column: cursorColumn, option: option) {
    case .move(let item, let column):
      self.cursor = item
      cursorColumn = column
    case .setCollapsed(let headings, let isCollapsed):
      library.setCollapsed(headings, isCollapsed)
    case .stay:
      break
    }
  }

  private func cell(for name: String) -> some View {
    let isSelected = selection.contains(name)
    let item = GridOutline.Item.image(name)
    return ThumbnailCell(
      library: library,
      name: name,
      isSelected: isSelected,
      showsCursor: isFocused && cursor == item
    )
    .id(item)
    .onTapGesture {
      cursor = item
      cursorColumn = nil
      isFocused = true
      toggle(name, extendingRange: NSEvent.modifierFlags.contains(.shift))
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(library.isPhoto(name) ? library.fileName(of: name) : ImageLibrary.path(of: name))
    .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    .accessibilityAction { toggle(name, extendingRange: false) }
  }

  private var emptyMessage: String {
    let many = library.sources.count > 1
    if library.unreachableSources.count == library.sources.count {
      return many ? "The image sources can't be opened. Check Settings." : "The image source can't be opened. Check Settings."
    }
    if library.sources.allSatisfy(\.isPhotos) {
      return many ? "No photos in these albums." : "No photos in this album."
    }
    return many ? "No JPEG, PNG, HEIC, or TIFF images in these folders." : "No JPEG, PNG, HEIC, or TIFF images in this folder."
  }

  /// [D-grid-collapse] A ⇧ range covers only the images showing between its
  /// ends; with its start folded away, it's a plain click.
  private func toggle(_ name: String, extendingRange: Bool) {
    if extendingRange, let anchor, let range = library.outline.range(from: anchor, to: name) {
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

      Text(library.fileName(of: name))
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
