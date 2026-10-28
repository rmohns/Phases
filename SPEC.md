# Phases — Specification (draft 22)

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
- `[D-grid-one-tab-stop]` **Keyboard: the thumbnail grid is one Tab stop.**
  Tab moves into the grid and the next Tab moves past it, the way Finder's
  icon view and Photos work. Inside the grid:
  - **Arrow keys** move a highlighted image (the cursor). Left and right
    step through images in order, wrapping across rows. Up and down move by
    one row in the same column, crossing subfolder headings; on a shorter
    row the cursor lands on its last image.
  - **Space** toggles the highlighted image; **⇧-Space** selects a range
    from the last toggled image, the same as ⇧-click.
  - The window scrolls to keep the highlighted image visible.
  - The highlight shows only while the grid has keyboard focus. Clicking an
    image moves the highlight there and focuses the grid.
  - Images are not individual Tab stops, and VoiceOver still sees each image
    as a toggleable button with its file name.
  - *Why:* in draft 19 each image was its own button. Tab stopped only at
    images already on screen, then jumped back to the sidebar instead of
    scrolling (found in testing, 2026-10-28; see "Platform quirks"). Making
    every image a Tab stop would fix that but cost one keypress per image to
    get past a large folder. One Tab stop with arrow keys matches macOS
    collection views and adds arrow-key movement.
  - *Verified* 2026-10-28 by the author: Tab enters and leaves the grid in
    one stop, arrows (including up/down column math) and ⇧-Space work, and
    the window scrolls to follow the cursor (`ScrollViewReader` around the
    grouped Form).
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

