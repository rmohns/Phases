# Phases — Specification (draft 44)

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
  section title, never a section number,** in every file in `docs/` and in
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
| On | Whether the phase is used; on by default. A phase turned off is skipped `[D-phase-turn-off]` |

**Which phase is active:** among phases whose appearance condition matches the
current system appearance, the one whose start trigger fired most recently
(looking back up to two days). So if "Night" starts at dusk and "Day" starts at
dawn, at 2 am "Night" is active. If no timed phase qualifies, the first matching
"Always" phase is used.

`[D-starter-phases]` **A new user starts with three phases:** Morning
(7:00 AM), Afternoon (12:00 PM), and Evening (6:00 PM), all Clock Time
triggers with no images yet. They cover the whole day, so one is always
active, and they need no location.
- *Why:* they show at a glance how phases divide the day, and give a new
  user something to fill in rather than an empty list (author,
  2026-11-06, after seeing the UI-test phases on a first launch). Draft
  42 and earlier started with one "All Day" phase on the Always trigger.
- Clock times, not dawn and dusk, so a first launch never asks for
  location.
- Only when there are no saved phases at all. Existing users keep theirs.

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
  - *Verified* 2026-11-04 by the author (`main` at `3ec6dee`, issue #15), with
    a folder two levels deep: turning the setting on shows the subfolder
    images at once, under one heading per folder path; rotation sets the
    wallpaper correctly for top + first level, top + first + second, first +
    second, and top + second; arrow keys cross subfolder headings. Symlinked
    folders weren't followed at the time (issue #17; this note said #18 by
    mistake until draft 35); see `[D-follow-links]`.
