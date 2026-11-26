# Phases — Testing

How Phases is checked: the unit tests, the hands-on checks, and what to
do when a fixed bug comes back. This is the test process. The tools
these use (the input driver, diagnostic logging, the launch arguments
that exist only for tests, and the tools' own quirks) are in
TEST-TOOLS.md. SPEC.md says what Phases does and why; ERRATA.md says
what macOS does to it. Sorting test: would someone using Phases ever see
or care about this line? No → here or TEST-TOOLS.md: process here, tools
there.

Until 2026-11-09 this file also held the tools ("Shared tools"); the old
wording was "How Phases is checked and how to look inside it: the unit
tests, the hands-on checks, and the tools they share (diagnostic logging
and the launch arguments that exist only for tests)."

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
| Unit tests | Logic tests | `bitrig test -package UnitTests` (or `swift test` in `UnitTests/`) | under a second once built | none (compiles the sources) | no | with every build |
| Hands-on checks | Interface tests | AX-driven UI tests in `UITests/`: the fast suite; the slow suite too when the change touches the sidebar | 1–3 min | the newest Bitrig build, in test mode `[D-ui-test-mode]` | yes | before merging any change to the window or the code it calls, and for every regression guard that's a UI test |
| Hands-on checks | Cover checks | `[D-cover-checks]`, checks 1–9 | 15–20 min (*estimate*) | Release | yes | before merging cover work, and after any change to `CrossfadeController` |
| Hands-on checks | Memory checks | `[D-memory-protocol]`: two runs of ten changes, the covers' cost and release, the no-covers baseline, the window check | 30–40 min (*estimate*) | Release | yes | two runs before and two after any change to covers, image loading, the thumbnail grid, or how wallpaper is set |
| Hands-on checks | Sandbox checks | checks 1–9 in "Sandbox checks" | 15–20 min (*estimate*) | the newest Bitrig build, diagnostics on | yes | after any change to the entitlements, or to how Phases reads the wallpaper store, sources, or the original wallpaper |
| Hands-on checks | Phase editor checks | `[D-editor-checks]`, checks 1–10, several displays for 1–4 | 20–30 min (*estimate*) | the newest Bitrig build, diagnostics on | yes | before merging the draft 63 editor, and after any change to the display tabs, the image header, or the Starts row |

The table's order is by time taken, nothing more: no check includes or
outranks another.

## Unit tests

### What they are

- A small Swift package in `UnitTests/`, using Swift Testing. Run it with
  `bitrig test -package UnitTests` from the project folder (about 200
  tests, well under a second once built). `swift test` from `UnitTests/`
  runs the same tests without Bitrig's build cache, and is the fallback
  when `bitrig` can't run.
  - *Why a package, not a test target in Project.json:* `swift test` runs
    without a test target or a generated Xcode project. The tooling fights
    the test-target route; see `[Q-bitrig-test-targets]`.
  - *Since draft 59* the project is `Phases.xcodeproj` `[D-xcode-project]`.
    *Since 2026-11-24* it lists `UnitTests/` as a folder reference, so
    Xcode loads the package and `bitrig test -package UnitTests` runs it.
    The app links nothing from it, and the tests stay unhosted
    `[D-tests-unhosted]` (GitHub issue #42; how, and what didn't work, in
    `[Q-bitrig-test-targets]`). Until then only `swift test` could run
    them (write-up: `docs/handoffs/2026-11-22-xcode-project.md`).

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
- `PhaseAvailability`: whether a phase can run and why not
  `[D-phase-cant-run]`, that the schedule drops every disabled phase, and
  that a denied dawn phase never becomes active even with a saved
  location `[D-denied-means-off]`; a phase turned off never runs, even
  without a location problem, and older saved phases load as on
  `[D-phase-turn-off]` (draft 42), and the row reads "Off" for it,
  "Phase disabled" otherwise (draft 42; no warning symbol since draft 45)
- `SidebarHighlight`: a row has the colored highlight only when it's
  selected, the window is in front, and the sidebar has focus
  `[D-active-badge]` (draft 45)
- `AppVersion`: the build number in the Xcode project
  (`Phases.xcodeproj/project.xcproj`; `Project.json` through draft 58)
  matches SPEC.md's title, and `App/Info.plist` takes both version
  numbers from build settings `[D-version-in-settings]`
- `FolderScan`: which images the folder scan finds and what it names
  them, following symlinks and aliases `[D-follow-links]` and ending on
  loops `[D-scan-each-folder-once]` (draft 35). These tests build folders
  in the temporary directory, never the user's. From draft 58, links and
  folders it isn't permitted to read are named apart from broken ones
  `[D-links-outside-refused]`; a mode-000 folder outside the library stands
  in for the sandbox's refusal (the tests don't run sandboxed).
- `SystemWallpaperCheck` (draft 58): reading the wallpaper store for
  Aerials, with an unreadable or garbled store, or a display with no entry
  or no UUID, coming out "unchecked" `[D-store-unreadable-safe]`; what Quit
  does with each kind; telling "no such file" from "not allowed to look"
  `[D-restore-file-check]`; and that the store is found in the real home
  `[Q-sandbox-container-home]`. The store is built in memory; the real one
  is never read.
- `WallpaperCheck`: what the scheduler's normal check does with what's
  already applied, including a screen change that leaves every image in
  its selection `[D-screen-change-no-reroll]` (draft 31); from draft 53,
  whether it advances (new occurrence, rotation due, however many were
  missed) or repairs (a display shows an image not in its selection, or
  nothing)
- `InOrderPicker` (draft 53): In order's next image after the remembered
  one, wrapping; a deselected or deleted image continues after where it
  sat in library order, a gone source starts at the first; never the
  image already showing unless it's the only one; consecutive images for
  several displays; a repair keeps the remembered image
  `[D-in-order-remembers]`. From draft 54: a deselected image is placed
  by the library's order; a photo removed from its album starts the
  album over, or its source if the album is gone
