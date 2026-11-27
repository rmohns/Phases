# `[X-menubar-overflow]` Menu bar overflow and the test harness

Part of "Other investigations" in [EXPERIMENTS.md](../EXPERIMENTS.md), the index of
experiments. Moved here word for word from EXPERIMENTS.md on
2026-11-27, when each record got its own file.
The group's introduction there applies to this record too; copied
here so the record reads on its own:

> Until 2026-11-09 this section was called "Open questions"; most of what
> it held has since been answered. What's still open is under "Still
> open" at its end.


- **Question:** is Phases' menu bar icon hidden when the menu bar runs
  out of room, and why does the UI test harness sometimes refuse to
  click it?
- **When, on what:** 2026-10-30 to 2026-11-04, macOS 27.2, several
  display setups. Tracked as issue #11.
- **Branch:** the harness fix on `fix/menubar-hit-retry`, tag
  `archive/fix/menubar-hit-retry`.
- **Outcome:** on macOS 27.2 a chevron reveals hidden icons; macOS 26
  untested. The harness now rechecks ownership for up to 2 s. The test
  beeps are macOS's type-to-select.
- **Findings:** `[L-menubar-overflow]`.

- `[L-menubar-overflow]` **Is Phases' menu bar icon hidden when the menu
  bar runs out of room?** On macOS 27.2, no: a chevron reveals it. Still
  open for macOS 26. Tracked as GitHub issue #11; no action for now.
  - **How it came up:** a UI test run on `fix/cover-memory` (tag
    `archive/fix/cover-memory`), 2026-10-30,
    two external displays (no built-in), Bartender not running.
    - The driver found Phases' menu bar item at x = 2630 but refused to
      click it ("isn't this test instance's"). *Measured.*
    - That failed `deleteRemovesANewlyAddedPhase` and, most likely, one
      `FocusTests` test whose message wasn't kept. A rerun of
      `FocusTests` alone passed all three.
    - Suspected cause (*guess*): the author runs the Cinema HD at
      1000 × 1600, narrow enough that macOS may push status items off the
      menu bar.
  - **Why it matters beyond tests:** on that display a person might not
    reach Phases' menu at all.
  - **Update, same day:** the author checked the narrow display. It had
    run out of room, and macOS showed a chevron that expands the hidden
    icons when clicked, so Phases stays reachable on macOS 27.2
    (*observed* by the author).
  - **Seen again, 2026-11-03** (Claude, `feature/reopen-window`, fast
    suite twice): the same refusal, "the menu bar item at (2541.0, 31.5)
    isn't this test instance's," at launch. 17:51: `brandingPanelScreenshot`
    (build not known, see the harness note under `[L-reopen-event]`).
    18:11: `brandingPanelScreenshot` and `gridIsOneTabStopAndArrowsScroll`
    (build of 18:11:16, printed by the harness); the other 11 passed
    (*verified*). Same x every time, wide display, no leftover Phases
    afterward. *Guess:* the previous test's force-quit instance still
    owns that spot for a moment.
  - **Seen again, 2026-11-04** (Claude, `main` at `63249c1`, Debug build
    of 22:53:03 printed by the harness, built-in display only, 3024 ×
    1964 Retina with the notch): `deletingAMiddlePhaseSelectsTheOneBelow`
    refused "the menu bar item at (987.0, 15.5) isn't this test
    instance's." The fast suite logged 2 issues; the other's message
    was lost (output cut off), so which test it hit is unknown. The
    installed Phases (`/Applications`, pid 99271) was running throughout
    (*verified* afterward, `pgrep`). *Hypotheses*, untested: the item
    found was the installed Phases' icon, or the notch left too little
    room right of it and hid the test instance's icon.
  - **Rerun, 2026-11-04** (Claude, same build, built-in display only, the
    notch area disabled by the author's resolution, no other Phases
    running, *verified* with `pgrep` before the run): 11 of 13 passed.
    `brandingPanelScreenshot` and `typingAfterReopeningDoesNotRenameThePhase`
    refused "the menu bar item at (1023.0, 15.5) isn't this test
    instance's"; `deletingAMiddlePhaseSelectsTheOneBelow`, which failed
    the first run, passed. That rules out the installed Phases and the
    notch. Both failing tests were the second in their suite, right after
    another test's instance was force-quit (*observed*, two cases).
    *Hypothesis*, untested: the harness hit-tests the item while the menu
    bar is still re-laying out after the old instance's item went away,
    so the point briefly belongs to something else. The refusal message
    doesn't name the owner it found, so the log can't confirm this.
  - The author heard a system beep the 2nd and 4th time a window
    appeared in this run (*observed*, author). *Hypothesis*, untested:
    the Focus tests press X to prove it doesn't rename the phase, and a
    key nothing handles beeps. The run's output has no timestamps, so
    which tests the beeps came from is unknown.
  - Beeps again in the 13-of-13 run (author). The run's output shows the
    sidebar outline had focus at every X press (*verified*, the tests'
    "Focused on" lines; 3 presses in that run, 2 in the rerun before it,
    where the reopen test failed before pressing). No phase starts with
    X, and a list's type-to-select beeps when nothing matches
    (*recalled*, not tested here). That fits, but nothing ties a beep to
    a press yet.
  - **Answered, 2026-11-04:** the author pressed keys in the sidebar by
    hand: focus behaves as the tests expect, and a key that matches no
    phase beeps (*verified* by the author). The beeps are macOS's, not a
    failure.
  - **Harness fix, 2026-11-04** (`fix/menubar-hit-retry`, tag `archive/fix/menubar-hit-retry`, approved by the
    author): the ownership check rechecks for up to 2 s and names the
    owner when it refuses. First run with it: 13 of 13 (*verified*).
