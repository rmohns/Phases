import SwiftUI

/// Settings' Image Sources list [D-image-sources]: a row per source in the
/// library's order, + to add a folder, − to remove the selected one.
struct ImageSourcesSection: View {
  var scheduler: WallpaperScheduler
  @State private var selectedID: String?
  @State private var picker: FolderPickerPurpose?
  @State private var pendingRemoval: ImageSource?

  private enum FolderPickerPurpose: Equatable {
    case add
    case locate(String)
  }

  private var library: ImageLibrary { scheduler.library }

  var body: some View {
    Section("Image Sources") {
      List(selection: $selectedID) {
        ForEach(library.sources) { source in
          ImageSourceRow(scheduler: scheduler, source: source) {
            picker = .locate(source.id)
          }
          .tag(source.id)
        }
      }
      .listStyle(.bordered)
      .alternatingRowBackgrounds(.disabled)
      .frame(height: listHeight)
      .overlay {
        if library.sources.isEmpty {
          Text("No image folders. Add one with +.")
            .foregroundStyle(.secondary)
        }
      }
      .accessibilityIdentifier("imageSources")

      HStack(spacing: 4) {
        Button("Add Folder…", systemImage: "plus") { picker = .add }
          .accessibilityIdentifier("addImageSource")
        Button("Remove Folder", systemImage: "minus") { removeSelected() }
          .disabled(selectedID == nil)
          .accessibilityIdentifier("removeImageSource")
      }
      .labelStyle(.iconOnly)
      .buttonStyle(.borderless)
    }
    .fileImporter(isPresented: isPicking, allowedContentTypes: [.folder]) { result in
      guard case .success(let url) = result, let purpose = picker else { return }
      chose(url, for: purpose)
    }
    .alert(
      "Remove “\(pendingRemoval.map(library.displayName) ?? "")”?",
      isPresented: isConfirmingRemoval,
      presenting: pendingRemoval
    ) { source in
      Button("Remove", role: .destructive) { remove(source.id) }
      Button("Cancel", role: .cancel) {}
    } message: { source in
      let count = phasesUsing(source.id)
      Text(
        "\(count == 1 ? "1 phase uses" : "\(count) phases use") images from this folder. They'll show as missing. Adding the folder again later won't bring them back."
      )
    }
  }

  /// Room for every row, up to five before the list scrolls.
  private var listHeight: CGFloat {
    CGFloat(min(max(library.sources.count, 1), 5)) * 64 + 8
  }

  private var isPicking: Binding<Bool> {
    Binding { picker != nil } set: { if !$0 { picker = nil } }
  }

  private var isConfirmingRemoval: Binding<Bool> {
    Binding { pendingRemoval != nil } set: { if !$0 { pendingRemoval = nil } }
  }

  private func chose(_ url: URL, for purpose: FolderPickerPurpose) {
    let started = url.startAccessingSecurityScopedResource()
    defer { if started { url.stopAccessingSecurityScopedResource() } }
    switch purpose {
    case .add:
      switch library.addFolder(url) {
      case .added(let id), .existing(let id):
        selectedID = id
      }
    case .locate(let id):
      library.locate(id, at: url)
    }
    scheduler.evaluate(reloadingLibrary: false)
  }

  private func phasesUsing(_ id: String) -> Int {
    scheduler.phases.filter { $0.uses(source: id) }.count
  }

  /// Asks first when any phase uses the source's images.
  private func removeSelected() {
    guard let id = selectedID, let source = library.source(withID: id) else { return }
    if phasesUsing(id) > 0 {
      pendingRemoval = source
    } else {
      remove(id)
    }
  }

  private func remove(_ id: String) {
    library.removeSource(id)
    selectedID = nil
    scheduler.evaluate(reloadingLibrary: false)
  }
}

private struct ImageSourceRow: View {
  var scheduler: WallpaperScheduler
  var source: ImageSource
  var locate: () -> Void

  private var library: ImageLibrary { scheduler.library }

  var body: some View {
    HStack(alignment: .top, spacing: 8) {
      Image(systemName: "folder")
        .foregroundStyle(.secondary)
        .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 2) {
        HStack {
          Text(library.displayName(of: source))
            .lineLimit(1)
            .truncationMode(.middle)
            .layoutPriority(1)
            .help(source.location)
            // [D-ui-test-ids]
            .accessibilityIdentifier("imageFolderName")
          Spacer(minLength: 8)
          if library.unreachableSources.contains(source.id) {
            Label("Can't open", systemImage: "exclamationmark.triangle")
              .foregroundStyle(.orange)
              .fixedSize()
            Button("Locate…", action: locate)
              .fixedSize()
          } else {
            Text(imageCount)
              .foregroundStyle(.secondary)
              .monospacedDigit()
              // A long folder name would otherwise squeeze this to a sliver
              // (as it did Choose…, found 2026-10-29).
              .fixedSize()
              .accessibilityIdentifier("imageSourceCount")
          }
        }
        Text(source.location)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)
          .truncationMode(.middle)
        Toggle("Include subfolders", isOn: includesSubfolders)
          .controlSize(.small)
      }
    }
    .padding(.vertical, 4)
  }

  private var imageCount: String {
    let count = library.imageCounts[source.id] ?? 0
    return count == 1 ? "1 image" : "\(count.formatted()) images"
  }

  private var includesSubfolders: Binding<Bool> {
    Binding {
      source.includesSubfolders
    } set: { isOn in
      library.setIncludesSubfolders(isOn, for: source.id)
      scheduler.evaluate(reloadingLibrary: false)
    }
  }
}
