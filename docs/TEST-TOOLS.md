# Phases — Test tools

The tools Phases is tested with, and what we know about them: the input
driver, diagnostic logging, test-only launch arguments, the quirks of
the tools themselves, and ad hoc techniques for driving and measuring
the Mac. TESTING.md is the test process: what to check, when, and how a
run goes. Sorting test: is this about how a tool works, or about what we
do with it? A tool → here. What we do → TESTING.md.

Decisions here carry `[D-…]` tags and follow the same approval rules as
TESTING.md's. Tool quirks keep the `[Q-…]` tags they had in ERRATA.md,
and findings keep their `[L-…]` tags, so code comments still find them.
Until 2026-11-09 this content was split across TESTING.md "Shared
tools", ERRATA.md "Tools", and LEARNINGS.md "Driving and measuring the
Mac in tests" (tag `archive/docs-before-refactor`).

## Shared tools

Used by both groups. Reference, not steps.

### Input driver

- `[D-input-driver]` **All mouse and keyboard driving goes through
  `PhasesUIDriver`'s `SyntheticInput`** (author, 2026-11-06): the UI
  tests, and one-off driving from the shell with `phases-drive`. No
  new input helpers; if something's missing (a key, a right-click), add
  it to `SyntheticInput` and `phases-drive`.
  - From `UITests/`: `swift run phases-drive where`,
    `… move <x> <y>`, `… click <x> <y>`, `… key tab|down|x [shift]`.
    Points are global, top-left origin, the same as accessibility
    positions. It's a hands-on check `[D-hands-on-checks]`; prove each
    action landed `[D-input-lands]`.
  - *Why:* on 2026-11-06 Claude wrote a throwaway CGEvent helper to
    click in System Settings instead of using the driver, then lost time
    working out whether the helper was why the click failed. A tool with
    a history is easier to trust and fix. `phases-drive` exists because
    `SyntheticInput` could only run inside `swift test`, which made a
    one-off helper look easier.
  - Its functions are `package` access, so the tests and `phases-drive`
    can call them and nothing outside `UITests/` can.

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
    returning to its Space; `[D-persistent-cover]`), and window layout
    (category `window`: the sidebar's and detail pane's top safe area,
    where the pause banner sits and when it goes
    `[D-window-pause-banner]`; under `sidebar`, the title area's height
    when the toolbar is installed, and each scroll view's top inset and
    scroll position when the window becomes key or the helper runs,
    logged only when they change). What to log when chasing a platform bug is in
    TESTING.md "When a fixed bug comes back" (until 2026-11-09, ERRATA.md
    "Diagnostic procedures").
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
    harness makes one with 60 images and a long name) as its one image
    source, or several folders given as a list,
    `-PhasesUITestImages '("<path 1>", "<path 2>")'`, as its sources in
    that order `[D-image-sources]` (draft 52). The harness makes a second,
    small folder for the tests that need two sources;
  - `[D-fake-photos]` never touch the Photos library (draft 54). With
    `-PhasesUITestPhotos <path>`, Phases uses a **fake Photos library**
    made from a folder the harness builds: each subfolder is an album, a
    subfolder of subfolders is a folder of albums, and a folder named
    `Shared` holds shared albums. Photo IDs are made from the file names.
    Everything above PhotoKit (the Add Photos Album… sheet, rows,
    headings, counts, saved names, In order, the cache and fetching
    ahead) runs as it would for real; only the PhotoKit calls are
    replaced. `-PhasesUITestPhotosDenied YES` makes the fake library
    refuse access. Without `-PhasesUITestPhotos`, test mode has no
    Photos library at all and never asks for access.
    - *Why:* every new build asks for Photos access again
      `[L-photos-new-build-asks]`, and the real library is the author's.
      Real PhotoKit is checked by hand (TESTING.md "Photos checks").
  - leave the window closed at launch, as usual. The UI tests open it the
    way the author does, from the menu bar item's Open Phases…, through
    AX actions. *Why:* opening it at launch instead skipped the focus and
    sidebar-watch bugs, so their tests passed with the fixes removed
    (2026-10-29). If Phases still isn't frontmost
    `[Q-launch-activate-refused]`, the tests bring it forward through the
    AX API;
  - never ask for location `[D-test-no-location-prompt]`;
  - never count as a first launch `[D-first-launch-shows-window]`, even
    though its store starts empty, unless launched with
    `-PhasesUITestFirstLaunch YES` as well. That switch makes the launch
    a first launch, so a test can check the window opens on its own.
    *Why:* every test-mode launch starts with no settings, so without
    this every test would start with the window already open.
  - `[D-test-paused-by-outside-change]` start paused as if the
    wallpaper had just been changed in System Settings, when launched
    with `-PhasesUITestPausedByOutsideChange YES` as well, with no
    notification. Ignored outside test mode. *Why:* the pause banner's
    layout bug showed only with this pause's two-line reason; the menu
    pause's one line never triggered it, and a real outside change
    would mean changing the real wallpaper (author's approval,
    2026-11-07, GitHub issue #30).
  - AppKit's own saved window frame and sidebar layout live in the normal
    settings, outside the separate store. The UI tests record both before
    each launch, clear them so the test starts from the defaults, and put
    them back after quitting. A test can ask for a window size instead
    of the default; the harness then saves that frame in place of the
    cleared one before launch, and the same restore puts the author's
    back (added 2026-11-07, author's request, for the pause banner's
    line wrap).
    - *Why:* on 2026-10-29 a revert-and-check run collapsed the sidebar,
      AppKit saved that, and the author's own Phases window would have
      opened with no sidebar and no way to reopen it. The key was reset by
      hand.
  - *Cost:* while tests run, two Phases icons can show in the menu bar.

## Tools

- `[Q-system-events-ax]` **System Events (AppleScript) doesn't report
  SwiftUI button descriptions (macOS 27).** *Verified* 2026-10-28: for the
  + / − buttons, System Events' `description` returned only "button" and
  found no AXDescription, while the AX API (`AXUIElementCopyAttributeValue`)
  read "Add Phase" / "Delete Phase" from the same buttons. Check
  accessibility labels with the AX API or Accessibility Inspector, not
  System Events. Whether an icon-only `Label` wrapped in
  `.frame`/`.contentShape` loses its title on its own is *unverified*;
  `[D-footer-ax-labels]` sets the label explicitly either way.
- `[Q-undo-menu-ax]` **Edit › Undo and Redo, read through the AX API,
  don't match what the menu shows, and a menu that wasn't opened by a
  click keeps stale enabled states (macOS 27.2).** On screen, after
  removing an image source, the item reads Undo Remove “<folder>”, and
  a long folder name is truncated in the middle, which can cut "Remove"
  itself; how much depends on the screen (*verified* 2026-11-12 by the
  author, on screen). Through AX the items read plain "Undo" and
  "Redo", open or closed. Redo read disabled right after an undo until
  the Edit menu was opened with a real click; opening it with an AX
  press didn't refresh it (*verified* 2026-11-12, four runs of
  `undoPutsBackASourceRemovedWithTheMouse`, LEARNINGS.md
  `[L-closed-menu-stale]`).
  - *Workaround:* the undo test chooses menu items with real clicks,
    through `PhasesApp.chooseMenuItem` `[D-input-driver]`, and matches
    only "Undo" or "Redo" plus enabled, never the action name. Phases
    leaves macOS's truncation alone (author, 2026-11-12).
