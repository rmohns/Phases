# Phases spec: Schedule

Part of the Phases specification. [SPEC.md](../SPEC.md) is its front
page: the draft number, the "Design decisions" rules, and the list of
spec files.

What's here: phases and how the active one is chosen, start triggers,
Light and Dark Mode, catching up after sleep or a lock, and location.

## Core model: phases plus rotation

The schedule is a list of **phases**. Exactly one phase is active at any moment.

Each phase has:

| Field | Description |
|---|---|
| Name | e.g. "Morning", "Night" |
| Start trigger | When the phase begins (see "Start triggers") |
| Images (Shared) | Images chosen from the library (multi-select). Used by every display that doesn't have its own selection (see "Per-display images"). Called **All Displays** through draft 62 |
| Images (per display) | Optional: a separate selection for a specific display, used instead of the Shared images on that display (see "Per-display images") |
| Display sharing | Whether the displays using the Shared images all show the same image, or each a different one `[D-sharing-per-phase]` (a phase setting from draft 63) |
| Order | Random or In order |
| Rotation | Optional: change to the next image every N minutes or hours while the phase is active |
| Appearance | Use in: **Any** (default), **Light Mode**, or **Dark Mode** (see "Light and Dark Mode") |
| On | Whether the phase is used; on by default. A phase turned off is skipped `[D-phase-turn-off]` |

**Which phase is active:** among phases whose appearance condition matches the
current system appearance, the one whose start trigger fired most recently
(looking back up to two days). So if "Night" starts at dusk and "Day" starts at
dawn, at 2 am "Night" is active. If no timed phase qualifies, the first matching
"Always" phase is used.

`[D-starter-phases]` **A new user starts with three phases:** Morning
(7:00 AM), Afternoon (12:00 PM), and Evening (6:00 PM), all Clock Time
triggers with no images yet, each changing images every 30 minutes
(author, 2026-11-27; until then rotation was off). They cover the whole day, so one is always
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

**When a phase starts**, each display changes immediately to an image from
the selection it uses (its own, or Shared): In order, the one after
the image that selection last showed `[D-in-order-remembers]`; Random, a
random one. Rotation then continues within the phase.

**In order** cycles through each selection in library order. Library order
is the order of the image sources in Settings, then each source's own
order: for a folder, top-level images first, then each subfolder, sorted
the way Finder sorts `[D-image-sources]`; for a Photos album, the album's
own order `[D-photos-order]`. **Random** avoids repeating the current image
when there's more than one choice.

- `[D-in-order-remembers]` **In order remembers the last image it showed
  and moves to the next one.** Each phase keeps, for each selection it
  uses (Shared, and each display with its own images), the name of
  the image it last showed. Every change, scheduled or Change Now, shows
  the image after that one in the selection's library order, wrapping
  from the last image to the first. The position is kept across
  launches, phase changes, and days.
  - **The selection changes:** nothing is recalculated. Adding or
    removing images, or reordering sources, only changes what "the next
    one" is.
  - **The remembered image is no longer in the selection** (deselected,
    deleted, or its source removed): the next image is the first one
    that comes after where it sat in library order; if its source is
    gone, the first image in the selection.
    - **Photos (draft 54):** a photo that's deselected but still in its
      album carries on after where it sits in the album. A photo removed
      from its album, or deleted, can't be placed, since Photos doesn't
      say where it was: that album starts over from its first image in
      the selection, and if the album is gone too, the selection carries
      on from the first image of that source onward. *Why:* photo IDs
      are random strings, so placing a missing photo by its name (as a
      file is placed by its path) lands anywhere (Claude, reading the
      code, 2026-11-13; approach approved by the author the same day).
  - **No remembered image** (a new or duplicated phase, a selection
    never shown, settings from draft 52 or earlier): the first image in
    the selection.
  - **Never the image already showing** when the selection has another
    image available: if the next one is what that display already shows,
    it moves on one more.
  - *Why:* until draft 53, In order worked the image out from the time:
    rotations since the phase started (for Always, since a start rounded
    down to 5 minutes) plus Change Now steps, counted into the current
    selection. Changing the selection shifted every image's place, so the
    next image jumped, and a phase that started earlier in the day picked
    up partway through. The author couldn't predict what should show and
    expected Phases to remember its last image and advance (2026-11-12,
    during the Photos checks).

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

