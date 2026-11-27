# `[X-33-image-sources]` Image sources: findings from merge 1 of issue #33

Part of "Image sources (issue #33, merge 1)" in [EXPERIMENTS.md](../EXPERIMENTS.md), the index of
experiments. Moved here word for word from EXPERIMENTS.md on
2026-11-27, when each record got its own file.


- **Question:** not recorded as one question; these are findings from merge
  1 of issue #33, not a planned experiment.
- **When, on what:** 2026-11-12, macOS 27.2; draft 52 build, not sandboxed
  (the NAS entry); the closed-menu entry rests on two runs of
  `undoPutsBackASourceRemovedWithTheMouse` the same day.
- **Branch:** none; findings from merge 1 of issue #33, no experiment
  branch.
- **Outcome:** not recorded as one outcome. `[L-nas-bookmark-rename]`
  needed no code change; `[L-closed-menu-stale]` was promoted to
  `[Q-undo-menu-ax]` (2026-11-12), per the entries below.
- **Findings:** `[L-nas-bookmark-rename]`, `[L-closed-menu-stale]`.

- `[L-nas-bookmark-rename]` **A security-scoped bookmark to a folder on
  a file server doesn't follow a rename; one to a local folder does.**
  Draft 52 build, not sandboxed, 2026-11-12, macOS 27.2. Renaming a local
  source folder while Phases ran: the row followed the new name. Renaming
  a source folder on the author's NAS: the row showed "Can't open", and
  Locate… brought the phase's selections back. *Verified* by the author,
  on screen. Why (*recalled*, not tested here): bookmarks find local
  items by file ID as well as path, and a network volume over SMB doesn't
  give a stable file ID, so only the old path is left. Matches
  `[D-source-location]`'s fallback design; no code change.
- `[L-closed-menu-stale]` **A closed menu's items, read through AX, keep
  the title and enabled state from when the menu last opened.** After
  removing a source, the closed Edit menu read "Undo" (not "Undo Remove
  “…”"), and after pressing it through AX, Redo still read disabled, so
  pressing Redo did nothing. Pressing Undo did work: the source came
  back. *Verified* by `undoPutsBackASourceRemovedWithTheMouse`, 2026-11-12
  (two runs). The author, opening the menu by hand, saw "Undo Remove
  “Jocelyn age 15-months-to-5-years”", and Undo and Redo both worked
  (*verified* by the author, on screen). Why (*recalled*): AppKit
  validates and retitles menu items when the menu is about to open. The
  test now opens the Edit menu through AX before reading it.
  - *Correction, same day:* opening the menu with an AX press didn't
    help; the items still read "Undo" and "Redo (disabled)". A real
    click on Edit, then on the item, worked, but only once the test
    matched plain "Undo"/"Redo": through AX the items never carry the
    action name, even with the menu open, and on screen a long folder
    name truncates the title in the middle (the author, watching the
    run). Passed with real clicks, 2026-11-12 (*verified*). So the
    "retitles on open" explanation holds for the screen but not for AX.
    Promoted to `[Q-undo-menu-ax]` (2026-11-12), since the test code
    depends on it.
