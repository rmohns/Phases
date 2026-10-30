# Phases — Errata

What macOS, SwiftUI, and AppKit do to Phases, and how Phases routes around
it. SPEC.md says what Phases does and why; this file holds everything that
would stop being true if a future macOS fixed the underlying behavior.

- **Sorting test:** if a future macOS fixed the bug, would the line still be
  true? Yes → SPEC.md. No → here.
- Each quirk has a stable `[Q-…]` ID and cites the `[D-…]` decisions it
  shapes. A spec decision that fights the platform points back with one
  line: "macOS fights this; see `[Q-…]`." Code comments carry both tags, so
  searching for either finds the spec, this file, and the code.
- Each quirk says whether it was **verified** (tested or measured, with
  date) or is **recalled** (believed from past knowledge, not tested here).
  Keep corrections and history; don't silently rewrite an entry.
- Cross-references use a tag or a quoted section title, never a section
  number `[D-refs-by-id]`.
- New quirks go here, with a new `[Q-…]` ID, when they're found.
- Only quirks the code on `main` depends on live here. Findings that don't
  shape code go in LEARNINGS.md; they're promoted here when code starts
  depending on them (see LEARNINGS.md "Promotion").
- **Demotion:** when the code a `[Q-…]` entry shapes is removed from
  `main`, the entry moves to LEARNINGS.md in the same change, keeping its
  `[Q-…]` tag alongside a new `[L-…]` tag so old comments and commits still
  find it, and leaves a one-line pointer here: "Demoted to `[L-…]` (date)."
  This duplicates LEARNINGS.md "Demotion" on purpose: this file is read
  every session and LEARNINGS.md isn't, so the rule has to be here when the
  code is being removed. Keep the two copies in sync.

## Quirks

### Wallpaper and menu bar (macOS)

- `[Q-wallpaper-motion-delay]` **After an app sets the wallpaper, macOS
  plays about 0.13 s of its own motion (a shift that settles back)
  somewhere within the next 1.5 s (macOS 27.2).** *Measured* 2026-10-28
  from a 30 fps screen recording of seven Phases changes on one display:
  the motion landed 0.55–0.65 s after the wallpaper was set, just as draft
  21's cover came off. With the cover held 1.5 s, the twitch is gone
  (verified by the author, 2026-10-28), so the motion finishes within that
  time. Whether macOS 27.1 was faster is *unknown*: the draft 5 fix worked
  then with a 0.5 s delay, and the author believes (not certain) that was
  on 27.1. Shapes `[D-cover-settle]`; history in "The twitch returns". If
  the twitch comes back again, measure the timing first, the same way (see
  "Diagnostic procedures").
  - *Correction:* draft 22 first said the wallpaper *appears* 0.55–0.65 s
    after being set, judging by when the menu bar restyled. But the menu
    bar's background restyles when the cover is removed
    (`[Q-menubar-bg-follows-window]`), so that timing only showed the 0.5 s
    cover removal. The motion's timing is measured; the cause of the motion
    is not.
- `[Q-menubar-bg-follows-window]` **The menu bar's background restyles
  when the window under it changes, not when the wallpaper changes (macOS
  27.2).** *Verified* 2026-10-28 by the author with "Show menu bar
  background" on: the background keeps its old color through the fade and
  after the wallpaper is set, and changes when Phases removes its cover.
  This looks like a sibling of `[Q-menubar-restyle-on-app-switch]`, where
  the restyle followed app switching; that link is a guess. Explains the
  cost noted under `[D-cover-settle]`: the background now lags the fade by
  about 1.5 s instead of 0.5 s (verified by the author with draft 22,
  2026-10-28).
- `[Q-menubar-reads-wallpaper]` **macOS picks the menu bar's text color and
  shadow from the actual wallpaper, ignoring windows above it.** *Verified*
  2026-10-26 in draft 4 testing: setting the wallpaper at the start of a
  fade switched the menu bar immediately, while the screen still showed
  the old image (most visible going from light to dark). Shapes
  `[D-fade-in]`; history in "Why fade in, not fade out".
- `[Q-menubar-blank]` **The menu bar blanks for about 0.1 s when the
  wallpaper changes.** *Verified* 2026-10-26 as macOS behavior:
  frame-by-frame recordings of a change made in System Settings show the
  same thing. The menu bar keeps its old styling for a couple of frames,
  disappears for 2–3 frames, then returns restyled. `[D-fade-in]` keeps the
  menu bar steady during the fade and limits this to the one blink at the
  end. Not fixable by Phases.
