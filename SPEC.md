# Phases — Specification (draft 19)

A personal macOS menu bar app that changes the desktop wallpaper on a schedule.
Not intended for the App Store.

## Design decisions

Deliberate choices that would be easy to "fix" by accident are tagged in
this spec, e.g. `[D-sidebar-width]`. The code that enforces each one carries
the same tag in a comment. Search for `[D-` to list them all, in the spec and
in the code.

- The reasoning lives here, next to the tag, not in the code comment.
- Before changing tagged code, re-read its decision. If the change
  contradicts it, update the decision here first (with the new reason),
  then the code.
- When a decision is replaced, keep a short note of what it replaced and
  why, as the existing *Why* and design-history notes do.
- New deliberate choices get a tag when they're added to the spec.

## 1. Core model: phases plus rotation

The schedule is a list of **phases**. Exactly one phase is active at any moment.

Each phase has:

| Field | Description |
|---|---|
| Name | e.g. "Morning", "Night" |
| Start trigger | When the phase begins (see §2) |
| Images (All Displays) | Images chosen from the library (multi-select). Used by every display that doesn't have its own selection (see §4) |
| Images (per display) | Optional: a separate selection for a specific display, used instead of the All Displays images on that display (see §4) |
| Order | Random or In order |
| Rotation | Optional: change to the next image every N minutes or hours while the phase is active |
| Appearance | Only in: **Any** (default), **Light**, or **Dark** mode (see §2a) |

**Which phase is active:** among phases whose appearance condition matches the
current system appearance, the one whose start trigger fired most recently
(looking back up to two days). So if "Night" starts at dusk and "Day" starts at
dawn, at 2 am "Night" is active. If no timed phase qualifies, the first matching
"Always" phase is used.

**Pure periodic changes** (no time-of-day switching) is just a single phase with
the "Always" trigger plus a rotation interval.

**When a phase starts**, each display changes immediately to the first image
(in order) or a random one from the selection it uses: its own, or All
Displays. Rotation then continues within the phase.

**In order** cycles through each selection in filename order and remembers its
position across launches. **Random** avoids repeating the current
image when there's more than one choice.

## 2. Start triggers

| Trigger | Example |
|---|---|
| Always | Used when no timed phase applies; for pure rotation or appearance-only setups |
| Clock time | 3:30 pm, every day |
| Civil dawn | Sun 6° below horizon, morning |
| Civil dusk | Sun 6° below horizon, evening |
| Dawn/dusk + offset | 30 minutes before dusk; 1 hour after dawn (−12 h to +12 h) |

- Dawn and dusk are calculated on the Mac (NOAA solar algorithm), with no network calls.
- Times are recalculated each day and whenever the location or time zone changes.
- If civil dawn or dusk doesn't happen on a given day (far north or south), that
  trigger is skipped that day and the previous phase stays active.

## 2a. Light and Dark Mode

- Each phase has an **Only in** setting: Any, Light, or Dark.
- The app listens for system appearance changes (including Auto switching) and
  re-evaluates immediately. If the switch makes a different phase active, the
  wallpaper changes right away; otherwise nothing happens.
- Examples:
  - *Dark images whenever Dark Mode is on:* two "Always" phases, one Light and one Dark.
  - *Dusk pictures, darker ones in Dark Mode:* two dusk phases, one Light and one Dark.
- The phase list shows a light/dark badge on phases with a condition.

## 3. Image library

- **App preference:** a single image folder, chosen with a standard folder picker.
- **App preference: Include subfolders** (off by default). When on, the folder is
  scanned recursively, skipping hidden folders and packages (app bundles, Photos
  libraries, etc.).
- Supported formats: JPEG, PNG, HEIC, TIFF.
- `[D-relative-paths]` Images are identified by their path relative to the folder (e.g.
  `Winter/snow.jpg`), so top-level selections stay valid when subfolders are
  turned on. Turning subfolders off makes subfolder images show as missing
  rather than silently dropping them.
