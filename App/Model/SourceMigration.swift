import Foundation

/// [D-source-names] Converts saved names from draft 44 and earlier (bare
/// paths relative to the one library folder) to names with a source part.
/// Names that already have one are left alone, so running it twice changes
/// nothing. No AppKit, so the unit tests can reach it.
enum SourceMigration {
  static func convert(_ name: String, to sourceID: String) -> String {
    StoredImageName.split(name) == nil ? StoredImageName.join(source: sourceID, path: name) : name
  }

  /// Every saved selection: All Displays and per display.
  static func convert(_ phases: [Phase], to sourceID: String) -> [Phase] {
    phases.map { phase in
      var phase = phase
      phase.imageNames = phase.imageNames.map { convert($0, to: sourceID) }
      phase.displayImageNames = phase.displayImageNames.mapValues { names in
        names.map { convert($0, to: sourceID) }
      }
      return phase
    }
  }

  /// The last image applied to each display.
  static func convert(_ state: AppliedState?, to sourceID: String) -> AppliedState? {
    guard var state else { return nil }
    state.imagesByDisplay = state.imagesByDisplay.mapValues { convert($0, to: sourceID) }
    return state
  }
}
