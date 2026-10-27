import Foundation

/// A display Phases has seen, remembered by hardware UUID with its last name.
struct KnownDisplay: Codable, Hashable, Identifiable {
  var uuid: String
  var name: String

  var id: String { uuid }
}
