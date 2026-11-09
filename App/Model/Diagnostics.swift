import Foundation
import os

/// [D-diagnostics-switch] Built-in diagnostic logging, off by default and
/// switched at launch (see TESTING.md "Diagnostics" for the commands).
enum Diagnostics {
  /// Read once at launch; changing it takes a relaunch.
  static let isEnabled = UserDefaults.standard.bool(forKey: "PhasesDiagnostics")

  /// A logger for `category` under the `PhasesDiag` subsystem, or a disabled
  /// one whose calls do nothing when diagnostics are off.
  static func logger(_ category: String) -> Logger {
    isEnabled ? Logger(subsystem: "PhasesDiag", category: category) : Logger(.disabled)
  }

  /// A short, stable-for-this-run label for an object, for telling
  /// instances apart in the log.
  static func id(_ object: AnyObject?) -> String {
    object.map { String(UInt(bitPattern: ObjectIdentifier($0).hashValue) % 100_000) } ?? "nil"
  }
}
