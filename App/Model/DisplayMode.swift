import Foundation

enum DisplayMode: String, Codable, CaseIterable, Identifiable {
  case sameOnAll, differentPerDisplay

  var id: Self { self }

  var title: String {
    switch self {
    case .sameOnAll: "Same image everywhere"
    case .differentPerDisplay: "Different picks per display"
    }
  }
}