- Supported formats: JPEG, PNG, HEIC, TIFF.
- `[D-follow-links]` **Symlinks and Finder aliases count as what they point
  to,** for images and for folders.
  - A link or alias to an image is listed under its own name, in the
    folder that holds it: `_link.png`, or `Winter/_link.png`.
  - A link or alias to a folder counts as a subfolder, even though the file
    system says it's something else (author, 2026-11-04). Phases follows it
    only when Include subfolders is on, and lists its images under the
    link's name, e.g. `Linked/snow.jpg` `[D-relative-paths]`.
  - The other subfolder rules apply to what a link points to: hidden
    links, and links to hidden folders or packages, are skipped.
  - Broken links and aliases, and ones pointing at anything other than a
    supported image or a folder, are skipped like any other unsupported
    file.
  - A link to something macOS protects (Desktop, Documents, Downloads,
    iCloud Drive, network or removable drives) may make macOS ask for
    permission the first time (*recalled*, not tested with Phases). If
    access is refused, that item is skipped. Whether to show it as "can't
    open" instead is open (issue #20).
  - Two links to the same image list it twice, once under each name.
    That's accepted (author, 2026-11-04).
  - *Why:* until draft 35 the scan skipped every symlink and alias, so
    images and folders reached that way never appeared (issue #17;
    *verified* 2026-11-04 by Claude with a test folder: symlinks report
    the type `public.symlink`, aliases `com.apple.alias-file`, and the
    scan didn't descend into a symlinked folder).
  - *Verified* 2026-11-04 by the author, draft 35 build, on the real
    wallpaper folder with Finder aliases: "seems to be working fine."
    Symlinks and loops are covered by the unit tests, not checked by
    hand.
- `[D-scan-each-folder-once]` **Each folder is scanned at most once,**
  identified by where it really is, not the path that reached it. This
  includes the chosen folder itself, so a link back to it, or to a folder
  above it, adds nothing, and the scan always ends.
  - When a folder can be reached both directly and through a link, the
    direct path names it (author, 2026-11-04).
  - When only links reach it, the first one in display order names it
    (top-level first, then Finder sort order).
  - *Why:* following links makes loops possible (a folder linked to itself,
    or A → B → A). Without this rule the scan would never end, or would
    list one folder's images over and over.
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
- `[D-grid-release-on-close]` **Closing the Phases window releases the
  grid's thumbnails.** Reopening it loads them again.
  - *Why:* the closed window kept every thumbnail and its view for as
    long as Phases ran: about 25 MB for a 22-image folder (measured
    2026-10-30, LEARNINGS.md `[L-mem-window]`), and more for bigger
    folders. Phases spends most of its life with the window closed.
  - *Cost:* thumbnails reload when the window reopens. Expected to be
    quick, since QuickLook keeps its own thumbnail cache (*recalled*, not
    measured).
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

- Changes apply to the current Space on each display (macOS limitation;
  see "Platform notes and limitations"). Each Space keeps its own
  wallpaper, with or without crossfades `[D-cover-per-space]`.

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
  - Covers are redrawn, added, or removed first `[D-cover-follows-displays]`.

## Transitions

- **App preference: Transition**: None or **Crossfade** (default).
- **App preference: Duration**: 0.5 to 3 seconds (default 1 second), shown
  only when Crossfade is selected.
- macOS has no transition for wallpapers set by apps, so Phases does it itself
  by **fading the new image in over the old one** `[D-fade-in]`
  (see *Why fade in* below), on a cover that then stays up while its
  Space is showing `[D-persistent-cover]`.

### The persistent cover

- `[D-persistent-cover]` **After a crossfade, the cover stays up for as
  long as its Space is showing.** It isn't removed after a settle delay;
  it goes when the next change on that display replaces it, or when you
  leave its Space `[D-cover-per-space]`. The real wallpaper is still set
  behind it, so the menu bar text, the lock screen, and the login window
  read the right image.
  - **The cover:** a borderless, click-through window showing the image.
    `[D-cover-level]` It sits just above the desktop picture and below the
    desktop icons, so icons and windows don't flicker. It covers the full
    screen, including under the menu bar. Desktop icons, widgets,
    right-clicks on the desktop, and "Click wallpaper to reveal desktop"
    work through it (*observed* 2026-10-30, LEARNINGS.md
    `[L-desktop-through-cover]`).
  - *Why:* two problems go away.
    - **The twitch** `[Q-wallpaper-motion-delay]`: a visible cover never
      comes off, so macOS's motion after a change plays behind it, never
      in view. Retires `[D-cover-settle]`. Measured: no twitch on one
      display or three (`[L-cover-three-displays]`, with covers that
      joined every Space; see `[D-cover-per-space]`).
    - **The menu bar background lag:** with the old cover, the background
      restyled only when the cover came off, 1.5 s after the fade
      `[Q-menubar-bg-follows-window]`. Now it restyles at the end of the
      fade `[D-cover-opacity]`.
  - *Cost:* memory. At most one cover buffer per display between changes
    `[D-cover-iosurface]`, about 25–63 MB each at the author's display
    sizes (*inference* from decoded image sizes, LEARNINGS.md
    `[L-mem-fix-ideas]`). That's why there's a cover only when crossfades
    are on `[D-cover-only-for-crossfade]`.
  - Tested on branch `spike/persistent-cover`, now tag
    `archive/spike/persistent-cover` (docs/X-PERSISTENT-COVER.md there),
    2026-10-30, macOS 27.2, one display and three.
  - *Verified* 2026-11-03, draft 33 Release build, macOS 27.2, three
    displays (cover check 1): no twitch. Five changes per display, each
    display recorded on its own; the frame 0.1 s after each fade's end
    matched the frame 1.5 s later at 44–48 dB. The only later change is
    a one-frame step of about one grey level some 0.65 s after the fade:
    the real wallpaper switching behind the cover's 1%.
- `[D-cover-per-space]` **Each Space keeps its own wallpaper.** A cover
  belongs to the Space it was made on, and is removed once that Space is
  no longer showing on its display. The Space keeps its real wallpaper,
  which Phases set at the end of the fade, so it's the same image.
  - Arriving on a Space shows its own real wallpaper, with no cover, the
    same as without Phases. The next change made there fades in a new
    cover over it.
  - Removing the cover happens off screen, so it can't be seen: no frame
    changed when it went, or after returning (*measured* 2026-10-31,
    `[L-cover-own-space]`).
  - *Why:* the author wants each Space to be able to show its own
    wallpaper, toward a future choice of images per Space within a phase
    (author, 2026-10-31). A cover that joins every Space shows one image
    on all of them, which rules that out. The experiment's covers did
    that, along with syncing each Space's real wallpaper on arrival
    (`[L-cover-all-spaces]`); neither is used.
  - *Also:* holds memory to one buffer per display, not one per Space,
    apart from pending changes `[D-change-stays-on-its-space]`.
  - A cover without `.canJoinAllSpaces` stays on the Space it was made
    on, slides away with it during a swipe, and reports itself off the
    active Space once macOS announces the change (*verified* 2026-10-31,
    one display, three Spaces, `[L-cover-own-space]`). Not yet tried on
    more than one display.
  - Phases tells whether a cover's Space is showing by asking its window
    (`isOnActiveSpace`) whenever macOS reports a Space change. There's no
    public API that names Spaces (*recalled*), so the future per-Space
    choice needs its own investigation.
  - *Verified* 2026-11-03, draft 33, three displays, three Spaces on the
    main one (cover check 3): after a change on Space 1, Spaces 2 and 3
    kept their own image and Space 1 kept the new one (read back on
    each); the log showed Space 1's cover removed on leaving; the
    recording shows only the four swipes, no frame change at the removal
    or on returning.
- `[D-change-stays-on-its-space]` **A change belongs to the Space it was
  made on, even if you leave mid-fade.** When a fade ends (or is cut short
  by another change), each display's new cover is checked:
  - **Still showing:** the wallpaper is set and the old cover removed, as
    in "A change, step by step".
  - **Its Space is no longer showing:** the wallpaper isn't set yet. The
    new cover stays on its Space, fully faded in, and the change is
    **pending**. When that Space shows again, Phases sets the wallpaper
    behind the cover, and from then on it's an ordinary cover
    `[D-cover-per-space]`.
  - `[D-reset-on-quick-return]` **Left just after the set:** if its Space
    stops showing within 1.5 s of its wallpaper being set, the cover
    isn't removed. It goes back to pending, and the wallpaper is set
    again when that Space shows again.
    - *Why:* a set made early in a swipe can land on the Space you're
      arriving on, even though the cover still reports its own Space as
      showing (3 of 19 trials, 2026-11-03). Nothing Phases can check at
      the moment of the set tells it where the set will go. Setting
      again on return makes sure the Space the change was made on gets
      it. If the first set did land there, the second changes nothing
      visible apart from the usual menu bar blink `[Q-menubar-blank]`.
      macOS fights this; see `[Q-set-target-decided-late]`.
    - *What it can't fix:* in that misfire, the Space you arrive on
      hard-cuts to the new image and keeps it until its own next change.
      Phases never learns what that Space showed before, so it can't put
      it back.
    - *1.5 s:* longer than the 0.5–1.1 s macOS takes to announce a Space
      change `[Q-space-notify-after-swipe]`, so every set made during a
      swipe falls inside it. *Cost:* that cover's buffer is held until
      you return, as for any pending change.
    - *Rejected:* reading the wallpaper just before the set and holding
      the change if it no longer matches the Space's image. The read
      pointed at the right Space while the set went to the other
      (LEARNINGS.md `[L-swipe-set-read]`).
    - *Verified* 2026-11-03, Release build `3c891b6` (cover check 5, 28
      trials, 24 informative): Space 1 showed the new image on return
      every time and Space 2 kept its own; 23 trials logged "pending
      again" 0.05–0.84 s after the set, then the set on return, with no
      visible change on return (recordings). The misfire itself didn't
      occur in these runs, so the return set after a real misfire is
      unobserved; it's the same ordinary set, made with no swipe under
      way (LEARNINGS.md `[L-misfire-not-seen]`).
  - A cover whose fade is still running, or whose change is pending, is
    not removed on leaving its Space. The old cover under a pending one
    is removed as usual (off screen).
  - The Space you arrive on is left alone: it keeps its own image.
  - *Why:* the public API sets the wallpaper only on the Space showing
    (*recalled*), and macOS announces a Space change only after the swipe,
    about 0.9–1.1 s after the key press (*verified*,
    `[Q-space-notify-after-swipe]`). With draft 33's first version, a
    3 s fade left mid-way set the wallpaper on the arrival Space, which
    hard-cut to the new image with no fade, while the Space left behind
    never got it (*measured* 2026-10-31, `[L-space-leave-mid-fade]`).
    Holding the cover keeps what you saw on the Space you left; setting
    on return finishes the change where it was made. macOS fights this;
    see `[Q-space-notify-after-swipe]`.
  - *Cost:* on returning, the menu bar keeps the old image's style until
    the set lands, about 1 s after the swipe starts, then blinks and
    restyles (*inference* from `[Q-space-notify-after-swipe]` and
    `[Q-menubar-blank]`). Each pending change holds a cover buffer until
    you return: at most one per Space per display.
  - *Rejected:* setting the real wallpaper when the fade starts, under a
    cover still showing the old image. The menu bar would switch up to
    3 s before the screen does, the draft 4 problem `[D-fade-in]`
    `[Q-menubar-reads-wallpaper]`. Also rejected: dropping the change on
    the Space left behind, because a fade you watched start would be
    undone when you came back.
  - **How long a pending change lives:** only in memory, never saved. It
    waits until its Space shows again, however long that takes, unless
    it's dropped first. Dropped means its cover goes and its Space keeps
    the older image. That happens on:
    - Quit, logout, restart, shutdown, Force Quit, or a crash
      `[D-cover-pause-quit]`;
    - crossfades turning off (Transition: None or Reduce Motion)
      `[D-cover-only-for-crossfade]`;
    - its display disconnecting `[D-cover-follows-displays]`.
      Reconnecting doesn't bring it back.
  - **Pending changes can't pile up.** A change only starts on the Space
    showing, and arriving on a Space sets its pending change. So each
    display has at most one per Space. One brief exception: if a new
    change starts on a Space before macOS has announced your arrival
    there `[Q-space-notify-after-swipe]`, and you leave again mid-fade,
    that Space holds two. On the next arrival the newer is set and the
    older dropped. Worst case memory: one buffer per Space per display.
  - *Why not saved across launches:* nothing public names a Space
    (*recalled*), so a saved change couldn't find its Space again.
  - *Untested:* deleting a Space in Mission Control while it holds a
    pending change. macOS moves a deleted Space's windows to another
    Space (*recalled*), so the change would land there when it shows.
    That Space would then show the image its cover was already showing.
  - **Checked by hand before merging** (TESTING.md `[D-cover-checks]`),
    including a 1 s fade that ends during the swipe, before macOS
    announces it. In that case, whether `isOnActiveSpace` and the
    wallpaper set agree on which Space is showing is untested; if they
    disagree, the change could still land on the wrong Space.
  - *Verified* 2026-11-03, draft 33 (cover checks 4 and 6): leaving a 3 s
    fade about 0.5 s and 1.2 s in, the log showed the change held
    pending, Space 2 kept its image with no cut, and on return the log
    showed it set and Space 1 read back the new image. Setting
    Transition to None, or quitting, while a change was pending removed
    every cover, and Space 1 kept its old image.
  - **Fails** 2026-11-03 (cover check 5, 1 s fade, ⌃→ about 0.7 s in):
    in 1 of 6 trials they disagreed. The fade ended 0.25 s into the
    swipe; `isOnActiveSpace` still said the cover's Space was showing,
    so the wallpaper was set, but it landed on Space 2, which hard-cut
    to the new image with no fade, while Space 1 kept its old one. The
    other 5 landed on Space 1. `[Q-set-target-decided-late]`. Answered
    by `[D-reset-on-quick-return]` (approved by the author, 2026-11-03).
    Checks 3–6 rerun on that build the same day: all pass.
- `[D-cover-only-for-crossfade]` **No cover at all unless crossfades will
  actually play:** Transition is Crossfade and Reduce Motion is off.
  - With **Transition: None**, or with Reduce Motion on, Phases just asks
    macOS to change the wallpaper, as drafts before the cover did, and
    holds no cover memory.
  - **Turning crossfades off** (in Settings, or Reduce Motion going on)
    removes every cover at once. Invisible: the real wallpaper behind each
    one is the same image.
  - **Turning crossfades on** puts up no cover by itself. The next change
    brings one.
  - Phases puts up no cover at launch either: until a change, there's no
    motion to hide.
  - *Why:* the cover's only job is to make transitions possible and keep
    them clean; it isn't worth its memory without them (author,
    2026-10-31). Reduce Motion counts as off because it turns every fade
    into an instant switch `[D-no-fade-cases]`.
  - *Verified* 2026-11-03, draft 33 (cover checks 6 and 7): with
    Transition: None, and with Crossfade plus Reduce Motion, changes cut
    in one frame and no cover window existed. Turning Reduce Motion on,
    or Transition to None, with covers up logged their removal and left
    none.