- `[Q-bitrig-test-targets]` **`bitrig test` doesn't see test targets in
  Project.json projects** ("has no test targets", *verified* 2026-10-28),
  and there's no generated Xcode project to hand to `xcodebuild`. That's
  why the unit tests are a Swift package run with `swift test` (see
  TESTING.md). *Re-verified* 2026-10-29 with a
  `bundle.ui-testing` target and a scheme naming it in `testTargets`: same
  message. So the Interface tests drive the app through the AX API instead of
  XCUITest `[D-ui-test-runner]`.

- `[Q-launch-activate-refused]` **A menu bar app launched in the
  background can't bring itself to the front with `NSApp.activate()`
  (macOS 27.2).** *Verified* 2026-10-29: in test mode, Phases called it
  when its window appeared, and the active app (Bitrig) stayed frontmost.
  Cooperative activation (macOS 14 and later) only hands focus over when
  the active app yields it (*recalled* explanation). Setting the app's AX
  frontmost attribute from the UI tests worked on the first try in 9 of 9
  launches the same day. Synthetic clicks don't count either: opening the
  window by real clicks on the menu bar item and Open Phases… still left
  Phases inactive when the window appeared (2026-10-29). So a UI test
  can't reproduce a first open, and the first-open half of
  `[D-initial-focus-sidebar]` stays a manual check. Shapes
  `[D-ui-test-runner]`.
  - *Verified* 2026-11-06 by the author, draft 43 build
    (`spec/starter-phases`): it happens on a real Finder launch too. With
    the test-mode switches saved in Phases' settings, a double-click in
    Finder made a first launch `[D-first-launch-shows-window]`: the window
    opened but stayed behind the frontmost app. Launched from Bitrig's
    shell (`open -n`), same result. So it isn't only an artifact of
    launching from Bitrig. Why `NSApp.activate()` is refused even when
    the user launched the app is not yet known; the window is opened
    from the menu bar icon's `.task` at launch, possibly before the
    launch has finished (*hypothesis*).
  - *Timing ruled out, workaround found:* *verified* 2026-11-06 on
    `experiment/first-launch-activation` (Finder launches by the author
    plus the diagnostics log). The menu bar icon's `.task` does run
    about 3 ms before `applicationDidFinishLaunching`, but opening the
    window after the launch finished changed nothing: Phases stayed
    inactive, Finder frontmost, at +0.5 s and +2 s. Then calling
    `NSRunningApplication.current.activate(from:)` with the app that was
    frontmost (Finder) returned true and brought Phases and its window
    to the front, in 2 of 2 launches. The deprecated
    `activate(ignoringOtherApps:)` wasn't tried (author's preference).
    Shapes `[D-first-launch-shows-window]`; see "First launch comes to
    the front" under "Workarounds".
  - *Verified* 2026-11-08 (draft 50 build, the author's click plus the
    diagnostics log): **a launch by a click on the pause notification
    is refused too.** The click launched Phases, the window was built
    (toolbar installed, banner laid out), and it stayed behind the
    frontmost app; ⌘Tab showed it there. So a notification click goes
    through the same `activate(from:)` routine as the first launch
    `[D-notice-opens-window]`.
  - A relaunch while running is granted activation without help
    `[D-reopen-shows-window]`. During the experiment, one double-click
    looked like a success only because Phases hadn't quit (window
    closed), so it was a relaunch. Quit from the app menu between
    first-launch checks.
