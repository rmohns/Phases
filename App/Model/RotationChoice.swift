import Foundation

/// [D-rotation-row] The Change images row's menu: a unit, which turns
/// rotation on, or "Only when the phase starts", which turns it off.
enum RotationChoice: Hashable, Identifiable {
  case every(TimeUnit)
  case onlyAtStart

  var id: Self { self }

  static let allCases: [RotationChoice] = [.every(.minutes), .every(.hours), .onlyAtStart]

  var title: String {
    switch self {
    case .every(let unit): unit.title
    case .onlyAtStart: "Only when the phase starts"
    }
  }
}

extension Phase {
  /// The rotation interval's limits.
  static let rotationRange = 1...999

  /// Turning rotation back on keeps the interval it had.
  var rotationChoice: RotationChoice {
    get { isRotating ? .every(rotation.unit) : .onlyAtStart }
    set {
      switch newValue {
      case .every(let unit):
        isRotating = true
        rotation.unit = unit
      case .onlyAtStart:
        isRotating = false
      }
    }
  }
}
