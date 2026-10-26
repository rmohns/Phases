import Foundation

enum TransitionStyle: String, CaseIterable, Identifiable {
  case none, crossfade

  var id: Self { self }

  var title: String {
    switch self {
    case .none: "None"
    case .crossfade: "Crossfade"
    }
  }

  static let durationRange: ClosedRange<Double> = 0.5...3
  static let defaultDuration = 1.0
}
