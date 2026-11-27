# Phases testing: Memory checks

Part of the testing docs. [TESTING.md](../TESTING.md) has the rules every
hands-on check follows (`[D-hands-on-checks]`: any check alone, who runs
it, proving the input landed), the unit tests, and what to do when a
fixed bug comes back. Moved here word for word from TESTING.md
"Hands-on checks" on 2026-11-27.

## Memory checks (draft 32; covers, draft 33)

- `[D-memory-protocol]` **Memory is checked by hand, ten changes per run,
  at least two runs before a change and two after.** This is how
  `[D-memory-flat]` passes or fails. Runs vary widely (297 MB after three
  changes in one, 144 MB in another), so one run proves nothing.

### When

- Two runs before and two after any change to covers, image loading, the
  thumbnail grid, or how wallpaper is set.

### Setup

- Ask first, naming the runs `[D-hands-on-checks]`. Clicks are real
  mouse events. Techniques: TEST-TOOLS.md `[L-synthetic-clicks]` and
  `[L-memory-tools]`.
- **Build:** the installed Release build, measured with `footprint -p
  <pid>`, which matches what Activity Monitor shows. No
  `MallocStackLogging` on pass/fail runs: it adds 16–64 MB of its own.
- A fresh launch, the window closed, Transition set to Crossfade, Reduce
  Motion off, and every display connected. Note the display setup with
  the results, since each display keeps one cover after a change
  `[D-persistent-cover]`. Note each display's decoded image size if
  known: a cover costs about width × height × 4 bytes.

### The runs

1. **Ten changes.** Read the footprint at idle, then make ten changes
   with Change Now from the menu bar menu, about 6 s apart, reading the
   footprint after each. Read it once more after 30 s idle. Stay on one
   Space throughout: leaving a Space removes its covers
   `[D-cover-per-space]`, which would hide growth.
   - **Pass:** after the tenth change, footprint is within 30 MB of what
     it was after the first (`[D-memory-flat]`). The covers are already
     up after the first change, so they're inside the comparison; what's
     measured is growth, not the covers' cost.
2. **Covers' cost and release** (draft 33), straight after the 30 s idle
   reading. Three readings, each after 30 s:
   1. **Leave the Space:** switch every display to another Space (⌃→ on
      each, or the one shared Space if "Displays have separate Spaces"
      is off). Expect a drop of about the covers' size
      `[D-cover-per-space]`.
   2. **Come back** to the first Space. No cover should return (no
      change has been made there since): footprint stays near reading 1.
   3. **Make one change, then set Transition to None** in Settings,
      close the window, and wait. Expect a drop of about the covers' size
      again `[D-cover-only-for-crossfade]`. (Opening the window adds its
      own lasting cost; see "Window" below. Read the footprint just
      before opening it and subtract the window's share by doing the same
      open-and-close once with Crossfade left on.)

   - **Pass:** readings 1 and 3 each fall by at least half the covers'
     expected size. Not tighter: macOS may keep freed memory for a while
     (LEARNINGS.md `[L-mem-freed-held]`), though cover buffers are
     IOSurfaces, not malloc blocks, so they're expected to go promptly
     (*inference*, not measured). Where the drop is short, check
     `vmmap --summary` for IOSurface regions of the covers' size before
     calling it a failure.
3. **Baseline with no covers:** one more run of the ten changes with
   Transition: None. Footprint should stay near idle (draft 32's
   after-change figures were 28–31 MB on two displays,
   `[L-mem-fix-runs]`, with covers that came off). It shows what the
   persistent covers add, for the record; it isn't a pass mark.
4. **Window:** for `[D-grid-release-on-close]`, read the footprint, open
   the window, scroll through the whole grid so every thumbnail loads,
   read it again, close the window, and wait 30 s. Then do it a second
   time.
   - **Pass:** both of these.
     - After each close, `heap <pid>` finds no `ThumbnailCell` views: the
       grid really was released.
     - The second close's reading is within 5 MB of the first close's:
       the window's cost doesn't grow with each open.
   - The footprint after closing isn't a target. Note it with the image
     count. It stays well above the pre-open figure even when the grid is
     released (40–50 MB at 22 images): freed memory the allocator keeps
     resident, and objects SwiftUI and AppKit hold on to, neither of
     which Phases can give back (LEARNINGS.md `[L-mem-fix-runs]`). Not
     worth chasing (author, 2026-10-30; this check approved the same
     day).

### Flag anything over 500 MB

- If any reading in a run, window open or closed, goes above 500 MB, tell
  the author. It doesn't fail the run; it's a signal to look at
  refactoring, decided when it happens, not built ahead of time (author,
  2026-10-30).

### Afterward

- Transition back to the author's setting, the test build quit, and the
  installed Phases relaunched if a run's build replaced it.

### Record

- Each run's figures in EXPERIMENTS.md "Memory" (in LEARNINGS.md
  "Memory" until 2026-11-09), with the date, macOS version, build, and
  displays, and a digest line in LEARNINGS.md "Memory".

### Why by hand

- Footprint swings with when macOS chooses to purge, so a pass mark needs
  several runs and judgment. An automated test would be flaky or too
  loose to catch anything.
