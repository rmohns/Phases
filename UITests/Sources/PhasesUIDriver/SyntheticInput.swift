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

  /// A modifier key, pressed as a key of its own [D-input-modifier-keys].
  /// Declared in the order they go down (and the reverse of how they come up).
  public enum Modifier: CaseIterable, CustomStringConvertible, Sendable {
    case control, option, shift, command

    /// The left-hand key.
    var keyCode: CGKeyCode {
      switch self {
      case .control: 59
      case .option: 58
      case .shift: 56
      case .command: 55
      }
    }

    var flag: CGEventFlags {
      switch self {
      case .control: .maskControl
      case .option: .maskAlternate
      case .shift: .maskShift
      case .command: .maskCommand
      }
    }

    public var description: String {
      switch self {
      case .control: "Control"
      case .option: "Option"
      case .shift: "Shift"
      case .command: "Command"
      }
    }
  }

  /// The modifiers the system reads as held right now.
  package static func heldModifiers() -> [Modifier] {
    let flags = CGEventSource.flagsState(.hidSystemState)
    return Modifier.allCases.filter { flags.contains($0.flag) }
  }

  /// Presses `key` with `modifiers` held. Each modifier is pressed as a key
  /// of its own, down before `key` and up after it, as a keyboard sends it.
  /// Flags on `key`'s events alone left the system holding the modifier
  /// afterward, so later clicks came out as modifier-clicks (GitHub issue
  /// #39; seen with Control in MDPrinter's copy of this driver). Throws if
  /// any modifier still reads held afterward [D-input-modifier-keys].
  package static func press(_ key: Key, modifiers: Set<Modifier> = []) async throws {
    let source = CGEventSource(stateID: .hidSystemState)
    let ordered = Modifier.allCases.filter(modifiers.contains)
    var held: CGEventFlags = []
    for modifier in ordered {
      held.insert(modifier.flag)
      post(keyCode: modifier.keyCode, isDown: true, flags: held, source: source)
    }
    post(keyCode: key.rawValue, isDown: true, flags: held, source: source)
    post(keyCode: key.rawValue, isDown: false, flags: held, source: source)
    for modifier in ordered.reversed() {
      held.remove(modifier.flag)
      post(keyCode: modifier.keyCode, isDown: false, flags: held, source: source)
    }
    try await pause(0.15)
    let stuck = heldModifiers()
    if !stuck.isEmpty {
      throw UITestFailure(
        "\(stuck.map(\.description).joined(separator: ", ")) still reads held after pressing \(key) (GitHub issue #39); later clicks would carry it")
    }
  }

  private static func post(keyCode: CGKeyCode, isDown: Bool, flags: CGEventFlags, source: CGEventSource?) {
    let event = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: isDown)
    event?.flags = flags
    event?.post(tap: .cghidEventTap)
  }

  /// Mouse down, up and drag carry click state 1, a single click
  /// [D-input-click-state]. Left alone, mouse up is created with 0. A
  /// precaution: Phases' clicks worked without it
  /// [L-click-state-not-needed]. Taken from MDPrinter's copy of this
  /// driver (`e40eef1`), whose claim that AppKit read `clickCount` 0 is
  /// unsupported.
  private static func post(_ type: CGEventType, at point: CGPoint) {
    let event = CGEvent(mouseEventSource: nil, mouseType: type, mouseCursorPosition: point, mouseButton: .left)
    if [.leftMouseDown, .leftMouseUp, .leftMouseDragged].contains(type) {
      event?.setIntegerValueField(.mouseEventClickState, value: 1)
    }
    event?.post(tap: .cghidEventTap)
  }

  private static func pause(_ seconds: Double) async throws {
    try await Task.sleep(for: .seconds(seconds))
  }
}
