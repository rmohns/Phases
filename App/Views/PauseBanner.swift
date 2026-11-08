import SwiftUI

private let diagLog = Diagnostics.logger("window")

/// [D-window-pause-banner] Above the detail pane while paused: what's wrong
/// on the left, the fix on the right. Always in the window and reads
/// `isPaused` in its own body, so it follows the pause whatever else
/// redraws [Q-safe-area-inset-refresh].
struct PauseBanner: View {
  var scheduler: WallpaperScheduler

  var body: some View {
    if scheduler.isPaused {
      VStack(spacing: 0) {
        HStack(spacing: 10) {
          HStack(spacing: 10) {
            Image(systemName: "pause.fill")
              .font(.title3)
              .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
              Text("Phases is paused")
                .font(.headline)
              Text(PauseReason.text(pausedForOutsideChangeAt: scheduler.pausedForOutsideChangeAt))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                // [Q-fixed-size-text-rigid-split] No `.fixedSize` here: with
                // it, a wrapped reason made the split view taller than the
                // window, shifted up.
            }
          }
          // One element for VoiceOver, then the button.
          .accessibilityElement(children: .combine)
          Spacer(minLength: 8)
          // [D-menu-pause-verb] The menu's wording.
          Button("Resume Schedule") { scheduler.isPaused = false }
            // [D-ui-test-ids]
            .accessibilityIdentifier("pauseBannerResume")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        Divider()
      }
      .background(.bar)
      .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).minY } action: { top in
        diagLog.log("pause banner top at \(top, privacy: .public) pt in the window")
      }
      .onDisappear { diagLog.log("pause banner gone") }
    }
  }
}
