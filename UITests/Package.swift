// swift-tools-version: 6.0
import PackageDescription

// UI tests for Phases (TESTING.md "Layer 2: UI tests"). [D-ui-test-runner] They
// launch the built app in test mode and drive it through the Accessibility
// API with real mouse and key events. Ask the author before running:
// `swift test` from this folder (add PHASES_UI_SLOW=1 for the slow suite).
let package = Package(
  name: "PhasesUITests",
  platforms: [.macOS("26.0")],
  targets: [
    .target(name: "PhasesUIDriver"),
    .testTarget(name: "PhasesUITests", dependencies: ["PhasesUIDriver"]),
  ],
  swiftLanguageModes: [.v5]
)
