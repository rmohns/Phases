# Phases — Specification (draft 25)

A personal macOS menu bar app that changes the desktop wallpaper on a schedule.
Not intended for the App Store.

This file says what Phases does and why. What macOS, SwiftUI, and AppKit do
to Phases, and how Phases routes around it, lives in **ERRATA.md**: platform
quirks, workaround mechanics, the design history behind them, diagnostic
procedures, and the regressions list. Sorting test: if a future macOS fixed
the bug, would the line still be true? Yes → here. No → ERRATA.md.

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
- **Platform quirks** carry a `[Q-…]` tag in ERRATA.md. A decision whose
  implementation fights the platform says so in one line ("macOS fights
  this; see `[Q-…]`"), and its *How* lives in ERRATA.md. Code comments
  carry both tags where relevant, so one search finds spec, errata, and
  code.
- `[D-refs-by-id]` **Cross-references use a `[D-…]` or `[Q-…]` tag or a
  section title, never a section number,** in this spec, ERRATA.md, and
  code comments. Sections aren't numbered, so adding one never breaks a
  reference. Prefer the tag when one covers the point; otherwise quote the
  section title, e.g. see "Persistence".
  - *Why:* drafts up to 22 numbered sections (§4a and so on) and cited
    them by number, which breaks whenever a section is added or moved
    (author's rule, 2026-10-28).

## Core model: phases plus rotation

The schedule is a list of **phases**. Exactly one phase is active at any moment.

Each phase has:

| Field | Description |
|---|---|
| Name | e.g. "Morning", "Night" |
| Start trigger | When the phase begins (see "Start triggers") |
| Images (All Displays) | Images chosen from the library (multi-select). Used by every display that doesn't have its own selection (see "Per-display images") |
| Images (per display) | Optional: a separate selection for a specific display, used instead of the All Displays images on that display (see "Per-display images") |
| Order | Random or In order |
| Rotation | Optional: change to the next image every N minutes or hours while the phase is active |
| Appearance | Only in: **Any** (default), **Light**, or **Dark** mode (see "Light and Dark Mode") |

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

## Start triggers

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

## Light and Dark Mode

- Each phase has an **Only in** setting: Any, Light, or Dark.
- The app listens for system appearance changes (including Auto switching) and
  re-evaluates immediately. If the switch makes a different phase active, the
  wallpaper changes right away; otherwise nothing happens.
- Examples:
  - *Dark images whenever Dark Mode is on:* two "Always" phases, one Light and one Dark.
  - *Dusk pictures, darker ones in Dark Mode:* two dusk phases, one Light and one Dark.
- The phase list shows a light/dark badge on phases with a condition.

## Image library

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
  - *Why:* in draft 19 each image was its own button, and Tab couldn't get
    through a grid larger than the window (found in testing, 2026-10-28).
    Making every image a reachable Tab stop would cost one keypress per
    image to get past a large folder. One Tab stop with arrow keys matches
    macOS collection views and adds arrow-key movement. macOS fights the
    per-image approach; see `[Q-lazy-grid-tab]`.
  - *Verified* 2026-10-28 by the author: Tab enters and leaves the grid in
    one stop, arrows (including up/down column math) and ⇧-Space work, and
    the window scrolls to follow the cursor.
- If a selected image is later deleted or renamed, it's skipped and the phase
  editor marks it as missing. A phase with no available images is skipped
  (the wallpaper stays as it is).

## Displays

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

- Changes apply to the current Space on each display (macOS limitation; see "Platform notes and limitations").

### When displays change
- `[D-screen-change-no-reroll]` When macOS reports a display change
  (connect, disconnect, resolution, arrangement, or anything else that
  changes screen geometry), Phases updates its list of known displays and
  then runs its normal check (the same one used after wake). The wallpaper
  changes only if something no longer fits: a newly connected display has
  no image yet, or a display's image isn't in its selection. Otherwise
  nothing changes. A screen change never by itself picks new images.
  - *Why:* a change that leaves every display's image fitting shouldn't
    change the wallpaper. Draft 21 re-applied the active phase on every
    display change, so with Random order unrelated system changes such as
    hiding the Dock crossfaded to a new image (found in testing,
    2026-10-28). macOS fights this; see `[Q-screen-params-notification]`.
  - When a change is needed, the whole phase is re-applied, so with Random
    a newly connected display can also give the other displays new picks.
    Unchanged from earlier drafts.

## Transitions

- **App preference: Transition**: None or **Crossfade** (default).
- **App preference: Duration**: 0.5 to 3 seconds (default 1 second), shown
  only when Crossfade is selected.
- macOS has no transition for wallpapers set by apps, so Phases does it itself
  by **fading the new image in over the old wallpaper** `[D-fade-in]`
  (see *Why fade in* below):
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
     - *Why:* removing the cover before macOS has finished drawing lets
       its motion show through as a twitch. A longer-lived cover can't be
       seen, because it shows the same image as the wallpaper behind it,
       so the delay errs long. macOS fights this; see
       `[Q-wallpaper-motion-delay]` (timing and margin in ERRATA.md
       "Crossfade settle timing").
     - *Cost:* the menu bar's background restyles only when the cover
       comes off, so it lags the fade by about 1.5 s; see
       `[Q-menubar-bg-follows-window]`.
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
  - Restoring the original wallpaper on quit `[D-restore-on-quit]`
- If another change starts while a fade is running, the running fade finishes
  instantly (its wallpaper is set and its cover removed) and the new change
  starts its own fade.
- *Why fade in `[D-fade-in]`:* the real wallpaper changes only at the end,
  behind an identical image, so nothing flashes and the menu bar switches
  once, at the end, just as it does when changing wallpaper in System
  Settings. The old wallpaper is never redrawn, so crossfades also work
  when the outgoing wallpaper is an Aerial. Draft 4 faded the old image
  out instead; macOS fought that; see `[Q-menubar-reads-wallpaper]` and
  ERRATA.md "Why fade in, not fade out".
- `[D-no-focus-steal]` **Phases never activates itself to force a menu bar
  restyle.** That would steal focus from the user's app. macOS sometimes
  delays the restyle; see `[Q-menubar-restyle-on-app-switch]`.

## Missed changes: sleep, wake, unlock

On launch, wake from sleep, screen unlock, and time zone / clock changes, the app
`[D-missed-latest-only]`:

1. Works out which phase should be active right now.
2. If it differs from the last phase it applied, switches to it immediately.
3. If the same phase is active but one or more rotations came due while asleep,
   it applies only the **most recent** missed rotation: the image that would be
   showing now had the Mac stayed awake. For In order, that means skipping ahead
   by the number of missed rotations; for Random, a single new random pick. The
   rotation clock stays aligned to the original schedule.

## Location

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

## Interface

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
  says so (see "Location").

`[D-menu-no-shortcuts]` The current image's filename is not shown in the
menu. There is no Quit item
in the menu; Quit lives in the app menu, which shows while the Phases
window is open `[D-app-menu]`.

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
       traffic-light button and of the sidebar row icons. The right edge
       mirrors it.
       - *Why:* the original 8 pt row inset matched nothing (about 25 pt from
         the edge). Matching the selection highlight (about 10 pt) was tried
         next and made the panel feel crowded against the sidebar edge
         (found in review, 2026-10-28). Once `[D-tall-toolbar]` moved the
         traffic lights right, their edge and the row icons' edge coincide,
         so one line serves both.
       - **Top edge:** the panel's top lines up with the top of the first
         grouped row in the detail form (the Name row, or Settings' first
         row), so the sidebar and detail start content on one line under
         the toolbar `[D-tall-toolbar]`.
       - The insets that achieve this depend on macOS's own list padding;
         see `[Q-list-row-padding]` and ERRATA.md "Branding panel insets".
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
      system draws it; see `[Q-borderless-pressed-state]`.
  - `[D-footer-ax-labels]` **+ and − carry explicit accessibility labels**
    ("Add Phase", "Delete Phase"), set on the buttons themselves, so
    VoiceOver and other assistive tools can name them.
    - *Why:* cheap insurance. A 2026-10-28 test that suggested the draft 16
      buttons had no accessibility name used a tool that can't see them
      (`[Q-system-events-ax]`), so the original gap is unconfirmed. With the
      labels, the AX API reports "Add Phase" and "Delete Phase" (verified
      2026-10-28).
  - `[D-sidebar-footer-view]` The + / − buttons are their own view, bound
    to the sidebar selection, not inline in the window's body.
    - *Why:* in draft 13, − did nothing: it started disabled and stayed
      that way when a phase was selected (found in testing, 2026-10-28). A
      separate view with its own binding to the selection is refreshed
      whenever the selection changes, and reads it at click time. macOS
      fights the inline version; see `[Q-safe-area-inset-refresh]`.
- `[D-initial-focus-sidebar]` **The sidebar list has keyboard focus when
  the window opens.** No text is selected and typing doesn't edit anything,
  the same as after clicking a phase in the sidebar.
  - *Why:* in draft 17, macOS focused the first text field (the selected
    phase's Name) on open and selected its text, so any keypress replaced
    the phase's name (found in testing, 2026-10-28). Undo worked, but
    renaming shouldn't be one stray key away.
  - macOS fights this; see `[Q-default-focus-loses]` (*How* in ERRATA.md
    "Initial focus").
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
  - macOS fights this; see `[Q-no-items-no-toolbar]` and
    `[Q-empty-toolbar-66pt]` (*How* in ERRATA.md "Tall toolbar").
  - `[D-window-helper-order]` **One AppKit helper, in a fixed order.** All
    of the window's AppKit adjustments live in one helper
    (`App/Views/WindowLayoutConfigurator.swift`): it attaches the toolbar
    first, then, one run-loop pass later, sets the sidebar's limits
    (`[D-sidebar-width]`, `[D-sidebar-always-visible]`).
    - *Why:* every reach past SwiftUI is in one file, the first place to
      check after an OS update. Two separate helpers ran in a varying
      order. The ordering was meant to stop the toolbar wiping the sidebar
      limits; that theory turned out wrong, but the order is harmless and
      kept. See `[Q-split-item-rewrite]` and ERRATA.md "Sidebar limits:
      history".
- `[D-sidebar-always-visible]` **The sidebar can't be hidden.** There is no
  sidebar toggle button, and dragging the divider past the minimum width
  doesn't collapse it.
  - *Why:* the sidebar is the window's only navigation (Settings and every
    phase), so hiding it leaves an editor with no visible way to anything
    else. Phases has no View › Show Sidebar menu item to recover with
    (the app menu leaves out View, `[D-app-menu]`). The editor is a form, so hiding a ≤ 320 pt sidebar gains
    nothing. Removing the toggle alone isn't enough: a drag past the
    minimum would close it with no way back except dragging the window's
    edge.
  - macOS fights this; see `[Q-sidebar-collapse]`. The workaround relies on
    undocumented AppKit internals; if a macOS update breaks it, the sidebar
    simply becomes collapsible again (nothing worse). *How* in ERRATA.md
    "Sidebar limits".
  - `[D-sidebar-limits-watch]` **The limits are watched and put back
    whenever SwiftUI changes them,** event-driven, with no polling or
    timers. Idle cost is zero.
    - *Why:* SwiftUI resets them seconds after the window opens, so setting
      them once isn't enough; see `[Q-split-item-rewrite]`. No polling,
      because an idle menu bar app shouldn't use CPU (the author's standing
      requirement; see also `[D-single-timer]`).
- **Phase selected:** editor with name, trigger, offset, appearance condition,
  order, rotation, and the Images section (Display picker and thumbnail grid).
- **Settings selected:** image folder and Include subfolders; display sharing
  preference (see "Displays sharing the All Displays images"); transition and duration; Launch at Login; location status
  with today's civil dawn and dusk and Update Now; and, at the bottom, a
  **Quitting** section with the **Restore original wallpaper when quitting**
  toggle and a note that says what quitting will do `[D-restore-on-quit]`.
  No Quit button: Quit lives in the app menu `[D-app-menu]` (draft 24 and
  earlier had a Quit Phases button here).
- `[D-version-in-settings]` **About section,** last in Settings, below
  Quitting, one line each:
  - **Version:** the app's version and build number, e.g. "1.0 (1)".
  - **Spec:** the SPEC.md draft the build was made against, e.g. "Draft 23".
  - **Built:** the date and time this copy of the app was built (taken
    from the app's executable file).
  - *Why:* during testing, the author needs to tell which build is
    running. The version and build number never change for a personal
    app, so the spec draft and build time are what actually tell builds
    apart.
  - *How:* the draft number is a constant in the code
    (`App/Model/AppVersion.swift`). A unit test reads SPEC.md's title and
    fails if the constant doesn't match it, so the number can't drift
    from the spec `[D-tests-carry-tags]`. Bump it with each new draft.

### Dock icon and app menu

- `[D-dock-while-open]` **Phases shows a Dock icon, and appears in the ⌘Tab
  switcher, only while its window is open.** It launches as a menu bar
  accessory with no Dock icon. Opening the window makes it a regular app;
  closing the window makes it an accessory again, and the Dock icon goes
  away. Minimizing the window does not count as closing: the icon stays, so
  the minimized window can be found.
  - *Why:* a window on screen that ⌘Tab can't reach is un-Mac-like
    (author, 2026-10-29). Removing the icon when the window closes follows
    single-window apps such as Contacts, Calculator, and System Settings,
    which quit (and leave the Dock) when their window closes. Phases keeps
    running in the menu bar instead, but the Dock looks the same.
  - *How:* the window helper `[D-window-helper-order]` makes Phases a
    regular app when it attaches to the window and watches for the window
    closing. "Open Phases…" also switches before activating, so the switch
    happens before the window comes forward.
  - Replaces draft 24's "No Dock icon" rule.
  - macOS may fight this; see `[Q-regular-activation-menubar]` and
    `[Q-accessory-focus-handoff]` (both recalled, not yet seen in Phases).
- `[D-app-menu]` **While the window is open, Phases has a standard menu
  bar,** trimmed to what applies:
  - **Phases** (app menu): About Phases, **Settings… ⌘,** (opens the window
    with Settings selected in the sidebar `[D-one-window]`), Hide, Hide
    Others, Show All, **Quit Phases ⌘Q**.
  - **File:** Close ⌘W.
  - **Edit:** kept. Text fields (phase names) get Undo, Cut, Copy, Paste,
    and Select All from the Edit menu's shortcuts; removing it would break
    ⌘C and ⌘V in them (recalled AppKit behavior, to be checked in testing).
  - **View:** removed. Its only items would be Show/Hide Sidebar, which
    `[D-sidebar-always-visible]` rules out, and Enter Full Screen, which the
    green window button still provides.
  - **Window:** kept as macOS provides it (Minimize, Zoom, the window list,
    and so on). The app must behave like a well-mannered Mac app (author,
    2026-10-29).
  - **Help:** no "Phases Help" item; there's no help book.
  - *Why:* Quit belongs in the app menu, like every Mac app (author,
    2026-10-29). Replaces `[D-quit-in-window]` (draft 24 and earlier: a
    hidden ⌘Q button in the window plus a Quit Phases button in Settings,
    because an accessory app has no app menu).
  - With the window closed there's no menu bar of Phases' own, so quitting
    means opening the window first, as before.

## Launch at login: explicit consent only

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

## Restore original wallpaper on quit

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

## Platform notes and limitations

- `NSWorkspace.setDesktopImageURL(_:for:options:)` sets the image **per screen**,
  so different images per display are supported.
- It only affects the **currently active Space** on each screen. Other Spaces
  keep their own wallpaper. There is no public API to set every Space.
- With "Displays have separate Spaces" on (the macOS default), each display has
  its own current Space, and the app sets each one.
- `[D-single-timer]` Scheduling uses a single timer aimed at the next event, recalculated after
  every change, wake, or settings edit, with an hourly re-check as a safety net
  against clock drift. No polling loop.

## Persistence

All settings (folder bookmark, phases including per-display selections,
preferences, in-order positions, last applied phase and image per display, known
displays and their names, last location) are stored in UserDefaults as Codable
data. Phases saved by earlier versions load unchanged (no per-display images).

## Out of scope (v1)

- Different schedules per weekday
- Multiple folders or online image sources
- Different wallpaper per Space
- Scaling/fill options (uses the current macOS fill setting)

## Known issues

- Unreproduced: the desktop once turned black. Source folder is local storage
  (not a cloud-synced folder). No change until it can be reproduced.
- Restoring an Aerial isn't supported yet (see `[D-aerials-untouched]`). Possible approach: back up
  and restore macOS's wallpaper store file and restart the wallpaper process.
  Undocumented, so it needs explicit approval before building.
- The menu bar blinks once at the end of each change, and sometimes doesn't
  restyle until the frontmost app changes. Both are macOS behavior that
  Phases can't fix; see `[Q-menubar-blank]` and
  `[Q-menubar-restyle-on-app-switch]` (FB25326597).

## Platform quirks

Moved to ERRATA.md, each with a `[Q-…]` ID.

## Testing

Regressions found in testing (the − button doing nothing, the Name field
taking focus, Tab skipping the grid) are why Phases has tests. They come in
two layers.

### Layer 1: unit tests (in place, draft 21)

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
    category `sidebar`). What to log when chasing a platform bug is in
    ERRATA.md "Diagnostic procedures".
  - *Verified* 2026-10-28: with the switch on, a relaunch logged the
    sidebar's limit passes, restores, and resizes. The off state is
    consistent but not proven: nothing was logged between that build's
    launch and the switch going on, but the window may not have been
    opened then.

### Layer 2: UI tests (planned, not built)

- XCUITest tests that drive the real Phases window (these need an Xcode
  test target, so first find a way to run one; see
  `[Q-bitrig-test-targets]`), aimed at the focus and wiring bugs Layer 1
  can't see. Start with the UI tests marked in ERRATA.md "Regressions
  found so far".
- Before building: decide how a UI test run avoids changing the real
  wallpaper (`[D-tests-unhosted]` doesn't apply, since UI tests must launch
  the app). Whether XCUITest drives a menu bar accessory app's window
  reliably is *recalled* as finicky, not tested.