- `[D-cover-opacity]` **The cover is 99% opaque, not 100%.**
  - *Why:* a fully opaque cover stopped the menu bar restyling for new
    wallpapers: text stayed one color through every change, and with
    "Show menu bar background" on, the background kept an earlier image's
    color through changes, app switches, and 15 s. At 99%, text and
    background restyled promptly for every change, with or without the
    background setting, on one display and three. *Measured* 2026-10-30.
    macOS fights this; see `[Q-opaque-cover-freezes-menubar]`.
  - The 1% that shows through is the real wallpaper, which is the same
    image once set, so it can't be seen. No twitch shows through either:
    frames before and after each fade matched at noise level (43–50 dB).
    *Measured.*
  - *Rejected:* taking an opaque cover off briefly once the wallpaper has
    settled. The background restyled, but the twitch came back at that
    moment, even 4 s after the set (*measured*, `[L-motion-waits-for-reveal]`).
  - Whether the cover could go to 100% once the menu bar has restyled is
    open and untested (`[L-cover-alpha-later]`); not part of this draft.
  - *Verified* 2026-11-03, draft 33, three displays, "Show menu bar
    background" on (the author's setting; cover check 2): text and
    background restyled to each new image on every display, 0.4–0.8 s
    after the fade ended, when macOS applied the set, with the one-frame
    blink `[Q-menubar-blank]`. During the fade the bar keeps the old
    image's background `[Q-menubar-bg-follows-window]`.
- `[D-cover-follows-displays]` **Covers follow display changes.** When a
  display's frame or scale changes, its cover is redrawn at once, without
  a fade, showing the same image at the new size. A disconnected
  display's cover is removed. A newly connected display has no cover
  until Phases changes its image; the normal check
  `[D-screen-change-no-reroll]` may do that right away.
  - Only real geometry changes count. Hiding the Dock or toggling "Show
    menu bar background" also sends the screen-change notification
    `[Q-screen-params-notification]`, but changes no display's full frame,
    so no cover is redrawn.
  - *Why:* a cover that no longer fits its display would show plainly,
    and the experiment didn't handle this (GitHub issue #6).
  - *Verified* 2026-11-03, draft 33 (cover check 8, partly): changing the
    main display from 2580×1080 to 1720×720 points logged every
    display's cover redrawn (the others moved in the arrangement), and
    the main one filled the screen (screenshot). Hiding and showing the
    Dock logged nothing. Disconnecting the Cinema HD (by the author, same
    day, build `3c891b6`) logged its cover removed ("display 3 gone")
    and the other two redrawn, since macOS rearranged the displays and
    changed the main one to 2614×1094. Reconnecting restored both;
    the other covers were redrawn again and the Cinema had no cover
    until its next change.
  - Accepted by the author, 2026-11-04: a reconnected display having no
    cover until its next change is left as is. Nobody using Phases can
    see the difference.

