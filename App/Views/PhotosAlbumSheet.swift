import SwiftUI

/// Add Photos Album… [D-photos-sources]: the library as Photos' sidebar
/// shows it (folders of albums, nested, in sidebar order), then shared
/// albums in their own section. Asks for access the first time
/// [D-photos-permission].
struct PhotosAlbumSheet: View {
  var library: ImageLibrary
  /// Called with the chosen album or folder.
  var choose: (PhotosCollection) -> Void
  @Environment(\.dismiss) private var dismiss
  @State private var collections: [PhotosCollection] = []
  @State private var selectedID: String?
  @State private var isLoading = true

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Add Photos Album")
        .font(.headline)
      content
        .frame(minWidth: 380, minHeight: 320)
      HStack {
        Spacer()
        Button("Cancel", role: .cancel) { dismiss() }
          .keyboardShortcut(.cancelAction)
        Button("Add") { add() }
          .keyboardShortcut(.defaultAction)
          .disabled(selected == nil)
      }
    }
    .padding(20)
    .task { await load() }
  }

  @ViewBuilder
  private var content: some View {
    if isLoading {
      ProgressView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    } else if library.photosAccess != .allowed {
      // [D-photos-permission]
      ContentUnavailableView {
        Label("Phases doesn't have access to Photos", systemImage: "photo.on.rectangle.angled")
      } description: {
        Text("Allow Phases in System Settings › Privacy & Security › Photos to use albums as wallpaper.")
      } actions: {
        Button("Open Privacy & Security Settings…") {
          if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Photos") {
            NSWorkspace.shared.open(url)
          }
        }
      }
    } else if collections.isEmpty {
      ContentUnavailableView("No Albums", systemImage: "photo.on.rectangle", description: Text("Make an album in Photos first."))
    } else {
      List(selection: $selectedID) {
        let user = collections.filter { $0.kind != .sharedAlbum }
        let shared = collections.filter { $0.kind == .sharedAlbum }
        if !user.isEmpty {
          Section("Albums") {
            OutlineGroup(user, children: \.outlineChildren) { row($0) }
          }
        }
        if !shared.isEmpty {
          Section("Shared Albums") {
            ForEach(shared) { row($0) }
          }
        }
      }
      .contextMenu(forSelectionType: String.self) { _ in
      } primaryAction: { ids in
        // Double-click adds.
        if ids.first.flatMap(find) != nil { add() }
      }
      .accessibilityIdentifier("photosAlbumList")
    }
  }

  private func row(_ collection: PhotosCollection) -> some View {
    let isEmptyAlbum = collection.kind != .folder && (collection.photoCount ?? 0) == 0
    return HStack {
      Label(collection.title, systemImage: icon(for: collection))
      Spacer()
      if let count = collection.photoCount {
        Text(count.formatted())
          .monospacedDigit()
          .foregroundStyle(.secondary)
      }
    }
    // Albums with no photos are listed but can't be chosen.
    .foregroundStyle(isEmptyAlbum ? .tertiary : .primary)
    .selectionDisabled(isEmptyAlbum)
    .tag(collection.id)
    .accessibilityLabel(accessibilityLabel(for: collection))
  }

  private func icon(for collection: PhotosCollection) -> String {
    switch collection.kind {
    case .album: "rectangle.stack"
    case .folder: "folder"
    case .sharedAlbum: "person.2"
    }
  }

  private func accessibilityLabel(for collection: PhotosCollection) -> String {
    switch collection.kind {
    case .folder: "\(collection.title), folder"
    case .album, .sharedAlbum: "\(collection.title), \(collection.photoCount ?? 0) photos"
    }
  }

  private var selected: PhotosCollection? {
    selectedID.flatMap(find)
  }

  private func find(_ id: String) -> PhotosCollection? {
    collections.lazy.compactMap { $0.find(id) }.first
  }

  private func load() async {
    if library.photos?.access == .notDetermined {
      _ = await library.requestPhotosAccess()
    } else {
      // Access may have changed in System Settings since the last reload.
      library.reload()
    }
    collections = library.photos?.collections() ?? []
    isLoading = false
  }

  private func add() {
    guard let selected else { return }
    let isEmptyAlbum = selected.kind != .folder && (selected.photoCount ?? 0) == 0
    guard !isEmptyAlbum else { return }
    choose(selected)
    dismiss()
  }
}
