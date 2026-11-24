import Darwin
import Foundation

/// Memory figures for Settings: the Mac's size for the low-memory note
/// [D-low-memory-note] and Phases' own use for the About section
/// [D-memory-in-about]. Not unit-tested: both read the live system.
enum MemoryUse {
  /// The Mac's physical memory in bytes. In test mode, a faked size when
  /// `-PhasesUITestMemoryGB` is given [D-test-memory-size].
  static var physicalMemory: UInt64 {
    UITestMode.fakedMemoryBytes ?? ProcessInfo.processInfo.physicalMemory
  }

  /// Phases' physical footprint in bytes, the figure Activity Monitor shows
  /// in its Memory column [D-memory-in-about]; nil if it can't be read.
  static func footprint() -> UInt64? {
    var info = task_vm_info_data_t()
    var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
    let result = withUnsafeMutablePointer(to: &info) { pointer in
      pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { rebound in
        task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), rebound, &count)
      }
    }
    guard result == KERN_SUCCESS else { return nil }
    return info.phys_footprint
  }
}
