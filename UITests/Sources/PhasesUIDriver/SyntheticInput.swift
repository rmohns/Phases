import CoreGraphics
import Foundation

/// Real mouse and key events, posted the way hardware posts them. Only
/// `PhasesApp` calls these, after checking that the test instance is
/// frontmost [D-ui-test-runner].
public enum SyntheticInput {
  public enum Key: CGKeyCode {
    case tab = 48
    case downArrow = 125
    case x = 7
  }

  static func click(at point: CGPoint) async throws {
    post(.mouseMoved, at: point)
    try await pause(0.05)
    post(.leftMouseDown, at: point)
    post(.leftMouseUp, at: point)
    try await pause(0.2)
  }

  /// Presses at `start`, moves to `end` in steps, and releases there.
  static func drag(from start: CGPoint, to end: CGPoint, steps: Int = 30) async throws {
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

  static func press(_ key: Key, shift: Bool = false) async throws {
    let source = CGEventSource(stateID: .hidSystemState)
    for isDown in [true, false] {
      let event = CGEvent(keyboardEventSource: source, virtualKey: key.rawValue, keyDown: isDown)
      if shift { event?.flags = .maskShift }
      event?.post(tap: .cghidEventTap)
    }
    try await pause(0.15)
  }

  private static func post(_ type: CGEventType, at point: CGPoint) {
    CGEvent(mouseEventSource: nil, mouseType: type, mouseCursorPosition: point, mouseButton: .left)?
      .post(tap: .cghidEventTap)
  }

  private static func pause(_ seconds: Double) async throws {
    try await Task.sleep(for: .seconds(seconds))
  }
}
