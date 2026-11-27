# `[X-33-sandbox]` Photos library from a sandboxed Phases (round B)

Part of "Photos library (issue #33)" in [EXPERIMENTS.md](../EXPERIMENTS.md), the index of
experiments. Moved here word for word from EXPERIMENTS.md on
2026-11-27, when each record got its own file.


- **Question:** not recorded as one question. The same probe as round A,
  built with `com.apple.security.app-sandbox` only.
- **When, on what:** 2026-11-12, macOS 27.2; builds cdhash `586935f0`, and
  `615f31ef` for the wallpaper check. Run by Claude with the author's yes.
- **Branch:** not recorded (the same probe as `experiment/33-photokit`;
  the text names no branch for round B).
  - *Added 2026-11-14 by Claude:* round B ran on `experiment/33-photokit`
    too: its commits `c2cc13b` and `979f220` are there (*verified*,
    `git log`, 2026-11-14). Tag `archive/experiment/33-photokit`.
- **Outcome:** not recorded.
  - *Added 2026-11-14 by Claude:* sandboxing became its own change,
    issue #19 (author, 2026-11-12); these findings are summarized there.
  - *Added 2026-11-22 by Claude:* draft 58 (branch `feature/19-sandbox`)
    builds on these findings. Promoted: `[L-sandbox-x0-paths]` →
    `[Q-sandbox-container-home]`; `[L-sandbox-team-needed]` →
    `[Q-sandbox-store-exception]`; `[L-sandbox-x4-container-wallpaper]` →
    `[Q-sandbox-set-unreadable-file]`; `[L-sandbox-prefs-move]` → SPEC.md
    `[D-sandbox-settings-move]`. The rest stay in LEARNINGS.md.
- **Findings:** `[L-sandbox-team-needed]`, `[L-sandbox-x0-paths]`,
  `[L-sandbox-prefs-move]`, `[L-sandbox-x1-no-entitlement]`,
  `[L-photos-new-build-asks]`, `[L-sandbox-photos-works]`,
  `[L-photos-ids-stable]`, `[L-sandbox-x4-container-wallpaper]`.

## Round B: sandboxed (2026-11-12, macOS 27.2)

Same probe, built with `com.apple.security.app-sandbox` only (build
cdhash `586935f0`). Run by Claude with the author's yes.

- `[L-sandbox-team-needed]` **Bitrig won't build the Photos or the
  wallpaper-store entitlement without a development team.** With either
  `com.apple.security.personal-information.photos-library` or the
  `temporary-exception.files.home-relative-path.read-only` exception,
  the build failed: "This Mac app uses capabilities that require
  development signing. No development team is available." The sandbox
  entitlement alone builds. *Verified* (three builds, one entitlement
  set each).
- `[L-sandbox-x0-paths]` **In the sandbox, `homeDirectoryForCurrentUser`
  and `NSHomeDirectory()` both point into the container**
  (`~/Library/Containers/<bundle ID>/Data`); `getpwuid` still gives
  `/Users/rmohns`. Caches is in the container. The wallpaper store
  can't be read either way: "no such file" through the container home,
  "you don't have permission" through the real home. *Verified.* So
  `WallpaperStoreWatcher` and `SystemWallpaperInspector` would silently
  see nothing in a sandboxed build without the exception.
- `[L-sandbox-prefs-move]` **The first sandboxed launch moved Phases'
  preferences into the container.** `~/Library/Preferences/<bundle
  ID>.plist` was gone afterward, and identical copies of it (and of the
  `.uitest` store) were in the container's `Library/Preferences`.
  *Verified* (compared against a backup taken just before).
  - Once the container exists, `defaults import` from Terminal wrote
    into the container, not `~/Library/Preferences`. *Verified* by the
    file's time. The TESTING.md `defaults write … PhasesDiagnostics`
    command would do the same (*inferred*, not tried).
  - Claude put the backup back at `~/Library/Preferences` by copying
    the file. Whether the unsandboxed installed Phases reads it
    correctly is untested until the author relaunches it.
- `[L-sandbox-x1-no-entitlement]` **Without the Photos entitlement, the
  sandboxed build still got a Photos prompt.** The TCC log at 11:43:55
  says "showing the prompt" for Phases. Nobody answered it (the author
  was away), so `requestAuthorization` waited over 5 minutes until
  Claude stopped the probe. *Verified* (TCC log). Whether access works
  without the entitlement once allowed is still open.
  - (Corrected 2026-11-12 by Claude: the first version said the TCC log
    showed no Photos request from Phases. That search filtered on
    "Photos" in the message and missed the lines naming Phases.)
- `[L-photos-new-build-asks]` **A new build asks for Photos again.** The
  same TCC request logged "Failed to match existing code requirement …
  kTCCServicePhotos" with the round A build's cdhash (`9808ae12…`) and
  this build's (`586935f0…`). So the round A grant didn't carry over to a
  build with a different signature. *Verified* (TCC log), for one rebuild
  that also added the sandbox. Whether a plain rebuild with no
  entitlement change does the same is untested.
- `[L-sandbox-photos-works]` **The sandbox-only build reads Photos.**
  With no Photos entitlement, a rerun of X1 (build `586935f0`, author at
  the Mac) found access already "authorized" before asking, and showed
  no prompt (author). X6 then read the album and its IDs. *Verified*
  for this ad-hoc-signed Debug build. How the 11:43 prompt came to be
  allowed is not known: the TCC log shows it prompting, and the author
  was away. Whether a Release or notarized build behaves the same is
  untested.
- `[L-photos-ids-stable]` **Photo IDs held across builds and the
  sandbox.** All 10 local IDs and cloud IDs from round A (unsandboxed,
  `9808ae12`) matched the sandboxed build's (`586935f0`). *Verified.*
- `[L-sandbox-x4-container-wallpaper]` **A sandboxed Phases can set a file
  in its container as the wallpaper, and put back one outside it.**
  Build `615f31ef` (probe store check skipped by
  `-PhasesProbeSkipStoreCheck`, after Claude confirmed from Terminal
  that the main display showed `~/Pictures/Desktop Pictures/Peter Lik -
  Bamboo Forest Path.jpg`) set a JPEG under
  `~/Library/Containers/<bundle ID>/Data/Library/Caches/` with no error,
  `desktopImageURL` read it back, and putting back the `~/Pictures`
  original raised no error. *Verified* by the API, and on screen by the
  author: the concert photo showed, then the Bamboo Forest came back.
  The store couldn't be read
  afterward, as in `[L-sandbox-x0-paths]`.
