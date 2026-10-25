import SwiftUI

/// Thumbnail grid of the library folder. Click toggles an image; Shift-click
/// selects the range from the last clicked image.
struct ImageGrid: View {
  var library: ImageLibrary
  @Binding var selection: [String]
  @State private var anchor: String?

  private let columns = [GridItem(.adaptive(minimum: 112), spacing: 12)]

  var body: some View {
    if library.folderURL == nil {
      Text("Choose an image folder in the General tab.")
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

      LazyVGrid(columns: columns, spacing: 12) {
        ForEach(library.imageNames, id: \.self) { name in
          let isSelected = selection.contains(name)
          Button {
            toggle(name, extendingRange: NSEvent.modifierFlags.contains(.shift))
          } label: {
            ThumbnailCell(library: library, name: name, isSelected: isSelected)
          }
          .buttonStyle(.plain)
          .accessibilityLabel(name)
          .accessibilityAddTraits(isSelected ? .isSelected : [])
        }
      }
      .padding(.vertical, 4)
    }
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
        .overlay(alignment: .topTrailing) {
          if isSelected {
            Image(systemName: "checkmark.circle.fill")
              .symbolRenderingMode(.palette)
              .foregroundStyle(.white, .tint)
              .font(.title3)
              .padding(5)
          }
        }

      Text(name)
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