- `[Q-closed-window-keeps-focus]` **Closing the Phases window only hides
  it; on reopen it still has whatever had focus, with the text cursor and
  selection where they were (macOS 27.2).** *Verified* 2026-10-29 by the
  author's hand check on a build without `[D-initial-focus-sidebar]`:
  leave the cursor in the Name field, close, reopen from the menu, and
  the next keypress renames the phase. The focus log agreed (the field's
  editor had focus 0.3 s after reopening). With the fix, focus goes back
  to the sidebar on every open, reopens included (UI test, same day).
  That a hidden window keeps its first responder is standard AppKit
  behavior as recalled, not checked in documentation.

## Driving and measuring the Mac in tests

How the experiment's UI runs were done, for next time. Test-suite
techniques belong in TESTING.md; these are the ad hoc ones. (Moved here
from LEARNINGS.md on 2026-11-09; the experiments they came from are in
EXPERIMENTS.md.)

- `[L-nswindow-screen-rect]` **`NSWindow(contentRect:…, screen:)` reads
  the rect relative to that screen, not in global coordinates.** A
  harness window meant for the built-in display (global x −1396) landed
  at −2908, off the display, shifted by the screen's own −1512 origin.
  *Measured* 2026-10-30. Pass global coordinates without `screen:`.
- `[L-test-window-height]` **A borderless 240 pt harness window came out
  241 pt tall on two displays** (240 on the third), leaving a 1 pt strip
  of window background: the white line seen across the color-test panes.
  *Measured* 2026-10-30; why macOS added the point is unknown. Fill the
  whole content view, or skip edge rows when comparing pixels.