- Access to the folder persists across launches (bookmark).
- The Phases window shows the library as a **thumbnail grid**, grouped under a
  heading per subfolder when subfolders are on. Click toggles an image in or out
  of the selection, ⇧-click selects a range, plus Select All / Select None buttons.
- If a selected image is later deleted or renamed, it's skipped and the phase
  editor marks it as missing. A phase with no available images is skipped
  (the wallpaper stays as it is).

## 4. Displays

### Per-display images
- Each phase has one image selection for **All Displays**, plus optional
  selections for specific displays. Schedule, order, and rotation are shared:
  every display changes at the same moments.
- In the phase editor's Images section, a **Display** picker lists All Displays
  plus each known display. It appears only when more than one display is known,
  so single-display setups look and behave as before.
- Choosing a specific display shows a **Use different images on this display**
  toggle. When on, that display gets its own thumbnail grid and draws only from
  its own selection (e.g. ultrawide images for an ultrawide monitor, portrait
  images for a portrait one). When off, it uses the All Displays selection.
- `[D-own-images-no-fallback]` If a display has its own selection but none
  of those images are available,
  that display keeps its current wallpaper; it does not fall back to All Displays.
- Turning the toggle off discards that display's selection for that phase.

### Display identity
- `[D-display-uuid]` Displays are identified by their hardware UUID, so settings survive
  unplugging, reconnecting, and rearranging. Phases remembers each display's
  name. Disconnected displays stay in the picker, marked "(not connected)", and
  keep their selections.

### Displays sharing the All Displays images
- Preference, applying only to displays **without** their own images in the
  active phase: **Same image everywhere** (default) or **Different picks per
  display** (each draws its own pick from the All Displays images).
- In order: each display's selection (or the shared one) advances in step. With
  Different picks, sharing displays are offset by one from each other.

### Not included
- `[D-no-shape-matching]` Automatic matching of images to each display's shape (portrait, ultrawide,
  standard). Considered and rejected: "ultrawide" vs. "wide" is fuzzy, and
  wrong guesses would surprise; explicit per-display choices are predictable.

- Changes apply to the current Space on each display (macOS limitation; see §9).

## 4a. Transitions

- **App preference: Transition**: None or **Crossfade** (default).
- **App preference: Duration**: 0.5 to 3 seconds (default 1 second), shown
  only when Crossfade is selected.
- macOS has no transition for wallpapers set by apps, so Phases does it itself
  by **fading the new image in over the old wallpaper** `[D-fade-in]`
  (see design history below):
  1. **Cover:** on each screen whose image is changing, a borderless,
     click-through window shows the *incoming* image, fully transparent.
     `[D-cover-level]` It sits just above the desktop picture and below the
     desktop icons, so icons
     and windows don't flicker. It covers the full screen, including under the
     menu bar.
  2. **Fade in:** the cover fades to fully opaque over the chosen duration.
     The real wallpaper hasn't changed yet.
  3. **Switch:** the new wallpaper is set behind the now-opaque cover, which
     shows the identical image.
  4. **Remove:** after a short settle delay (0.5 s) to let macOS finish drawing
     the new wallpaper, the cover is removed. This is invisible, since the
     cover and the wallpaper match.
- The cover draws the incoming image the way macOS will, using that screen's
  scaling (fill, fit, stretch, or center) and fill color.
- `[D-no-screenshots]` The cover is drawn from the image file. No screenshots and no Screen
  Recording permission.
- `[D-no-fade-cases]` **No fade (instant switch) when:**
  - Transition is set to None
  - Reduce Motion is on (System Settings › Accessibility › Display)
  - The incoming image file can't be read (that screen only: it switches
    without a fade, at the same moment as the other screens finish fading)
  - A screen's image isn't actually changing (that screen only)
  - Restoring the original wallpaper on quit (§8a)
- If another change starts while a fade is running, the running fade finishes
  instantly (its wallpaper is set and its cover removed) and the new change
  starts its own fade.

### Why fade in, not fade out (design history)

Draft 4 did the reverse: it covered the screen with the *outgoing* image, set the
new wallpaper immediately, and faded the cover out. Testing found two problems:

