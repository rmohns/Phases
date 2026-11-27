# Phases spec: Phase editor

Part of the Phases specification. [SPEC.md](../SPEC.md) is its front
page: the draft number, the "Design decisions" rules, and the list of
spec files.

What's here: the phase editor, shown in the window's detail pane when a
phase is selected ([window.md](window.md)).

## Phase editor

Draft 63 (GitHub issue #27). The design is the author's mockups of
2026-11-25; the review notes are Claude's from the same day, approved by
the author. Draft 51's version (the abandoned `feature/compact-editor`
branch) supplied the display tabs and pinned header.

- `[D-editor-layout]` **The phase editor is a name row, one block of
  settings, then the images.** Top to bottom:
  1. the name row `[D-name-row]`;
  2. the settings block, one grouped box of four rows: **Starts**
     `[D-starts-row]`, **Use in**, **Change images** `[D-rotation-row]`,
     and **Show images** `[D-order-row]`;
  3. the images block, a second grouped box: the pinned image header
     `[D-image-header]`, then the thumbnail grid with its source headings.
  - Text uses the system sizes the form uses now; the mockups' larger
    text isn't intended (author, 2026-11-25).
  - Each group of controls holds what it controls, and each message sits
    under the row that fixes it `[D-phase-status-inline]`: the name row
    manages the phase, the settings block says when it runs and how it
    changes, and the images block chooses images for each display.
  - *Why:* draft 62 gave nearly every setting its own row under its own
    section heading (Name, Starts, Wallpaper, Images), so on a laptop the
    grid started near or below the bottom of the window. The four-row
    block keeps every setting visible with a label while taking about
    half the height (author's side-by-side screenshot of draft 62 and the
    mockups, 2026-11-25, *observed*). Draft 51's two-row version was
    shorter still, but packed several settings into each row and needed
    explaining; the author wants the editor to explain itself without
    help text (2026-11-25).
  - *Replaced:* draft 62's sections Name (Name, Use this phase), Starts
    (Trigger, Time or offset, Only in), Wallpaper (Order, Rotate images
    during this phase, Every), and Images (Display, the grid).
- `[D-editor-labels]` **Row labels are plain words with no trailing "…"**
  ("Starts", not "Starts at…"). On the Mac a trailing ellipsis marks a
  command that asks for more before it acts, like "Save As…", not a label
  (HIG, *recalled*). Approved by the author 2026-11-25.
- `[D-name-row]` **The name row:** the phase's name as a title, a pencil
  after it, and the On/Off switch at the trailing edge `[D-phase-turn-off]`.
  - **The name is a text field drawn without a border,** in a larger
    title style than the form's text (a system text style, no fixed
    size). Clicking the pencil starts editing in place with the text
    selected; clicking the name puts the insertion point where it was
    clicked, as in any text field. Return or clicking elsewhere ends
    editing, and Escape puts back the name it had when editing started.
    The sidebar row follows the name as it's typed, as in draft 62. (The
    toolbar title is always "Phases" `[D-window-title-phases]`.)
    - *Changed while building* (Claude, 2026-11-25): the approved draft
      said clicking the name also selected the text, and that the name
      was saved on Return. A click in a text field places the insertion
      point, and the name already saved with each keystroke in draft 62;
      matching both keeps the field ordinary, and Escape still undoes
      the edit.
    - The pencil (`square.and.pencil`) is only a hint that the name can
      be edited; VoiceOver sees one text field labelled "Name". It keeps
      the `phaseName` accessibility identifier `[D-ui-test-ids]`.
    - **The pencil shows it can be clicked:** when the pointer is over
      it, a rounded highlight appears behind it, using a standard macOS
      button style that does this (`.accessoryBar`, the style of the
      buttons in accessory bars), not a custom effect.
      - *Changed while building* (Claude, 2026-11-26): the approved
        draft named `.accessoryBarAction`; in a test copy it drew a gray
        box all the time that didn't change under the pointer.
        `.accessoryBar` shows nothing until the pointer is over it
        (*verified* by Claude, 2026-11-26, screenshots with and without
        the pointer over it).
      The pencil stays centered on the name's capitals, level with the
      switch, and the highlight starts 8 pt after the name's last letter,
      leaving room for the insertion point when editing.
      - *Why:* a bare symbol gave no sign that clicking it does anything
        (author, 2026-11-26).
      - *Why 8 pt:* the first build with the highlight left 17.5 pt,
        which looked detached from the name (author, 2026-11-26); 5.5 pt
        nearly touched the last letter; 9 pt looked right, and the author
        chose 8 pt, an even number. At 8 pt the pencil symbol sits 2 pt
        further right than before the highlight, and the style draws it
        about 1.5 pt smaller (*verified* by Claude, 2026-11-26,
        screenshots of a test copy).
    - Initial focus `[D-initial-focus-sidebar]` still applies: the window
      opens with the sidebar focused, never the name field.
    - *Why in place:* the mockup's pencil could have opened a separate
      editor; editing the name where it's shown is simpler, and works
      the same from the keyboard and with VoiceOver (Claude's suggestion,
      approved by the author 2026-11-25).
  - **The switch is mini size** (`.controlSize(.mini)`, about 35 × 15 pt,
    *verified* by Claude 2026-11-26; the size System Settings' switches
    look like, *recalled*), with its On/Off text at the form's text
    size.
    - *Why:* the regular switch (about 53 × 23 pt) gave the row undue
      emphasis (author, 2026-11-26).
  - **The switch** is labelled **On** or **Off**, to match its state, with
    "Use this phase" as its VoiceOver label and `phaseIsOn` as its
    accessibility identifier, as now. When it's off, "This phase is
    turned off, so it's skipped." shows under the row
    `[D-phase-status-inline]`.
