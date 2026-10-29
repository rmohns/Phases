# Phases — Testing

How Phases is checked and how to look inside it: the test layers, the
launch arguments that exist only for tests, and diagnostic logging.
SPEC.md says what Phases does and why; ERRATA.md says what macOS does to
it. Sorting test: would someone using Phases ever see or care about this
line? No → here.

Decisions here carry `[D-…]` tags and follow the same rules as SPEC.md's:
the author approves changes before code is written, and the code that
enforces a decision carries its tag. Cross-references use tags or quoted
section titles, never numbers `[D-refs-by-id]`.

Regressions found in testing (the − button doing nothing, the Name field
taking focus, Tab skipping the grid) are why Phases has tests. They come in
two layers.

## Layer 1: unit tests (in place, draft 21)

- A small Swift package in `UnitTests/`, using Swift Testing. Run it with
  `swift test` from that folder (about 30 tests, well under a second once
  built).
  - *Why a package, not a test target in Project.json:* `swift test` runs
    without a test target or a generated Xcode project. The tooling fights
    the test-target route; see `[Q-bitrig-test-targets]`.
- Covers the pure logic that decides what the app does:
  - `ScheduleEngine`: which phase is active (including overnight and
    Light/Dark conditions), the next phase start, and rotation slots, which
    are how `[D-missed-latest-only]` lands on the most recent missed rotation
  - `SolarCalculator`: civil dawn and dusk at a known location, and days with
    no civil dawn or dusk (far north)
  - `ImageGridNavigation`: arrow-key movement `[D-grid-one-tab-stop]`
  - `PhaseListSelection`: which phase is selected after a delete
    `[D-delete-selects-next]`
  - `AppVersion`: the spec draft constant matches SPEC.md's title
    `[D-version-in-settings]`
  - `WallpaperCheck`: what the scheduler's normal check does with what's
    already applied, including a screen change that leaves every image
    fitting `[D-screen-change-no-reroll]` (draft 31)
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
- Expected dawn and dusk times come from published almanac values
  (*recalled*, not checked against a source). The tests allow ±10 minutes,
  which catches real breakage (wrong day, wrong time zone, AM/PM swapped)
  without depending on the almanac's exact rounding.

## Diagnostics

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
    category `sidebar`). What to log when chasing a platform bug is in
    ERRATA.md "Diagnostic procedures".
  - *Verified* 2026-10-28: with the switch on, a relaunch logged the
    sidebar's limit passes, restores, and resizes. The off state is
    consistent but not proven: nothing was logged between that build's
    launch and the switch going on, but the window may not have been
    opened then.

## Test launch arguments

- `[D-test-no-location-prompt]` **Test launches can skip the location
  prompt.** Launching with `--args -PhasesNoLocationPrompt YES` makes
  Phases never ask for location; if permission was never decided, solar
  phases fall back as they do when it's denied. It lasts one launch only
  (a launch argument, not a saved setting), so it can't leak into normal
  use.
  - *Why:* each rebuild asks for location again, and the prompt sat over
    the screen during UI test runs, where it could catch clicks (author,
    2026-10-29).

## Layer 2: UI tests (draft 31)

- A second Swift package, `UITests/`, that launches the built Phases and
  drives its window the way a person would. It guards the regressions in
  ERRATA.md "Regressions found so far"; each row's "Guarded by" names its
  test. Run it with `swift test` from that folder, only after asking the
  author: it moves the mouse and types (see `[D-ui-test-runner]`).
- `[D-ui-test-runner]` **The UI tests drive Phases through the
  Accessibility API, not XCUITest.**
  - *How:* the harness launches a new instance of the newest Bitrig build
    (or the app named by `PHASES_APP`) in test mode `[D-ui-test-mode]`,
    finds controls by accessibility identifier `[D-ui-test-ids]`, clicks,
    drags, and types with synthetic mouse and key events, reads results
    back through the AX API, and force-quits the instance after each test.
  - *Safety:* before any click or keystroke, the harness checks that the
    test instance of Phases is frontmost; if not, the test fails without
    sending input, so a stray keystroke can't land in another app.
  - *Why:* `bitrig test` can't run test targets in a Project.json project
    `[Q-bitrig-test-targets]`, and the AX API reads these controls
    reliably where System Events doesn't `[Q-system-events-ax]`.
  - *Needs:* Accessibility permission (and Screen Recording, for the
    screenshot checks) for the app that runs `swift test`.
- **Suites:**
  - *Fast* (the default, about a minute): sidebar width limits, the +/−
    buttons, delete selection, initial focus, the grid's Tab stop, and
    the toolbar height.
  - *Slow* (`PHASES_UI_SLOW=1 swift test`, about two minutes): the
    sidebar limits again after waiting 30 s, across three launches,
    because SwiftUI's rewrite lands seconds after the window opens
    `[Q-split-item-rewrite]`.
  - *Screenshots:* saved to `UITests/Screenshots/` (not committed) for the
    author to review, for regressions that are visual only (the branding
    tagline, the image folder name's truncation). Not compared pixel by
    pixel; that would break on every wallpaper and macOS change.
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
- `[D-ui-test-mode]` **Test mode: one launch that touches nothing real.**
  Launching with `--args -PhasesUITestMode YES` makes Phases:
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
  - Like `[D-test-no-location-prompt]`, it's a launch argument, not a
    saved setting, so it can't leak into normal use.
  - AppKit's own saved window frame and sidebar layout live in the normal
    settings, outside the separate store. The UI tests record both before
    each launch, clear them so the test starts from the defaults, and put
    them back after quitting.
    - *Why:* on 2026-10-29 a revert-and-check run collapsed the sidebar,
      AppKit saved that, and the author's own Phases window would have
      opened with no sidebar and no way to reopen it. The key was reset by
      hand.
  - *Cost:* while tests run, two Phases icons can show in the menu bar.
- `[D-ui-test-ids]` **Controls the tests use carry accessibility
  identifiers:** `sidebar`, `addPhase`, `deletePhase`, `phaseName`,
  `imageGrid`, `imageFolderName`. They're invisible to users, but renaming
  one breaks the tests.
- **Not covered by UI tests:** crossfade timing (the twitch) is checked
  with frame-by-frame recordings ("Diagnostic procedures" in ERRATA.md);
  the screen-change rule `[D-screen-change-no-reroll]` is a Layer 1 test.