### When displays change
- `[D-screen-change-no-reroll]` When macOS reports a display change
  (connect, disconnect, resolution, arrangement, or anything else that
  changes screen geometry), Phases updates its list of known displays and
  then runs its normal check (the same one used after wake). The wallpaper
  changes only if something no longer fits: a newly connected display has
  no image yet, or a display's image isn't in its selection. Otherwise
  nothing changes. A screen change never by itself picks new images.
  - *Why:* draft 21 re-applied the active phase on every display change.
    With Random order, that picked a new image each time. macOS sends the
    same notification when the Dock is hidden or shown and when "Show menu
    bar background" is toggled, so those started a crossfade to a new
    image (found in testing, 2026-10-28, on macOS 27.2; see "Platform
    quirks").
  - When a change is needed, the whole phase is re-applied, so with Random
    a newly connected display can also give the other displays new picks.
    Unchanged from earlier drafts.

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
  4. **Remove:** `[D-cover-settle]` after a settle delay of **1.5 s**, to let
     macOS finish drawing the new wallpaper (including its own brief
     change motion), the cover is removed. This is invisible, since the
     cover and the wallpaper match.
     - *Why 1.5 s:* macOS shows an app-set wallpaper about 0.55–0.65 s
       after Phases sets it, then plays about 0.13 s of its own motion
       (see "Platform quirks"). Draft 5's 0.5 s delay removed the cover
       right as that motion played, bringing the twitch back (see "The
       twitch returns" below). 1.5 s leaves about 0.7 s of margin. A
       longer-lived cover can't be seen, because it shows the same image
       as the wallpaper behind it.
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

### The twitch returns (2026-10-28, draft 22)

The twitch came back on macOS 27.2, on one display or two. A frame-by-frame
analysis of a screen recording (seven changes) showed:

- The fade itself is smooth, and the cover matches the final wallpaper
  exactly (before and after differ only at noise level). So the cover's
  image and geometry aren't the cause.
- The twitch is about 0.13 s of the image shifting and settling back. It
  starts 0.55–0.65 s after the fade ends, in the same frames as the menu
  bar restyle: that's when macOS actually shows the new wallpaper.
- The cover was removed 0.5 s after the fade ended `[D-cover-settle]`, just
  before macOS's own motion, so the motion showed through.

The crossfade code's timing hadn't changed since draft 5. The author
believes (not certain) the original fix was tested on macOS 27.1, so
macOS 27.2 may have made wallpaper changes slower. That's unconfirmed; the
draft 5 timing may also have been marginal from the start. The fix is a
longer settle delay (1.5 s), not a new mechanism. See "Platform quirks" for
the measured macOS behavior.

The same recording showed a second, separate problem: turning System
Settings' "Show menu bar background" on or off started a crossfade to a new
image. See `[D-screen-change-no-reroll]` (§4).

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
     like a laptop screen, spanning the sidebar's width between the inset
     edges below (expected about 201 × 126 pt at the default sidebar width).
     Centered, top to bottom:
     - `[D-brand-inset]` **Edges line up with the traffic lights and row
       icons.** The panel's left edge matches the left edge of the red
       traffic-light button and of the sidebar row icons, about 19–20 pt
       from the window's left edge (measured from a 2× screenshot with the
       tall toolbar, 2026-10-28). The right edge mirrors it.
       - *Why:* the original 8 pt row inset matched nothing (about 25 pt from
         the edge). Matching the selection highlight (about 10 pt) was tried
         next and made the panel feel crowded against the sidebar edge
         (found in review, 2026-10-28). Once `[D-tall-toolbar]` moved the
         traffic lights right, their edge and the row icons' edge coincide,
         so one line serves both.
       - *How:* the row inset is +3 pt on each side; the system list adds
         about 14–16 pt of its own padding inside a row's insets. Negative
         insets are honored if ever needed (verified, 2026-10-28). Recheck
         if a macOS update moves the traffic lights or row icons.
       - **Top edge:** the panel's top lines up with the top of the first
         grouped row in the detail form (the Name row, or Settings' first
         row), so the sidebar and detail start content on one line under
         the toolbar `[D-tall-toolbar]`. The row's top inset is 20 pt
         (measured: the form starts about 16 pt lower than the panel did
         with a 4 pt inset).
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
    - The rule lives in a small model function (`PhaseListSelection`), not
      in the view, so the unit tests can check it (see "Testing").
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
- `[D-tall-toolbar]` **Full-height toolbar over the detail pane only.** The
  window keeps macOS's tall unified toolbar, like System Settings and
  Bitrig, even though it has no toolbar buttons. The sidebar stays full
  height beside it. The toolbar title always names the sidebar selection:
  the phase name, "Settings", or the window name "Phases" when nothing is
  selected.
  - *Why:* removing the sidebar toggle left the toolbar empty, and the
    window fell back to a short title bar. The traffic lights moved up and
    the form's top crowded into the title area (found in review,
    2026-10-28). A Notes-style toolbar across the full width only works
    there because Notes' folder sidebar can be hidden, which
    `[D-sidebar-always-visible]` rules out. System Settings' hide-the-title-
    until-you-scroll was rejected: it has no SwiftUI API that I know of
    (recalled), and the Name field already shows the phase name.
  - *How:* `.windowToolbarStyle(.unified)` alone did nothing, because
    SwiftUI gives the window no toolbar at all when it has no items (see
    "Platform quirks"). The window's AppKit `NSToolbar` is therefore
    created by hand, empty, with the unified style, when SwiftUI hasn't
    made one. It's set to icon-only display, which brought the title area
    from 66 pt down to the standard 52 pt (verified from diagnostic
    logging and a screenshot, 2026-10-28).
  - **Status: appears fixed, cause not proven.** Icon-only fixed the
    height, which fits the theory that the default display mode reserves
    a row for item labels. Nobody confirmed that theory in Apple
    documentation. If the toolbar grows tall again, first check (by
    logging `frame.height − contentLayoutRect.height`) whether the toolbar
    is still icon-only and whether SwiftUI has replaced it with its own.
  - `[D-window-helper-order]` **One helper, in a fixed order.** A single
    AppKit helper (`App/Views/WindowLayoutConfigurator.swift`) attaches the
    toolbar first, then, one run-loop pass later, sets the sidebar's split
    view limits (`[D-sidebar-width]`, `[D-sidebar-always-visible]`).
    - *Why:* with two separate helpers, the order they ran in varied by
      launch. Suspected (not proven): when the sidebar limits went on
      first, attaching the toolbar rebuilt the split view and wiped them,
      so the sidebar could be dragged to any width (regression found in
      review, 2026-10-28; didn't reproduce in a logged run where the
      toolbar went first). The run-loop pass covers the rebuild happening
      after the toolbar is attached.
    - **Status: appears fixed, cause not proven.** With the merged helper,
      one logged launch kept the limits on a single split view through
      520 resizes, with drags stopping at exactly 240 and 320 pt
      (2026-10-28). The original failure was never caught in a log, so
      the ordering theory is unconfirmed: the fix may have worked for a
      different reason, or the bug may be intermittent and just didn't
      happen. **If the sidebar width limits vanish again,** don't retry
      the ordering fix. Instead, log the split view controller's identity
      at launch and on each resize, to see whether SwiftUI swaps in a new
      one later, and log the item's `minimumThickness`/`maximumThickness`
      to see what resets them. The untried fallback is re-applying the
      limits whenever the split view resizes.
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
    `App/Views/WindowLayoutConfigurator.swift` (`[D-window-helper-order]`);
    check there first if the
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

