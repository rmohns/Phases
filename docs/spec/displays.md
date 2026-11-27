# Phases spec: Displays

Part of the Phases specification. [SPEC.md](../SPEC.md) is its front
page: the draft number, the "Design decisions" rules, and the list of
spec files.

What's here: per-display images, how displays are recognized, the
Shared images, and what happens when displays change.

## Displays

### Per-display images
- Each phase has one image selection called **Shared** (**All Displays**
  through draft 62), plus optional selections for specific displays.
  Schedule, order, and rotation are shared: every display changes at the
  same moments.
  - *Why "Shared":* the selection isn't used by all displays once one has
    its own images, so "All Displays" stopped being true (draft 51 on the
    abandoned `feature/compact-editor` branch; author, 2026-11-25, issue
    #27).
- `[D-display-tabs]` **The phase editor picks a display with a row of
  display tabs** at the top of the Images section, in place of draft 62's
  **Display** pop-up menu. The row is part of the pinned image header
  `[D-image-header]`.
  - **Tabs, left to right:** **Shared**, a thin vertical divider, then each
    connected display `[D-connected-displays-only]`, in macOS's display
    order (*recalled*: the main display first).
  - **Each tab** is a display picture over the display's name, with a
    caption under it in secondary text:
    - Shared: two overlapping screens, in the accent color; caption
      "18 images" (its selection count, the same number as the count line
      under the tabs).
    - A display: its outline `[D-display-tab-shapes]`.
    - A display using the Shared images: caption "Uses Shared". With its
      own images: "Own · 1 image".
  - Tabs have a fixed width. A name too long for it wraps to a second
    line, then truncates at the end; the tooltip shows the full name.
    *Why:* an earlier mockup truncated in the middle ("Built-in…a
    Display"), which reads badly (Claude, 2026-11-09).
  - The selected tab gets a rounded, filled background.
  - **Overflow:** Shared and the divider stay put; the display tabs to
    their right scroll sideways when they don't fit, with the edge faded
    on any side that has tabs out of view.
    - *Why:* the fade shows there's more without a scroll bar, and
      keeping Shared in place means it's always one click away. A mouse's
      scroll wheel may not scroll a sideways row without ⇧ (*recalled*,
      not tested here); a trackpad does. Approved by the author
      2026-11-25.
  - Shared is selected whenever a phase is opened. If the selected
    display disconnects while the editor is open, Shared is selected.
  - **Accessibility:** the tabs are one selection control, one Tab stop,
    with arrow keys moving between tabs (scrolling the row to keep the
    chosen tab in view). VoiceOver reads each as its name and caption,
    plus "selected" on the chosen one. They aren't a row of separate
    buttons.
  - *Why:* a pop-up menu hides which displays have their own images until
    it's opened. The tabs show every display and its state at a glance,
    and the divider sets Shared apart as a different kind of choice
    (author's design, 2026-11-09, kept in the 2026-11-25 mockups;
    draft 51 added the divider and the author found it helped a lot).
- `[D-display-tab-shapes]` **A display's tab draws its outline at its
  real proportions:** a rounded rectangle at the display's current
  aspect ratio, as arranged in System Settings, so a rotated display is
  drawn tall and an ultrawide drawn wide. The outlines share one height
  (32 pt), and one too wide for the tab is scaled down to fit, keeping
  its proportions, so a very wide display is drawn shorter.
  - *Why:* per-display images exist mostly for portrait and ultrawide
    displays, so the shape is what tells the tabs apart. Only connected
    displays are listed, so the shape is always known (author's mockup,
    2026-11-25; Claude's review the same day).
  - *Replaced:* draft 51's laptop and monitor symbols, which made no
    attempt to draw a display's real shape.
- `[D-display-tabs-visibility]` **The tab row shows when more than one
  display is connected,** or when exactly one is connected and it has its
  own images in this phase (then the row is Shared plus that display).
  Otherwise it's hidden, and the editor shows the Shared selection, so a
  one-display Mac looks and behaves as before.
  - *Why the exception:* with only connected displays shown, a laptop
    given its own images while docked would hide the row once undocked.
    The editor would then show the Shared grid while the laptop actually
    uses its own images, with no way to see or undo that (found in review,
    Claude, 2026-11-09).
- **A display's tab** shows a **Use different images on this display**
  checkbox in the image header `[D-image-header]`. When on, that display
  gets its own thumbnail grid and draws only from its own selection (e.g.
  ultrawide images for an ultrawide monitor, portrait images for a
  portrait one). When off, it uses the Shared selection, and in place of
  the grid the editor says so: "Uses the Shared images" with "This
  display shows the images chosen under Shared. Turn on “Use different
  images on this display” to choose different ones for it." centered
  below, in secondary text.
- `[D-own-images-start-from-shared]` **Turning "Use different images on
  this display" on starts from a copy of the Shared selection,** not an
  empty one.
  - *Why:* an empty selection makes the display keep its current wallpaper
    and stop changing `[D-own-images-no-fallback]`, which looks like a
    bug. Starting from Shared changes nothing until the user edits it
    (Claude's call, approved by the author 2026-11-09; confirmed
    2026-11-25).
  - *Replaced:* through draft 62, turning it on started from an empty
    selection.
- `[D-own-images-no-fallback]` If a display has its own selection but none
  of those images are available,
  that display keeps its current wallpaper; it does not fall back to Shared.
- Turning the checkbox off discards that display's selection for that phase.

### Display identity
- `[D-display-uuid]` Displays are identified by their hardware UUID, so settings survive
  unplugging, reconnecting, and rearranging. Phases remembers each display's
  name.
- `[D-connected-displays-only]` **Only connected displays are shown.** A
  display that isn't connected has no tab; it reappears, with its
  selections, when it's connected again.
  - If its tab was chosen when it disconnected, Shared is chosen
    instead, and stays chosen when the display comes back: the editor
    doesn't jump back to a tab on its own (author, 2026-11-25, after
    the Phase editor checks found it returning selected).
  - *Why:* through draft 62 every display ever seen stayed in the picker,
    marked "(not connected)", so one hotel projector became a permanent
    entry. Showing only what's connected also removes the need for a
    "disconnected" warning (author, 2026-11-09; confirmed 2026-11-25,
    issue #27).
  - *Replaced:* `[D-display-uuid]`'s "Disconnected displays stay in the
    picker, marked "(not connected)", and keep their selections" (drafts
    up to 62). They still keep their selections.
- `[D-keep-display-settings]` **Saved display settings are never pruned.**
  A display's selections are kept however long it's been away.
  - *Why:* a saved display is its UUID, its name, and lists of image
    names, a few hundred bytes to a few KB (*recalled* estimate, not
    measured). Pruning would add code and lose the settings of a monitor
    used once a year. System Settings seems to keep displays the same way
    (author's observation, 2026-11-09).
  - Removing a source treats these saved selections like any other: its
    images show as missing (see "Image library").

### Displays sharing the Shared images
- `[D-sharing-per-phase]` **A setting of each phase,** applying only to
  displays **without** their own images in that phase: same image
  everywhere (default), or each display shows a different image (each
  draws its own pick from the Shared images).
  - Shown on the Shared tab as an **Each display shows a different image**
    checkbox in the image header `[D-image-header]`, only when the tab row
    is shown. It's dimmed when fewer than two connected displays use the
    Shared images in this phase.
  - *Why:* it's an image decision, so it belongs beside the image picker,
    and a phase is where image decisions live (author, 2026-11-09 and
    2026-11-25; GitHub issues #2 and #26).
  - **Upgrading** from draft 62 or earlier copies the app-wide preference
    (**Same image everywhere** / **Different picks per display**) into
    every phase, so nothing changes on the desktop. The app-wide value is
    then no longer read. New and duplicated phases: a new phase starts with
    the same image everywhere; a duplicate copies its phase's setting
    `[D-duplicate-phase]`.
  - *Replaced:* `[D-sharing-no-interface]` (drafts 60–62): the app-wide
    preference had no control after it left Settings in the Settings
    cleanup (GitHub issue #2), and was to move into each phase's editor
    in a later change, this one. Through draft 59 it was one app
    preference in Settings.
- In order: each display's selection (or the shared one) advances in step. With
  different images, sharing displays are offset by one from each other: the
  shared selection remembers the image on the first sharing display (the
  main display first) `[D-in-order-remembers]`, and the others show the
  images after it.

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
  changes only if something needs repair: a newly connected display has
  no image yet, or a display's image isn't in its selection. Otherwise
  nothing changes. A screen change never by itself picks new images. In
  order, a repair doesn't move the place: displays whose image is still
  in their selection keep it `[D-in-order-remembers]`.
  - *Why:* a change that leaves every display's image in its selection shouldn't
    change the wallpaper. Draft 21 re-applied the active phase on every
    display change, so with Random order unrelated system changes such as
    hiding the Dock crossfaded to a new image (found in testing,
    2026-10-28). macOS fights this; see `[Q-screen-params-notification]`.
  - When a change is needed, the whole phase is re-applied, so with Random
    a newly connected display can also give the other displays new picks.
    Unchanged from earlier drafts.
  - Covers are redrawn, added, or removed first `[D-cover-follows-displays]`.
