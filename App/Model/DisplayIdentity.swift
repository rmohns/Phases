import AppKit
import ColorSync

/// [D-display-uuid] Stable identifiers for displays. The hardware UUID survives unplugging,
/// reconnecting, and rearranging; the numeric display ID does not.
enum DisplayIdentity {
  static func uuid(for displayID: CGDirectDisplayID) -> String? {
    guard let uuid = CGDisplayCreateUUIDFromDisplayID(displayID)?.takeRetainedValue() else { return nil }
    return CFUUIDCreateString(nil, uuid) as String?
  }
}

extension NSScreen {
  var displayID: CGDirectDisplayID? {
    (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
  }

  var displayUUID: String? {
    displayID.flatMap(DisplayIdentity.uuid(for:))
  }
}