- **macOS: an app-set wallpaper appears about 0.55–0.65 s after
  `setDesktopImageURL` returns, followed by about 0.13 s of macOS's own
  motion (macOS 27.2).** *Measured* 2026-10-28 from a 30 fps screen
  recording of seven Phases changes on one display: the menu bar restyle
  and a brief shift-and-settle of the wallpaper image both land
  0.55–0.65 s after the fade ends, which is when Phases sets the
  wallpaper. Whether macOS 27.1 was faster is *unknown*: the draft 5 fix
  worked then with a 0.5 s delay, and the author believes (not certain)
  that was on 27.1. Shapes `[D-cover-settle]`; history in "The twitch
  returns" (§4a). If the twitch comes back again, measure this delay
  first, the same way.
- **AppKit: `NSApplication.didChangeScreenParametersNotification` fires
  for more than display changes (macOS 27.2).** *Verified* 2026-10-28 by
  the author: hiding or showing the Dock, and toggling System Settings ›
  Menu Bar › "Show menu bar background", each started a Phases crossfade,
  which only that notification could trigger. The likely reason, that
  these change each screen's visible frame, is *recalled*, not checked.
  Display UUIDs don't change. Shapes `[D-screen-change-no-reroll]` (§4).
- **SwiftUI: a window with no toolbar items gets no toolbar at all, so
  `.windowToolbarStyle(.unified)` has no effect and the title bar stays
  short (macOS 27).** *Verified* 2026-10-28: after removing the sidebar
  toggle and adding `.windowToolbarStyle(.unified)`, the title bar stayed
  short in a screenshot, and the AX API listed no toolbar on the window.
  Shapes `[D-tall-toolbar]`.
- **AppKit: an empty unified `NSToolbar` makes the title area 66 pt tall
  (macOS 27).** *Verified* 2026-10-28 from diagnostic logging: the window's
  title area went from 32 pt (no toolbar) to 66 pt the moment an empty
  `NSToolbar` with `.unified` style was attached, and stayed there. That's
  taller than Notes' toolbar (about 50 pt in a screenshot). Setting the
  toolbar's `displayMode` to `.iconOnly` brought it to 52 pt (verified
  2026-10-28). The label-row explanation is a theory, not confirmed.
  Affects `[D-tall-toolbar]`.
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
- **SwiftUI: Tab can't reach buttons in a `LazyVGrid` that haven't been
  created yet, and the Form doesn't scroll to follow Tab (macOS 27).**
  *Partly verified* 2026-10-28 from a screen recording: Tab visited only the
  on-screen thumbnails (including two half-visible ones, without scrolling),
  then wrapped to the sidebar. The cause (lazy grids only create views near
  the visible area, and only existing views are in the Tab order) is
  *recalled*, not proven. Shaped `[D-grid-one-tab-stop]`.
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

## 14. Testing

Regressions found in testing (the − button doing nothing, the Name field
taking focus, Tab skipping the grid) are why Phases has tests. They come in
two layers.

### Layer 1: unit tests (in place, draft 21)

- A small Swift package in `UnitTests/`, using Swift Testing. Run it with
  `swift test` from that folder (about 30 tests, well under a second once
  built).
  - *Why a package, not a test target in Project.json:* `bitrig test`
    doesn't see test targets in Project.json projects ("has no test
    targets", verified 2026-10-28), and there's no generated Xcode project
    to hand to `xcodebuild`. `swift test` needs neither.
- Covers the pure logic that decides what the app does:
  - `ScheduleEngine`: which phase is active (including overnight and
    Light/Dark conditions), the next phase start, and rotation slots, which
    are how `[D-missed-latest-only]` lands on the most recent missed rotation
  - `SolarCalculator`: civil dawn and dusk at a known location, and days with
    no civil dawn or dusk (far north)
  - `ImageGridNavigation`: arrow-key movement `[D-grid-one-tab-stop]`
  - `PhaseListSelection`: which phase is selected after a delete
    `[D-delete-selects-next]`
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

### Layer 2: UI tests (planned, not built)