- `[Q-menubar-restyle-on-app-switch]` **macOS sometimes doesn't restyle the
  menu bar after a wallpaper change until the frontmost app changes (macOS
  27.0.1).** *Verified* in a recording of System Settings' own 5-second
  shuffle: the menu bar's styling changed when apps were switched, not when
  the wallpaper changed. Bug or design decision is unknown. Phases could
  force a restyle by briefly activating itself, but `[D-no-focus-steal]`
  rules that out. Reported to Apple: **FB25326597** (2026-10-27).
- `[Q-bartender-menubar]` **Bartender (menu bar manager) caused additional
  odd menu bar behavior during testing.** Observed, not characterized. Not
  a Phases issue; rule it out before chasing menu bar glitches.
- `[Q-screen-params-notification]`
  **`NSApplication.didChangeScreenParametersNotification` fires for more
  than display changes (macOS 27.2).** *Verified* 2026-10-28 by the author:
  hiding or showing the Dock, and toggling System Settings › Menu Bar ›
  "Show menu bar background", each started a Phases crossfade, which only
  that notification could trigger. The likely reason, that these change
  each screen's visible frame, is *recalled*, not checked. Display UUIDs
  don't change. Shapes `[D-screen-change-no-reroll]`.

### Window, sidebar, and toolbar (SwiftUI and AppKit)

- `[Q-split-item-rewrite]` **`NavigationSplitView` rewrites its sidebar's
  AppKit split view item some time after the window opens, ignoring
  `.navigationSplitViewColumnWidth` (macOS 27.2).** *Verified* 2026-10-28
  from diagnostic logging: the item's minimum thickness went back to
  140 pt, its maximum to unspecified, and `canCollapse` to true, 1.5–28 s
  after Phases set them, on the same item object. The sidebar has
  `.navigationSplitViewColumnWidth(min: 240, ideal: 240, max: 320)`, yet
  the values SwiftUI wrote match none of it, so on macOS 27.2 that modifier
  isn't reaching the item either. What triggers the rewrite is *unknown*.
  Shapes `[D-window-helper-order]`, `[D-sidebar-always-visible]`, and
  `[D-sidebar-limits-watch]`; workaround in "Sidebar limits".
  - *Trigger, partly found* 2026-10-29: in UI tests the rewrite didn't
    happen with the window left alone for 30 s, but did once the detail
    pane had switched between Settings and phases (limits gone, sidebar
    collapsible). Which switch triggers it isn't isolated.
- `[Q-sidebar-collapse]` **A sidebar's minimum width doesn't stop it
  collapsing, and SwiftUI can't make it non-collapsible.** macOS snaps a
  sidebar shut when its divider is dragged past the minimum; since Phases'
  sidebar opens at its minimum, a short leftward drag closed it
  (*reproduced* 2026-10-28). SwiftUI has no API to stop this (*recalled*;
  none found). Shapes `[D-sidebar-always-visible]`; workaround in "Sidebar
  limits".
- `[Q-no-items-no-toolbar]` **A SwiftUI window with no toolbar items gets
  no toolbar at all, so `.windowToolbarStyle(.unified)` has no effect and
  the title bar stays short (macOS 27).** *Verified* 2026-10-28: after
  removing the sidebar toggle and adding `.windowToolbarStyle(.unified)`,
  the title bar stayed short in a screenshot, and the AX API listed no
  toolbar on the window. Shapes `[D-tall-toolbar]`.
- `[Q-empty-toolbar-66pt]` **An empty unified `NSToolbar` makes the title
  area 66 pt tall (macOS 27).** *Verified* 2026-10-28 from diagnostic
  logging: the window's title area went from 32 pt (no toolbar) to 66 pt
  the moment an empty `NSToolbar` with `.unified` style was attached, and
  stayed there. That's taller than Notes' toolbar (about 50 pt in a
  screenshot). Setting the toolbar's `displayMode` to `.iconOnly` brought
  it to 52 pt (verified 2026-10-28). The theory that the default display
  mode reserves a row for item labels is not confirmed in Apple
  documentation. Affects `[D-tall-toolbar]`. *Confirmed* 2026-10-29 by
  the UI tests: removing `.iconOnly` alone brings back exactly 66 pt.
- `[Q-list-row-padding]` **The sidebar list adds about 14–16 pt of its own
  padding inside a row's insets (macOS 27).** *Measured* 2026-10-28 from a
  2× screenshot with the tall toolbar: the red traffic light and the row
  icons' left edges sit about 19–20 pt from the window's left edge. Negative
  row insets are honored if ever needed (verified 2026-10-28). Recheck if a
  macOS update moves the traffic lights or row icons. Affects
  `[D-brand-inset]`; numbers in "Branding panel insets".
