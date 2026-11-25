import SwiftUI

/// [D-image-header] Pinned over the grid while it scrolls: the display tabs
/// (when shown), the checkbox line, missing images, and the count line.
struct ImageHeader: View {
  var library: ImageLibrary
  @Binding var phase: Phase
  var connected: [ConnectedDisplay]
  /// The chosen display, or nil for Shared.
  @Binding var display: String?

  var body: some View {
    let tabs = DisplayTabs.tabs(connected: connected, phase: phase)
    VStack(alignment: .leading, spacing: 10) {
      if let tabs {
        DisplayTabsRow(
          displays: tabs,
          sharedCount: library.availableCount(of: phase.imageNames),
          ownCounts: phase.displayImageNames.mapValues(library.availableCount(of:)),
          selection: $display
        )
        checkboxLine
      }

      if let selection = selectionBinding {
        let missing = selection.wrappedValue.filter { !library.contains($0) }
        if !missing.isEmpty {
          HStack {
            Label(
              missing.count == 1 ? "1 selected image is missing" : "\(missing.count) selected images are missing",
              systemImage: "exclamationmark.triangle"
            )
            .foregroundStyle(.orange)
            Spacer()
            Button("Remove Missing") { selection.wrappedValue.removeAll { missing.contains($0) } }
              .accessibilityIdentifier("removeMissing")
          }
        }
        if !library.names.isEmpty {
          HStack {
            Text("\(library.availableCount(of: selection.wrappedValue)) of \(library.names.count) selected")
              .foregroundStyle(.secondary)
            Spacer()
            Button("Select All") { selection.wrappedValue = library.names }
            Button("Select None") { selection.wrappedValue = [] }
          }
        }
      }
    }
    .padding(10)
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityElement(children: .contain)
    // [D-ui-test-ids]
    .accessibilityIdentifier("imageHeader")
  }

  /// The selection being edited: Shared, or the chosen display's own
  /// images. Nil on a display that uses Shared, where there's no grid.
  var selectionBinding: Binding<[String]>? {
    guard let display else { return $phase.imageNames }
    guard phase.hasOwnImages(display) else { return nil }
    return Binding {
      phase.displayImageNames[display] ?? []
    } set: { names in
      phase.displayImageNames[display] = names
    }
  }

  @ViewBuilder
  private var checkboxLine: some View {
    if let display {
      Toggle("Use different images on this display", isOn: Binding {
        phase.hasOwnImages(display)
      } set: { isOn in
        phase.setOwnImages(isOn, for: display)
      })
      .accessibilityIdentifier("ownImagesCheckbox")
    } else {
      // [D-sharing-per-phase]
      Toggle("Each display shows a different image", isOn: Binding {
        phase.displayMode == .differentPerDisplay
      } set: { isOn in
        phase.displayMode = isOn ? .differentPerDisplay : .sameOnAll
      })
      .disabled(!DisplayTabs.sharingApplies(connected: connected, phase: phase))
      .accessibilityIdentifier("sharingCheckbox")
    }
  }
}
