# `[X-ui-tests-sandboxed]` First fast-suite run since the sandbox

Part of "UI tests on the sandboxed build" in [EXPERIMENTS.md](../EXPERIMENTS.md), the index of
experiments. Moved here word for word from EXPERIMENTS.md on
2026-11-27, when each record got its own file.


- **Question:** does the UI test harness still work now that Phases is
  sandboxed (draft 59 on), and does the #47 build pick choose the right
  build?
- **When and on what:** 2026-11-24, 15:2x local, by Claude with the
  author's yes. `main` at `bbd8735`, Debug build
  `1795551375230-57492B11` (build 61, made 15:16:15). No branch; nothing
  changed.
- **Outcome:** the build pick works; the image-folder tests fail under
  the sandbox. Digest: LEARNINGS.md `[L-ui-tests-sandboxed]`. Not fixed.
  *Update 2026-11-24:* promoted to TEST-TOOLS.md
  `[Q-container-closed-to-tests]`; fixed by SPEC.md
  `[D-debug-test-folder]` (draft 62). The divider failure is
  `[L-divider-drag-right]`, still open.
- **Run 1:** `swift test --filter toolbarIs52PointsTall` in `UITests/`:
  passed (7.8 s). The harness printed the newest build, number 61
  (*verified*).
- **Run 2:** the fast suite, `swift test` in `UITests/` (280 s): 32 tests
  in 11 suites, **20 passed, 12 failed**. All 31 launches used the same,
  newest build (*verified*, the harness's printout).
  - Failed on missing image content: `imageFolderNameScreenshot` (no
    `imageSourceCount`), `gridIsOneTabStopAndArrowsScroll` and
    `arrowKeysCrossSources` (no `imageGrid`), `eachSourceHasAHeadingInOrder`,
    `selectAllSelectsBothSources`, `settingsRowsCountPerSourceAndTogglePerRow`
    (timed out), and all five `PhotosSourcesTests` (timed out waiting for
    the album list).
  - Failed otherwise: `dividerStaysWithin240To320`. Dragged far right,
    the sidebar stayed 239.5 pt (expected 320); the far-left drags
    measured as expected. *Observed* once; no rerun.
  - Passed: everything that needs no image content (toolbar, branding,
    rename-on-type, remove button, undo, tab, low-memory note, pause
    banner, phase list, Photos denied, relaunch, divider far left).
- **Evidence for the cause:** the run's screenshot of the image source
  row (`UITests/Screenshots/2026-11-24T202423 image folder name.png`)
  shows the test folder under `/var/folders/…` with "Can't open" and
  Locate…, not its image count (*verified*). The harness passes that
  folder by `-PhasesUITestImages` with no bookmark, and the sandbox only
  lets Phases read folders the user picked or its own container
  (*recalled* sandbox rules; the entitlements grant
  `files.user-selected.read-only` and one home-relative exception). The
  system log kept no sandbox denials for Phases over the run (`log show`
  for "sandbox" and "Phases"; denials can go unlogged, *recalled*), so
  the sandbox cause is *inferred* from the screenshot, not shown by a
  denial. The fake Photos library (`-PhasesUITestPhotos`) is presumably
  blocked the same way (*hypothesis*).
- **Predicted:** the sandbox handoff
  (`docs/handoffs/2026-11-23-sandbox.md`, follow-ups) flagged that the
  harness's temporary folders without bookmarks might behave differently
  sandboxed.
- **Possible fix (not tried):** make the test folders inside Phases' own
  container (`~/Library/Containers/com.robertmohns.phases/Data/…`), which
  the sandboxed app can read and the unsandboxed runner can write. No
  app or entitlement change. It's a TESTING.md decision, so it needs the
  author's approval.
- **Container probe, 2026-11-24 (Claude, author's request): the fix
  above won't work as things stand.** From the shell the UI tests run
  in (spawned by Bitrig's `claude`, so Bitrig is the responsible app),
  every access to `~/Library/Containers/com.robertmohns.phases/Data`
  failed with "Operation not permitted": listing `Data`, `Data/tmp`,
  `Data/Library/Caches`, and `Data/Library/Application Support`, and
  making a folder in each (*verified*). Listing the container's top level
  and reading its metadata xattr worked. A control write, read and
  delete in `~/Library/Caches` worked (*verified*), so the shell can write
  in `~/Library` generally. No prompt appeared, and neither the TCC nor
  the sandbox log recorded anything. The TCC database couldn't be opened
  either (needs Full Disk Access), so Bitrig doesn't have it.
  - *Explanation (recalled, not tested here):* since macOS 14, a process
    outside an app's sandbox can't touch that app's Data container unless
    its responsible app has Full Disk Access or the user consents ("would
    like to access data from other apps"), or both are signed by the same
    team. Bitrig and Phases are signed by different teams.
  - *Not tried:* giving Bitrig Full Disk Access or App Data consent, both
    the author's call, or a probe with Claude Code's own shell sandbox
    turned off. The control write suggests that sandbox isn't what refused
    (*inferred*).
- **Run 3, the fix:** the fast suite again, 2026-11-24 15:5x local, by
  Claude with the author's yes, on branch `fix/ui-tests-sandbox-folder`
  (spec draft 62, `[D-debug-test-folder]`), Debug build
  `1795553173707-C7EA3758` (build 62; all 31 launches used it,
  *verified* from the harness's printout). 32 tests in 11 suites, 248 s:
  **31 passed, 1 failed** (*verified*). All 11 failures of run 2 that
  needed image or album content passed, the five `PhotosSourcesTests`
  included, so the sandboxed Debug build reads
  `~/Library/Caches/PhasesUITests/` through the exception.
  `dividerStaysWithin240To320` failed exactly as in run 2 (far right:
  239.5 pt, expected 320), so it reproduces and isn't caused by the
  missing folders: `[L-divider-drag-right]`.
- **The divider failure explained (issue #49), 2026-11-24.** The author
  checked by hand: the app's divider works, and the sidebar can't widen
  only when the window is too narrow (*observed* by the author). The
  window's minimum is 700 pt, the 240 pt sidebar minimum plus the 460 pt
  detail minimum (*verified* from the code, Claude), so at that width the
  divider can't move right at all; reaching 320 needs at least 780 pt.
  Why the test window opened narrow instead of at the 960 pt default
  wasn't found: the saved-frame keys `SavedLayout` clears were absent
  from Phases' settings afterward (*verified*, Claude), and only
  `PauseBannerTests` asks for a size (700 × 600). Fix, on branch
  `fix/sidebar-test-window-width`: the tests that call
  `expectSidebarLimitsHold` open the window at 1000 × 680, narrower on a
  narrow active screen (the author's suggestion; he runs a portrait
  monitor), and throw if the screen can't fit 780 pt.
- **Run 4, the test fix:** `dividerStaysWithin240To320` alone,
  2026-11-24 ~16:20 local, by Claude with the author's yes, build 62
  (`1795555173693-F7169932`): **passed** in 12 s (*verified*). Not run
  against the old test to show it failing alone; runs 2 and 3 already
  did, inside the suite.