- `[Q-safe-area-inset-refresh]` **Content in a List's `.safeAreaInset` may
  not refresh when the parent view's state changes (macOS).** *Recalled*,
  not verified against Apple documentation or a bug report. Matches the
  draft 13 bug where − stayed disabled; moving the bar into its own view
  with a binding fixed it (fix verified by the author, 2026-10-28). Shaped
  `[D-sidebar-footer-view]`.
- `[Q-default-focus-loses]` **`.defaultFocus` on the sidebar List doesn't
  stop macOS from focusing the first text field when the window opens
  (macOS 27).** *Verified* 2026-10-28 by the author, across several
  relaunches: with `.focused` + `.defaultFocus` on the List (draft 18), the
  phase's Name field still opened focused with its text selected. The AX
  API confirmed it: the focused element is the Name text field, with all
  of its text selected (2026-10-28). Moving focus one run-loop pass after
  `onAppear`, once the phase editor is in place, works: the AX API then
  reports the sidebar outline as focused (verified 2026-10-28). That fits a
  timing cause (the editor appears after SwiftUI applies default focus),
  but the cause itself is unproven. Shapes `[D-initial-focus-sidebar]`.
- `[Q-lazy-grid-tab]` **Tab can't reach buttons in a `LazyVGrid` that
  haven't been created yet, and the Form doesn't scroll to follow Tab
  (macOS 27).** *Partly verified* 2026-10-28 from a screen recording: Tab
  visited only the on-screen thumbnails (including two half-visible ones,
  without scrolling), then wrapped to the sidebar. The cause (lazy grids
  only create views near the visible area, and only existing views are in
  the Tab order) is *recalled*, not proven. Shaped `[D-grid-one-tab-stop]`,
  whose cursor scrolling uses a `ScrollViewReader` around the grouped Form
  (verified 2026-10-28).