1. **Flash and twitch.** The new wallpaper could reach the screen before the
   cover did, briefly showing the new image (and macOS's own wallpaper-change
   motion) before the fade. Draft 4.1 worked around this by waiting for the
   cover to be on screen and suppressing window resize/appear animations.
2. **Menu bar blink.** macOS picks the menu bar's text color and shadow from
   the *actual* wallpaper, ignoring windows above it. Setting the wallpaper at
   the start of the fade switched the menu bar immediately, while the screen
   still showed the old image (most visible going from light to dark).

Fading the new image in and setting the wallpaper at the end fixes both: the
wallpaper changes behind an identical image, and the menu bar switches once, at
the end, just as it does when changing wallpaper in System Settings. The menu
bar's own switch is still instant; macOS doesn't animate it. The draft 4.1
workarounds were removed as no longer needed.

A side benefit: the old wallpaper is never redrawn, so crossfades now work when
the outgoing wallpaper is an Aerial.

## 5. Missed changes: sleep, wake, unlock

On launch, wake from sleep, screen unlock, and time zone / clock changes, the app
`[D-missed-latest-only]`:

1. Works out which phase should be active right now.
2. If it differs from the last phase it applied, switches to it immediately.
3. If the same phase is active but one or more rotations came due while asleep,
   it applies only the **most recent** missed rotation: the image that would be
   showing now had the Mac stayed awake. For In order, that means skipping ahead
   by the number of missed rotations; for Random, a single new random pick. The
   rotation clock stays aligned to the original schedule.

## 6. Location

- `[D-location-on-demand]` Uses Location Services. Permission is requested
  only when a phase first uses
  a dawn/dusk trigger, not at launch.
- Settings shows the current location, today's civil dawn and dusk, when the
  location was last updated, and an **Update Now** button.
- Uses low-accuracy, infrequent updates. The last known location is saved so
  dawn/dusk still work offline or after a restart.
- If permission is denied: dawn/dusk phases are disabled and marked with a
  warning, and the menu explains how to turn it on in System Settings. Clock and
  "Always" phases keep working.

## 7. Interface

### Icons
- **App icon:** the supplied artwork (landscape in a circle between two lunar
  crescents, blue gradient).
- `[D-menubar-icon]` **Menu bar icon:** a simplified version of the app icon, drawn for legibility
  at menu bar size: a bold photo circle (about two-thirds of the width) with a
  filled sun and filled mountains clipped inside, flanked by two solid
  crescents set close to the ring. Rendered as a template image so macOS colors
  it for light and dark menu bars, drawn at 20 pt.
  - *Why:* the first version (draft 7) used thin outlines throughout; at 20 pt
    the inner landscape became a squiggle and the outlined crescents blurred.
    Solid shapes and a larger central circle fixed it, checked by rendering
    both at actual menu bar pixel sizes.

### Menu bar menu
`[D-menu-status-header]` Kept short. Status is a single section header, not separate dimmed items,
following the pattern of Apple's own menu bar extras (e.g. Time Machine's
"Latest backup" line).