- `[D-starts-row]` **The Starts row reads as a sentence, so its controls
  change with the trigger.** The trigger menu lists **Clock Time**,
  **Dawn**, **Dusk**, and **Always**, each with the same symbol the
  sidebar rows use. Its place in the row moves with the trigger, on
  purpose, so each reads naturally (author, 2026-11-25):
  - **Clock Time:** "Starts [Clock Time] [9:00 AM]": the trigger menu,
    then a time field with a stepper.
  - **Dawn or Dusk:** "Starts [30] [minutes] [before] [Dawn]": a number
    field with a stepper, a **minutes / hours** menu, a **before / after /
    at** menu, then the trigger menu.
    - **at** means exactly at dawn or dusk: the number and unit hide, and
      the row reads "Starts [at] [Dawn]". Choosing before or after again
      starts from 30 minutes.
    - Limits stay −12 h to +12 h (see "Start triggers"): 1–720 minutes
      or 1–12 hours. A typed number past the limit becomes the limit.
      The minutes stepper moves by 5, the hours stepper by 1. Changing
      the unit keeps the number (clamped), so 30 minutes becomes 12
      hours, not half an hour.
    - The offset is stored in minutes; it's shown in the largest unit
      that divides it evenly, so 120 minutes shows as 2 hours and 90 as
      90 minutes.
    - Today's start time shows under the row `[D-start-readout]`.
  - **Always:** "Starts [Always]", with "Used when no timed phase
    applies." under the row in secondary text, always shown.
    - *Replaced:* draft 62's longer note, shown only when there was more
      than one phase: "An “Always” phase is used only when no timed phase
      applies. Use “Only in” to switch between Always phases with Light
      and Dark Mode."
  - *Why:* the 2026-11-25 mockup's number-and-stepper fields replace
    draft 51's preset menus: they cover any offset in minutes or hours
    without a Custom… step, and two hours no longer means typing 120 as
    in draft 62. The **at** choice gives the zero offset a natural
    reading; "[0] minutes before Dawn" read oddly (Claude's review,
    2026-11-25).
  - *Replaced:* draft 62's Trigger, Time, and offset rows ("[before, by]
    [30] minutes", minutes only).
- `[D-start-readout]` **A dawn or dusk phase says when it starts today,**
  in secondary text under the Starts row: "Today 6:12 AM (dawn 6:42 AM)",
  or "Today 6:42 AM" at dawn exactly. If dawn or dusk doesn't happen
  today (far north or south): "No dawn today" or "No dusk today". It
  follows the day, the location, and the time zone, as the schedule does
  (see "Start triggers").
  - Without a usable location, the location message shows in its place
    `[D-phase-status-inline]`.
  - *Why:* it's the only way to check an offset without doing the math
    (draft 51; approved again by the author 2026-11-25).
- **Use in:** a segmented control, **Any | Light Mode | Dark Mode**
  (see "Light and Dark Mode"). Words, not sun and moon symbols: the
  author doesn't want meaning carried by an icon nothing explains (see
  `[D-active-badge]`).
- `[D-rotation-row]` **Change images:** "Change images every [30]
  [minutes]": a number field with a stepper (1–999), then a menu of
  **minutes**, **hours**, a separator, and **Only when the phase
  starts**. Choosing that last item turns rotation off: "every" and the
  number hide, and the row reads "Change images [Only when the phase
  starts]". Choosing minutes or hours again turns it back on with the
  interval it had.
  - *Why:* the mockup's "Change every [30] [minutes]" had no way to turn
    rotation off, which draft 62 allows (Claude's review, 2026-11-25).
    Putting "off" in the unit menu costs no extra control; the label
    became "Change images" so the off state reads as a sentence. Claude's
    proposal in this draft, for the author to confirm.
  - *Replaced:* draft 62's **Rotate images during this phase** switch and
    a separate **Every** row.
- `[D-order-row]` **Show images:** a segmented control, **In Order |
  Randomly**. It stays separate from rotation: order still matters with
  rotation off, since it decides the phase's first image (In order: the
  next one `[D-in-order-remembers]`; Random: a random one).
  - *Why separate:* found in review of draft 51 (Claude, 2026-11-09) and
    confirmed by the author 2026-11-25; one "in order / randomly / never"
    menu would lose a combination.
