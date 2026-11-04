# Phases — Testing

How Phases is checked and how to look inside it: the unit tests, the
hands-on checks, and the tools they share (diagnostic logging and the
launch arguments that exist only for tests). SPEC.md says what Phases
does and why; ERRATA.md says what macOS does to it. Sorting test: would
someone using Phases ever see or care about this line? No → here.

Decisions here carry `[D-…]` tags and follow the same rules as SPEC.md's:
the author approves changes before code is written, and the code that
enforces a decision carries its tag.

Regressions found in testing (the − button doing nothing, the Name field
taking focus, Tab skipping the grid) are why Phases has tests.

## At a glance

Two groups, split by whether a run touches the Mac. **Unit tests** never
launch Phases and run freely. **Hands-on checks** move the mouse, press
keys, or change the real wallpaper and settings, so each run needs the
author's yes.

| Group | Check | What runs | Takes | Build | Asks first | Required |
|---|---|---|---|---|---|---|
| Unit tests | Logic tests | `swift test` in `UnitTests/` | under a second once built | none (compiles the sources) | no | with every build |
| Hands-on checks | Interface tests | AX-driven UI tests in `UITests/`: the fast suite; the slow suite too when the change touches the sidebar | 1–3 min | the newest Bitrig build, in test mode `[D-ui-test-mode]` | yes | before merging any change to the window or the code it calls, and for every regression guard that's a UI test |
| Hands-on checks | Cover checks | `[D-cover-checks]`, checks 1–9 | 15–20 min (*estimate*) | Release | yes | before merging cover work, and after any change to `CrossfadeController` |
| Hands-on checks | Memory checks | `[D-memory-protocol]`: two runs of ten changes, the covers' cost and release, the no-covers baseline, the window check | 30–40 min (*estimate*) | Release | yes | two runs before and two after any change to covers, image loading, the thumbnail grid, or how wallpaper is set |

The table's order is by time taken, nothing more: no check includes or
outranks another.

## Unit tests

### What they are

- A small Swift package in `UnitTests/`, using Swift Testing. Run it with
  `swift test` from that folder (about 30 tests, well under a second once
  built).
  - *Why a package, not a test target in Project.json:* `swift test` runs
    without a test target or a generated Xcode project. The tooling fights
    the test-target route; see `[Q-bitrig-test-targets]`.

### What they cover

The pure logic that decides what the app does:

- `ScheduleEngine`: which phase is active (including overnight and
  Light/Dark conditions), the next phase start, and rotation slots, which
  are how `[D-missed-latest-only]` lands on the most recent missed rotation
- `SolarCalculator`: civil dawn and dusk at a known location, and days with
  no civil dawn or dusk (far north)
  - Expected dawn and dusk times come from published almanac values
    (*recalled*, not checked against a source). The tests allow ±10
    minutes, which catches real breakage (wrong day, wrong time zone,
    AM/PM swapped) without depending on the almanac's exact rounding.
- `ImageGridNavigation`: arrow-key movement `[D-grid-one-tab-stop]`
- `PhaseListSelection`: which phase is selected after a delete
  `[D-delete-selects-next]`
- `AppVersion`: the spec draft constant matches SPEC.md's title
  `[D-version-in-settings]`
- `WallpaperCheck`: what the scheduler's normal check does with what's
  already applied, including a screen change that leaves every image
  fitting `[D-screen-change-no-reroll]` (draft 31)

### Rules

- `[D-tests-unhosted]` **The tests never launch Phases.** The test package
  compiles the files it tests directly instead of loading them into the
  running app.
  - *How:* `UnitTests/Sources/PhasesLogic` holds symlinks to the app's
    own source files, so the tests always check the code the app ships.
  - *Why:* launching Phases records and changes the real wallpaper, so a
    test run would touch the desktop. Testing only pure files also keeps
    the tests fast and free of AppKit side effects. The cost: a newly
    tested file needs a new symlink there.
  - *Verified* 2026-10-28: all tests pass, and deliberately breaking
    `PhaseListSelection` back to the draft 15 behavior made two tests fail.
- `[D-tests-carry-tags]` **Tests for a tagged decision carry its tag** in
  the test's name or a comment, so searching for `[D-…]` finds the spec, the
  code, and the test together.

## Hands-on checks

