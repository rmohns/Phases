import Foundation

/// A UI test step that couldn't go on, with what the harness saw.
public struct UITestFailure: Error, CustomStringConvertible {
  public var description: String

  public init(_ description: String) {
    self.description = description
  }
}

/// Polls until `condition` returns a value, or fails after `timeout`.
@MainActor
public func waitFor<T>(
  _ what: String, timeout: Duration = .seconds(5), _ condition: () -> T?
) async throws -> T {
  let clock = ContinuousClock()
  let deadline = clock.now + timeout
  while true {
    if let value = condition() { return value }
    guard clock.now < deadline else { throw UITestFailure("Timed out waiting for \(what)") }
    try await Task.sleep(for: .milliseconds(100))
  }
}

/// Waits for a Bool condition to become true.
@MainActor
public func waitUntil(_ what: String, timeout: Duration = .seconds(5), _ condition: () -> Bool) async throws {
  _ = try await waitFor(what, timeout: timeout) { condition() ? true : nil }
}