- Each phase has a **Use in** setting: Any, Light Mode, or Dark Mode.
  Called **Only in** (Any, Light, Dark) through draft 62; "Only in… Any"
  read oddly (author, 2026-11-25, GitHub issue #27).
- The app listens for system appearance changes (including Auto switching) and
  re-evaluates immediately. If the switch makes a different phase active, the
  wallpaper changes right away; otherwise nothing happens.
- Examples:
  - *Dark images whenever Dark Mode is on:* two "Always" phases, one Light and one Dark.
  - *Dusk pictures, darker ones in Dark Mode:* two dusk phases, one Light and one Dark.
- The phase list shows a light/dark badge on phases with a condition.

## Missed changes: sleep, wake, unlock

On launch, wake from sleep, screen unlock, and time zone / clock changes, the app
`[D-missed-latest-only]`:

1. Works out which phase should be active right now.
2. If it differs from the last phase it applied, switches to it immediately.
3. If the same phase is active but one or more rotations came due while asleep,
   it makes **one** change, not one per missed rotation. For In order, that's
   the next image after the one last shown `[D-in-order-remembers]`; for
   Random, a single new random pick. The rotation clock stays aligned to the
   original schedule.
   - Until draft 53, In order skipped ahead by the number of missed
     rotations, to the image that would be showing had the Mac stayed
     awake. With In order remembering its place, skipping would pass over
     images nobody saw; the next one is the one to show.

## Location

- `[D-location-on-demand]` Uses Location Services. Permission is requested
  only when a phase first uses
  a dawn/dusk trigger, not at launch.
- Settings shows the current location, today's civil dawn and dusk, when the
  location was last updated, and an **Update Now** button.
- `[D-location-privacy-note]` **The Location section always carries a
  note:** "Phases uses this to work out your dawn and dusk times. Phases
  never sends your location anywhere; it stays on your Mac." It shows in
  every state: location shown, waiting, denied, or not needed yet.
  - It sits immediately under **Current location**, in the same row (no
    separator), in the normal text size (secondary color). In the other
    states there's no Current location row, so it joins the section's
    first row (the status line) the same way.
  - *Why:* the note describes that data, so it stays visually joined to
    it (author, 2026-11-24, after seeing draft 60's first build, where it
    was a separate caption row at the end of the section).
  - *Why it's true:* Phases has no network access. Its entitlements don't
    include `com.apple.security.network.client`, so the sandbox blocks
    any outgoing connection (*verified* 2026-11-24 by Claude, reading
    `App/Phases.entitlements`). The location is saved only in Phases' own
    settings on the Mac.
  - *Why "Phases never sends":* macOS's Location Services may ask Apple's
    servers to work out the position (*recalled*, not tested). That's
    outside Phases, so the note speaks only for Phases.
  - **If Phases ever gets network access, recheck this note** before that
    change lands.
  - *Why:* people reasonably wonder why a wallpaper app wants their
    location, and where it goes (author, 2026-11-24, GitHub issue #2).
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
  (name and icon), and the trigger line ends with **Phase disabled**.
  VoiceOver reads "Phase disabled". Such a phase is never the active one,
  so it never shows "Active" `[D-active-badge]`.
  - *Draft 45 removed the warning symbol:* until then the status followed
    an orange `exclamationmark.triangle.fill`. Not worth keeping: the
    dimmed row and the words say it, and an explicit orange would vanish
    on an orange Highlight Color, the problem issue #22 found with
    "Active" (author's call, 2026-11-06).
  - `[D-row-status-not-cause]` **The row shows the status; the editor
    shows the cause.** The sidebar row says "Phase disabled" for every
    reason Phases can't run a phase, the one exception being a phase the
    user turned off, which reads "Off" `[D-phase-turn-off]`. The phase
    editor's message names the reason ("Location access is off, so this
    phase is skipped." or "No location yet, so this phase is skipped."),
    under the row that fixes it `[D-phase-status-inline]` (draft 63).
    - *Why:* the row is for scanning the schedule; clicking it shows why.
      One status also covers any later reason a phase can't run without
      changing the row (author's call, 2026-11-05). Replaces the first
      draft 36 wording, where the row named the reason ("Location off",
      "No location yet").
    - *Why "Off" is the exception:* turning a phase off is the user's
      choice, not a problem. "Phase disabled" with a warning read as an
      error for it (author, after trying draft 42, 2026-11-06). Draft 42
      first showed "Phase disabled" for it too. Since draft 45 neither
      status has a warning symbol; the words alone set them apart.
  - `[D-phase-turn-off]` **A phase can be turned off** without deleting
    it, keeping all its settings and images, and turned back on later.
    Turned off is a reason a phase can't run: the schedule skips it.
    Its row is dimmed like any phase that can't run, and its trigger line
    ends with **Off** `[D-row-status-not-cause]`.
    VoiceOver reads "Off".
    - **Controls:** a switch at the trailing end of the editor's name
      row `[D-name-row]`, labelled **On** or **Off** to match its state,
      with "Use this phase" as its VoiceOver label; and **Turn Off** (or
      **Turn On**) in both the action menu and the row's context menu
      `[D-phase-actions]`, after Duplicate.
      - *Replaced:* through draft 62, a **Use this phase** switch in the
        editor's first section, under Name.
    - **Editor message:** "This phase is turned off, so it's skipped.",
      under the name row `[D-phase-status-inline]`.
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
    - *Why On/Off from draft 63:* the author's 2026-11-25 mockup puts the
      switch beside the name, where "Use this phase" won't fit. A label
      that follows the switch does read as a status, but here the status
      is the point, and the "turned off" message under the row says what
      Off means (author, 2026-11-25). VoiceOver keeps "Use this phase".
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