- `ImageSource` (draft 52): stored names (`<source>:<path>`, splitting at
  the first colon, draft 44 names with no source part), source IDs,
  locations under the home folder, saved sources and phases, and library
  order: sources in their stored order, then each source's own
  `[D-image-sources]` `[D-source-names]`. From draft 54, Photos names
  (`<source>:<album>:<photo>`) and sources, photo entries with no file,
  and a photo in two albums `[D-photos-names]` `[D-photos-sources]`
- `FetchAhead` (draft 54): the lead before a scheduled change (2
  minutes, or half a shorter rotation), never before now; and what a
  display shows when its photo can't be had: In order, the next one on
  hand, never what's showing unless it's all there is; Random, any on
  hand, avoiding what's showing; nothing on hand keeps the wallpaper
  `[D-photos-fetch-ahead]`
- `ChangeRecord` (draft 55): a change waiting on photos leaves the saved
  record alone until it shows, a check during the wait applies nothing,
  and pausing drops the pending change `[D-record-after-wait]` (issue
  #36). *Verified* 2026-11-14 by Claude: making the change save at its
  start, as draft 54 did, fails three of its tests
- `ReduceMotionNote` (draft 56): the Transition section's note shows only
  while Reduce Motion is on, and the Transition and Duration controls are
  dimmed only then `[D-reduce-motion-note]` (issue #32)
- `PhotoCacheRules` (draft 54): which cached photos a cleanup deletes
  (least recently shown first, only until under the limit, never a
  protected file, and with an unreadable wallpaper store, nothing shown
  in the last 30 days), and cache file names that change with a photo's
  edit date `[D-photos-cache]` `[D-photos-version]`
- `OutsideChangeRule`: which store changes count as a wallpaper picked
  outside Phases (System Settings picks and Aerials yes; Phases' own sets,
  "last used"-only writes, and an unreadable store no), and reading
  entries and file names from a store built in the test
  `[D-outside-change-rule]` (draft 37)
- `Phase`: a new phase starts now, rounded down to 5 minutes
  `[D-new-phase-now]` (draft 40); a duplicate copies every setting
  with a new ID and a "copy" name `[D-duplicate-phase]` (draft 41); a new user's
  three starter phases `[D-starter-phases]` (draft 43)
- `FirstLaunch`: which launches count as a first launch: none recorded
  and no saved settings yes; a recorded launch or settings from an
  earlier version no; test mode only with its switch
  `[D-first-launch-shows-window]` (draft 39)
- **Phase editor (draft 63)**, in `PhaseEditorRulesTests.swift`: the
  editor's decisions live in pure files (`OffsetParts`, `RotationChoice`,
  `StartReadout`, `DisplayTabs`, and additions to `Phase` and
  `PhaseAvailability`) so these can be unit tests:
  - Offset: stored minutes to number, unit, and before / after / at, in
    the largest unit that divides evenly (120 → 2 hours, 90 → 90
    minutes, 0 → at), and back; limits (1–720 minutes, 1–12 hours) with
    typed values clamped; changing the unit keeps the number, clamped;
    leaving "at" starts from 30 minutes `[D-starts-row]`
  - Rotation: "Only when the phase starts" turns rotation off, and
    minutes or hours turns it back on with the interval it had
    `[D-rotation-row]`
  - Today's start: "Today 6:12 AM (dawn 6:42 AM)", "Today 6:42 AM" at
    exactly dawn, "No dusk today" on a day without one (using the
    far-north dates the `SolarCalculator` tests already use)
    `[D-start-readout]`
  - Messages: which message shows and under which row, with turned off
    winning `[D-phase-status-inline]` (extends `PhaseAvailability`)
  - Display tabs: which tabs show, in what order, and when the row is
    hidden, including one connected display with its own images
    `[D-display-tabs-visibility]`; disconnected displays left out but
    their selections kept `[D-connected-displays-only]`
    `[D-keep-display-settings]`; the selected tab falls back to Shared
    when its display disconnects; captions ("18 images", "Uses Shared",
    "Own · 1 image") `[D-display-tabs]`; outline sizes for portrait,
    standard, and ultrawide displays, one height and capped width
    `[D-display-tab-shapes]`
  - Display sharing: settings from draft 62 copy the app-wide preference
    into every phase; a new phase starts with the same image everywhere,
    and a duplicate copies its phase's setting `[D-sharing-per-phase]`;
    turning on "Use different images on this display" starts from a
    copy of Shared `[D-own-images-start-from-shared]`
  - *Verified* 2026-11-25 by Claude: `bitrig test -package UnitTests`,
    239 of 239 passed, these included (and `AppVersion` with the build
    number at 63).

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
  can run on its own** (draft 33). There are four: Interface tests, Cover
  checks, Memory checks, and from draft 54 Photos checks (from draft 58,
  Sandbox checks too; from draft 63, Phase editor checks). The Interface tests are automated but still
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
  - `[D-input-lands]` **Prove the input landed before trusting a
    result** (author, 2026-11-06). Synthetic input can fail without an
    error, so a run where it did is a failed run, not a finding.
    - **New setups:** before driving an app other than Phases (System
      Settings, Finder), move the pointer once and confirm it on screen:
      the author watching, or a screenshot with the cursor
      (`screencapture -C`). Reading the position back
      (`swift run phases-drive where`) isn't proof by itself; see
      *Findings*.
    - **Every action:** check its effect through something that doesn't
      depend on the click: the diagnostics log, an AX read, the
      wallpaper store, a screenshot. "No change" counts only once the
      click has been shown to land.
    - **AX press isn't a click.** Pressing a System Settings wallpaper
      thumbnail through System Events returns without error and selects
      nothing (*observed* once, 2026-11-06, macOS 27.2). Use real mouse
      events there, as for menus (ERRATA.md "Open here").
    - *Findings* (2026-11-06, Claude, author watching), one display:
      - About 08:33: a one-off CGEvent helper built in `/tmp`, then
        `SyntheticInput.move` from `swift test`, each read back exactly on
        target, but the author saw no pointer move either time
        (*observed*). So a read-back position alone doesn't show the
        pointer moved on screen.
      - About 08:40: `phases-drive move` twice. The author saw the
        pointer jump both times, and `screencapture -C` showed it at each
        target (*verified*).
      - Why the earlier moves didn't show is unknown; the calls were the
        same. The 08:40 run differed in reading the position first and
        screenshotting between moves. Untested.
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
    toolbar height, a relaunch with the window closed
    `[D-reopen-shows-window]`, and the pause banner
    `[D-window-pause-banner]`: the window first opened while paused
    starts below the toolbar; the banner follows 20 outside-change
    pauses `[D-test-outside-change-now]`, resumed from the banner and the
    menu in turn; and a pause from the menu or the Settings switch shows
    no banner (draft 61). Photos albums as image sources, against the
    fake library `[D-fake-photos]`: adding an album or a folder of
    albums, adding one twice, an empty album, shared albums, and denied
    access (draft 54).
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
  - *Modifier keys:* `app.press(_:modifiers:)` presses and releases each
    modifier (Shift, Command, Option, Control) as a key of its own, and
    every press, modified or not, fails the test if any modifier still
    reads held afterward `[D-input-modifier-keys]`. A failure that names
    GitHub issue #39 means a modifier was left down (by the driver, or
    by a key physically held during the run), not that Phases is wrong;
    any click after it may have gone out as a modifier-click.
  - *Which build:* see `[D-ui-test-build-pick]`, next.
