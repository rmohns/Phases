# Phases testing: Interface tests

Part of the testing docs. [TESTING.md](../TESTING.md) has the rules every
hands-on check follows (`[D-hands-on-checks]`: any check alone, who runs
it, proving the input landed), the unit tests, and what to do when a
fixed bug comes back. Moved here word for word from TESTING.md
"Hands-on checks" on 2026-11-27.

## Interface tests (draft 31)

### What they are

- A second Swift package, `UITests/`, that launches the built Phases and
  drives its window the way a person would. It guards the regressions in
  ERRATA.md "Regressions found so far"; each row's "Guarded by" names its
  test.

### When

- Before merging any change to the window or the code it calls, and for
  every regression guard that's a UI test. Add the slow suite when the
  change touches the sidebar.

### Setup and running

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

### How the tests work

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
  - From draft 64: `gridHeading`, on every heading in the image grid
    (one per heading; tests tell them apart by label, the heading's
    name) `[D-grid-collapse]`. The driver also presses ← (`leftArrow`)
    and clicks with modifiers held (`app.click(_:modifiers:)`, for
    ⇧-click and ⌥-click), each modifier pressed as a key of its own and
    checked afterward as `press` does `[D-input-modifier-keys]`.

- **Relaunch:** the harness relaunches its own instance by sending it a
  reopen Apple event, as Finder does, rather than `open`, which could
  reach a Phases the author is running. Only the closed-window case is a
  test: the harness always opens the window at launch, so "never opened"
  can't happen under test. That case, minimized, and closed on another
  Space were checked by hand on the experiment build, which used the
  same routing (`[L-reopen-event]`, 2026-11-03).

### Phase editor tests (draft 63)

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

#### Runs

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

### Grid collapse tests (draft 64)

UI tests for collapsible grid headings (GitHub issue #37), in
`GridCollapseTests.swift`, fast suite. Written 2026-11-26 by Claude;
first run the same day (see Runs, at the end of this section). A heading is one AX element with identifier
`gridHeading`, its name as label, and "Expanded" or "Collapsed,
<count>" as value.

- **Click** `[D-grid-collapse]`
  (`clickingAHeadingFoldsItsImagesAndShowsItsCount`): clicking the first
  source's heading removes its images from the grid and its value reads
  "Collapsed, 60 images"; clicking again brings them back.
- **Keyboard** `[D-grid-one-tab-stop]`
  (`keyboardFoldsAndUnfoldsAHeading`): from the first image, ← moves to
  its heading; Space collapses and expands it; ← collapses, → expands;
  → on the open heading moves to the first image, which Space selects.
- **Select All** (`selectAllIncludesCollapsedImages`): with the first
  source collapsed, Select All gives "64 of 64 selected" and the heading
  reads "Collapsed, 60 of 60 selected".
- **⇧-click** (`shiftClickRangeSkipsCollapsedImages`): three sources,
  Nested (2), the second folder (4, collapsed), the big folder (60);
  Nested Image 01 then ⇧-click Test Image 01 selects 3, not 7.
- **Kept** `[D-grid-collapse-saved]`
  (`collapsedHeadingStaysAfterTheWindowCloses`): collapsed, the window
  closed and reopened by a relaunch, the heading is still collapsed.
  Kept after quitting isn't testable here, since test mode erases its
  settings at launch `[D-ui-test-mode]`; that's a hand check.
- `ImageSourcesTests/arrowKeysCrossSources` changed with this draft:
  Right from the first source's last image now lands on the second
  source's heading, so it presses Right once more.
- **Not covered by UI tests** (test mode's sources never include
  subfolders, and the fake Photos library has no folders here): ⌥-click
  and ⌥←/⌥→ on a source with subheadings, subheadings' icons, a Photos
  folder's album subheadings, and the triangle's look. Those are hand
  checks, with a folder that includes subfolders, and are covered by
  the unit tests' logic.

#### Runs

- 2026-11-26, first run (Claude, with the author's yes; branch
  `bitrig/add-collapsible-folders-and-albums`; Debug build 64
  `1795717573778-874A84D1` on every launch, *verified* from the
  printout; the author's own copy of the same build was running
  alongside, not in test mode), fast suite, 343 s: **40 of 41 passed**
  (*verified*), all five `GridCollapseTests` and the changed
  `arrowKeysCrossSources` among them.
  - `ImageSourcesTests/eachSourceHasAHeadingInOrder` failed: "Second
    Image 01.png" wasn't in the grid when the second source's heading
    first appeared. The test assumed a section's images load with its
    heading. Likely cause (*inferred*, not proven): from draft 64 Down
    stops on the heading, so the window scrolls only to the heading and
    the lazy grid hasn't loaded the images under it; until draft 63
    Down skipped the heading and landed on the image. A test
    assumption, not the app's. The test now presses Down up to 3 more
    times until the image appears, then reads both positions. Re-run
    alone: passed (*verified*, same build).
- Also *verified* by the author the same day, by hand with real Photos
  (the build started with `open`), of the hand checks Claude listed
  (album icons, a Photos folder's album subheadings, ⌥-click and
  ⌥←/⌥→, collapsed counts, the triangle, kept after quitting):
  "Functionally, all that seems to work" (*observed*, per-check results
  not recorded). The tightened spacing looked right ("Beautiful").

### Not covered here

- Crossfade timing (the twitch) and the persistent cover's Space behavior
  are the Cover checks. Memory is the Memory checks. The screen-change
  rule `[D-screen-change-no-reroll]` is a unit test.
- The display tabs with more than one display, and the editor's look,
  are the Phase editor checks (draft 63).

### History

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