- `[L-memory-tools]` **Measuring memory:** `footprint -p <pid>` (what
  Activity Monitor shows), `vmmap --summary` (look for "Malloc Large
  (empty)"), `heap` (live objects by class), `malloc_history <pid>
  <address>` and `-allBySize` (who allocated it; needs the app launched
  with `MallocStackLogging=1`, which adds 16–64 MB of its own), `leaks`.
  All work on the installed build because it carries `get-task-allow`.
  Changes were made by clicking the menu bar item's Change Now with real
  mouse events, positions read through System Events.

- `[L-twitch-measurement]` **Measuring a twitch:** record with
  `screencapture -v -V <seconds> -x out.mov` (60 fps, variable frame rate;
  no permission prompt, since the shell already had Screen Recording
  access, 2026-10-29). Per-frame differences with ffmpeg's `tblend`
  difference plus `signalstats` (average luma) over a region with no
  windows find motion; `psnr` between two frames tells a real shift
  (about 26 dB) from noise (about 43 dB). Tiling menu bar crops at 4
  frames per second shows restyle timing. *Verified* 2026-10-30.
  The recording only adds frames when the screen changes (a few per
  second while still, up to 60 during motion), so a twitch can't fall
  between frames, but frame counts aren't a time base: use the frame
  timestamps. Recording several displays at once starves the encoder;
  record one at a time (`-D<n>`, where 1 is the main display, which isn't
  the same numbering as `NSScreenNumber`).
- `[L-settings-panes]` **Opening System Settings panes directly:**
  `open "x-apple.systempreferences:com.apple.ControlCenter-Settings.extension"`
  (Menu Bar, including "Show menu bar background") and
  `…com.apple.Desktop-Settings.extension` (Desktop & Dock, including Stage
  Manager). Toggle positions depend on where the window lands, so read
  its position with System Events and check a screenshot before
  clicking. Turning Stage Manager on the first time shows an intro sheet
  with its own Turn On button. Verify the result
  (`defaults read com.apple.WindowManager GloballyEnabled` for Stage
  Manager, or a screenshot) and put every setting back after the test.
  *Verified* 2026-10-30.
- `[L-synthetic-clicks]` **Synthetic input that works:** CGEvent clicks
  on a menu bar extra need about 60 ms between mouse down and up, or the
  menu opens but the item doesn't fire. ⌃← and ⌃→ to switch Spaces need
  the Secondary Fn and Numeric Pad flags set along with Control. Read
  the menu bar item's position from accessibility each time; it moves as
  other items come and go. Check what's under the pointer
  (`CGWindowListCopyWindowInfo`) before each click. *Verified*
  2026-10-30. See also "Open here" in ERRATA.md on System Events clicks.
- `[L-cover-check-driving]` **What the 2026-11-03 cover checks needed.**
  - **Change Now's fade starts 0.6–1.15 s after the click** (decode), so
    "⌃→ 0.3 s into the fade" has to be timed from the cover window
    appearing (poll `CGWindowListCopyWindowInfo`), not from the click
    (`[L-swipe-before-cover]`).
  - **Random picks often repeat a Space's current image,** which makes a
    trial uninformative; read the wallpaper first and repeat.
  - **The 30-minute rotation** fired mid-trial at 11:00; pause the
    schedule for the run (Change Now still works) and put it back.
  - **Transition is a segmented picker:** AX radio buttons "None" and
    "Crossfade". Reduce Motion is the `AX_REDUCE_MOTION` checkbox on
    `x-apple.systempreferences:com.apple.Accessibility-Settings.extension?Motion`
    (not the Display pane, macOS 27.2).
  - **The test build asks for location** (its own signature), a prompt
    left unanswered on screen.
  - *Verified* 2026-11-03.
- `[L-no-fullscreen-apps]` Activity Monitor doesn't support full screen
  (it only zooms); use Calendar to test full screen. Author, 2026-10-30.