### A change, step by step

With crossfades on `[D-cover-only-for-crossfade]`:

1. **New cover:** on each display whose image is changing, a new cover
   showing the *incoming* image appears, fully transparent, above the
   display's current cover (if it has one).
2. **Fade in:** the new cover fades to 99% `[D-cover-opacity]` over the
   chosen duration. The real wallpaper hasn't changed yet.
3. **Switch:** the new wallpaper is set behind the covers, and the old
   cover is removed at the same moment. Invisible: the new cover is on
   top, and the old cover and the real wallpaper only show through its 1%.
4. **Stay:** the new cover stays up until the next change on that display,
   or until its Space stops showing `[D-cover-per-space]`. There's no
   settle delay.

- *Why a new window per change,* not a new image inside the same window:
  the 99% results were all measured that way (variant B in the
  experiment). A single window was tested only at 100%, where the menu
  bar failed in both forms `[Q-opaque-cover-freezes-menubar]`.
- The cover draws the image the way macOS will, using that screen's
  scaling (fill, fit, stretch, or center) and fill color.
- *Replaced:* `[D-cover-settle]` (drafts 5–32) removed the cover after a
  settle delay, so macOS's motion `[Q-wallpaper-motion-delay]` would
  finish behind it. The delay had to be raised from 0.5 s to 1.5 s on
  macOS 27.2 (cause unconfirmed; see "The twitch returns" in ERRATA.md),
  and it made the menu bar background lag the fade
  `[Q-menubar-bg-follows-window]`. A cover that stays up while it can be
  seen needs no delay.
- `[D-no-screenshots]` The cover is drawn from the image file. No screenshots and no Screen
  Recording permission.
- `[D-cover-iosurface]` **Each cover holds one copy of its image, and only
  while it's up.**
  - The file is decoded once, at no more than the size the screen needs,
    then drawn into a shared graphics buffer (an IOSurface) that the cover
    shows. The decoded image is dropped as soon as it's drawn: two copies
    for a moment, then only the buffer.
    - ImageIO is told not to cache a full-size decode
      (`kCGImageSourceShouldCache` off). Whether it still makes one
      internally for some formats is measured, not assumed.
    - Not decoded straight into the buffer: macOS has no public way to
      decode a file into memory the caller supplies (*recalled*, not
      verified).
  - 8 bits per channel: macOS shows the wallpaper as SDR, even for an
    HDR photo (LEARNINGS.md `[L-hdr-wallpaper]`).
  - The buffer is tagged with the image's own color space, so colors match
    what macOS draws for the same file on every display, whatever that
    display's color space. An image with no color space, or one that
    isn't RGB (grayscale, CMYK), is drawn in sRGB and tagged sRGB.
  - When the cover is removed, its buffer is released with it.
  - *Why:* up to draft 31, each change left full-screen copies behind (one
    per changing display, about 25–63 MB each at the author's sizes), and
    memory climbed by roughly 20–40 MB per change across three displays,
    to about 300 MB after ten changes. Most of that was a copy the system
    made of every image handed to a cover; a shared buffer is shown as is,
    with no copy. macOS fights this; see `[Q-cover-image-copied]` and
    `[Q-iosurface-color-tag]`.
  - *Cost:* the cover's pixels are drawn by Phases rather than by the
    system's image pipeline, so color matching depends on the tag. Measured
    within 1–5 of 255 of the system's own drawing on all three of the
    author's displays (2026-10-30, test harness, not yet in Phases).
  - *Also:* this sets the floor for the persistent cover
    `[D-persistent-cover]`: at most one buffer per display between
    changes, while crossfades are on, plus one more per changing display
    during a fade. Draft 32 held a buffer only during a fade and the 1.5 s
    after it.
- `[D-no-fade-cases]` **No fade (instant switch) when:**
  - Transition is set to None, or Reduce Motion is on (System Settings ›
    Accessibility › Display). There's no cover in either case
    `[D-cover-only-for-crossfade]`.
  - The incoming image file can't be read, or its cover buffer can't be
    made `[D-cover-iosurface]` (that screen only: its old cover is
    removed and the wallpaper switches without a fade, at the same moment
    as the other screens finish fading). That display stays uncovered
    until a later change there gets a cover; an old cover left up would
    hide the new wallpaper.
  - A screen's image isn't actually changing (that screen only; its cover
    stays as it is, if it has one)
  - Restoring the original wallpaper on quit `[D-restore-on-quit]`
- If another change starts while a fade is running, the running fade finishes
  instantly (its cover jumps to 99%, its wallpaper is set, and the cover it
  replaced is removed) and the new change starts its own fade.
- *Why fade in `[D-fade-in]`:* the real wallpaper changes only at the end,
  behind an identical image, so nothing flashes and the menu bar switches
  once, at the end, just as it does when changing wallpaper in System
  Settings. The old wallpaper is never redrawn, so crossfades also work
  when the outgoing wallpaper is an Aerial. Draft 4 faded the old image
  out instead; macOS fought that; see `[Q-menubar-reads-wallpaper]` and
  ERRATA.md "Why fade in, not fade out". Unchanged by the persistent
  cover: the fade still runs on a new cover and the wallpaper is still set
  at its end.
- `[D-cover-pause-quit]` **Pause, Quit, and crashes:**
  - **Pause** leaves any cover up. It stops scheduled changes, not what's
    on screen. The exception is a pause caused by an outside change, which
    fades out the changed display's cover `[D-outside-change-pauses]`.
  - **Quit** removes every cover at once, after any restore
    `[D-restore-on-quit]` has set the real wallpaper. With restore on,
    that's a hard cut to the original, as in draft 32 (restoring never
    fades, `[D-no-fade-cases]`). With restore off, the real wallpaper
    already matches, so nothing visible happens. Pending changes are
    dropped `[D-change-stays-on-its-space]`.
  - **Logout, restart, shutdown, Force Quit, or a crash** take the covers
    with the process, leaving the real wallpaper, which matches, except
    on a Space with a pending change: that Space keeps its older image. A
    Force Quit showed nothing (*observed* 2026-10-30).
  - *Verified* 2026-11-03, draft 33 (cover check 9): with restore on,
    Quit was a one-frame cut back to each display's pre-launch image;
    with restore off, nothing moved. No cover windows remained either
    way. Quit was sent as an Apple Event, which skips the "Quit Phases?"
    alert but runs the same termination path.
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

