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
- `ImageGridNavigation`: arrow-key movement `[D-grid-one-tab-stop]`,
  including headings as stops, the column kept across them, and ←/→
  (and ⌥←/⌥→) folding headings `[D-grid-collapse]` (draft 64)
- `GridOutline` (draft 64): what the grid shows with headings collapsed
  `[D-grid-collapse]`: sections and subheadings, flat subheadings, the
  saved heading keys `[D-grid-collapse-saved]`, counts under a heading,
  ⇧ ranges that skip collapsed images, and where the cursor goes when
  its section folds
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
- `[D-doc-check]` **A unit test checks the docs' tags and references, and
  keeps `docs/INDEX.md` current.** `DocIndexTests` fails when:
  - code or a doc cites a tag that no doc defines. A tag mentioned only
    as replaced, retired, or renamed is history, not missing; the index
    lists it under "Retired tags".
  - a tag is defined twice. An `[L-…]` finding's digest entry in
    LEARNINGS.md and its full entry in the experiment's record count as
    one definition, and a promoted or demoted entry's one-line pointer
    doesn't count.
  - a `FILE.md "Title"` reference matches no heading in that file.
    `SPEC.md`, `TESTING.md`, and `EXPERIMENTS.md` stand for the front page
    plus its folder (`docs/spec/`, `docs/testing/`, `docs/experiments/`),
    so references written before a split still resolve `[D-refs-by-id]`.
    A paragraph that names an `archive/…` tag describes an old layout and
    isn't checked.
  - a Markdown link to a file in the repository points nowhere.
  - a section title appears twice in the spec (SPEC.md and `docs/spec/`),
    so a quoted title always names one place.
  When `docs/INDEX.md` is out of date the test rewrites it and fails
  once, so the new index is looked at and committed with the change.
  - *How a definition is found* (`DocIndex.swift`): the tag in backticks
    opens a line (after any list marker, number, heading marks, or table
    bar), followed by the statement itself (bold text, a capital letter,
    a colon, or nothing). For a tag with no such line, its first mid-line
    definition counts: right after a bold phrase, or opening a sentence.
  - *Why:* nothing learned is ever dropped (CLAUDE.md). The docs get
    split and moved as they grow; this makes "nothing lost" something the
    tests check rather than something we hope for (author, 2026-11-27,
    approving Claude's proposal). The test only reads files; it never
    launches Phases `[D-tests-unhosted]`.

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

### Where each check's procedure is

Each check's procedure (what it is, when, setup, the steps, afterward,
its record) is its own file in `docs/testing/`, moved there word for
word on 2026-11-27. The rules above apply to all of them.

| Check | File |
|---|---|
| Interface tests (draft 31) | [testing/interface-tests.md](testing/interface-tests.md) |
| Cover checks (draft 33) | [testing/cover-checks.md](testing/cover-checks.md) |
| Memory checks (draft 32; covers, draft 33) | [testing/memory-checks.md](testing/memory-checks.md) |
| Outside change check (draft 37) | [testing/outside-change-check.md](testing/outside-change-check.md) |
| Photos checks (draft 54) | [testing/photos-checks.md](testing/photos-checks.md) |
| Phase editor checks (draft 63) | [testing/phase-editor-checks.md](testing/phase-editor-checks.md) |
| Sandbox checks (draft 58) | [testing/sandbox-checks.md](testing/sandbox-checks.md) |

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
