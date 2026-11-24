import CoreGraphics
import Foundation

/// Real mouse and key events, posted the way hardware posts them. Only
/// `PhasesApp`, after checking that the test instance is frontmost
/// [D-ui-test-runner], and the `phases-drive` command [D-input-driver]
/// call these.
public enum SyntheticInput {
  public enum Key: CGKeyCode {
    case tab = 48
    case downArrow = 125
    case rightArrow = 124
    case space = 49
    case x = 7
  }

  package static func click(at point: CGPoint) async throws {
    post(.mouseMoved, at: point)
    try await pause(0.05)
    post(.leftMouseDown, at: point)
    post(.leftMouseUp, at: point)
    try await pause(0.2)
  }

  package static func move(to point: CGPoint) async throws {
    post(.mouseMoved, at: point)
    try await pause(0.5)
  }

  /// Presses at `start`, moves to `end` in steps, and releases there.
  package static func drag(from start: CGPoint, to end: CGPoint, steps: Int = 30) async throws {
    post(.mouseMoved, at: start)
    try await pause(0.1)
    post(.leftMouseDown, at: start)
    try await pause(0.1)
    for step in 1...steps {
      let t = CGFloat(step) / CGFloat(steps)
      post(.leftMouseDragged, at: CGPoint(x: start.x + (end.x - start.x) * t, y: start.y + (end.y - start.y) * t))
      try await pause(0.015)
    }
    post(.leftMouseUp, at: end)
    try await pause(0.4)
  }

  /// Presses `key`, holding Shift around it when `shift` is set. Shift is
  /// pressed as a key of its own, down before `key` and up after it, as a
  /// keyboard sends it. Flags on `key`'s events alone left the system
  /// holding the modifier afterward, so later clicks came out as
  /// modifier-clicks (GitHub issue #39; seen with Control in MDPrinter's
  /// copy of this driver). Throws if Shift still reads held afterward.
  package static func press(_ key: Key, shift: Bool = false) async throws {
    let source = CGEventSource(stateID: .hidSystemState)
    let flags: CGEventFlags = shift ? .maskShift : []
    if shift { post(keyCode: shiftKeyCode, isDown: true, flags: .maskShift, source: source) }
    post(keyCode: key.rawValue, isDown: true, flags: flags, source: source)
    post(keyCode: key.rawValue, isDown: false, flags: flags, source: source)
    if shift { post(keyCode: shiftKeyCode, isDown: false, flags: [], source: source) }
    try await pause(0.15)
    if CGEventSource.flagsState(.hidSystemState).contains(.maskShift) {
      throw UITestFailure("Shift still reads held after pressing \(key) (GitHub issue #39); later clicks would be Shift-clicks")
    }
  }

  /// The left Shift key.
  private static let shiftKeyCode: CGKeyCode = 56

  private static func post(keyCode: CGKeyCode, isDown: Bool, flags: CGEventFlags, source: CGEventSource?) {
    let event = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: isDown)
    event?.flags = flags
    event?.post(tap: .cghidEventTap)
  }

  private static func post(_ type: CGEventType, at point: CGPoint) {
    CGEvent(mouseEventSource: nil, mouseType: type, mouseCursorPosition: point, mouseButton: .left)?
      .post(tap: .cghidEventTap)
  }

  private static func pause(_ seconds: Double) async throws {
    try await Task.sleep(for: .seconds(seconds))
  }
}
