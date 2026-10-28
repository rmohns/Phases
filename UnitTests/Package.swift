// swift-tools-version: 6.0
import PackageDescription

// Unit tests for Phases' pure logic (SPEC.md "Testing"). Run with `swift test`
// from this folder. [D-tests-unhosted] Sources/PhasesLogic holds symlinks to
// the app's own files, so the tests never launch Phases.
let package = Package(
  name: "PhasesLogic",
  platforms: [.macOS("26.0")],
  targets: [
    .target(name: "PhasesLogic"),
    .testTarget(name: "PhasesLogicTests", dependencies: ["PhasesLogic"]),
  ],
  swiftLanguageModes: [.v5]
)
