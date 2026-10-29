import ApplicationServices
import CoreGraphics

/// One element in another app's accessibility tree, read through the AX API
/// `[Q-system-events-ax]`.
public struct AXNode {
  public let element: AXUIElement

  public init(_ element: AXUIElement) {
    self.element = element
  }

  public static func application(pid: pid_t) -> AXNode {
    AXNode(AXUIElementCreateApplication(pid))
  }

  public func attribute(_ name: String) -> CFTypeRef? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
    return value
  }

  public func string(_ name: String) -> String? {
    attribute(name) as? String
  }

  public func bool(_ name: String) -> Bool? {
    (attribute(name) as? NSNumber)?.boolValue
  }

  public func node(_ name: String) -> AXNode? {
    guard let value = attribute(name), CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
    return AXNode(value as! AXUIElement)
  }

  public func nodes(_ name: String) -> [AXNode] {
    (attribute(name) as? [AXUIElement])?.map(AXNode.init) ?? []
  }

  public var role: String? { string(kAXRoleAttribute) }
  public var identifier: String? { string(kAXIdentifierAttribute) }
  public var title: String? { string(kAXTitleAttribute) }
  public var value: String? { string(kAXValueAttribute) }
  public var label: String? { string(kAXDescriptionAttribute) }
  public var isEnabled: Bool { bool(kAXEnabledAttribute) ?? false }
  public var isSelected: Bool { bool(kAXSelectedAttribute) ?? false }
  public var children: [AXNode] { nodes(kAXChildrenAttribute) }
  public var parent: AXNode? { node(kAXParentAttribute) }

  /// Screen frame, top-left origin: the same coordinates mouse events use.
  public var frame: CGRect? {
    var position = CGPoint.zero, size = CGSize.zero
    guard let p = axValue(kAXPositionAttribute), AXValueGetValue(p, .cgPoint, &position),
      let s = axValue(kAXSizeAttribute), AXValueGetValue(s, .cgSize, &size)
    else { return nil }
    return CGRect(origin: position, size: size)
  }

  private func axValue(_ name: String) -> AXValue? {
    guard let value = attribute(name), CFGetTypeID(value) == AXValueGetTypeID() else { return nil }
    return (value as! AXValue)
  }

  @discardableResult
  public func perform(_ action: String) -> AXError {
    AXUIElementPerformAction(element, action as CFString)
  }

  /// Every string this element and its descendants show or speak.
  public var allText: String {
    ([self] + descendants()).flatMap { [$0.title, $0.value, $0.label].compactMap { $0 } }.joined(separator: " ")
  }

  /// Breadth-first, depth-limited, so a huge tree can't hang a test.
  public func descendants(maxDepth: Int = 30) -> [AXNode] {
    var result: [AXNode] = []
    var level = children
    var depth = 0
    while !level.isEmpty, depth < maxDepth {
      result += level
      level = level.flatMap(\.children)
      depth += 1
    }
    return result
  }

  public func first(where predicate: (AXNode) -> Bool) -> AXNode? {
    descendants().first(where: predicate)
  }

  public func first(identifier: String) -> AXNode? {
    first { $0.identifier == identifier }
  }

  /// Whether this element is `other` or lies inside it.
  public func isInside(_ other: AXNode) -> Bool {
    var current: AXNode? = self
    var steps = 0
    while let node = current, steps < 60 {
      if node == other { return true }
      current = node.parent
      steps += 1
    }
    return false
  }

  /// One-line summary for failure messages.
  public var summary: String {
    "\(role ?? "?") id=\(identifier ?? "-") title=\(title ?? "-") label=\(label ?? "-") frame=\(frame.map { "\($0)" } ?? "-")"
  }
}

extension AXNode: Equatable {
  public static func == (lhs: AXNode, rhs: AXNode) -> Bool {
    CFEqual(lhs.element, rhs.element)
  }
}
