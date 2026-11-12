import SwiftUI

/// Settings' Image Sources list [D-image-sources]: a row per source in the
/// library's order, a + / − bar joined to its bottom, folders dragged in
/// from Finder, rows dragged to reorder, and a context menu per row.
struct ImageSourcesSection: View {
  var scheduler: WallpaperScheduler
  @State private var selectedID: String?
  @State private var isPicking = false
  /// Kept apart from `isPicking`: SwiftUI sets that to false before the
  /// picker's completion runs, so it can't carry the purpose (SDK docs for
  /// `fileImporter(isPresented:…)`; Fable review, 2026-11-12).
  @State private var pickerPurpose = FolderPickerPurpose.add
  @State private var pendingRemoval: ImageSource?
  @Environment(\.undoManager) private var undoManager

  private enum FolderPickerPurpose: Equatable {
    case add
    case locate(String)
  }

  private var library: ImageLibrary { scheduler.library }

  var body: some View {
    Section("Image Sources") {
      // One form row holding the list and its bar, so the bar is 24 pt
      // and joined to the list, as under the phase list
      // [D-sidebar-footer-style].
      VStack(spacing: 0) {
        list
        Divider()
        footer
      }
      .clipShape(.rect(cornerRadius: 6))
      .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(.separator))
    }
    .fileImporter(isPresented: $isPicking, allowedContentTypes: [.folder]) { result in
      guard case .success(let url) = result else { return }
      chose(url, for: pickerPurpose)
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

  private var list: some View {
    List(selection: $selectedID) {
      ForEach(library.sources) { source in
        ImageSourceRow(scheduler: scheduler, source: source) {
          pick(for: .locate(source.id))
        }
        .tag(source.id)
      }
      // Dragging rows reorders the sources.
      .onMove { offsets, destination in
        library.moveSources(fromOffsets: offsets, toOffset: destination)
        scheduler.evaluate(reloadingLibrary: false)
      }
    }
    .listStyle(.plain)
    .alternatingRowBackgrounds(.disabled)
    .scrollContentBackground(.hidden)
    .frame(height: listHeight)
    .overlay {
      if library.sources.isEmpty {
        Text("No image folders. Add one with +, or drag folders here.")
          .foregroundStyle(.secondary)
      }
    }
    // Control-click and right-click, on any row, selected or not.
    .contextMenu(forSelectionType: String.self) { ids in
      if let id = ids.first, let source = library.source(withID: id) {
        // Folders only; a Photos album gets its own item or none (merge #2).
        if source.isInFileSystem {
          Button("Show in Finder") {
            if let url = library.folder(of: id) { NSWorkspace.shared.activateFileViewerSelecting([url]) }
          }
          .disabled(library.folder(of: id) == nil)
        }
        // Only for a lost source; a found one has nothing to locate.
        if library.unreachableSources.contains(id) {
          Button("Locate…") { pick(for: .locate(id)) }
        }
        Divider()
        Button("Remove") { requestRemoval(of: source) }
      }
    }
    // ⌫ removes the selected source, asking first as − does.
    .onDeleteCommand { removeSelected() }
    // Folders dragged in from Finder; anything else is ignored.
    .dropDestination(for: URL.self) { urls, _ in
      let folders = urls.filter { url in
        (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
      }
      for folder in folders { chose(folder, for: .add) }
      return !folders.isEmpty
    }
    .accessibilityIdentifier("imageSources")
  }

  /// [D-sidebar-footer-style] [D-footer-ax-labels]
  private var footer: some View {
    HStack(spacing: 0) {
      Button { pick(for: .add) } label: {
        ListFooter.cell("Add Folder", systemImage: "plus")
      }
      .accessibilityLabel("Add Folder")
      .accessibilityIdentifier("addImageSource")
      ListFooter.divider
      Button { removeSelected() } label: {
        ListFooter.cell("Remove Folder", systemImage: "minus")
      }
      .accessibilityLabel("Remove Folder")
      .accessibilityIdentifier("removeImageSource")
      .disabled(selectedID == nil)
      Spacer()
    }
    .buttonStyle(.borderless)
  }

  /// Room for every row, up to five before the list scrolls.
  private var listHeight: CGFloat {
    CGFloat(min(max(library.sources.count, 1), 5)) * 48 + 4
  }

  private var isConfirmingRemoval: Binding<Bool> {
    Binding { pendingRemoval != nil } set: { if !$0 { pendingRemoval = nil } }
  }

  private func pick(for purpose: FolderPickerPurpose) {
    pickerPurpose = purpose
    isPicking = true
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

  private func removeSelected() {
    guard let id = selectedID, let source = library.source(withID: id) else { return }
    requestRemoval(of: source)
  }

  /// Asks first when any phase uses the source's images.
  private func requestRemoval(of source: ImageSource) {
    if phasesUsing(source.id) > 0 {
      pendingRemoval = source
    } else {
      remove(source.id)
    }
  }

  /// Every way of removing (−, ⌫, the context menu, the confirmation)
  /// ends here, so each can be undone [D-undo-remove-source]. The window's
  /// undo manager, so Edit › Undo reaches it whatever has focus, unless a
  /// text field has its own undo.
  private func remove(_ id: String) {
    guard let removed = library.removeSource(id) else { return }
    if selectedID == id { selectedID = nil }
    scheduler.evaluate(reloadingLibrary: false)
    registerUndo(restoring: removed.source, at: removed.index)
  }

  private func registerUndo(restoring source: ImageSource, at index: Int) {
    guard let undoManager else { return }
    Self.registerRestore(source, at: index, library: library, scheduler: scheduler, undoManager: undoManager)
  }

  /// Undo puts the source back and registers its redo, which removes it
  /// and registers the undo again, so undo and redo alternate freely.
  private static func registerRestore(
    _ source: ImageSource, at index: Int, library: ImageLibrary, scheduler: WallpaperScheduler, undoManager: UndoManager
  ) {
    let name = "Remove “\(library.displayName(of: source))”"
    undoManager.registerUndo(withTarget: library) { library in
      library.restoreSource(source, at: index)
      scheduler.evaluate(reloadingLibrary: false)
      undoManager.registerUndo(withTarget: library) { library in
        guard let removed = library.removeSource(source.id) else { return }
        scheduler.evaluate(reloadingLibrary: false)
        registerRestore(removed.source, at: removed.index, library: library, scheduler: scheduler, undoManager: undoManager)
      }
      undoManager.setActionName(name)
    }
    undoManager.setActionName(name)
  }
}

/// Two lines: the folder's name with its Include subfolders switch, then
/// `~/Pictures/Desktop Pictures • 77 images` [D-image-sources].
private struct ImageSourceRow: View {
  var scheduler: WallpaperScheduler
  var source: ImageSource
  var locate: () -> Void

  private var library: ImageLibrary { scheduler.library }
  private var isUnreachable: Bool { library.unreachableSources.contains(source.id) }

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 8) {
      Image(systemName: "folder")
        .foregroundStyle(.secondary)
        .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 2) {
        HStack(alignment: .firstTextBaseline) {
          Text(library.displayName(of: source))
            .lineLimit(1)
            .truncationMode(.middle)
            .layoutPriority(1)
            // [D-ui-test-ids]
            .accessibilityIdentifier("imageFolderName")
          Spacer(minLength: 8)
          Toggle("Include subfolders", isOn: includesSubfolders)
            .controlSize(.small)
            .fixedSize()
            // The list is one Tab stop [D-image-sources]; the switch is
            // reached by clicking or the row's accessibility action.
            .focusable(false)
        }
        HStack(spacing: 4) {
          Text(source.location)
            .lineLimit(1)
            .truncationMode(.middle)
            .help(source.location)
          Text("•")
            .accessibilityHidden(true)
          if isUnreachable {
            Label("Can't open", systemImage: "exclamationmark.triangle")
              .foregroundStyle(.orange)
              .fixedSize()
            Button("Locate…", action: locate)
              .controlSize(.small)
              .fixedSize()
          } else {
            Text(imageCount)
              .monospacedDigit()
              // A long location would otherwise squeeze this to a sliver
              // (as it did Choose…, found 2026-10-29).
              .fixedSize()
              .accessibilityIdentifier("imageSourceCount")
          }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
      }
    }
    .padding(.vertical, 3)
    .accessibilityAction(named: source.includesSubfolders ? "Exclude Subfolders" : "Include Subfolders") {
      includesSubfolders.wrappedValue.toggle()
    }
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