- `[D-hands-on-checks]` **Every check that drives the mouse and keyboard
  or touches the real wallpaper is a hands-on check, and any one of them
  can run on its own** (draft 33). There are three: Interface tests, Cover
  checks, and Memory checks. The Interface tests are automated but still
  belong here, because they move the mouse; the line is touching the Mac,
  not automated versus by hand.
  - **Any check alone.** Each starts from a fresh launch, does its own
    setup, and puts back everything it changed (its "Setup" and
    "Afterward"). None depends on another having run first, or on the
    same sitting. A branch that needs more than one runs them in any
    order, in as many sittings as suit the author.
  - **Part of a check.** A check can also be split: the three-display
    cover checks are their own sitting, for example. Record which parts
    ran. A check counts as done for merging when every part it requires
    has run.
  - **Who runs it.** The author can run any of them directly: the
    Interface tests are `swift test` in `UITests/` (`PHASES_UI_SLOW=1`
    adds the slow suite), and the Cover and Memory checks follow the steps
    in their sections. When Claude runs one, it asks first and names the
    check and parts ("Cover checks 1–7 and 9, one display"), following
    the author's standing rule for mouse and keyboard runs (one yes per
    named set, spoken warnings before and after).
  - **Hands-off windows** (2026-11-03). When the author opens one ("I'm
    hands-off for 30 minutes", "tonight"), Claude may run the Interface
    tests, either suite, as often as needed until it ends, without asking
    each time. The spoken warnings still apply. Cover and Memory checks
    change the real wallpaper and settings, so they still need a named
    yes.
  - *Why:* the memory runs take most of a sitting and matter only when
    memory could change. Tying each check to the code it guards keeps a
    small change from costing an hour of hands-off time (author,
    2026-11-03).
  - *Names:* plain names, not numbered tiers, because numbers read as a
    ladder where each includes the one before. They don't.

### Interface tests (draft 31)

#### What they are

- A second Swift package, `UITests/`, that launches the built Phases and
  drives its window the way a person would. It guards the regressions in
  ERRATA.md "Regressions found so far"; each row's "Guarded by" names its
  test.

#### When

- Before merging any change to the window or the code it calls, and for
  every regression guard that's a UI test. Add the slow suite when the
  change touches the sidebar.

#### Setup and running

- Ask first `[D-hands-on-checks]`. Then `swift test` from `UITests/`.
  Test mode `[D-ui-test-mode]` keeps the run off the author's wallpaper,
  phases, and window layout, so there's nothing to put back afterward.
- *Needs:* Accessibility permission (and Screen Recording, for the
  screenshot checks) for the app that runs `swift test`.
- **Suites:**
  - *Fast* (the default, about a minute): sidebar width limits, the +/−
    buttons, delete selection, initial focus, the grid's Tab stop, the
    toolbar height, and a relaunch with the window closed
    `[D-reopen-shows-window]`.
  - *Slow* (`PHASES_UI_SLOW=1 swift test`, about two minutes): the
    sidebar limits again after waiting 30 s, across three launches,
    because SwiftUI's rewrite lands seconds after the window opens
    `[Q-split-item-rewrite]`.
  - *Screenshots:* saved to `UITests/Screenshots/` (not committed) for the
    author to review, for regressions that are visual only (the branding
    tagline, the image folder name's truncation). Not compared pixel by
    pixel; that would break on every wallpaper and macOS change.

#### How the tests work

- `[D-ui-test-runner]` **The UI tests drive Phases through the
  Accessibility API, not XCUITest.**
  - *How:* the harness launches a new instance of the newest Bitrig build
    (or the app named by `PHASES_APP`) in test mode `[D-ui-test-mode]`,
    finds controls by accessibility identifier `[D-ui-test-ids]`, clicks,
    drags, and types with synthetic mouse and key events, reads results
    back through the AX API, and force-quits the instance after each test.
  - *Which build:* the newest by its executable's modification date, and
    the harness prints the path and date. Until 2026-11-03 it compared
    the `Phases.app` bundles' dates, which Bitrig sets the same on every
    build, so with several builds present it could test a stale one
    (*verified* 2026-11-03, `stat`; `[L-reopen-event]`). Runs before
    then may have tested an older build than intended.
  - *Safety:* before any click or keystroke, the harness checks that the
    test instance of Phases is frontmost; if not, the test fails without
    sending input, so a stray keystroke can't land in another app.
  - *Why:* `bitrig test` can't run test targets in a Project.json project
    `[Q-bitrig-test-targets]`, and the AX API reads these controls
    reliably where System Events doesn't `[Q-system-events-ax]`.
- `[D-ui-menubar-wide]` **Phases' menu bar item is only clicked on a
  display at least 1200 points wide.** If the item is on a narrower
  display, the harness moves the pointer to a wide one and looks again;
  if it's still narrow, the test fails with that reason. If no display
  that wide is connected, the test fails and the harness says so aloud.
  - *Why:* a narrow menu bar runs out of room and hides status items
    (made more likely by iPhone Live Activities in the menu bar on
    macOS 27). That's the setup, not a Phases failure: a display under
    1200 points is only possible on Apple Silicon by changing display
    settings (author, 2026-10-30; LEARNINGS.md `[L-menubar-overflow]`).
- `[D-ui-test-ids]` **Controls the tests use carry accessibility
  identifiers:** `sidebar`, `addPhase`, `deletePhase`, `phaseName`,
  `imageGrid`, `imageFolderName`. They're invisible to users, but renaming
  one breaks the tests.

- **Relaunch:** the harness relaunches its own instance by sending it a
  reopen Apple event, as Finder does, rather than `open`, which could
  reach a Phases the author is running. Only the closed-window case is a
  test: the harness always opens the window at launch, so "never opened"
  can't happen under test. That case, minimized, and closed on another
  Space were checked by hand on the experiment build, which used the
  same routing (`[L-reopen-event]`, 2026-11-03).

#### Not covered here

- Crossfade timing (the twitch) and the persistent cover's Space behavior
  are the Cover checks. Memory is the Memory checks. The screen-change
  rule `[D-screen-change-no-reroll]` is a unit test.

#### History

- *Verified* 2026-10-29: the fast suite passed 9 of 9 (about 30 s), and
  the slow suite passed 3 of 3 launches (112 s).
- **Revert-and-check, 2026-10-29:** each fix reverted, the app rebuilt,
  and its test run alone.
  - *Caught:* sidebar collapse, Delete doing nothing, delete selecting the
    first phase, every thumbnail a Tab stop, the 66 pt toolbar, Choose…
    squeezed.
  - *Caught, differently:* with no sidebar limits helper, the sidebar was
    missing at launch, rather than dragging out of range as recorded in
    `[D-window-helper-order]`. Why is unknown.
  - *Not caught at first:* the initial focus and the limits watch. A hand
    check of a build without either fix (author, 2026-10-29) showed both
    bugs still happen, and why the tests missed them:
    - **Focus:** a test can't open the window while Phases is active, so
      the first-open case never happens under test. The other path, a
      reopened window keeping the Name field's focus
      `[Q-closed-window-keeps-focus]`, is what
      `typingAfterReopeningDoesNotRenameThePhase` drives.
    - **Limits watch:** the limits escaped only after the window had been
      used. The sidebar tests now switch between Settings and phases
      before dragging.
    - Rerun against that build: the reopen test, the sidebar limits test,
      and the slow suite (3 of 3 launches) all failed, with the sidebar
      collapsing completely. All passed on the fixed build.
  - *Caught, differently:* with no limits helper, the sidebar is missing
    at launch, by every opening path.
  - *Side effect:* without the focus fix, the grid's Tab test also fails,
    because focus starts on the window instead of the sidebar.
  - The brand panel screenshot has no assertion, so it can't fail.
- 2026-11-04 (Claude, `main` at `63249c1`, Debug build of 22:53:03,
  built-in display only): the slow suite passed 3 of 3 launches (146 s,
  *verified*). The fast suite failed with 2 issues (111 s): one was the
  menu bar refusal in `deletingAMiddlePhaseSelectsTheOneBelow`
  (LEARNINGS.md `[L-menubar-overflow]`); the other's message was lost.
  The relaunch and sidebar tests passed. Not yet a clean pass.
  Rerun the same day, no other Phases running: 11 of 13, the same
  refusal in two other tests (`[L-menubar-overflow]`).

### Cover checks (draft 33)

- `[D-cover-checks]` **The persistent cover is checked by hand before it
  merges, and again after any change to `CrossfadeController`.** Frame
  timing and Space behavior are out of reach of the unit and Interface
  tests.

#### When

- Before merging cover work, and after any change to
  `CrossfadeController`. Checks marked **(3)** are repeated on three
  displays, usually as their own sitting.

#### Setup

- Ask first, naming the checks `[D-hands-on-checks]`. Techniques:
  LEARNINGS.md `[L-synthetic-clicks]`, `[L-twitch-measurement]`,
  `[L-settings-panes]`.
- Quit the installed Phases (two copies would both set the wallpaper),
  then launch a Release build fresh, with diagnostics on (`cover`
  category), Crossfade, and one display with three Spaces and no window
  covering the desktop.

#### Reading results

- Each Space's wallpaper is read back by switching to it and asking
  `NSWorkspace.desktopImageURL(for:)`. Cover windows are listed with
  `CGWindowListCopyWindowInfo`: owner Phases, one level above the desktop
  picture.

#### The checks

Each with what passes:

1. **Twitch (3):** five changes, each display recorded on its own.
   Frames before and after each fade's end match at noise level
   (about 40 dB or better). `[D-persistent-cover]`
2. **Menu bar (3):** text, and with "Show menu bar background"
   turned on for the test, the background restyle to each image at
   the end of its fade. A late restyle that a menu bar click fixes is
   macOS's own (`[L-menubar-lazy-restyle]`), not a failure. Put the
   setting back after. `[D-cover-opacity]`
3. **Own Space:** change on Space 1, then visit 2 and 3. Each keeps
   its own image; the log shows Space 1's cover removed on leaving;
   no frame changes at the removal or on returning.
   `[D-cover-per-space]`
4. **Leave mid-fade:** 3 s fade, ⌃→ about 0.3 s in, then again about
   1.5 s in. Space 2 never changes (no hard cut); the log shows the
   change held pending; back on Space 1 the log shows it set, and the
   read-back gives the new image there and the old one on Space 2.
   `[D-change-stays-on-its-space]`
5. **Fade ends during the swipe:** 1 s fade, ⌃→ about 0.5 s in, timed
   from the cover window appearing, not the click; at least ten trials
   where Spaces 1 and 2 had different images. Every trial ends with
   Space 1 showing the new image once you're back, set directly or on
   return. Space 2 hard-cutting to the new image now and then is
   macOS's own `[Q-set-target-decided-late]`, not a failure; the log
   should show the change pending again and set on return.
   `[D-reset-on-quick-return]`
6. **Pending dropped:** leave mid-fade as in 4, then set Transition to
   None; repeat, then Quit. Each time the log shows the covers
   removed, no cover windows remain, and Space 1 keeps its old image.
7. **No crossfades, no covers:** with Transition: None, and again
   with Reduce Motion on, changes apply at once and no cover windows
   exist. Turning Reduce Motion on with a cover up removes it.
   `[D-cover-only-for-crossfade]`
8. **Displays (3):** change one display's resolution: its cover is
   redrawn and fits (screenshot). Disconnect a display: the log shows
   its cover removed. Hide the Dock: no redraw in the log.
   `[D-cover-follows-displays]`
9. **Quit:** with restore on, a hard cut to the original and no cover
   windows left; with restore off, nothing visible. `[D-cover-pause-quit]`

#### Afterward

- Reduce Motion and "Show menu bar background" as they were, Transition
  back to the author's setting, diagnostics back to the author's setting,
  the test build quit, and the installed Phases relaunched.

#### Record

- Results as *Verified* notes, with date, on the decision each check
  covers in SPEC.md, and anything unexpected in LEARNINGS.md.

#### Why by hand

- The evidence is recordings, the log, and wallpapers read back per
  Space. None of it fits an automated test that wouldn't be flaky
  (author's standing approach for the twitch since draft 4).

### Memory checks (draft 32; covers, draft 33)

- `[D-memory-protocol]` **Memory is checked by hand, ten changes per run,
  at least two runs before a change and two after.** This is how
  `[D-memory-flat]` passes or fails. Runs vary widely (297 MB after three
  changes in one, 144 MB in another), so one run proves nothing.

#### When

- Two runs before and two after any change to covers, image loading, the
  thumbnail grid, or how wallpaper is set.

#### Setup

- Ask first, naming the runs `[D-hands-on-checks]`. Clicks are real
  mouse events. Techniques: LEARNINGS.md `[L-synthetic-clicks]` and
  `[L-memory-tools]`.
- **Build:** the installed Release build, measured with `footprint -p
  <pid>`, which matches what Activity Monitor shows. No
  `MallocStackLogging` on pass/fail runs: it adds 16–64 MB of its own.
- A fresh launch, the window closed, Transition set to Crossfade, Reduce
  Motion off, and every display connected. Note the display setup with
  the results, since each display keeps one cover after a change
  `[D-persistent-cover]`. Note each display's decoded image size if
  known: a cover costs about width × height × 4 bytes.

#### The runs

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

#### Flag anything over 500 MB

- If any reading in a run, window open or closed, goes above 500 MB, tell
  the author. It doesn't fail the run; it's a signal to look at
  refactoring, decided when it happens, not built ahead of time (author,
  2026-10-30).

#### Afterward

- Transition back to the author's setting, the test build quit, and the
  installed Phases relaunched if a run's build replaced it.

#### Record

- Each run's figures in LEARNINGS.md "Memory", with the date, macOS
  version, build, and displays.

#### Why by hand

- Footprint swings with when macOS chooses to purge, so a pass mark needs
  several runs and judgment. An automated test would be flaky or too
  loose to catch anything.

## Shared tools

Used by both groups. Reference, not steps.

### Diagnostics

- `[D-diagnostics-switch]` **Diagnostic logging is built in and off by
  default.** Every build is the same; logging is switched on at launch,
  not compiled in or out.
  - Turn on (then quit and relaunch Phases):
    `defaults write app.bitrig.new.ecd0db30-b411-4419-8736-9fe3d1c96268 PhasesDiagnostics -bool true`
  - Turn off: the same with `-bool false`, or `defaults delete … PhasesDiagnostics`.
  - Read: `/usr/bin/log show --last 30m --style compact --predicate 'subsystem == "PhasesDiag"'`
    (in zsh, plain `log` is a shell builtin; use the full path).
  - Code: `App/Model/Diagnostics.swift`. Get a logger with
    `Diagnostics.logger("category")`; guard any extra work done only to
    build a log line with `Diagnostics.isEnabled`. Add new diagnostic
    lines this way instead of writing new logging from scratch.
  - *Why a launch switch, not a build flag:* switching needs a relaunch,
    not a rebuild, and the logging code is compiled in every build, so
    it can't silently stop compiling. When off, each call is a disabled
    `os.Logger` call, which skips building its message (*recalled*,
    standard `os.Logger` behavior). No extra observers or timers run for
    logging alone.
  - *Why:* the 2026-10-28 sidebar investigation needed logging twice,
    and it was written from scratch both times (author's request).
  - Currently instrumented: the sidebar limits (`[D-sidebar-limits-watch]`,
    category `sidebar`), and covers (category `cover`: each cover made,
    removed and why, redrawn or resized, held pending, and set on
    returning to its Space; `[D-persistent-cover]`). What to log when chasing a platform bug is in
    ERRATA.md "Diagnostic procedures".
  - *Verified* 2026-10-28: with the switch on, a relaunch logged the
    sidebar's limit passes, restores, and resizes. The off state is
    consistent but not proven: nothing was logged between that build's
    launch and the switch going on, but the window may not have been
    opened then.

### Launch arguments

Both last one launch only (launch arguments, not saved settings), so
neither can leak into normal use.

- `[D-test-no-location-prompt]` **Test launches can skip the location
  prompt.** Launching with `--args -PhasesNoLocationPrompt YES` makes
  Phases never ask for location; if permission was never decided, solar
  phases fall back as they do when it's denied.
  - *Why:* each rebuild asks for location again, and the prompt sat over
    the screen during UI test runs, where it could catch clicks (author,
    2026-10-29).
- `[D-ui-test-mode]` **Test mode: one launch that touches nothing real.**
  Used by the Interface tests. Launching with `--args -PhasesUITestMode
  YES` makes Phases:
  - never change the wallpaper: no crossfade, no wallpaper calls, and no
    restore point captured or restored;
  - keep its settings in a separate store (the bundle ID plus `.uitest`),
    erased at every test-mode launch and seeded with three clock-time
    phases (Morning 7:00, Afternoon 12:00, Evening 18:00), so the user's
    phases are never read or changed and every test starts from the same
    list. Deleting phases can never run out;
  - use the image folder given by `-PhasesUITestImages <path>` (the
    harness makes one with 60 images and a long name);
  - leave the window closed at launch, as usual. The UI tests open it the
    way the author does, from the menu bar item's Open Phases…, through
    AX actions. *Why:* opening it at launch instead skipped the focus and
    sidebar-watch bugs, so their tests passed with the fixes removed
    (2026-10-29). If Phases still isn't frontmost
    `[Q-launch-activate-refused]`, the tests bring it forward through the
    AX API;
  - never ask for location `[D-test-no-location-prompt]`.
  - AppKit's own saved window frame and sidebar layout live in the normal
    settings, outside the separate store. The UI tests record both before
    each launch, clear them so the test starts from the defaults, and put
    them back after quitting.
    - *Why:* on 2026-10-29 a revert-and-check run collapsed the sidebar,
      AppKit saved that, and the author's own Phases window would have
      opened with no sidebar and no way to reopen it. The key was reset by
      hand.
  - *Cost:* while tests run, two Phases icons can show in the menu bar.