## Wallpaper changed outside Phases

- `[D-outside-change-pauses]` **When someone picks a wallpaper in System
  Settings (or any other app), Phases pauses everything** and steps
  aside until it's resumed. Nothing is asked first.
  - *Why:* picking a wallpaper is a clear statement of what the person
    wants on screen now. Before this, Phases hid the pick behind its cover
    and then overrode it at its next change, 9 s and 23 s later in the
    experiment (*verified* 2026-11-06, LEARNINGS.md `[L-store-watch]`), so
    the pick looked broken. Pausing is the author's call (2026-11-06,
    GitHub issue #5).
- **What pausing does:**
  - Scheduled changes stop, exactly as with **Pause Schedule** in the menu: it's the
    same paused state, saved across launches, with a reason attached
    (see "Interface" below).
  - Any cover on the changed display fades out over the Transition
    duration, revealing the pick. Covers on other displays stay, as with
    Pause `[D-cover-pause-quit]`. With Transition set to None it's a cut.
  - The pick becomes that display's "original" in the restore record, so
    Quit restores it, not the wallpaper from before Phases launched
    `[D-restore-on-quit]`. An Aerial pick marks the display as an Aerial,
    which Quit leaves alone `[D-aerials-untouched]`.
- **Resuming** (any of the controls under "Interface") applies the active
  phase's image right away, with the usual transition, and the schedule
  carries on. The restore record keeps the pick.
- **Change Now while paused** changes the image once and stays paused, as
  it does today with Pause Schedule.