- `[D-editor-popups]` **The settings block's pop-up menus look like
  System Settings' own:** the current choice, then the chevron in a
  small circle, with no box around them; when the pointer is over the
  menu, a rounded box appears behind the text and chevron, and the
  circle goes away. That covers the four menus: the trigger, minutes /
  hours, before / after / at, and Change images.
  - **They behave as standard pop-up menus,** as System Settings' do:
    a click anywhere in the control opens the menu, over the control,
    with the current choice under the pointer and checked; they work
    from the keyboard; and they keep their VoiceOver names ("Trigger",
    "Offset unit", "Before or after", "Change images") and accessibility
    identifiers `[D-ui-test-ids]` (author, 2026-11-26).
  - Each is as wide as its current choice, so Change images showing
    "minutes" isn't as wide as "Only when the phase starts" (author,
    2026-11-25).
  - The look copies System Settings' Sidebar icon size menu: the chevron
    in a 20 pt circle about 12 pt after the text; under the pointer, a
    box 23 pt tall with 6 pt corners, the same light gray as the circle
    (*verified* by Claude, 2026-11-26, measured from the author's
    screenshots of macOS 27.2).
  - *Why:* the standard pop-up's gray box around the whole control made
    the form harder to read; System Settings marks its menus with the
    chevron alone (author, 2026-11-26).
  - *How:* each is a real AppKit pop-up button set to draw its box only
    under the pointer, which draws System Settings' box and chevron there
    and opens its menu the standard way. On macOS 26 and later it draws
    no chevron at rest, so Phases draws the resting chevron and circle
    itself, on the same spot, taking no clicks `[Q-settings-popup-look]`.
    - **Check again on macOS 28 and later:** the resting chevron is
      Phases' own drawing, so a macOS that changes its pop-ups' look
      won't change it to match. The author will revisit then (author,
      2026-11-26).
    - *Set aside:* rebuilding the settings block as a grouped `Form`
      (where SwiftUI draws this look itself): the editor scrolls as one
      page under a pinned image header, and a `Form` scrolls on its own.
      A first version drew the whole look on a SwiftUI `Menu`; clicks
      between the text and the chevron, on the chevron, and in the
      box's margins did nothing, and its menu opened below the control
      like a pull-down (author's screen recording, 2026-11-26). Both are
      in EXPERIMENTS.md `[X-settings-popup-look]`.
  - *Replaced:* the standard pop-up button (gray box, chevrons at the
    trailing end) these four menus used through draft 63.
- `[D-phase-status-inline]` **Why a phase can't run shows under the row
  that fixes it,** in secondary text, with no banner:
  - Turned off: "This phase is turned off, so it's skipped." under the
    name row, which holds the switch.
  - Location access off: "Location access is off, so this phase is
    skipped." under the Starts row, with an **Open System Settings…**
    button that opens Privacy & Security › Location Services.
  - No location yet: "No location yet, so this phase is skipped." under
    the Starts row, with no button (Phases asks on its own
    `[D-location-on-demand]`).
  - Turned off wins, as before `[D-phase-turn-off]`: when a phase is
    both off and missing a location, only the name row's message shows.
  - The window-wide pause banner is unchanged `[D-window-pause-banner]`.
  - *Why:* status beside its fix, the rule the pause banner already
    follows. A phase-level banner would cost a row and say less (Claude's
    call, approved by the author 2026-11-09; confirmed 2026-11-25).
  - The **Open System Settings…** button is new in draft 63 (from
    draft 51).
  - *Replaced:* draft 62's orange warning with a triangle symbol, at the
    end of the Starts section for every reason, including turned off.
- `[D-image-header]` **The image header pins to the top of the editor
  while the grid scrolls.** Once the settings block has scrolled out of
  view, the header stays under the toolbar and the grid scrolls beneath
  it. Top to bottom:
  1. The display tabs `[D-display-tabs]`, when shown
     `[D-display-tabs-visibility]`.
  2. When the tabs are shown, a checkbox line: on the Shared tab, **Each
     display shows a different image** `[D-sharing-per-phase]`; on a
     display's tab, **Use different images on this display**.
  3. When selected images are missing: "2 selected images are missing"
     and **Remove Missing** (see "Image library").
  4. "9 of 293 selected", then **Select All** and **Select None**. Hidden
     on a display that uses the Shared images, where there's no grid to
     select in.
  5. A divider, then the grid.
  - The header has an opaque background, so thumbnails never show
    through it `[D-content-vs-tools]`.
  - *Why:* scrolled down a long grid, the user still has to see which
    display they're choosing for, and reach Select All and Select None
    (author, 2026-11-09; still wanted 2026-11-25). With the tabs shown
    it's about 130 pt tall (*estimate*, to check on the real window).
  - Source headings and subheadings in the grid collapse
    `[D-grid-collapse]` (draft 64, GitHub issue #37). Select All, Select
    None, and the count include collapsed images.
