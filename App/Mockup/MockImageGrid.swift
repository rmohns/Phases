import SwiftUI

/// MOCKUP: the image grid with no file names and a tinted plate behind each
/// selected image. The checkmark shows only with Differentiate Without
/// Color on. Scrolls on its own, filling the rest of the pane.
struct MockImageGrid: View {
  var library: ImageLibrary
  @Binding var selection: [String]
  @State private var anchor: String?

  private let columns = [GridItem(.adaptive(minimum: 140), spacing: 4)]

  var body: some View {
    if library.folderURL == nil {
      ContentUnavailableView {
        Text("No image folder")
      } description: {
        Text("Choose the folder your wallpapers come from.")
      } actions: {
        Button("Choose Folder…") {}
      }
    } else {
      let groups = library.groups
      ScrollView {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 4) {
          ForEach(groups, id: \.folder) { group in
            Section {
              ForEach(group.names, id: \.self) { name in
                MockThumbnail(library: library, name: name, isSelected: selection.contains(name))
                  .onTapGesture { toggle(name, extendingRange: NSEvent.modifierFlags.contains(.shift)) }
              }
            } header: {
              if groups.count > 1 {
                Text(group.folder.isEmpty ? "Top Level" : group.folder)
                  .font(.headline)
                  .padding(.top, 10)
                  .padding(.leading, 6)
                  .frame(maxWidth: .infinity, alignment: .leading)
              }
            }
          }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
      }
    }
  }

  private func toggle(_ name: String, extendingRange: Bool) {
    let names = library.imageNames
    if extendingRange, let anchor,
      let from = names.firstIndex(of: anchor), let to = names.firstIndex(of: name)
    {
      let range = names[min(from, to)...max(from, to)]
      if selection.contains(anchor) {
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

private struct MockThumbnail: View {
  var library: ImageLibrary
  var name: String
  var isSelected: Bool
  @State private var image: NSImage?
  @Environment(\.displayScale) private var displayScale
  @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

  var body: some View {
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
      .clipShape(.rect(cornerRadius: 4))
      .overlay {
        RoundedRectangle(cornerRadius: 4)
          .strokeBorder(.separator, lineWidth: 1)
      }
      .overlay(alignment: .topTrailing) {
        if isSelected && differentiateWithoutColor {
          Image(systemName: "checkmark.circle.fill")
            .symbolRenderingMode(.palette)
            .foregroundStyle(.white, .tint)
            .font(.title3)
            .padding(4)
        }
      }
      .padding(7)
      .background {
        if isSelected {
          RoundedRectangle(cornerRadius: 9)
            .fill(.tint.opacity(0.35))
        }
      }
      .contentShape(.rect)
      .help(ImageLibrary.fileName(of: name))
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(ImageLibrary.fileName(of: name))
      .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
      .task(id: name) {
        image = await library.thumbnail(for: name, size: CGSize(width: 240, height: 150), scale: displayScale)
      }
  }
}