- `[D-outside-change-rule]` **How a change is recognised:** Phases watches
  macOS's wallpaper store (read only, as `[D-aerials-untouched]` already
  does), event-driven with no polling. A change counts as outside when an
  entry for a display (macOS only sets the showing Space's) gets a new
  "last set" time and its image isn't one Phases set on that display in
  the last 10 seconds. Store details: ERRATA.md `[Q-wallpaper-store]`.
  - Writes that change only the "last used" time are ignored: opening or
    quitting System Settings and switching Spaces make them (*verified*
    2026-11-06, `[L-store-watch]`).
  - The store, not `NSWorkspace`, is the source: for an Aerial,
    `desktopImageURL` reports a placeholder (`DefaultDesktop.heic`), and
    it kept reporting one Space's image while another Space was showing
    (*observed* 2026-11-06).
  - The rule is a pure function, unit-tested `[D-tests-unhosted]`.
  - A pick of the same image Phases already shows isn't noticed. Nothing
    on screen changes, so nothing needs to.
- `[D-outside-change-notice]` **Telling the user:**
  - **Once, when it happens:** one macOS notification: "Phases paused.
    You chose a new wallpaper in System Settings. Phases won't change it
    until you resume." with a **Resume** action. Permission is asked the
    first time it's needed, not at launch. If it's denied, the lasting
    signs below still show.
  - **Lasting:** the menu bar icon's paused look, the menu's status line,
    and the top of Settings (see "Interface").
  - *Why both:* the pick itself is what the person was looking at, so a
    notification is the only sign they'll get in the moment; the lasting
    signs answer "why isn't it changing?" later without nagging.

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
- `[D-denied-means-off]` **Denied means no location at all, saved or
  fresh.** While permission is denied or restricted, the schedule ignores
  the saved location, so dawn/dusk phases don't run on an old one. The
  saved location is kept, so turning access back on works at once.
  - *Why:* until draft 36 the schedule kept using the saved location after
    access was turned off, so those phases still ran while the editor and
    menu said they were skipped (found by reading the code, 2026-11-05,
    issue #16). Turning access off reads as "stop using my location"
    (author's call, 2026-11-05).
- `[D-phase-cant-run]` **A phase that can't run is flagged in the
  sidebar.** A dawn/dusk phase can't run when there is no usable location:
  access is denied (**Location off**), or it was never granted and no
  location has been saved yet (**No location yet**). Its row is dimmed
  (name and icon), and the trigger line ends with an orange
  `exclamationmark.triangle.fill` and **Phase disabled**. VoiceOver reads
  "Phase disabled". Such a phase is never the active one, so it never
  shows "Active".
  - `[D-row-status-not-cause]` **The row shows the status; the editor
    shows the cause.** The sidebar row says "Phase disabled" for every
    reason Phases can't run a phase, the one exception being a phase the
    user turned off, which reads "Off" `[D-phase-turn-off]`. The phase
    editor's warning names the reason ("Location access is off, so this
    phase is skipped." or "No location yet, so this phase is skipped.").
    - *Why:* the row is for scanning the schedule; clicking it shows why.
      One status also covers any later reason a phase can't run without
      changing the row (author's call, 2026-11-05). Replaces the first
      draft 36 wording, where the row named the reason ("Location off",
      "No location yet").
    - *Why "Off" is the exception:* turning a phase off is the user's
      choice, not a problem. "Phase disabled" with a warning read as an
      error for it (author, after trying draft 42, 2026-11-06). Draft 42
      first showed "Phase disabled" for it too.
  - `[D-phase-turn-off]` **A phase can be turned off** without deleting
    it, keeping all its settings and images, and turned back on later.
    Turned off is a reason a phase can't run: the schedule skips it.
    Its row is dimmed like any phase that can't run, and its trigger line
    ends with **Off**, with no warning symbol `[D-row-status-not-cause]`.
    VoiceOver reads "Off".
    - **Controls:** a **Use this phase** switch in the editor's first
      section, under Name; and **Turn Off** (or **Turn On**) in both the
      action menu and the row's context menu `[D-phase-actions]`, after
      Duplicate.
    - **Editor message:** "This phase is turned off, so it's skipped."
    - **Turned off wins.** A phase that is both turned off and missing a
      location names only "turned off" in the editor, since turning it
      back on is the first thing the user would do (author, 2026-11-06).
    - **Turning off the active phase** switches at once to whichever
      phase should now be active, just as deleting it does: any change
      to the phase list re-checks the schedule (verified by reading
      `WallpaperScheduler.phases`, Claude, 2026-11-06).
    - The menu bar says nothing about turned-off phases; it's a choice,
      not a problem to report.
    - Phases saved by earlier versions load as on.
    - *Why:* until now the only way to stop a phase was to delete it and
      lose its settings (GitHub issue #21). "Use this phase" says what
      the switch does in the editor's own terms; a bare "On" or
      "Enabled" next to the name could read as a status.
  - The rule ("can this phase run, and if not, why") lives in a small model
    function next to `ScheduleEngine`, not in the view, so the unit tests
    can check it (see TESTING.md). The schedule and the sidebar use the
    same rule, so the flag can't disagree with what actually runs.
  - **Disabled is one status with any number of reasons.** The schedule
    skips every disabled phase, whatever the reason, and the row shows the
    same status for all of them. A future reason (such as the user turning
    a phase off) adds a reason and its editor message; the row and the
    schedule need no change (author's request, 2026-11-05).
  - *Why:* the issue (#16): a dawn/dusk phase silently did nothing, and
    only its editor said so. The sidebar is where the user scans the
    schedule.
  - *Observed* 2026-11-05 by Claude, draft 36 build, location access
    turned off by the author: two dusk phases showed dimmed with the
    warning and "Location off"; clock phases unchanged; list order
    unchanged (one window screenshot). A second screenshot, after the
    author selected Dusk: the editor showed "Location access is off, so
    this phase is skipped."; the selected flagged row (inactive window,
    grey highlight) stayed dimmed with the warning legible. Not yet seen:
    a flagged row on the accent highlight (window in front), "No location
    yet".
  - *Observed* 2026-11-05 by Claude, after `[D-row-status-not-cause]`:
    with access on, the dusk phases showed no flag; after the author
    turned access off, with Phases still running and no relaunch, both
    rows read "Phase disabled", dimmed with the warning (two window
    screenshots).
  - *Verified* 2026-11-05 by the author: a flagged row selected with the
    window in front (accent highlight) reads correctly. "No location
    yet" is covered by unit tests only; reaching it on a real Mac means
    resetting Location Services state (author's call to leave it).

## Interface

- `[D-content-vs-tools]` **Controls stay clearly separate from content.**
  By default, a control doesn't blend into the wallpaper or images behind
  it; an exception has to be a deliberate, stated choice. Where Liquid
  Glass-style translucency costs legibility or findability, Phases doesn't
  follow it.
  - *Why:* the author's standing design principle, moved here from
    CLAUDE.md (2026-11-01) so it carries a tag like other decisions.

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
  - `[D-menubar-icon-paused]` **While paused, for any reason, the icon
    shows a small pause badge** (two bars) at its lower right, still a
    template image.
    - *Why:* a pause caused by an outside change `[D-outside-change-pauses]`
      happens without the person choosing Pause, so they need a sign that
      lasts without opening anything. Manual pause gets the same badge so
      one look means one thing.

### Menu bar menu
`[D-menu-status-header]` Kept short. Status is a single section header, not separate dimmed items,
following the pattern of Apple's own menu bar extras (e.g. Time Machine's
"Latest backup" line).

- **Status header**, one line:
  - "Dusk · until 7:13 PM": active phase and when the next phase starts
    (weekday added if it's not today)
  - "All Day": an active phase with no upcoming phase change
  - "Dusk · Paused" while paused; "No active phase" if none applies
  - "Paused · wallpaper changed in System Settings" while Phases has
    paused itself for an outside change `[D-outside-change-notice]`, in
    place of the phase line. **Resume Schedule** resumes.
    - *Why:* it's status, so it stays in the header, the way Apple's own
      menu bar extras show status. Draft 37 first added it as a second,
      dimmed line, which made two hard-to-read lines (author,
      2026-11-06). The HIG has no guidance on status lines in menus; it
      reserves dimming for unavailable items (*verified* 2026-11-06,
      HIG "Menus").
- **Change Now**: advances to the next image in the active phase
- `[D-menu-pause-verb]` **Pause Schedule**, which reads **Resume Schedule**
  while paused (for any reason). The pause is saved across launches.
  - *Why:* a command names what it will do. A checked "Pause Schedule"
    reads as a state and leaves people working out what unchecking means
    (author, 2026-11-06). The HIG allows either; it suggests a verb when
    a changeable label could be read as a state (*verified* 2026-11-06,
    HIG "Menus"). Draft 36 and earlier used a checkmark.
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
     also sets them apart from the one-line Settings row. A phase that can't
     run is dimmed and flagged `[D-phase-cant-run]`.
  - + / − buttons below the list add and remove phases. − removes the
    selected phase and is dimmed when no phase is selected.
  - `[D-new-phase-now]` **A new phase starts at the current time,** as a
    Clock Time trigger rounded down to the nearest 5 minutes (2:37 PM
    becomes 2:35 PM), named "New Phase", and selected.
    - Starting now usually makes it the active phase at once, so the
      wallpaper may change as soon as it has images. That's intended: if
      the user then moves its start, the schedule re-evaluates and
      switches back as needed (author, 2026-11-06).
    - *Why:* the time someone adds a phase is a likelier start than a
      fixed one; draft 38 and earlier always used 9:00 AM (GitHub issue
      #25). Rounding keeps the time picker on a tidy value.
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
      in the view, so the unit tests can check it (see TESTING.md).
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
  - `[D-duplicate-phase]` **Duplicate makes a copy of a phase** with every
    setting: start trigger, appearance, order, rotation, and its All
    Displays and per-display images. It's named like a Finder copy
    ("Morning copy"), and selected once made. It keeps the original's
    start time; the user changes it from there.
    - Two phases with the same start time tie, and the one saved first
      wins, so the original stays active and duplicating never changes
      the wallpaper (verified by reading `ScheduleEngine.activePhase`,
      Claude, 2026-11-06). The copy is saved after the original.
    - The copy starts its own In Order position, from the first image.
    - *Why:* the quick way to make a variant of an existing phase (GitHub
      issue #24). Keeping the start time follows the author's call
      (2026-11-06).
  - `[D-phase-actions]` **Phase actions live in two places that list the
    same commands:**
    - **An action menu** in the sidebar footer, right of − : a third
      24 × 23 pt cell with the same 1 pt divider before it
      `[D-sidebar-footer-style]`, showing an ellipsis (`ellipsis`, no
      menu arrow). Clicking it opens a menu of commands for the selected
      phase: **Duplicate** and **Turn Off** (or **Turn On**) `[D-phase-turn-off]`. It's dimmed when no phase is selected, like
      − . Accessibility label "Phase Actions".
    - **A context menu** on each phase row: **Duplicate**, **Turn Off** (or **Turn On**), then a
      separator and **Delete**. It acts on the row clicked, whether or
      not it's the selected one. Deleting the selected phase selects the
      next one `[D-delete-selects-next]`; deleting another phase leaves
      the selection alone.
    - *Why:* an action menu beside + / − is long-standing Mac practice
      (Finder's and Mail's old gear menus), even if Apple uses it less
      now; it makes the commands findable without knowing to
      Control-click (author, 2026-11-06). The context menu is where Mac
      users look first for commands on a list item. The action menu started (draft 41) with
      Duplicate alone; Turn Off / Turn On joined it in draft 42
      (GitHub issue #21).
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
- `[D-window-min-size]` **Minimum window size.** The editor pane can't
  be made narrower than **460 pt**, so the window's minimum width is the
  sidebar's current width plus 460 pt (700 pt with the sidebar at its
  240 pt minimum `[D-sidebar-width]`). The window can't be made shorter
  than **480 pt**. The window opens at 960 × 680 pt, as before. A saved
  window frame smaller than the minimum opens at the minimum.
  - *Why:* without a minimum, the window could be dragged down to a
    sliver where the editor's controls and image grid are unusable
    (GitHub issue #12). Rare, but odd window states do happen, and a
    minimum costs nothing.
  - *The numbers* are estimates, not measured (Claude, 2026-11-06): 460 pt
    leaves room for the editor's label column, the three-segment "Only
    in" picker, and two or three thumbnail columns; 480 pt shows the Name
    and Starts sections plus part of the next. Adjust after a look at the
    real window.
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
- `[D-settings-schedule-switch]` **Settings starts with a Schedule
  section:** a **Change wallpaper on schedule** switch, the inverse of
  the menu's Pause Schedule (one state, two controls). When it's off, a note under it
  says why: "Paused from the menu" or "Paused at 9:06 AM because the
  wallpaper was changed in System Settings." Turning it on resumes
  `[D-outside-change-pauses]`.
  - *Why:* resuming shouldn't depend on finding a menu item; the window is
    where someone goes to ask why Phases stopped. Placed at the top for
    now; a broader Settings cleanup may move it (author, 2026-11-06).
- **Settings selected:** the Schedule section above, then image folder and Include subfolders; display sharing
  preference (see "Displays sharing the All Displays images"); transition and duration; Launch at Login; location status
  with today's civil dawn and dusk and Update Now; and, at the bottom, a
  **Quitting** section with the **Restore original wallpaper when quitting**
  toggle and a note that says what quitting will do `[D-restore-on-quit]`,
  and the **Ask before quitting** toggle `[D-quit-confirm]`.
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
    `[Q-accessory-focus-handoff]` (seen 2026-10-29; handled by
    `[D-close-stays-here]`).
- `[D-close-stays-here]` **Closing the window keeps you on the current
  Space.** When the window closes, Phases hands focus to the frontmost
  app with a window on the current Space, or to Finder if there is none,
  before dropping its Dock icon `[D-dock-while-open]`. Only when Phases
  is the active app; otherwise focus is already elsewhere.
  - *Why:* without this, macOS activated the most recently used app,
    wherever its window was, and switched Spaces to it. Contacts, which
    quits when its window closes, hands off to the current Space or
    Finder instead; Phases should feel the same (author, 2026-10-29).
  - *How:* the choice of app is a pure function over the on-screen
    window list (front to back): the first ordinary window (layer 0,
    visible, at least 50 × 50 pt) not owned by Phases; else Finder.
    Unit-tested.
  - macOS fights this; see `[Q-accessory-focus-handoff]`.
- `[D-open-here]` **"Open Phases…" brings the window to the Space you're
  on; the Dock and ⌘Tab take you to the window.** Choosing "Open Phases…"
  from the menu bar shows the window on the current Space, whether it's
  open on another Space or was closed there, instead of switching Spaces. Clicking the Dock icon
  or picking Phases in ⌘Tab behaves like any other app: macOS follows the
  user's Mission Control setting ("When switching to an application,
  switch to a Space with open windows for the application"). Phases never
  changes that setting. A minimized window is left to macOS: "Open
  Phases…" restores it as usual.
  - *Why:* the menu bar is on every Space, so choosing from it means "show
    it here"; being pulled to another Space is disorienting. It matters
    more in Phases than most apps, because wallpaper changes apply to the
    current Space. The Dock and ⌘Tab are about the app, and on the Mac
    switching to an app goes to its windows; keeping that respects the
    user's own setting (author, 2026-10-29).
  - *How:* if the window (open or closed) belongs to another Space, "Open
    Phases…" turns on
    `.moveToActiveSpace` before activating and turns it off once the
    window has arrived on the current Space (or if Phases loses focus
    first). Nothing persistent changes on the window. Details and the
    approaches that failed: ERRATA.md "Open here".
  - macOS fights this; see `[Q-activate-switches-space]`.
- `[D-reopen-shows-window]` **Launching Phases while it's already running
  shows the window** (from Finder, Spotlight, Launchpad, the Dock, or
  `open`). It behaves exactly like "Open Phases…": Dock icon first
  `[D-dock-while-open]`, window brought to the current Space
  `[D-open-here]`, focus on the sidebar `[D-initial-focus-sidebar]`. An
  open window comes to the front; a minimized one is restored.
  - *Why:* a menu bar app has no other sign that it's running, so
    launching it again is how people look for it. Before draft 34, a
    relaunch made Phases the active app and showed nothing: focus left
    the user's app for no visible reason (GitHub issue #13; seen
    2026-11-03, `[L-reopen-event]`).
  - *Scope:* only a relaunch while running. A fresh launch shows nothing
    (Launch at Login must stay silent), except the very first launch
    `[D-first-launch-shows-window]`.
  - *How:* "Open Phases…", Settings…, the relaunch, and the first launch
    share one window-opening routine, so they can't drift apart. macOS
    delivers the relaunch to Phases, but SwiftUI ignores it when the
    window is closed or was never opened; see
    `[Q-reopen-ignores-closed-window]`.
- `[D-first-launch-shows-window]` **The first launch opens the window,**
  exactly as "Open Phases…" does `[D-reopen-shows-window]`. Every later
  launch starts in the menu bar only.
  - **First launch** means this user account has no saved Phases settings
    at all. Phases records that it has launched, and a launch with that
    record, or with any settings saved by an earlier version, is not a
    first launch. So updating Phases never pops the window open for
    someone who already uses it. Erasing Phases' settings on purpose
    makes the next launch a first launch again, which is fine.
  - Launch at Login can't trigger it: it can only be turned on from
    inside Phases `[D-login-consent]`, by which time the launch is
    recorded.
  - *Why:* someone opening Phases for the first time should find its
    settings straight away instead of a menu bar icon they may not
    notice (GitHub issue #14, author). An onboarding screen may come
    later.
  - The window comes to the front, like any app the user just opened.
    macOS fights this; see `[Q-launch-activate-refused]` (*How* in
    ERRATA.md "First launch comes to the front").
- `[D-app-menu]` **While the window is open, Phases has a standard menu
  bar,** trimmed to what applies:
  - **Phases** (app menu): About Phases, **Settings… ⌘,** (opens the window
    with Settings selected in the sidebar `[D-one-window]`), Hide, Hide
    Others, Show All, **Quit Phases ⌘Q**.
  - **File:** none. Phases has no documents, so nothing to put in it.
    Close ⌘W is in the Window menu, where SwiftUI puts it for a
    single-window app (verified 2026-10-29). System Settings has no File
    menu either (recalled).
  - **Edit:** kept. Text fields (phase names) get Undo, Cut, Copy, Paste,
    and Select All from the Edit menu's shortcuts; removing it would break
    ⌘C and ⌘V in them (recalled AppKit behavior, to be checked in testing).
  - **View:** no Show/Hide Sidebar (ruled out by
    `[D-sidebar-always-visible]`) and no toolbar items. What's left is a
    View menu holding only a disabled Enter Full Screen, which macOS
    insists on `[Q-view-menu-fullscreen]`. It stays: removing it with AppKit
    made it show up when the menus opened and then vanish when they were
    clicked, which is worse than an extra menu (author, 2026-10-29; tried in
    draft 26).
  - **Window:** kept as macOS provides it (Minimize, Zoom, the window list,
    and so on). The app must behave like a well-mannered Mac app (author,
    2026-10-29).
  - **Help:** no "Phases Help" item; there's no help book. The menu stays
    for its search field.
  - *Why:* Quit belongs in the app menu, like every Mac app (author,
    2026-10-29). Replaces `[D-quit-in-window]` (draft 24 and earlier: a
    hidden ⌘Q button in the window plus a Quit Phases button in Settings,
    because an accessory app has no app menu).
  - With the window closed there's no menu bar of Phases' own, so quitting
    means opening the window first, as before.
- `[D-quit-confirm]` **Quit Phases (⌘Q) asks first,** because with a Dock
  icon, ⌘Q looks like "close this app", and it's easy to forget that
  Phases keeps working from the menu bar. An alert:
  - **Title:** "Quit Phases?"
  - **Text:** "Your wallpaper will stop changing on schedule." plus what
    happens to it, from `[D-restore-on-quit]`: "The wallpaper you had before
    Phases started will be put back." or "The current wallpaper will stay."
    Then: "To keep Phases running in the menu bar, close its window
    instead."
  - **Buttons:** **Quit** (default, Return), **Keep in Menu Bar** (closes the
    window; Phases keeps running), **Cancel** (Esc; nothing happens).
  - **"Don't ask again"** checkbox. Checked plus Quit turns the question off.
    Settings' Quitting section has an **Ask before quitting** toggle (on by
    default, saved across launches) to turn it back on.
  - Only the Quit menu item asks. Logging out, restarting, or shutting down
    quits without asking, so it never blocks them.
  - *Why:* the author pressed ⌘Q meaning "close" and quit Phases instead
    (2026-10-29). "Keep in Menu Bar" names where Phases goes, rather than the
    mechanism ("Close Window") or a vaguer "Keep Running".

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
- A wallpaper picked outside Phases while it runs replaces that display's
  entry in the record `[D-outside-change-pauses]`.
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
  - **Only the showing Space is restored.** The record holds each
    display's wallpaper on the Space showing at launch, and Quit restores
    whichever Space is showing on each display then. Other Spaces keep the
    image Phases last set while they were showing: macOS offers no way to
    set a Space that isn't showing (see "Platform notes and limitations").
    Accepted by the author (2026-10-31).
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
  keep their own wallpaper. There is no public API to set every Space, or
  to set or restore a Space that isn't showing.
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

## Memory

- `[D-memory-flat]` **Memory doesn't build up with wallpaper changes.**
  Between changes, with the window closed, Phases should sit near its idle
  launch figure, not climb change after change.
  - **With crossfades on,** the figure after a change includes at most one
    cover buffer per display `[D-persistent-cover]`. During a fade it holds
    one more per changing display `[D-cover-iosurface]`, and gives the old
    one back when the fade ends. Leaving a Space gives its cover's buffer
    back `[D-cover-per-space]`, unless its change is still pending
    `[D-change-stays-on-its-space]`.
  - **With Transition: None or Reduce Motion,** no cover buffers at all
    `[D-cover-only-for-crossfade]`. Turning crossfades off gives them back.
  - **Target:** after ten changes, footprint is within 30 MB of what it
    was after the first change (approved by the author, 2026-10-30).
  - Checked by hand, with at least two runs before a change and two after,
    because runs vary widely (one run measured 297 MB after three changes,
    another 144 MB). Procedure: TESTING.md `[D-memory-protocol]`.
  - *Verified* 2026-11-03, draft 33 with persistent covers, three
    displays: two runs pass (137 → 100 MB and 113 → 87 MB, first change
    to tenth). Figures in LEARNINGS.md `[L-mem-draft33-runs]`.
  - *Why:* Phases runs all day in the background. Draft 31 reached about
    300 MB after ten changes on three displays (measured 2026-10-30,
    LEARNINGS.md "Memory").
  - The persistent-cover experiment grew about 25–30 MB per change on
    three displays (`[L-cover-memory]`). It drew covers from CGImages, which
    Core Animation copies `[Q-cover-image-copied]`; that copy is the likely
    cause (*inference*, not measured on the experiment). The shipping
    cover uses `[D-cover-iosurface]`, and must pass the target above before
    it merges.

## Out of scope (v1)

- Different schedules per weekday
- Multiple folders or online image sources
- Choosing different images per Space within a phase. Planned as a later
  enhancement (author, 2026-10-31); `[D-cover-per-space]` keeps the way
  open. Needs a way to tell Spaces apart, which the public API doesn't
  offer (*recalled*).
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
  `[Q-menubar-restyle-on-app-switch]` (FB25326597). macOS also sometimes
  leaves menu bar text the wrong color with no cover involved
  (LEARNINGS.md `[L-menubar-lazy-restyle]`).
- At logout, a twitch was seen just as the login window appeared
  (*observed* by the author with the experiment build, 2026-10-30,
  `[L-login-dims-wallpaper]`). Not checked on draft 32; may be macOS
  redrawing the wallpaper for the login window.

## Platform quirks

Moved to ERRATA.md, each with a `[Q-…]` ID.

## Testing and diagnostics

Moved to TESTING.md: the unit and UI test layers, test-only launch
arguments, and diagnostic logging, with their `[D-…]` tags.