- **Status header**, one line:
  - "Dusk · until 7:13 PM": active phase and when the next phase starts
    (weekday added if it's not today)
  - "All Day": an active phase with no upcoming phase change
  - "Dusk · Paused" while paused; "No active phase" if none applies
- **Change Now**: advances to the next image in the active phase
- **Pause Schedule** (checkmark when paused; saved across launches)
- **Open Phases…**: opens the Phases window
- If location access is denied and a phase needs it, one extra dimmed line
  says so (§6).

`[D-menu-no-shortcuts]` The current image's filename is not shown in the
menu. There is no Quit item
in the menu; Quit lives in the Phases window (below).

No keyboard shortcuts in the menu. Shortcuts in a menu bar extra's menu work
only while that menu is open, so they'd be decoration; Apple's own menu bar
extras don't show them. No global hotkey.

### Phases window (one window for everything)
- `[D-one-window]` A single resizable window with a sidebar. There is no
  separate Settings
  window: with two windows, the wrong one kept getting opened (draft 3 split
  them; draft 6 merged them back).
- **Sidebar, top to bottom:**
  1. **Branding panel** (decorative): a rounded panel in a 16:10 aspect ratio,
     like a laptop screen, spanning the sidebar's width (about 191 × 119 pt at
     the default sidebar width, measured from the running app). Centered, top
     to bottom:
     - the app icon, about 52 pt
     - "Phases" in a semibold title font
     - the tagline in two balanced lines, 12 pt light, with a deliberate break:
       "Wallpaper for every / phase of your day"
     - `[D-brand-layout]` *Why:* the first tagline ("Wallpaper sets for every phase of your
       day", 10 pt) wrapped awkwardly and was hard to read; with a 64 pt icon
       the contents filled the whole panel height. Shorter text, a chosen line
       break, and a smaller icon fixed both (compared in mockups at the
       panel's real size).
     - `[D-brand-fixed-text]` **Fixed text sizes:** the name (15 pt semibold) and tagline (12 pt
       light) use fixed point sizes, not system text styles, so the panel
       looks the same at every Sidebar icon size and Text size setting. It's
       a fixed-shape decorative graphic with no room for text to grow; the
       rest of the window scales normally. VoiceOver reads the name and
       tagline from the panel's accessibility label.
     - **Background:** a soft blue-to-indigo gradient taken from the app icon
       until Phases has applied a wallpaper; after that, the wallpaper
       currently on the main display. It updates when the wallpaper changes.
     - `[D-brand-legibility]` **Legibility:** the wallpaper is not dimmed overall. A soft black
       gradient rises from the bottom edge, behind the name and tagline only;
       the top of the image keeps its full brightness. The icon needs no help
       (it has its own solid tile).
       - *Why:* draft 8 dimmed the whole image by 35%, which turned light
         wallpapers grey and lifeless. A brightness-adaptive gradient was
         considered and deferred; add it only if light images prove hard to
         read.
     - `[D-brand-scrolls]` It's the first item in the sidebar list, so it
       **scrolls away** when
       there are enough phases to scroll; it's never pinned.
  2. `[D-settings-at-top]` **"App" section:** a **Settings** row (gear icon). It sits at the top so
     it's always visible however many phases there are; the HIG advises
     against putting important items at the bottom of a sidebar, since window
     bottoms often end up offscreen.
  3. **"Phases" section:** the phase list, sorted by start time, with the
     active phase marked. Phase rows are two lines (name plus trigger), which
     also sets them apart from the one-line Settings row.
  - + / − buttons below the list add and remove phases. − removes the
    selected phase and is dimmed when no phase is selected.
  - `[D-delete-selects-next]` **After deleting a phase, the next phase down
    is selected.** That is the phase that moves into the deleted one's
    place in the time-sorted list. If the deleted phase was last, the one
    above it is selected; if no phases are left, Settings is selected.
    - *Why:* draft 15 always jumped to the first phase, which threw away
      the user's place in the list (found in testing, 2026-10-28). Mail and
      Finder select the next item after a delete (recalled, not tested).
      The HIG has no explicit rule about this; matching those apps follows
      its general call for familiar, consistent behavior.
  - `[D-sidebar-footer-style]` **+ / − layout matches System Settings.**
    Reference: System Settings › General › Login Items & Extensions, the
    + / − under "Open at Login" (macOS 27). Measured from a screenshot
    (2026-10-28): each button is a 24 × 23 pt cell, with a 1 pt vertical
    divider, 16 pt tall and centered, between the two; the whole cell is
    clickable. The divider uses the system separator color. Glyphs stay the
    default size (about 9 pt wide, matching the reference).
    - *Why:* draft 14 placed the two icons side by side with no gap ("+−"),
      making them small, crowded targets. The pressed state is left as the
      system draws it; see "Platform quirks".
  - `[D-footer-ax-labels]` **+ and − carry explicit accessibility labels**
    ("Add Phase", "Delete Phase"), set on the buttons themselves, so
    VoiceOver and other assistive tools can name them.
    - *Why:* a 2026-10-28 test suggested the draft 16 buttons had no
      accessibility name, but that reading came from System Events, which
      turned out not to see these descriptions at all (see "Platform
      quirks"). So the original gap is unconfirmed. The explicit labels stay
      as cheap insurance; with them, the AX API reports "Add Phase" and
      "Delete Phase" (verified 2026-10-28).
  - `[D-sidebar-footer-view]` The + / − buttons are their own view, bound
    to the sidebar selection, not inline in the window's body.
    - *Why:* in draft 13, − did nothing (found in testing, 2026-10-28). The
      buttons sit in a bar pinned below the sidebar list, and macOS SwiftUI
      doesn't reliably refresh that bar when the selection changes. The
      window opens with nothing selected, so − started disabled and stayed
      that way. A separate view with its own binding to the selection is
      refreshed whenever the selection changes, and reads it at click time.
- `[D-initial-focus-sidebar]` **The sidebar list has keyboard focus when
  the window opens.** No text is selected and typing doesn't edit anything,
  the same as after clicking a phase in the sidebar.
  - *Why:* in draft 17, macOS focused the first text field (the selected
    phase's Name) on open and selected its text, so any keypress replaced
    the phase's name (found in testing, 2026-10-28). Undo worked, but
    renaming shouldn't be one stray key away.
  - *How:* the window moves focus to the sidebar list one run-loop pass
    after it appears, once the phase editor is in place. Draft 18 used
    SwiftUI's `.defaultFocus` on the list, which the Name field still beat
    (see "Platform quirks").
- `[D-sidebar-width]` **Sidebar width:** resizable from **240 pt** (minimum and default) to
  **320 pt** (maximum). The sidebar opens at its narrowest and can only be
  widened.
  - *Why the minimum:* draft 10 allowed 220 pt, but at that width the
    branding panel was cramped (found in testing, 2026-10-28). 240 pt also
    leaves headroom for phase rows at the Large sidebar icon size (System
    Settings › General), where row text grows and names and trigger times
    truncate sooner. The HIG gives no numeric sidebar widths; it asks only
    for reasonable pane minimums and maximums (Split views) and notes that
    sidebar text scales with the icon size setting (Sidebars, macOS).
  - *Why the maximum:* without one, the sidebar could be dragged across nearly
    the whole window, squeezing the editor into an unusable column, and the
    branding panel's fixed-size icon and text looked lost in a huge panel
    (found in testing, 2026-10-27). 320 pt leaves room for long phase names
    while keeping the editor the primary area.
- `[D-sidebar-always-visible]` **The sidebar can't be hidden.** There is no
  sidebar toggle button, and dragging the divider past the minimum width
  doesn't collapse it.
  - *Why:* the sidebar is the window's only navigation (Settings and every
    phase), so hiding it leaves an editor with no visible way to anything
    else. As a menu bar accessory, Phases has no View › Show Sidebar menu item
    to recover with. The editor is a form, so hiding a ≤ 320 pt sidebar gains
    nothing.
  - The `[D-sidebar-width]` minimum does **not** prevent collapsing: macOS
    snaps a sidebar shut when its divider is dragged past the minimum, and
    since the sidebar opens at its minimum, a short leftward drag closed it
    (reproduced 2026-10-28). Removing the toggle alone would have made that
    unrecoverable except by dragging the window's edge.
  - *How:* the sidebar's underlying AppKit split view item is marked as
    not collapsible, with its minimum and maximum thickness set from
    `[D-sidebar-width]`, so dragging stops at 240 pt.
  - **Works around SwiftUI on purpose.** SwiftUI has no way to stop a
    sidebar from collapsing, so Phases reaches past `NavigationSplitView` to
    the AppKit `NSSplitViewController` SwiftUI happens to use for it, and
    changes that controller's sidebar item. This relies on undocumented
    internals and **may break in a future macOS update**. If it does, the
    sidebar simply becomes collapsible again (nothing worse). All of it is in
    `App/Views/SidebarSplitItemConfigurator.swift`; check there first if the
    sidebar starts collapsing after an OS update.
  - *Design history:* the first version (2026-10-28) let the sidebar
    collapse and reopened it right away. In testing, the sidebar flickered
    closed and open on every mouse move during the drag, and the 240 pt
    minimum stopped working (it shrank to about 90 pt). Replaced with the
    non-collapsible split view item.
- **Phase selected:** editor with name, trigger, offset, appearance condition,
  order, rotation, and the Images section (Display picker and thumbnail grid).
- **Settings selected:** image folder and Include subfolders; display sharing
  preference (§4); transition and duration; Launch at Login; location status
  with today's civil dawn and dusk and Update Now; and, at the bottom, a
  **Quit** section with the **Restore original wallpaper when quitting** toggle
  and a **Quit Phases** button whose note says what quitting will do (§8a).
- `[D-quit-in-window]` **⌘Q** quits Phases whenever the Phases window is
  active, and Settings has the Quit Phases button (above).

No Dock icon. The app runs as a menu bar accessory, so it has no app menu;
that's why Quit needs a home in the window.

## 8. Launch at login: explicit consent only

`[D-login-consent]`

- Preference **Launch at Login**, **off by default**.
- The app never turns it on by itself. Turning it on shows a confirmation that
  explains what it does ("Adds Phases to System Settings › General ›
  Login Items") before anything is registered.
- Implemented with `SMAppService.mainApp`, which registers the app itself as a
  standard Login Item. It does **not** install a LaunchAgent plist or any daemon,
  and the app installs no other agents, daemons, or helpers. If that ever
  changes, the app has to ask first.
- Turning it off unregisters it. If the user removes it in System Settings, the
  preference updates to match.

## 8a. Restore original wallpaper on quit

- At launch, before changing anything, Phases records each display's current
  wallpaper (image file plus fill/scaling options), keyed by display ID.
- The record is saved to disk and kept until it's been restored. After a crash
  or Force Quit, the next launch reuses it instead of recording Phases' own image.
- `[D-restore-on-quit]` **App preference: Restore original wallpaper when
  quitting**, **on by default**. When on, an actual **Quit** restores each
  display's original and clears the record. When off, Quit leaves Phases'
  current image in place and clears the record, so the kept image becomes the
  "original" the next launch records.
  - *Why a preference:* restoring is what the author expects (Phases' images
    belong to Phases), but someone else may expect the wallpaper to stay as
    it is after the app quits. Both are valid ways to use the app. Draft 12
    and earlier always restored.
  - Logout, restart, shutdown, and **Pause** leave the current image in
    place regardless of the setting; at logout the record is kept for the
    next launch.
- `[D-aerials-untouched]` **Aerials and other system wallpapers:** Phases
  reads (never writes) macOS's
  wallpaper store to detect them. The public API can't restore them, so those
  displays are left alone on quit instead of getting a still frame.
- Displays that were disconnected in the meantime are skipped. If the original
  image file no longer exists, that display is skipped.

## 9. Platform notes and limitations

- `NSWorkspace.setDesktopImageURL(_:for:options:)` sets the image **per screen**,
  so different images per display are supported.
- It only affects the **currently active Space** on each screen. Other Spaces
  keep their own wallpaper. There is no public API to set every Space.
- With "Displays have separate Spaces" on (the macOS default), each display has
  its own current Space, and the app sets each one.
- `[D-single-timer]` Scheduling uses a single timer aimed at the next event, recalculated after
  every change, wake, or settings edit, with an hourly re-check as a safety net
  against clock drift. No polling loop.

## 10. Persistence

All settings (folder bookmark, phases including per-display selections,
preferences, in-order positions, last applied phase and image per display, known
displays and their names, last location) are stored in UserDefaults as Codable
data. Phases saved by earlier versions load unchanged (no per-display images).

## 11. Out of scope (v1)

- Different schedules per weekday
- Multiple folders or online image sources
- Different wallpaper per Space
- Scaling/fill options (uses the current macOS fill setting)

## 12. Known issues

- Unreproduced: the desktop once turned black. Source folder is local storage
  (not a cloud-synced folder). No change until it can be reproduced.
- Restoring an Aerial isn't supported yet (see §8a). Possible approach: back up
  and restore macOS's wallpaper store file and restart the wallpaper process.
  Undocumented, so it needs explicit approval before building.
- **Menu bar blanks for about 0.1 s when the wallpaper changes (macOS behavior,
  confirmed 2026-10-26).** Frame-by-frame recordings of a change made in System
  Settings show the same thing: the menu bar keeps its old styling for a couple
  of frames, disappears for 2–3 frames, then returns restyled. Phases' fade-in
  design keeps the menu bar steady during the fade and limits this to the one
  blink at the end. Not fixable by Phases.
- **macOS sometimes doesn't restyle the menu bar after a wallpaper change until
  the frontmost app changes** (macOS 27.0.1). In a recording of System
  Settings' own 5-second shuffle, the menu bar's styling changed when apps
  were switched, not when the wallpaper changed. Bug or design decision is
  unknown. Phases could force a restyle by briefly activating itself, but that
  would steal focus from the user's app, so it deliberately doesn't
  `[D-no-focus-steal]`.
  Reported to Apple: **FB25326597** (2026-10-27).
- Bartender (menu bar manager) caused additional odd menu bar behavior during
  testing. Not a Phases issue.

## 13. Platform quirks

Framework and OS behavior that affects Phases' code and is easy to trip
over. Each entry says whether it was **verified** (tested or measured, with
date) or is **recalled** (believed from past knowledge, not tested here).
Add new quirks here when they're found; link them from the `[D-…]` decision
they shaped.

- **SwiftUI: content in a List's `.safeAreaInset` may not refresh when the
  parent view's state changes (macOS).** *Recalled*, not verified against
  Apple documentation or a bug report. Matches the draft 13 bug where −
  stayed disabled; moving the bar into its own view with a binding fixed it
  (fix verified by the author, 2026-10-28). Shaped
  `[D-sidebar-footer-view]`.
- **SwiftUI: `.defaultFocus` on the sidebar List doesn't stop macOS from
  focusing the first text field when the window opens (macOS 27).**
  *Verified* 2026-10-28 by the author, across several relaunches: with
  `.focused` + `.defaultFocus` on the List, the phase's Name field still
  opened focused with its text selected. The AX API confirmed it: the
  focused element is the Name text field, with all of its text selected
  (2026-10-28). Moving focus one run-loop pass after `onAppear` works:
  the AX API then reports the sidebar outline as focused (verified
  2026-10-28). That fits a timing cause (the editor appears after SwiftUI
  applies default focus), but the cause itself is unproven. Shapes
  `[D-initial-focus-sidebar]`.
- **System Events (AppleScript) doesn't report SwiftUI button
  descriptions (macOS 27).** *Verified* 2026-10-28: for the + / − buttons,
  System Events' `description` returned only "button" and found no
  AXDescription, while the AX API (`AXUIElementCopyAttributeValue`) read
  "Add Phase" / "Delete Phase" from the same buttons. Check accessibility
  labels with the AX API or Accessibility Inspector, not System Events.
  Whether an icon-only `Label` wrapped in `.frame`/`.contentShape` loses its
  title on its own is *unverified*; `[D-footer-ax-labels]` sets the label
  explicitly either way.
- **SwiftUI: borderless buttons show their pressed state only by darkening
  the icon (macOS 27).** *Verified* 2026-10-28 by holding the mouse down
  and measuring screenshots: Phases' + went from 0.53 to 0.18 gray; System
  Settings' Login Items + went from 0.52 to 0.35. There's no background or
  whole-area highlight, and the change sits under the mouse pointer, so
  it's easy to miss. Earlier macOS versions highlighted the whole button
  more clearly (author's recollection). Same as Apple's own +/− bars, so
  Phases matches it for now `[D-sidebar-footer-style]`.
  - **Possible future TODO:** revisit (a) a custom pressed state that
    highlights the whole 24 × 23 pt cell, and (b) how the system style
    behaves on earlier macOS versions Phases supports (deployment target is
    macOS 26; only macOS 27 was tested).
