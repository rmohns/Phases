import SwiftUI

/// [D-window-pause-banner] Pinned to the top of the detail pane while
/// paused: what's wrong on the left, the fix on the right.
struct PauseBanner: View {
  var scheduler: WallpaperScheduler

  var body: some View {
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
              .fixedSize(horizontal: false, vertical: true)
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
  }
}