- `[D-ui-test-build-pick]` **The UI tests launch the newest Bitrig Debug
  build, by the time in its folder's name, and refuse it unless its
  build number matches the project's.**
  - *How:* each build sits in
    `Builds/<project>/Apps/Debug/Phases.app/<ms since 1970>-<ID>/`; the
    harness takes the folder with the largest time, reads the build's
    `CFBundleVersion`, and compares it with `CURRENT_PROJECT_VERSION` in
    `Phases.xcodeproj/project.xcproj`. On a mismatch the test fails before
    launching anything and says to build again. It prints the path, build
    number, and build time of what it launches. `PHASES_APP` still
    overrides both, unchecked, and the printout says so. The logic is
    pure (`UITests/Sources/PhasesUIDriver/BuildPick.swift`), symlinked
    into the unit tests, and tested there (`BuildPickTests`).
  - *Why:* file dates can't tell Bitrig's builds apart
    `[Q-bitrig-build-dates]`. The build number is the spec draft
    `[D-version-in-settings]`, so the check catches a build from an
    earlier draft; it can't catch code changed since the last build
    within one draft.
  - *History:* until 2026-11-03 the harness compared the `Phases.app`
    bundles' dates; then, until 2026-11-24, the executables' dates. Both
    can tie, so with several builds present a run could test a stale one
    (*verified* 2026-11-03, `stat`; `[L-reopen-event]`; GitHub issue
    #47). Runs before 2026-11-24 may have tested an older build than
    intended; each printed the path it used.
  - *Safety:* before any click or keystroke, the harness checks that the
    test instance of Phases is frontmost; if not, the test fails without
    sending input, so a stray keystroke can't land in another app.
    Clicks outside the window (the menu bar item, its menu) go only to a
    point the test instance owns. The harness rechecks for up to 2 s
    before refusing, since the menu bar can still be rearranging after
    the previous test's instance quits, and the refusal names the
    process that owned the point (author's approval, 2026-11-04;
    `[L-menubar-overflow]`).
  - *Why:* `bitrig test` can't run test targets in a Project.json project
    `[Q-bitrig-test-targets]` (the project became `Phases.xcodeproj` in
    draft 59, with no UI test target either), and the AX API reads these controls
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
  `imageGrid`, `imageFolderName` (now one per Image Sources row),
  `pauseBannerResume`, and from draft 52 `imageSources`,
  `imageSourceCount`, `addImageSource`, `removeImageSource`, and from
  draft 54 `imageSourceLocation` and `photosAlbumList`, and from draft
  61 `pauseSwitch`. They're invisible
  to users, but renaming one breaks the tests.
  - From draft 63: `phaseIsOn` (the name row's switch; draft 62's
    switch already carries it in `PhaseEditor.swift`, but it wasn't
    listed here),
    `phaseNamePencil`, `startTrigger`, `startTime`, `offsetValue`,
    `offsetDirection`, `rotationValue`, `rotationChoice`, `imageHeader`,
    `displayTabs`, `ownImagesCheckbox`, `sharingCheckbox`, and
    `removeMissing`. `phaseName` stays on the name field `[D-name-row]`.
  - From draft 63 the driver also presses Y, Return, and Escape
    (`SyntheticInput.Key`), for renaming in place.

- **Relaunch:** the harness relaunches its own instance by sending it a
  reopen Apple event, as Finder does, rather than `open`, which could
  reach a Phases the author is running. Only the closed-window case is a
  test: the harness always opens the window at launch, so "never opened"
  can't happen under test. That case, minimized, and closed on another
  Space were checked by hand on the experiment build, which used the
  same routing (`[L-reopen-event]`, 2026-11-03).

#### Phase editor tests (draft 63)

UI tests for the redesigned editor (GitHub issue #27), in
`PhaseEditorTests.swift`, fast suite. Written 2026-11-25; first passing
run the same day (see Runs, below):

- **Name in place** `[D-name-row]` (`nameEditsInPlace`): clicking the
  pencil (found by position: it's hidden from accessibility, so it has
  no identifier the harness can see) focuses `phaseName` with its text
  selected; typing "x" and
  pressing Return renames the phase, and the sidebar row reads the new
  name; editing again, typing "y", and pressing Escape puts "x" back.
- **The focus tests still hold** `[D-initial-focus-sidebar]`: the three
  `FocusTests` that type after opening or reopening must pass unchanged
  against the borderless name field; they're the guard that it never
  takes focus on its own.
- **Starts row** `[D-starts-row]` (`startsRowFollowsTheTrigger`):
  choosing Dawn in `startTrigger` for a clock-time phase (no offset)
  gives "at" dawn, with no number or unit; choosing before brings the
  number back at 30; choosing Clock Time shows the time field.
- **Rotation off** `[D-rotation-row]` (`rotationTurnsOffAndBackOn`):
  choosing "Only when the phase starts" hides the number; choosing
  minutes brings it back with the same value.
- **Pinned header** `[D-image-header]`
  (`imageHeaderPinsWhileTheGridScrolls`): after the arrow keys scroll the
  grid well down (as in `gridIsOneTabStopAndArrowsScroll`),
  `imageHeader`'s top is where it was once pinned, just under the
  toolbar, and the grid's top has moved up past it.
- `gridIsOneTabStopAndArrowsScroll` must still pass: the grid stays one
  Tab stop after the new header, and the display tabs are one Tab stop
  of their own.
- Multi-display behavior isn't here: the test window runs on whatever
  displays are connected, so the display tabs are the Phase editor
  checks, below.

##### Runs

- 2026-11-25, first run (Claude, with the author's yes; branch
  `feature/ui-refactor-editor` at `b45b509`; Debug build 63
  `1795653866893-A59A58A0` on every launch, *verified* from the
  printout), fast suite, 295 s: **32 of 36 passed** (*verified*). Every
  older suite passed, the three `FocusTests` included. Of the editor
  tests, `imageHeaderPinsWhileTheGridScrolls` passed; three failed, plus
  the sidebar test:
  - `nameEditsInPlace`: "No element with accessibility identifier
    `phaseNamePencil`". The pencil is hidden from accessibility on
    purpose (VoiceOver sees one field, `[D-name-row]`), which hides it
    from the harness too. A test mistake, not the app's.
  - `startsRowFollowsTheTrigger`: timed out waiting for the offset
    number. The test phase is at a clock time with no offset, so
    choosing Dawn gives "Starts [at] [Dawn]", which hides the number as
    `[D-starts-row]` says. A test mistake.
  - `rotationTurnsOffAndBackOn`: timed out finding "Only when…" in the
    `rotationChoice` menu. The author saw the menu work as intended by
    hand (2026-11-25, *observed*), so it's the test's to fix.
  - `dividerStaysWithin240To320`: dragged far right, the sidebar
    measured 239.5 pt, expected 320 (*verified*). GitHub issue #49
    again (it read 290.5 on build 62). 239.5 is what fits a 790 pt window
    beside the new 550 pt editor minimum (*inferred*): a hypothesis that
    the test's window never reached the 870 pt it asks for. The author
    judged it a test setup issue.
- 2026-11-25, fixing the four (Claude, the author's go-ahead to fix all
  four; same build). Test and driver changes only; the app is unchanged:
  - `nameEditsInPlace` clicks the pencil by where it sits, 18 pt past
    the name field's trailing edge (new driver call
    `click(rightOf:by:)`). Passed on the next run.
  - `startsRowFollowsTheTrigger` now expects "at" right after Dawn, then
    before at 30. The menu tests then failed differently: the *second*
    menu choice in a row found "no items" (the new failure message lists
    what the menu holds), so the menu never opened. A guess: the click
    landed while the first menu was still closing. `chooseMenuButtonItem`
    now waits for its menu to close, plus 400 ms. Both menu tests then
    passed, so the guess fits, but it isn't proven.
  - The sidebar test: a rerun printed the window opening 790 pt wide,
    confirming the hypothesis above (*verified*); the next launch opened
    it 963 pt wide against the screen's right edge, for a saved 1000. So
    the saved frame isn't reliable. `expectSidebarLimitsHold` now widens
    the window through AX to 870 pt when it opens narrower (driver call
    `setWindowSize`). Passed twice alone, but both launches opened wide
    enough, so the resize itself hasn't run in a passing test yet.
  - Then the whole fast suite, 286 s: **36 of 36 passed** (*verified*).

#### Not covered here

- Crossfade timing (the twitch) and the persistent cover's Space behavior
  are the Cover checks. Memory is the Memory checks. The screen-change
  rule `[D-screen-change-no-reroll]` is a unit test.
- The display tabs with more than one display, and the editor's look,
  are the Phase editor checks (draft 63).

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
- *Verified* 2026-11-04 (Claude, `fix/menubar-hit-retry`, tag `archive/fix/menubar-hit-retry`, same app
  build): with the 2 s recheck, the fast suite passed 13 of 13 (116 s).
  The harness doesn't log whether a recheck was needed, so this one run
  doesn't show the recheck was what fixed it.
- 2026-11-24 (Claude, tag `archive/fix/driver-shift-key`, with the author's yes):
  modifiers are now pressed as keys of their own `[D-input-modifier-keys]`
  (GitHub issue #39). Old and new driver checked with `phases-drive`
  (results in TEST-TOOLS.md under that tag). Then the fast suite on
  Debug build 62 (`1795558769061-83C1007C`, every launch, *verified*
  from the printout), 259 s: **31 of 32 passed** (*verified*).
  `FocusTests`, which holds the one Shift press (Shift-Tab), passed;
  no press reported a held modifier.
  - The failure: `dividerStaysWithin240To320`, dragged far right, the
    sidebar measured 290.5 pt, expected 320 (*verified*). Not the
    modifier change: that test presses no keys. It's the symptom of
    GitHub issue #49 (`[L-divider-drag-right]`), whose window-width fix
    is in this build, but at a new width: 290.5, where runs 2 and 3
    read 239.5. A sidebar of 290.5 fits a window about 750 pt wide
    (290.5 + the 460 pt detail minimum, *inferred*), under the 780 pt
    the fix asks for; the window's width wasn't logged. Not rerun.

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
  TEST-TOOLS.md `[L-synthetic-clicks]`, `[L-twitch-measurement]`,
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
  covers in SPEC.md, and anything unexpected recorded in EXPERIMENTS.md
  with a digest line in LEARNINGS.md (until 2026-11-09: "anything
  unexpected in LEARNINGS.md").

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

- Each run's figures in EXPERIMENTS.md "Memory" (in LEARNINGS.md
  "Memory" until 2026-11-09), with the date, macOS version, build, and
  displays, and a digest line in LEARNINGS.md "Memory".

#### Why by hand

- Footprint swings with when macOS chooses to purge, so a pass mark needs
  several runs and judgment. An automated test would be flaky or too
  loose to catch anything.

### Outside change check (draft 37)

- `[D-outside-change-check]` **Pausing for a wallpaper picked elsewhere
  is checked by hand** before it merges, and after any change to
  `WallpaperStoreWatcher`, `OutsideChangeRule`, `PauseNotifier`, or
  `WindowRequest`. It needs the real wallpaper and System Settings, out
  of reach of the unit tests.
  - Build: the newest Bitrig Debug build, crossfades on, diagnostics on
    (log category `store`).
  - 1. Let Phases change once (Change Now): no outside change logged.
  - 2. Pick a still in System Settings › Wallpaper: the cover fades out,
    the pick shows, the menu bar icon gets its pause badge, one
    notification appears, the menu header reads "Paused · wallpaper
    changed in System Settings", and Settings' switch is off with the time.
  - 3. Open and quit System Settings, and switch Spaces: nothing more is
    logged as an outside change.
  - 4. Resume from the notification, the menu, and the Settings switch
    in turn (re-pausing with a pick each time): the phase's image comes
    back at once with a crossfade, the badge goes, the schedule resumes.
  - 5. Pick an Aerial: same as step 2.
  - 6. With restore on, pick a still, then Quit: the pick stays (it's the
    new original).
  - 7. `[D-notice-opens-window]` Click the notification's body (not
    Resume), re-pausing with a pick each time: with the window closed,
    minimized, and open on another Space, the window comes to the front
    on the current Space with the pause banner showing, and Phases stays
    paused. The log (category `reopen`) shows one "window requested by
    notification" per click; a second "by relaunch" line would mean
    macOS also sent a reopen (harmless, but note it in EXPERIMENTS.md
    `[X-notice-click]`; LEARNINGS.md until 2026-11-09).
  - 8. Re-pause with a pick, Quit Phases, then click the notification in
    Notification Center: Phases launches and its window opens with the
    banner. (Added draft 50, GitHub issue #31.)
  - *Verified* 2026-11-08 by the author, steps 7–8 only, one display:
    every body click opened the window in front with the banner. Step 7
    (closed, minimized, another Space) on the build of e6336d6; step 8
    (after a quit) and step 7 again (closed) on the build of d57f146,
    which fixed step 8's window staying behind. Claude checked the log: one notification
    request per click, plus macOS's relaunch when Phases was running;
    no second copy. Run the build Launch Services knows; see
    `[L-notice-click-launches-copy]` in EXPERIMENTS.md `[X-notice-click]`
    (LEARNINGS.md until 2026-11-09).
  - *Verified* 2026-11-06 by the author on the draft 37 build: picks in
    System Settings paused Phases with one notification each, Resume
    worked from the notification and Settings, and the new menu header
    and Resume Schedule item read correctly. Claude checked steps 1–2 in
    the log (detection about 2 s after the pick, no false pause on
    Phases' own sets). Two displays untested.

### Photos checks (draft 54)

- `[D-photos-checks]` **Real Photos behavior is checked by hand before
  merge #2 merges,** and after any change to the Photos source or the
  photo cache. The fake library `[D-fake-photos]` can't show what
  PhotoKit, iCloud, and the wallpaper do. Ask first, naming the checks;
  some change the real wallpaper and need the author at the Mac.
- **The checks**, on the author's library:
  1. **Permission:** a fresh build, Add Photos Album… shows the prompt;
     Don't Allow shows the sheet's message and every Photos row "Can't
     open"; allowing it in System Settings brings them back.
  2. **Adding:** an album, a folder of albums (headings per album), a
     shared album; an album already added selects its row.
  3. **In order:** an album sorted by hand rotates in its Photos order.
  4. **iCloud-only photo:** shows on time at a scheduled change (fetched
     ahead), and with Change Now (late by the download).
  5. **Offline:** Wi-Fi off, a scheduled change falls back to a photo on
     hand, or keeps the wallpaper if none is.
  6. **Edited photo, Live Photo, HEIC, RAW:** each shows as it looks in
     Photos. Phase 0 tested none of these.
  7. **Album changes:** adding, removing, and reordering photos in Photos
     updates the grid while Phases runs; deleting the album shows "Can't
     open"; a deleted photo shows as missing.
  8. **Cache:** the file path of a showing photo is under Application
     Support; it survives a change on another Space and a relaunch;
     Restore original wallpaper on quit puts back the original.
  9. **Outside change:** picking a wallpaper in System Settings while a
     photo shows still pauses Phases, and Phases' own photo changes
     don't `[D-outside-change-rule]`.
- Record results with date and build in this section, as the other
  checks do.
- *Verified* 2026-11-12 by the author, builds from 16:44 to 22:26 local
  on `feature/33-photos-albums` (draft 53 there, before the move to 54),
  Claude reading the diagnostics log: **all nine pass.** Notes, with the
  records in EXPERIMENTS.md `[X-33-photos-checks]`:
  - 1: a grant made in System Settings reached Phases only after a
    relaunch `[L-photos-grant-needs-relaunch]`; each new build needs the
    grant again `[L-photos-grant-per-build]`.
  - 4: on time when fetched ahead; about 1 s late with Change Now.
  - 5: fell back, but kept landing on the same photo
    `[L-photos-offline-check]`. Draft 54 skips what's showing; not yet
    checked by hand.
  - 7: passed after a fix for a photo from a just-deleted album being
    shown `[L-photos-deleted-album-race]`.
  - 9: a System Settings pick paused Phases; after resuming, two of its
    own photo changes didn't.
  - The checks ran before the merge with draft 53's In order
    `[D-in-order-remembers]`, which changed how fetching ahead picks.
    Check 4 is worth repeating on the merged build.
- *Verified* 2026-11-13 by the author, on screen, and by Claude from the
  diagnostics log, draft 54 build (`87ef762`, merged with `main`):
  checks 4 and 5 again. 4: fetched ahead 30 s early (0.39 s) and set on
  the minute; Change Now fetched in 0.91 s and showed about 1 s late.
  5: offline, each failed photo fell back to a cached one, alternating
  between the two on hand instead of repeating
  `[L-photos-offline-check]`. The UI suite passed 29 of 29 (247 s) on
  the same build.

### Phase editor checks (draft 63)

- `[D-editor-checks]` **The redesigned phase editor is checked by hand
  before it merges,** and after any change to the display tabs, the
  image header, or the Starts row. The UI tests can't add or remove
  displays, and nothing automated judges how the editor looks. Ask
  first, naming the checks. Checks 1–4 need several displays: real
  ones, or the author's tool that adds displays that aren't physically
  connected.
  - Build: the newest Bitrig Debug build, diagnostics on.
- **The checks:**
  1. **Tab row shows and hides** `[D-display-tabs-visibility]`: one
     display, the row is hidden; two or more, it shows Shared, the
     divider, then each display in macOS's order; back to one display
     after giving it its own images, the row shows Shared plus that
     display.
  2. **Shapes** `[D-display-tab-shapes]`: a rotated (portrait) display
     is drawn tall and an ultrawide wide, all at one height; a long name
     wraps, then truncates at the end, with the full name in the
     tooltip.
  3. **Overflow** `[D-display-tabs]`: with enough displays to overflow
     at the minimum window width, Shared and the divider stay put, the
     other tabs scroll sideways with a trackpad, and the edge fades on
     each side with tabs out of view. Note whether a mouse's scroll wheel
     scrolls the row without ⇧ (*recalled* that it doesn't; record what
     happens).
  4. **Disconnect and reconnect** `[D-connected-displays-only]`: with a
     display's tab selected and its own images chosen, disconnect it:
     Shared is selected and the tab is gone. Reconnect: the tab is back,
     "Own · N images", same selection.
  5. **Sharing checkbox** `[D-sharing-per-phase]`: dimmed when fewer than
     two connected displays use Shared; with two, turning it on gives the
     displays different images at the next change, per phase. A Mac
     upgraded from draft 62 with **Different picks per display** shows
     it on in every phase.
  6. **Own images** `[D-own-images-start-from-shared]`: turning on "Use
     different images on this display" shows the Shared selection
     already chosen, and the wallpaper doesn't change; turning it off
     shows "Uses the Shared images".
  7. **Pinned header** `[D-image-header]`: scrolled down a long grid, the
     tabs, checkbox, count, and Select All / Select None stay in view,
     with no thumbnail showing through; with a missing image, Remove
     Missing is in the header and works.
  8. **Starts row and messages** `[D-starts-row]` `[D-start-readout]`
     `[D-phase-status-inline]`: each trigger's row reads as a sentence;
     a dawn phase's "Today …" line matches Settings' dawn time minus
     the offset; with Location off, the message and Open System
     Settings… replace that line; a phase turned off shows its message
     under the name row only.
  9. **Fit and look** `[D-window-min-size]` `[D-editor-layout]`: at the
     minimum window width, the dawn Starts row and "Any | Light Mode |
     Dark Mode" fit without clipping; Light and Dark Mode both read
     well; the branding panel's top lines up with the name row
     `[D-brand-inset]`.
  10. **VoiceOver:** the name field reads "Name", the switch "Use this
      phase", the display tabs as one control with each tab's name,
      caption, and "selected".
- Record results with date and build in this section, as the other
  checks do.

#### Runs

- 2026-11-25, checks 1–4 (Claude, with the author's yes; Debug build 63
  `1795653866893-A59A58A0`, a test-mode copy, so no real wallpaper or
  settings touched). Displays: the built-in (1300 × 845) and BetterDisplay
  virtual screens, driven through BetterDisplay's command line (the author
  turned its CLI integration on): "Virtual 16:10" (1366 × 768), then four
  made for the run, "Phases Test Portrait" (9:16), "Phases Test
  Ultrawide Display With a Deliberately Long Name" (21:9), "Phases Test
  4:3", and "Phases Test 16:9". Evidence is screenshots of the test
  window (*observed*), except where noted. Diagnostics weren't on.
  - **Check 1, passed.** Two displays: Shared, the divider, Built-in,
    Virtual 16:10, in `NSScreen.screens` order. Down to one display
    using Shared: the row hidden. Down to one display with its own
    images: Shared plus that display.
  - **Check 2, passed, with one flaw.** Portrait drawn tall, ultrawide
    wide, every outline one height; the long name wraps to two lines,
    then truncates at the end ("Ultrawide Displa…"); hovering shows the
    full name as a tooltip. *Flaw:* a tab whose name wraps is taller
    than the others, and the row centers tabs vertically, so its outline
    and caption sit higher than its neighbours'.
  - **Check 3, mostly passed.** At 790 pt (the minimum) six displays
    overflow; Shared and the divider stay put; arrow keys move the
    selection and scroll it into view; the trailing edge fades with tabs
    out of view there, the leading edge once tabs are hidden on that
    side. *Flaw:* the chosen tab scrolls only just into view, so it can
    sit under the 24 pt trailing fade. *Not settled:* a synthetic
    two-finger swipe (new `phases-drive swipe`, continuous pixel deltas
    with began/changed/ended phases) didn't scroll the row, and neither
    did a synthetic mouse wheel without ⇧ (`phases-drive wheel`). Per
    `[D-input-lands]` neither is a finding: nothing shows the swipe was
    delivered as a real trackpad's would be. A real trackpad and mouse
    are the author's to try. After Tab / Shift-Tab, and after a click on
    a tab, Right Arrow worked every time (5 presses, *observed*).
    - **Finding, open:** three Right Arrow presses at about
      23:10:00–23:10:08 did nothing, and the author heard beeps then
      ("about eleven ten and a few seconds past", *observed* by the
      author; the screenshot after them is stamped 23:10:08). A beep is
      macOS refusing an unhandled key, so the presses reached Phases and
      nothing took them, while the row was drawn with focus. Before them:
      a click on a tab (23:08), the AX resize to 790 pt, then the
      synthetic swipe and wheel over the row. *Hypothesis, untested:* the
      resize or the scroll events left focus drawn on the row while key
      focus was elsewhere. The unified log showed no beep entry.
      Reproduce before fixing.
  - **Check 4, passed.** Virtual 16:10's tab selected with its own 4
    images, then disconnected: the row hid (one display left, using
    Shared), with Shared's grid shown. Reconnected: the tab back, "Own ·
    4 images", all 4 still chosen. The tab came back *selected*: the
    editor remembers the chosen display while it's away
    (`DisplayTabs.selection` falls back to Shared only while the tab is
    missing). The spec doesn't say whether it should.
  - Also seen: at one moment just after the AX resize to 790 pt, the
    row's focus ring ran past the image box's right edge to the
    window's; on the next screenshot it fit. Taken as mid-resize, not a
    finding.
  - **Both flaws fixed** the same day (author's go-ahead): the tab row
    is top-aligned, and the chosen tab scrolls to the row's center
    instead of just into view. Rechecked on Debug build 63
    `1795666506719-097FA50C` at 790 pt with the same six displays
    (*observed*, screenshots): every outline and name level, wrapped or
    not; the ultrawide, chosen by arrow keys, centered clear of both
    fades; at the far end the last tabs fully in view and no trailing
    fade. The four test displays were then discarded.
  - **Reconnect, changed** (author, 2026-11-25): a reconnected display's
    tab now comes back unselected, Shared staying chosen
    (`[D-connected-displays-only]`). Rechecked on Debug build 63
    `1795666739618-64C3AE82`: Virtual 16:10's tab chosen, disconnected,
    reconnected; Shared chosen (*observed*).
- 2026-11-25, checks 5–10 (Claude, with the author's yes; Debug build 63
  `1795666739618-64C3AE82`, test mode, diagnostics on; the built-in
  display and Virtual 16:10; 790 pt window; a 60-image copy of the test
  folder). Screenshots throughout (*observed*).
  - **Check 5, passed in part.** With two displays using Shared the
    sharing checkbox is on and live; with Virtual 16:10 on its own images,
    dimmed. *Upgrade:* launched with a draft-62 store passed as launch
    arguments (`-phases <data>` holding one old phase with no
    `displayMode`, plus `-displayMode differentPerDisplay`); the phase
    opened with "Each display shows a different image" on. One phase,
    not several. *Not run:* "different images at the next change," since
    test mode never sets the wallpaper; that needs a real run.
  - **Check 6, passed.** Turning on own images for Virtual 16:10 showed
    Shared's 60 already chosen ("Own · 60 images"), and the branding
    panel's picture didn't change (test mode sets no wallpaper, so the
    panel is the evidence). Turning it off showed "Uses the Shared
    images".
  - **Check 7, passed.** Wheel-scrolled down the grid: the tabs,
    checkbox, count, and Select All / Select None pinned under the
    toolbar, no thumbnail showing through. One image file deleted, then
    the window closed and reopened (the library rescans on open; it
    didn't notice the deletion while open): "1 selected image is
    missing" with Remove Missing in the header; clicking it cleared the
    line, 59 of 59. The synthetic wheel scrolled the editor, so
    `phases-drive wheel` is shown to land (TEST-TOOLS.md), which makes
    check 3's wheel result a finding: a plain mouse wheel doesn't scroll
    the display tabs sideways, as recalled.
  - **Check 8, passed in part.** Always: "Used when no timed phase
    applies." Dawn, at: "Starts [at] [Dawn]", "Today 6:17 AM"; before:
    "[30] [minutes] [before] [Dawn]", "Today 5:47 AM (dawn 6:17 AM)",
    matching Settings' civil dawn, 6:17 AM. Turned off: "This phase is
    turned off, so it's skipped." under the name row only. *Not run:*
    Location off (it means changing the Mac's privacy settings). *Seen:*
    the trigger menu lists Always, Clock Time, Dawn, Dusk, where
    `[D-starts-row]` lists Clock Time, Dawn, Dusk, and Always; whether
    the spec meant an order isn't clear.
  - **Check 9, passed.** At 790 pt the dawn Starts row and "Any | Light
    Mode | Dark Mode" fit unclipped; Dark and Light Mode both read well
    (the Mac switched to Light Mode for one screenshot and straight
    back); the Settings header's top lines up with the branding panel's.
  - **Check 10, read from the accessibility tree, not with VoiceOver
    running.** The switch: "Use this phase". The display tabs: one radio
    group, each tab "name, caption", Shared selected. *Gap:* the name
    field's only label is its placeholder, "Name" (no description), so
    VoiceOver likely reads "Old, text field" without "Name"
    (*recalled* that placeholders are spoken only when empty; not
    tested). `[D-name-row]` says it's labelled "Name". The radio group
    has no name of its own either. Not fixed yet.
- 2026-11-25, follow-ups (author's answers; branch
  `fix/editor-spec-gaps`):
  - **Trackpad:** scrolling the display tabs sideways works with a real
    trackpad (*observed* by the author). Check 3 is complete.
  - **The arrow-key beeps** (check 3's open finding): dropped by the
    author, not pursued.
  - **Fixed to match the spec:** the name field carries the
    accessibility label "Name" (read back from the accessibility tree,
    *observed*); the trigger menu lists Clock Time, Dawn, Dusk, Always,
    as `[D-starts-row]` does (screenshot, *observed*). Debug build 63
    `1795667585641-33B38DA7`: unit tests 239 of 239, and the
    `PhaseEditorTests` and `FocusTests` UI tests 8 of 8 (94 s,
    *verified*).
  - *Left behind:* the image copy,
    `~/Library/Caches/PhasesUITests/Phases Editor Check Images` (deleting
    it was refused).
  - *Process note:* the spoken warnings before and after driving
    (`[D-hands-on-checks]`) were missed for the first clicks of this
    sitting and used from the key presses on.
- 2026-11-26, name row polish (branch `fix/editor-spec-gaps`; Claude
  measured screenshots of test copies, 2× pixels halved to points):
  - **Alignment:** the name's capitals sat 1.25 pt above the switch and
    the pencil's square 1.5 pt below the capitals. A first fix (a
    cap-height guide on the name, caa133e) moved nothing (*verified*,
    the author's screenshot). Putting the field on the sizing text's
    baseline and centering the pencil on its cap height brought all
    four (capitals, pencil, "On", switch) within 0.5 pt (*verified*).
  - **Pencil highlight:** `.accessoryBarAction` drew a gray box at rest
    that didn't change under the pointer; `.accessoryBar` shows nothing
    at rest and a highlight under the pointer (*verified*, screenshots
    with the pointer moved by `phases-drive move`).
  - **Gap:** the highlight started 17.5 pt after the name's last letter;
    5.5 pt nearly touched it; 9 pt settled (author asked to pull it in).
    While editing, the insertion point fits after the last letter
    (*observed*, a screenshot frame caught it).
  - **UI tests:** `nameEditsInPlace` first failed at launch, before any
    input, timing out on the test copy's menu bar item while the
    author's own copy was running. With it quit, it passed (*observed*;
    hypothesis: the author's copy's item crowded the menu bar,
    `[L-menubar-overflow]`, not tested). One rerun to read that error
    was started without the spoken warning (it failed at the same
    launch step, sending no input).
  - At 9 pt, `PhaseEditorTests` and `FocusTests` 8 of 8 (93.9 s,
    *verified*). An earlier run of the same build was stopped after the
    author heard a system beep and their own input may have landed in
    it; which step beeped wasn't found.

### Sandbox checks (draft 58)

- **When:** after any change to the entitlements `[D-sandbox-entitlements]`,
  to how Phases reads the wallpaper store, sources, or the original
  wallpaper, and before a change to the sandbox merges. Unit tests cover
  the decisions (`SystemWallpaperCheckTests`, the refusal cases in
  `FolderScanTests`), but only a launched, sandboxed build shows what
  macOS allows. Ask first, naming the checks; most change the real
  wallpaper and need the author at the Mac.
- **Which build's sandbox:** a Debug build's sandbox also reads
  `~/Library/Caches/PhasesUITests/` `[D-debug-test-folder]`. That changes
  nothing these checks look at, but a check of exactly what ships runs
  on a Release build.
- **Setup:** diagnostics on; read the log with
  `/usr/bin/log show --last 10m --style compact --predicate 'subsystem == "PhasesDiag"'`.
- **The checks:**
  1. **Settings:** phases, sources, and options are as they were.
  2. **Aerials left alone:** an Aerial on one display, a still on
     another. No "can't read the wallpaper store" line (`restore`,
     `store`); `store` says "watching the store: N entries". Quit with
     Restore on: the Aerial display logs "left alone on quit: system
     wallpaper", the other "restored". This is the check that the store
     exception works.
  3. **Folder sources** open, and still open after quit and relaunch
     (the log says "found by its bookmark").
  4. **Photos:** Change Now onto a Photos phase, an iCloud-only photo
     among them if one is handy. A failure only on iCloud photos points
     at a missing `network.client`.
  5. **Crossfade** on: Change Now, switch Spaces and back, change a
     display's resolution. No "cover: no surface" in `cover`.
  6. **Restore on quit** from an original outside every source (in
     `/System/Library/Desktop Pictures/` or `~/Downloads`): it comes
     back, logged "restored", not "file no longer exists".
  7. **Links:** a symlink or alias to an image outside the folder is
     missing from the grid, and `sources` logs "not permitted to read
     <name>"; one to an image inside the folder shows.
  8. **Location:** a dawn/dusk phase gets times once allowed.
  9. **Outside change:** a System Settings pick pauses Phases.
- **Not in the list:** a change missed while locked being applied at
  unlock has no hand-made way to produce it, and going back to an
  unsandboxed build isn't supported (SPEC.md `[D-sandbox-settings-move]`).
- Record results with date and build in this section.
- *Verified* 2026-11-22 by the author, build from `feature/19-sandbox`
  (draft 58), diagnostics on: **all nine pass**, with nothing failing in
  the log. 1: the container couldn't be inspected (TEST-TOOLS.md
  "Diagnostics"), so settings were checked in the app. 4: whether an
  iCloud-only photo was shown wasn't recorded. Details in SPEC.md
  "Hands-on checks of the first sandboxed build".
- 2026-11-22, build from `feature/xcode-project` (draft 59, bundle ID
  `com.robertmohns.phases`, after the settings move): checks 1–3
  **deferred** by the author to GitHub issue #43. The launch log showed
  the store read ("watching the store: 988 entries"), and the author
  *verified* settings and folder sources after Locate… in the app
  (SPEC.md `[D-bundle-id-settings-move]`).

## When a fixed bug comes back

What to do first when a bug we've already fixed shows up again. Each
procedure names the quirk it's about; the quirk's entry in ERRATA.md
points back here. Until 2026-11-09 this was ERRATA.md "Diagnostic
procedures", and its first line read: Logging is switched on and read as
described under "Diagnostics" in TESTING.md `[D-diagnostics-switch]`.

Logging is switched on and read as described under "Diagnostics" in
TEST-TOOLS.md `[D-diagnostics-switch]`.

- **Crossfade twitch returns:** measure before changing when the cover
  comes off `[D-persistent-cover]`. (Until 2026-11-09 this said "before
  changing the delay", the settle delay draft 33 removed; see
  EXPERIMENTS.md `[X-cover-settle]`.) Record
  the screen at 30 fps or more and step through frame by frame: when the
  wallpaper is set, when the cover comes off, and when macOS's motion
  plays `[Q-wallpaper-motion-delay]`. How to record and step through
  frames: TEST-TOOLS.md `[L-twitch-measurement]`.
- **Toolbar grows tall again:** log `frame.height −
  contentLayoutRect.height` and check whether the toolbar is still
  icon-only and whether SwiftUI has replaced it with its own
  `[Q-empty-toolbar-66pt]`.
- **Sidebar width limits vanish again:** don't retry the ordering fix.
  Switch diagnostics on; the `sidebar` category logs each limits pass (or a
  "SKIPPED limits" error), each restore and which hook caught it, a
  swapped-in item, and each change in the split view's limits or an
  out-of-range width. Check whether SwiftUI swaps in a new split view
  controller or item, and what resets `minimumThickness` /
  `maximumThickness` `[Q-split-item-rewrite]`. The categories and how to
  read them: TEST-TOOLS.md "Diagnostics".
- **Accessibility labels:** check with the AX API or Accessibility
  Inspector, not System Events `[Q-system-events-ax]`. Why System Events
  can't be trusted here: that quirk, in TEST-TOOLS.md "Tools".