- XCUITest tests that drive the real Phases window (these need an Xcode
  test target, so first find a way to run one, given the `bitrig test`
  limit above), aimed at the focus and
  wiring bugs Layer 1 can't see. Start with the UI tests marked in
  "Regressions found so far" below.
- Before building: decide how a UI test run avoids changing the real
  wallpaper (`[D-tests-unhosted]` doesn't apply, since UI tests must launch
  the app). Whether XCUITest drives a menu bar accessory app's window
  reliably is *recalled* as finicky, not tested.

#### Regressions found so far

Bugs found in testing and fixed, oldest first, with how a test could guard
each one. Design changes made after review (menu bar icon legibility,
sidebar width limits, branding panel dimming) aren't listed; neither is the
unreproduced black desktop (see "Known issues"). Entries marked *git only*
were found in the commit history, not in this spec.

| Found | What broke | Fix | Guarded by |
|---|---|---|---|
| 2026-10-25 | Long image folder names in Settings were truncated badly (*git only*, commit 4e86957) | Middle truncation, full path in a tooltip | Nothing yet; visual only (AX reports the full name), so a screenshot check |
| 2026-10-26 (draft 4) | Crossfade flashed the new image and twitched before fading; menu bar blinked to the new styling at the start | Fade the new image in and set the wallpaper at the end `[D-fade-in]` | Not suited to XCUITest (frame timing); checked with frame-by-frame recordings. Twitch returned on macOS 27.2 (see the draft 21 row below) |
| 2026-10-27 (draft 10) | Branding tagline cut off after its first line, because sidebar rows default to one line (*git only*, commit 58555d3) | Allow two lines on the tagline | Nothing yet; visual only (the panel's AX label is fixed text), so a screenshot check |
| 2026-10-28 | Dragging the sidebar divider past its minimum collapsed the sidebar, with no way to reopen it; the first fix flickered and broke the 240 pt minimum | Non-collapsible split view item `[D-sidebar-always-visible]` | **UI test:** drag the divider far left; the sidebar stays at least 240 pt wide |
| 2026-10-28 (draft 13) | − did nothing: it started disabled and never re-enabled when a phase was selected | +/− bar as its own view bound to the selection `[D-sidebar-footer-view]` | **UI test:** select a phase, click Delete Phase; the phase is gone |
| 2026-10-28 (draft 15) | Deleting a phase always selected the first phase | Select the next phase down `[D-delete-selects-next]` | Unit test (Layer 1); **UI test:** delete a middle phase; the one below is selected |
| 2026-10-28 (draft 17; draft 18's fix didn't work) | The Name field had focus with its text selected when the window opened, so any keypress renamed the phase | Move focus to the sidebar a run-loop pass after the window appears `[D-initial-focus-sidebar]` | **UI test:** open the window, type a letter; the phase name is unchanged |
| 2026-10-28 (draft 19) | Tab visited only the on-screen thumbnails, didn't scroll, then jumped back to the sidebar | Grid is one Tab stop with an arrow-key cursor `[D-grid-one-tab-stop]` | Unit test for arrow movement (Layer 1); **UI test:** Tab enters and leaves the grid in one stop, and arrowing down past the visible rows scrolls |
| 2026-10-28 | Title bar became short and crowded after the sidebar toggle was removed; then the fix made it 66 pt tall | Hand-made empty unified toolbar, icon-only `[D-tall-toolbar]` | Nothing yet; a screenshot check (toolbar 52 pt). Cause of the 66 pt only theorized |
| 2026-10-28 | Sidebar could be dragged far below 240 pt and far above 320 pt again, right after the toolbar helper was added | One helper, toolbar first, then sidebar limits `[D-window-helper-order]` | **UI test:** drag the divider both ways; width stays 240–320. Appears fixed; cause not proven, never caught in a log |
| 2026-10-28 (draft 21, macOS 27.2) | The crossfade twitch returned: the cover was removed while macOS was still showing the new wallpaper | Settle delay raised from 0.5 s to 1.5 s `[D-cover-settle]`; see "The twitch returns" (§4a) | Not suited to XCUITest (frame timing); checked with frame-by-frame recordings |
| 2026-10-28 (draft 21) | Hiding the Dock or toggling "Show menu bar background" crossfaded to a new image | Screen changes run the normal check instead of re-applying `[D-screen-change-no-reroll]` | Nothing yet; a unit test would need the scheduler's check pulled out of `WallpaperScheduler` |
