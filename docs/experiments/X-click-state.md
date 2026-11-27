# `[X-click-state]` Do Phases' synthetic clicks need `mouseEventClickState`?

Part of "UI driver click state (issue #39 follow-up)" in [EXPERIMENTS.md](../EXPERIMENTS.md), the index of
experiments. Moved here word for word from EXPERIMENTS.md on
2026-11-27, when each record got its own file.


- **Question:** `SyntheticInput` posts mouse up with click state 0
  (TEST-TOOLS.md, under `[D-input-modifier-keys]`). Does any click in
  Phases fail because of it? The image grid's tile click
  (`onTapGesture`, `App/Views/ImageGrid.swift`) is the suspect, and no UI
  test clicks a tile.
- **When, on what:** 2026-11-25, macOS 27.2, by Claude with Robert's
  go-ahead (he quit the installed Phases first). A throwaway UI test in
  test mode `[D-ui-test-mode]` clicks a tile and reads its selected state
  through AX, first with the driver as on `main`, then with click state
  set to 1 on down, up and drag.
- **Branch:** `experiment/click-state` (commit `78a9d5b`): the test
  `ClickStateTests`, an experiment-only `PHASES_CLICK_STATE=1` switch in
  `SyntheticInput.post(_:at:)` that sets click state 1 on down, up and
  drag and logs each posted event's click state, and a scroll-wheel
  `SyntheticInput.scroll(at:lines:)` with `PhasesApp.scroll(_:lines:)`
  and `phases-drive scroll`. Not merged.
- **Outcome:** **not needed.** A tile click toggles the tile with click
  state 0 on mouse up, the same as with 1. No driver change.
- **Findings:** `[L-click-state-not-needed]`, `[L-window-size-ignored]`,
  `[L-detail-scroll-short]`.

All runs 2026-11-25, morning, by Claude, Debug build 62
(`1795621942946-1F17B1BC`, built from `main` at `d6f4e89`), one
`swift test --filter …` per run, spoken warnings before and after.
Every run posted two clicks before the test's own (the harness opening
the window and bringing it to the front), each with click state 1 down,
0 up.

- **Run 1:** the test looked for a tile wholly inside the window and
  found none; no tile clicked. A test problem, not an answer.
- **Runs 2–3:** dumped the grid. Window 751 × 645 pt at (1038, 78), so
  its bottom edge at y 723; the grid's first row at y 755.5, below it.
  Run 3 asked the harness for a 1000 × 1104 pt window
  (`withPhases(windowSize:)`); it still opened 751 × 645 (*verified*,
  AX frame). See `[L-window-size-ignored]`.
- **Run 4:** the same, with the frames printed.
- **Run 5:** AX `AXScrollToVisible` on the first tile returned success
  and moved the grid 20 pt (684.5 → 664); the row was still below the
  window.
- **Robert, between runs 5 and 6,** thought the test copy couldn't read
  its images. A hold-open run (`holdOpenForALook`, launched by the
  harness exactly as the tests do) and a screenshot of its window showed
  "0 of 60 selected" and the test folder's heading, so it could; the
  grid was below the window's edge (*verified*, Claude's screenshot;
  Robert agreed). The log showed sandbox denials only for the system's
  `ImageThumbnailExtension` (`syscall-mach`), none for Phases.
- **Run 6:** 8 × 5 lines of scroll wheel over the Name field moved the
  tiles only 30 pt (735.5 → 705.5); still below the window. See
  `[L-detail-scroll-short]`.
- **Run 7:** resized the window through AX (`kAXSizeAttribute`) to
  751 × 1050; it took. The first tile, Test Image 01, at (1308, 755.5),
  was clicked twice, 1.8 s apart, mouse up click state 0: selected false
  → **true** → **false**, and the grid took focus (*verified*, AX). The
  test reported a failure, but that was its own bug: it read
  `isSelected` live from the node after the second click.
- **Run 8** (test fixed to keep the value), click state 0 on up:
  false → true → false, **passed**.
- **Run 9,** `PHASES_CLICK_STATE=1`, click state 1 on down, up and drag
  (confirmed by the log of each posted event): false → true → false,
  **passed**.
- *Not tested:* whether the window server rewrites click state on
  posting (no event tap was used), drags with click state 0 (the
  divider-drag tests already pass with it), and double clicks, which
  Phases doesn't use.