- `[Q-borderless-pressed-state]` **Borderless buttons show their pressed
  state only by darkening the icon (macOS 27).** *Verified* 2026-10-28 by
  holding the mouse down and measuring screenshots: Phases' + went from
  0.53 to 0.18 gray; System Settings' Login Items + went from 0.52 to 0.35.
  There's no background or whole-area highlight, and the change sits under
  the mouse pointer, so it's easy to miss. Earlier macOS versions
  highlighted the whole button more clearly (author's recollection). Same
  as Apple's own +/− bars, so Phases matches it for now
  `[D-sidebar-footer-style]`.
  - **Possible future TODO:** revisit (a) a custom pressed state that
    highlights the whole 24 × 23 pt cell, and (b) how the system style
    behaves on earlier macOS versions Phases supports (deployment target is
    macOS 26; only macOS 27 was tested).
- `[Q-regular-activation-menubar]` **Switching from accessory to regular
  and activating in the same pass can leave the app frontmost without its
  menu bar.** *Recalled*, not yet seen in Phases: a long-standing AppKit
  report that after `setActivationPolicy(.regular)` plus `activate()`, the
  window comes forward but the menu bar still shows the previous app's
  menus until you switch away and back. Commonly cited fixes: set the
  policy first and activate on the next run-loop pass, or activate another
  app (e.g. the Dock) and then this one. Watch for it in testing
  `[D-dock-while-open]`.
- `[Q-accessory-focus-handoff]` **Switching back to accessory hands focus
  to the most recently used app, even on another Space.** *Verified*
  2026-10-29 (author's report): closing the Phases window activated the
  next app in the recent-apps order and switched to that app's Space. A
  quitting app gets a gentler handoff (an app on the current Space, else
  Finder; recalled, matches Contacts). Shapes `[D-close-stays-here]`.
- `[Q-activate-switches-space]` **Activating an app whose only window is
  on another Space switches to that Space, whatever triggered it.**
  *Verified* 2026-10-29 (author's report): with the Phases window on
  another Space, "Open Phases…", the Dock icon, and ⌘Tab all switched
  Spaces. That's the Mission Control setting "When switching to an
  application, switch to a Space with open windows for the application"
  (on by default, recalled). A window can opt out with
  `NSWindow.CollectionBehavior.moveToActiveSpace`, but that applies to
  every activation, Dock and ⌘Tab included. Shapes `[D-open-here]`.
- `[Q-closed-window-keeps-space]` **A closed SwiftUI `Window` comes back
  on the Space it was closed on.** *Verified* 2026-10-29 (author's report,
  confirmed in the diagnostics log: `visible=false onActiveSpace=false`
  on reopening). SwiftUI keeps the closed window and re-shows it, and a
  hidden window keeps its Space, so reopening switches to that Space.
  Shapes `[D-open-here]`.
- `[Q-view-menu-fullscreen]` **Emptying SwiftUI's View menu doesn't remove
  it: macOS adds Enter Full Screen, so a one-item View menu remains (macOS
  27.2).** *Verified* 2026-10-29: with the `.sidebar` and `.toolbar` command
  groups replaced by nothing, the View menu held only a separator and a
  disabled Enter Full Screen (author's report, confirmed by reading the menu
  bar through System Events). SwiftUI has no API to remove a whole standard
  menu (recalled). Removing it from `NSApp.mainMenu` doesn't work cleanly
  either: the menu still showed, then vanished once the menus were clicked
  (*verified* 2026-10-29, author). Shapes `[D-app-menu]`, which keeps the
  menu; see "View menu removal" under "Design history".

### Tools

- `[Q-system-events-ax]` **System Events (AppleScript) doesn't report
  SwiftUI button descriptions (macOS 27).** *Verified* 2026-10-28: for the
  + / − buttons, System Events' `description` returned only "button" and
  found no AXDescription, while the AX API (`AXUIElementCopyAttributeValue`)
  read "Add Phase" / "Delete Phase" from the same buttons. Check
  accessibility labels with the AX API or Accessibility Inspector, not
  System Events. Whether an icon-only `Label` wrapped in
  `.frame`/`.contentShape` loses its title on its own is *unverified*;
  `[D-footer-ax-labels]` sets the label explicitly either way.
- `[Q-bitrig-test-targets]` **`bitrig test` doesn't see test targets in
  Project.json projects** ("has no test targets", *verified* 2026-10-28),
  and there's no generated Xcode project to hand to `xcodebuild`. That's
  why the unit tests are a Swift package run with `swift test` (see
  TESTING.md). *Re-verified* 2026-10-29 with a
  `bundle.ui-testing` target and a scheme naming it in `testTargets`: same
  message. So Layer 2 drives the app through the AX API instead of
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

## Workarounds

How the tagged decisions route around the quirks above.

### Crossfade settle timing

`[D-cover-settle]` removes the cover 1.5 s after the wallpaper is set.

- *Why 1.5 s:* macOS plays its own motion 0.55–0.65 s after the wallpaper
  is set `[Q-wallpaper-motion-delay]`. Draft 5's 0.5 s delay removed the
  cover right as that motion played, bringing the twitch back (see "The
  twitch returns"). 1.5 s leaves about 0.7 s of margin.
- *Cost:* the menu bar's background lags the fade by about 1.5 s instead of
  0.5 s `[Q-menubar-bg-follows-window]`. The menu bar's text and icon color
  lag as before `[Q-menubar-restyle-on-app-switch]`.
- Code: `CrossfadeController.settleDelay`.

### Tall toolbar

`[D-tall-toolbar]` keeps a full-height unified toolbar with no items.

- *How:* `.windowToolbarStyle(.unified)` alone did nothing
  `[Q-no-items-no-toolbar]`. The window's AppKit `NSToolbar` is therefore
  created by hand, empty, with the unified style, when SwiftUI hasn't made
  one. It's set to icon-only display, which brought the title area from
  66 pt down to the standard 52 pt `[Q-empty-toolbar-66pt]` (verified from
  diagnostic logging and a screenshot, 2026-10-28).
- **Status: appears fixed, cause not proven.** Icon-only fixed the height,
  which fits the label-row theory; nobody confirmed that theory in Apple
  documentation. If the toolbar grows tall again, see "Diagnostic
  procedures".
- Code: `App/Views/WindowLayoutConfigurator.swift`, `installToolbar`.

### Initial focus

`[D-initial-focus-sidebar]`: the window moves focus to the sidebar list one
run-loop pass after it appears, once the phase editor is in place, because
`.defaultFocus` loses to the Name field `[Q-default-focus-loses]`. Code:
`PhasesWindow.onAppear`.

### Open here

`[D-open-here]`: settled 2026-10-29 (last item below). Tests run 2026-10-29 with diagnostics
and a probe that reads the active Space ID and whether the window is on
screen.

- **Test method matters.** Clicking the menu through System Events
  accessibility actions doesn't let Phases activate at all (Finder stayed
  frontmost, no Space switch), so those runs prove nothing. Real mouse
  events (CGEvent) at the menu item's position do. *Verified* 2026-10-29.
- **Temporary `.moveToActiveSpace` (on, `orderFront`, off, then activate):
  failed.** *Verified* 2026-10-29 with real clicks: "Open Phases…" on
  another Space switched to the window's Space, same as before the fix;
  `isOnActiveSpace` stayed false right after `orderFront`.
- **Order out, activate, `makeKeyAndOrderFront`: failed.** *Verified*
  2026-10-29 with real clicks: switched to the window's Space;
  `isOnActiveSpace` false after re-showing. macOS keeps a hidden window's
  Space.
- **`.moveToActiveSpace` on until `didBecomeActiveNotification`, then
  off: failed.** *Verified* 2026-10-29 with real clicks and the location
  prompt off `[D-test-no-location-prompt]`: switched to the window's
  Space; `isOnActiveSpace` false once active.
- **Not SwiftUI's `openWindow`.** *Verified* 2026-10-29: bringing the
  existing window forward with `makeKeyAndOrderFront` instead (flag on
  until active) still switched Spaces.
- **`.moveToActiveSpace` left on: works.** *Verified* 2026-10-29: "Open
  Phases…" on another Space kept the user there and brought the window;
  a Dock click did the same (expected with the flag left on). The flag
  survived to activation, so SwiftUI doesn't reset it. But the window
  was still off the active Space at `didBecomeActive`: the move happens
  *after* activation, which is why turning the flag off there failed.
- **Flag on until the window arrives (occlusion turns visible on the
  active Space), or until Phases resigns active: works; this is the
  fix.** *Verified* 2026-10-29 with real clicks: "Open Phases…" on Space
  B stayed on B and the window came; the log showed "flag off (arrived)";
  a Dock click from a third Space then switched to the window's Space as
  usual. ⌘Tab not driven in the test (it goes through the same
  activation path as the Dock, recalled).
- **Closed window:** the flag now applies to a closed window too
  `[Q-closed-window-keeps-space]`. *Verified* 2026-10-29 with real
  clicks: open on A, ⌘W, switch to B, "Open Phases…" → window on B, no
  switch; the open-window run passed again in the same session.
- **Dock click:** went to the window's Space in every real-click run, as
  intended.

Code: `App/Model/WindowSpaceMover.swift`.

### Close stays here

`[D-close-stays-here]`: on `willClose`, before dropping to accessory,
Phases yields activation to the app chosen by `HandoffChoice` and
activates it. *Verified* 2026-10-29 with real clicks: Phases window on
Space A, Calculator on B as the most recent app, Dock click back to
Phases, ⌘W → stayed on A, focus to the app with a window on A (Bitrig).
Finder fallback with Finder's only window on another Space: no Space
switch. *Verified* 2026-10-29 (author, by hand); Finder seems to be
treated specially because it owns the desktop on every Space (recalled
explanation). UI test rerun the same day: same pass. Code:
`App/Model/FocusHandoff.swift`, `App/Model/HandoffChoice.swift`.

### Branding panel insets

`[D-brand-inset]` lines the panel up with the traffic lights and row icons.

- *How:* the row inset is +3 pt on each side; the system list adds about
  14–16 pt of its own padding inside it `[Q-list-row-padding]`, putting the
  panel's edges about 19–20 pt from the window edge.
- **Top edge:** the row's top inset is 20 pt (measured: the form starts
  about 16 pt lower than the panel did with a 4 pt inset), so the panel's
  top lines up with the first grouped row in the detail form.
- Recheck both if a macOS update moves the traffic lights, row icons, or
  form.

### Sidebar limits

`[D-sidebar-always-visible]`, `[D-sidebar-width]`, `[D-window-helper-order]`,
and `[D-sidebar-limits-watch]` together keep the sidebar between 240 and
320 pt and stop it collapsing, despite `[Q-sidebar-collapse]` and
`[Q-split-item-rewrite]`.

- **Works around SwiftUI on purpose.** SwiftUI has no way to stop a sidebar
  from collapsing, so Phases reaches past `NavigationSplitView` to the
  AppKit `NSSplitViewController` SwiftUI happens to use for it, and changes
  that controller's sidebar item: not collapsible, with its minimum and
  maximum thickness set from `[D-sidebar-width]`, so dragging stops at
  240 pt. This relies on undocumented internals and **may break in a
  future macOS update**. If it does, the sidebar simply becomes collapsible
  again (nothing worse). All of it is in
  `App/Views/WindowLayoutConfigurator.swift`; check there first if the
  sidebar starts collapsing after an OS update.
- **One helper, in a fixed order** `[D-window-helper-order]`: the helper
  attaches the toolbar first, then, one run-loop pass later, sets the
  sidebar limits. The run-loop pass was meant to cover a split view rebuild
  after the toolbar is attached; that theory was later disproved (see
  "Sidebar limits: history").
- **Watching the limits** `[D-sidebar-limits-watch]`: event-driven only, no
  polling or timers. A key-value observer on the split view item fires when
  anything sets its minimum, maximum, or collapse settings; if a value
  differs from Phases', it's set back (setting it again fires the observer
  once more, finds it correct, and stops). As a backstop, the same check
  runs on the sidebar's own split view resize notification, which also
  re-attaches the observer if SwiftUI ever swaps in a new item. Both go
  away when the window closes. Idle cost is zero.
  - *Verified* 2026-10-28 by the author (drags across two launches) and the
    diagnostic log: `NSSplitViewItem` does send key-value notifications for
    all four properties, and the observer caught every rewrite. In one
    window SwiftUI rewrote the limits in two bursts about 15 s after
    opening; each property was put back once, with no loop (10 restores in
    total). The resize backstop never had to act, and the item was never
    swapped. It stays in as cheap insurance.
  - Seen once, not fixed: one resize reported the sidebar at 230.5 pt, just
    under the minimum, 54 ms *after* the limits were set and about 120 ms
    after the helper joined the window (possibly before the window was on
    screen). The split view hadn't yet applied its new minimum. How long it
    lasted is unknown, because the diagnostic log only records changes. It
    was back in range by the author's first drag, since no later resize
    was out of range. No one noticed it on screen.

## Design history

### Why fade in, not fade out

Draft 4 did the reverse of `[D-fade-in]`: it covered the screen with the
*outgoing* image, set the new wallpaper immediately, and faded the cover
out. Testing found two problems:

1. **Flash and twitch.** The new wallpaper could reach the screen before the
   cover did, briefly showing the new image (and macOS's own
   wallpaper-change motion) before the fade. Draft 4.1 worked around this
   by waiting for the cover to be on screen and suppressing window
   resize/appear animations.
2. **Menu bar blink.** The menu bar follows the actual wallpaper, not the
   windows above it `[Q-menubar-reads-wallpaper]`. Setting the wallpaper at
   the start of the fade switched the menu bar immediately, while the
   screen still showed the old image (most visible going from light to
   dark).

Fading the new image in and setting the wallpaper at the end fixes both:
the wallpaper changes behind an identical image, and the menu bar switches
once, at the end, just as it does when changing wallpaper in System
Settings. The menu bar's own switch is still instant; macOS doesn't animate
it `[Q-menubar-blank]`. The draft 4.1 workarounds were removed as no longer
needed.

### The twitch returns

2026-10-28, draft 22. The twitch came back on macOS 27.2, on one display or
two. A frame-by-frame analysis of a screen recording (seven changes)
showed:

- The fade itself is smooth, and the cover matches the final wallpaper
  exactly (before and after differ only at noise level). So the cover's
  image and geometry aren't the cause.
- The twitch is about 0.13 s of the image shifting and settling back. It
  starts 0.55–0.65 s after the fade ends, in the same frames as the menu
  bar restyle. (Draft 22 read that as when macOS actually shows the new
  wallpaper; see the correction under `[Q-wallpaper-motion-delay]`.)
- The cover was removed 0.5 s after the fade ended `[D-cover-settle]`, just
  before macOS's own motion, so the motion showed through.

The crossfade code's timing hadn't changed since draft 5. The author
believes (not certain) the original fix was tested on macOS 27.1, so macOS
27.2 may have made wallpaper changes slower. That's unconfirmed; the draft
5 timing may also have been marginal from the start. The fix is a longer
settle delay (1.5 s), not a new mechanism (see "Crossfade settle timing").

The same recording showed a second, separate problem: turning System
Settings' "Show menu bar background" on or off started a crossfade to a new
image `[Q-screen-params-notification]`. See `[D-screen-change-no-reroll]`.

### Sidebar collapse: first version

The first version of `[D-sidebar-always-visible]` (2026-10-28) let the
sidebar collapse and reopened it right away. In testing, the sidebar
flickered closed and open on every mouse move during the drag, and the
240 pt minimum stopped working (it shrank to about 90 pt). Replaced with the
non-collapsible split view item (see "Sidebar limits").

### Sidebar limits: history

- **Two helpers, varying order.** With separate toolbar and sidebar
  helpers, the order they ran in varied by launch. Suspected (not proven):
  when the sidebar limits went on first, attaching the toolbar rebuilt the
  split view and wiped them, so the sidebar could be dragged to any width
  (regression found in review, 2026-10-28; didn't reproduce in a logged run
  where the toolbar went first). Merged into one helper, toolbar first
  `[D-window-helper-order]`.
- **"Appears fixed, cause not proven."** With the merged helper, one logged
  launch kept the limits on a single split view through 520 resizes, with
  drags stopping at exactly 240 and 320 pt (2026-10-28). The original
  failure was never caught in a log, so the ordering theory was
  unconfirmed.
- **Regressed 2026-10-28 (draft 22 build).** The sidebar again dragged from
  very narrow to very wide (found by the author). No window or sidebar code
  had changed since the merged helper; that build only touched the
  crossfade and scheduler. So the bug was intermittent, and the ordering
  fix hadn't removed it. The unit tests all passed but couldn't see this.
  - A suspect from reading the code was a silent skip: the helper's delayed
    pass running before the split view was ready. **Ruled out by the log**
    (zero skips across three windows, 2026-10-28).
  - **Cause found (logged 2026-10-28, three windows over two launches):**
    the helper applies the limits every time, and they take effect (min
    240, max 320, not collapsible). Then, 1.5–28 s later, SwiftUI writes
    its own defaults back onto the **same** split view item
    `[Q-split-item-rewrite]`. The split view, its controller, and the item
    never change. So the limits hold for a few seconds after opening and
    then vanish, which is why it looked intermittent. The author's
    recording shows both results: the sidebar collapsing to nothing, and
    widening until the form is pushed out of the window.
  - This also means the ordering theory was wrong, or at most incidental.
    The 520-resize run that "confirmed" it probably ended before SwiftUI's
    rewrite.
  - Fixed by `[D-sidebar-limits-watch]` (see "Sidebar limits").

### View menu removal

`[D-app-menu]` `[Q-view-menu-fullscreen]`, draft 26 only.

- Draft 26 removed the one-item View menu from `NSApp.mainMenu` itself,
  picking it by contents (only separators and `toggleFullScreen:` items)
  and redoing it whenever the menu bar changed (`NSMenu.didAddItemNotification`
  and key-value observing on `mainMenu`).
- In use, the View menu still appeared in the menu bar, then disappeared
  the moment the author clicked into the menus (2026-10-29). Why it showed
  at all is *unknown*; most likely SwiftUI or AppKit put it back and the
  removal only ran once a menu event changed the menu again (a guess,
  not tested).
- Dropped in draft 27: a menu that vanishes under the pointer is worse than
  a View menu with one disabled item.

## Diagnostic procedures

Logging is switched on and read as described under "Diagnostics" in TESTING.md
`[D-diagnostics-switch]`.

- **Crossfade twitch returns:** measure before changing the delay. Record
  the screen at 30 fps or more and step through frame by frame: when the
  wallpaper is set, when the cover comes off, and when macOS's motion
  plays `[Q-wallpaper-motion-delay]`.
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
  `maximumThickness` `[Q-split-item-rewrite]`.
- **Accessibility labels:** check with the AX API or Accessibility
  Inspector, not System Events `[Q-system-events-ax]`.

## Regressions found so far

Bugs found in testing and fixed, oldest first, with how a test could guard
each one (see "Layer 2: UI tests" in TESTING.md). UI tests live in
`UITests/Tests/PhasesUITests/`, unit tests in `UnitTests/Tests/`. Design changes made after
review (menu bar icon legibility, sidebar width limits, branding panel
dimming) aren't listed; neither is the unreproduced black desktop (see
"Known issues" in SPEC.md). Entries marked *git only* were found in the
commit history, not in the spec.

Every new regression gets a row here and a guard: a test that fails without
the fix, or, if none is practical, the reason and the manual procedure
(standing rule in CLAUDE.md, 2026-10-29).

| Found | What broke | Fix | Guarded by |
|---|---|---|---|
| 2026-10-25 | Long image folder names in Settings were truncated badly (*git only*, commit 4e86957) | Middle truncation, full path in a tooltip | `AppearanceTests/imageFolderNameScreenshot` (AX full name, plus a screenshot for review) |
| 2026-10-26 (draft 4) | Crossfade flashed the new image and twitched before fading; menu bar blinked to the new styling at the start | Fade the new image in and set the wallpaper at the end `[D-fade-in]` | Not suited to XCUITest (frame timing); checked with frame-by-frame recordings. Twitch returned on macOS 27.2 (see the draft 21 row below) |
| 2026-10-27 (draft 10) | Branding tagline cut off after its first line, because sidebar rows default to one line (*git only*, commit 58555d3) | Allow two lines on the tagline | `AppearanceTests/brandingPanelScreenshot` (screenshot for review; the panel's AX label is fixed text) |
| 2026-10-28 | Dragging the sidebar divider past its minimum collapsed the sidebar, with no way to reopen it; the first fix flickered and broke the 240 pt minimum `[Q-sidebar-collapse]` | Non-collapsible split view item `[D-sidebar-always-visible]` | `SidebarTests/dividerDraggedFarLeftKeepsSidebarOpen` |
| 2026-10-28 (draft 13) | − did nothing: it started disabled and never re-enabled when a phase was selected `[Q-safe-area-inset-refresh]` | +/− bar as its own view bound to the selection `[D-sidebar-footer-view]` | `PhaseListTests/deleteRemovesANewlyAddedPhase` (adds a phase, then deletes it) |
| 2026-10-28 (draft 15) | Deleting a phase always selected the first phase | Select the next phase down `[D-delete-selects-next]` | `PhaseListSelectionTests` (Layer 1); `PhaseListTests/deletingAMiddlePhaseSelectsTheOneBelow` |
| 2026-10-28 (draft 17; draft 18's fix didn't work) | The Name field had focus with its text selected when the window opened, so any keypress renamed the phase `[Q-default-focus-loses]` | Move focus to the sidebar a run-loop pass after the window appears `[D-initial-focus-sidebar]` | `FocusTests/typingAfterReopeningDoesNotRenameThePhase` (reopen path `[Q-closed-window-keeps-focus]`; failed without the fix, passed with it, 2026-10-29). First open: manual only `[Q-launch-activate-refused]`: open from the menu, type a letter |
| 2026-10-28 (draft 19) | Tab visited only the on-screen thumbnails, didn't scroll, then jumped back to the sidebar `[Q-lazy-grid-tab]` | Grid is one Tab stop with an arrow-key cursor `[D-grid-one-tab-stop]` | `ImageGridNavigationTests` (Layer 1); `FocusTests/gridIsOneTabStopAndArrowsScroll` |
| 2026-10-28 | Title bar became short and crowded after the sidebar toggle was removed; then the fix made it 66 pt tall `[Q-no-items-no-toolbar]` `[Q-empty-toolbar-66pt]` | Hand-made empty unified toolbar, icon-only `[D-tall-toolbar]` | `AppearanceTests/toolbarIs52PointsTall` (AX toolbar frame; matching AppKit's measure is unverified). Cause of the 66 pt only theorized |
| 2026-10-28 | Sidebar could be dragged far below 240 pt and far above 320 pt again, right after the toolbar helper was added | One helper, toolbar first, then sidebar limits `[D-window-helper-order]` | `SidebarTests/dividerStaysWithin240To320`. Appeared fixed; the real cause was found later (draft 22 row) |
| 2026-10-28 (draft 21, macOS 27.2) | The crossfade twitch returned: the cover was removed while macOS was still showing the new wallpaper `[Q-wallpaper-motion-delay]` | Settle delay raised from 0.5 s to 1.5 s `[D-cover-settle]`; see "The twitch returns" | Not suited to XCUITest (frame timing); checked with frame-by-frame recordings |
| 2026-10-28 (draft 21) | Hiding the Dock or toggling "Show menu bar background" crossfaded to a new image `[Q-screen-params-notification]` | Screen changes run the normal check instead of re-applying `[D-screen-change-no-reroll]` | `WallpaperCheckTests` (Layer 1; check pulled out into `WallpaperCheck`). The handler's wiring to that check isn't tested |
| 2026-10-28 (draft 22) | Sidebar width limits gone again: drags from very narrow to very wide | Cause logged: SwiftUI rewrites the split view item's limits seconds after the window opens `[Q-split-item-rewrite]`. Fix: watch the item and put the limits back `[D-sidebar-limits-watch]`; verified 2026-10-28 | `SlowSidebarTests` (`PHASES_UI_SLOW=1`) and `SidebarTests/dividerStaysWithin240To320`, both switching the detail pane before dragging; failed without the watch (sidebar collapsed), passed with it, 2026-10-29 |
| 2026-10-29 (found by the UI tests) | A long image folder name squeezed Settings' Choose… button to a 16 pt sliver: the name's `.layoutPriority(1)` takes its full width first | `.fixedSize()` on Choose… | `AppearanceTests/imageFolderNameScreenshot` (button at least 60 pt); failed on the old build at 16 pt, passed on the fix, 2026-10-29 |
