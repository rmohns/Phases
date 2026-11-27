# Phases spec: Phases window

Part of the Phases specification. [SPEC.md](../SPEC.md) is its front
page: the draft number, the "Design decisions" rules, and the list of
spec files.

What's here: the window, its sidebar and toolbar, the pause banner,
and the Settings pane. The phase editor: [phase-editor.md](phase-editor.md).
The interface-wide rule `[D-content-vs-tools]`: [interface.md](interface.md).

## Phases window (one window for everything)
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
       - **Top edge:** the panel's top lines up with the top of the
         detail pane's first content (the phase editor's name row
         `[D-name-row]`, or Settings' header `[D-settings-order]`), so the sidebar and
         detail start content on one line under the toolbar
         `[D-tall-toolbar]`.
         - The name row sits where draft 62's first grouped row (Name)
           did, so the panel doesn't move. Through draft 62 the rule
           named "the first grouped row in the detail form"; from draft
           63 the phase editor's first row isn't grouped (author's
           question and Claude's answer, 2026-11-25).
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
     - `[D-brand-egg]` **Easter egg: click the panel and it turns into a
       meme.** Clicking anywhere on the panel replaces it with the "Get in
       loser, we're going vibe coding" meme (Mean Girls convertible still,
       632 × 396 px, bundled with the app). The meme fills the panel alone:
       no icon, name, tagline, or bottom gradient `[D-brand-legibility]`.
       It crossfades in with the panel's existing smooth animation.
       - **It goes back to the normal panel on its own** (draft 57,
         issue #23), whichever of these comes first:
         - **30 seconds pass.** The timer starts when the meme appears.
         - **The wallpaper changes:** anything that would change the
           panel's thumbnail (see "Background" above: Phases applying a different
           image to the main display). Nothing new watches for changes; the
           panel's existing update clears the meme and drops the timer.
         - **The window closes.** The window's state outlives a close (see
           `[D-grid-release-on-close]`), so the reset happens explicitly
           when the window closes, alongside the thumbnail release; it
           doesn't rely on the view going away. The next open shows the
           normal panel.

         The return crossfades with the same smooth animation as the way
         in.
       - **Clicking while the meme shows does nothing**; it doesn't
         restart the 30 seconds. Once the panel is back, clicking shows
         the meme again, for another 30 seconds.
       - *Until draft 56* the meme stayed until the window closed and
         further clicks did nothing. *Why the change:* the author asked
         for it to revert on its own (2026-11-14, issue #23), so a meme
         left up doesn't hide the wallpaper the panel exists to show.
       - *Verified* 2026-11-14 by the author, hands-on, draft 57 build: the
         meme reverts after 30 seconds; clicking again brings it back; a
         wallpaper change while it shows reverts it; the timer still fires
         with the panel scrolled offscreen.
       - **Scrolling doesn't reset it.** The flag and the 30-second timer
         belong to the window, not the panel row, so the meme survives the
         panel scrolling offscreen `[D-brand-scrolls]` and the timer keeps
         counting meanwhile.
       - **No hints.** The pointer doesn't change over the panel, and
         clicking it doesn't change the sidebar selection. It stays a
         surprise.
       - **VoiceOver gets it too.** The panel is a button. Before: label
         "Phases. Wallpaper for every phase of your day", hint "Get in."
         After: label "Meme: three women in a convertible. Get in loser,
         we're going vibe coding." with no hint.
       - The meme is 632 × 396 px, 1.6:1, the panel's own 16:10, so it
         fills the panel without a visible crop.
       - *Why:* the author asked for an utterly stupid easter egg
         (2026-11-06). The meme's own text takes the tagline's place
         instead of fighting it, and resetting on close keeps the joke
         from becoming the app's look.
  2. `[D-settings-at-top]` **"App" section:** a **Settings** row (gear icon). It sits at the top so
     it's always visible however many phases there are; the HIG advises
     against putting important items at the bottom of a sidebar, since window
     bottoms often end up offscreen.
  3. **"Phases" section:** the phase list, sorted by start time, with the
     active phase marked. Phase rows are two lines (name plus trigger), which
     also sets them apart from the one-line Settings row. A phase that can't
     run is dimmed and flagged `[D-phase-cant-run]`.
     - `[D-active-badge]` **The active phase is marked with the word
       "Active"** after its name, in small semibold text in the accent
       color. On the selected row, while that row has the colored
       highlight, "Active" switches to the row's text color (white on the
       highlight), like the rest of the row's text. The row has the
       colored highlight when it's selected, the window is in front, and
       the sidebar has keyboard focus; otherwise the highlight is grey and
       "Active" stays in the accent color. macOS fights this; see
       `[Q-tint-on-highlight]`.
       - *Why:* in the accent color on the accent-colored highlight,
         "Active" vanished (GitHub issue #22). The highlight is the user's
         Highlight Color (System Settings › Appearance), so no fixed color
         is safe on it. A symbol or a bold name instead was ruled out: the
         author doesn't want meaning carried by an icon or weight that
         nothing explains (2026-11-06).
       - The rule ("does this row have the colored highlight") lives in a
         small model function, `SidebarHighlight`, so the unit tests can
         check it (see TESTING.md).
       - *Verified* 2026-11-06; the record is under "Record for `[D-active-badge]`"
         at the end of this file.
       - *Verified* 2026-11-06 by the author on the draft 45 build: every
         Highlight Color, in dark and light mode. Yellow, Green, and
         Graphite are a little hard to read in light mode; accepted, since
         that's the look the user chose (author's call).
  - + / − buttons below the list add and remove phases. − removes the
    selected phase and is dimmed when no phase is selected.
  - `[D-new-phase-now]` **A new phase starts at the current time,** as a
    Clock Time trigger rounded down to the nearest 5 minutes (2:37 PM
    becomes 2:35 PM), named "New Phase", and selected.
    - It changes images every 30 minutes `[D-rotation-row]`, not "Only
      when the phase starts" (author, 2026-11-27). So do the starter
      phases `[D-starter-phases]`. Phases already saved keep their own
      setting, and a saved phase with no rotation setting still loads
      with rotation off.
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
  be made narrower than **490 pt** (460 pt through draft 62, 550 pt
  until 2026-11-27), so the window's minimum width is the sidebar's
  current width plus 490 pt (730 pt with the sidebar at its 240 pt
  minimum `[D-sidebar-width]`).
  The pane's content reports that minimum itself, so the window can't
  open or be dragged narrower than what the editor needs, whichever pane
  is showing. The window can't be made shorter
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
  - *Draft 63:* the widest editor row is now Starts with a dawn or dusk
    offset, "Starts [30] [minutes] [before] [Dawn]" `[D-starts-row]`,
    about 420 pt with the form's padding (*estimate*), and "Any | Light
    Mode | Dark Mode" is wider than draft 62's segments. Both must fit at
    460 pt; check on the real window before changing the minimum.
  - *Draft 63, after the first build:* at 460 pt they didn't fit. The
    Starts label was pushed out of view, "Change images" truncated, and
    the controls ran past the pane's edge (*observed* by the author,
    2026-11-25, two screenshots). The author set the minimum to about
    540–550 pt; 550 it is.
  - *2026-11-27, down to 490 pt:* 550 was a conservative pick while the
    draft 63 layout settled; with the layout fixed, the author asked for
    a true minimum. The Starts row with a dawn or dusk offset is still
    the widest row. *Measured* by Claude from the author's screenshot of
    the window at its 790 pt minimum (scale about 1.19 px per pt, checked
    against the 44 pt offset field and the 240 + 550 pt panes; by eye,
    about ±2 pt): "Starts [30] [minutes] [after] [Dawn]" left about 93 pt
    between the label and the field, 12 pt of it `EditorRow`'s fixed
    spacing, so about 81 pt to spare. The pop-ups are as wide as their
    current choice `[D-editor-popups]`, and "before" is about 8 pt wider
    than "after" (*estimate*), making "minutes before Dawn" the widest
    case, about 73 pt to spare. Every other row had 150 pt or more.
    490 pt (−60) leaves about 13 pt in the widest case; the author chose
    it. Check "minutes before Dawn" on the real window at the minimum.
    *Observed* by the author on the real window at the new minimum,
    2026-11-27: "looks perfect".
  - *Draft 63, also found then:* the window could be narrower than the
    editor's content. The draft 62 editor was a `Form`, which tells the
    window its minimum width; the draft 63 editor is a scroll view, which
    doesn't, so its controls were clipped at the pane's edge instead. Once
    Settings (still a form) had been shown, the window kept the larger
    minimum (*observed* by the author; the cause is Claude's hypothesis,
    not traced in AppKit). *Verified* by Claude the same day, AX resize of
    a test-mode window: the 700 pt minimum held, so the window wasn't
    going below its minimum; the minimum was too small for the content.
- `[D-tall-toolbar]` **Full-height toolbar over the detail pane only.** The
  window keeps macOS's tall unified toolbar, like System Settings and
  Bitrig, even though it has no toolbar buttons. The sidebar stays full
  height beside it. `[D-window-title-phases]` The toolbar title is always
  **Phases**, the window's name; what's selected is named by the pane's
  own header: the phase editor's name row `[D-name-row]`, or Settings'
  header `[D-settings-order]`.
  - *Why:* the draft 63 editor puts the phase's name in its name row, so
    a title naming it too showed the name twice (author, 2026-11-25).
    Settings got a header the same way, so both panes match.
  - *Replaced:* drafts up to 62, and draft 63's first builds, titled the
    toolbar with the selection: the phase name, "Settings", or "Phases"
    when nothing was selected.
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
- **Phase selected:** the phase editor, next.

### Pause banner and Settings

Moved here from the end of the phase editor's section when the spec was
split into files (2026-11-27): these apply to the whole detail pane
and to Settings, not to the phase editor.

- `[D-window-pause-banner]` **While Phases has paused itself for an
  outside change `[D-outside-change-pauses]`, a pause banner sits at the
  top of the detail pane,** whatever is selected (a phase, Settings, or
  nothing). It stays put while the form scrolls. A pause the person
  chose, from the menu or the Settings switch, shows no banner.
  - *Why only then:* a pause someone chose is a normal state they already
    know about, so a banner explaining it is noise, and its one-line
    reason ("Paused from the menu.") was wrong whenever the switch had
    done it. An outside change pauses without anyone choosing to, so
    that's the case that needs explaining (author, 2026-11-24). A manual
    pause still shows in the menu bar icon's badge
    `[D-menubar-icon-paused]`, the menu, and the Settings switch. Drafts
    49–60 showed the banner for any pause, with "Paused from the menu."
    as the manual reason.
  - If the person had already paused when a wallpaper is picked in
    System Settings, the pause becomes an outside-change pause and the
    banner appears.
  - **Left:** a pause symbol (`pause.fill`, secondary), then "Phases is
    paused" in a bold headline, with the reason under it in secondary
    text: "Paused at 9:06 AM because the wallpaper was changed in System
    Settings." (the date is added when it wasn't today). The symbol
    repeats what the words say; it carries no meaning of its own.
  - **Right:** a **Resume Wallpaper Changes** button, the menu's wording
    `[D-menu-pause-verb]` (Resume Schedule through draft 59). It resumes
    exactly as the menu does `[D-outside-change-pauses]`.
    - The new label is longer, so the banner's wrapping at the narrowest
      window (GitHub issue #30) is rechecked when it lands.
  - VoiceOver reads the symbol and text as one element ("Phases is
    paused. Paused at 9:06 AM because…"), then the button.
  - The reason text is worked out in the model, not the view, and
    unit-tested `[D-tests-unhosted]`.
  - While it shows, the detail form starts lower, so its first row no
    longer lines up with the branding panel's top `[D-brand-inset]`.
    Accepted: pausing is an abnormal state, and the banner is meant to
    stand out.
  - *Why:* the window opens on a phase's editor, so a pause shown only
    in Settings went unseen there, and "why isn't it changing?" had no
    answer without knowing to click Settings. Status with its fix right
    beside it, in every view (author, 2026-11-07, GitHub issue #30). A
    status bar at the bottom of the sidebar was considered and rejected:
    at 240 pt the System Settings reason wraps to three lines, and it
    would sit beside the phase list's + / − (Claude, 2026-11-07).
- `[D-settings-pause-switch]` **Settings starts with a Pause wallpaper
  changes switch,** in a section of its own with no heading. On means
  paused: it's the same state as the menu's Pause Wallpaper Changes (one
  state, two controls) `[D-menu-pause-verb]`. A pause for an outside
  change `[D-outside-change-pauses]` turns it on too. Otherwise turning
  it off resumes. No note under it.
  - `[D-pause-switch-disabled]` **While the pause banner shows
    `[D-window-pause-banner]`, the switch is disabled:** on, greyed out,
    no extra text. The banner's **Resume Wallpaper Changes** is the way
    back; the menu's Resume still works too.
    - *Why:* two controls one above the other doing the same thing is
      ambiguous. The banner's button resolves the outside change, and
      resolving it is what puts Phases back to normal (author,
      2026-11-24). Underneath, both resume the same way.
  - *Why:* changing wallpaper is what Phases is for, so nobody turns it
    "off"; pausing is what people actually want to do, so the switch
    names that (author, 2026-11-24, GitHub issue #2). No heading, because
    the switch's own label says it all.
  - *Why in Settings at all:* resuming shouldn't depend on finding a menu
    item; the window is where someone goes to ask why Phases stopped
    (author, 2026-11-06).
  - *Replaced:* `[D-settings-schedule-switch]`, drafts 37–59: a
    **Change wallpaper on schedule** switch under a Schedule heading, on
    meaning not paused. Drafts 37–48 also put the pause reason in a note
    under it; draft 49 moved that to the banner so it shows in every
    view.
- `[D-settings-order]` **Settings selected,** top to bottom (GitHub issue
  #2, draft 60):
  0. From draft 63, a **Settings** header in the same title style as the
     phase editor's name row `[D-name-row]`, in the same place, scrolling
     with the form. The toolbar title is "Phases"
     `[D-window-title-phases]` (author, 2026-11-25).
  1. The pause switch `[D-settings-pause-switch]`.
  2. **Image Sources** `[D-image-sources]`.
  3. **Transition:** None / Crossfade and duration, with the Reduce
     Motion note `[D-reduce-motion-note]` and the low-memory note
     `[D-low-memory-note]`.
  4. **Location:** status, today's civil dawn and dusk, Update Now, and
     the privacy note `[D-location-privacy-note]`.
  5. **Launch & Quit:** **Launch at Login** `[D-login-consent]` (with its
     approval and error lines), **Restore original wallpaper when
     quitting** with a note that says what quitting will do
     `[D-restore-on-quit]`, and **Ask before quitting** `[D-quit-confirm]`.
  6. **About** `[D-version-in-settings]`.
  - No Displays section: display sharing is a phase setting, in the
    phase editor `[D-sharing-per-phase]` (draft 63). Drafts 60–62 had no
    control for it at all (`[D-sharing-no-interface]`, replaced).
  - No Quit button: Quit lives in the app menu `[D-app-menu]` (draft 24
    and earlier had a Quit Phases button here).
  - *Why Launch & Quit is one section:* both are about Phases starting and
    stopping, and as two sections each held a toggle or two (author,
    2026-11-24, GitHub issue #2).
  - *Replaced:* drafts up to 59 ran Schedule, Image Sources, Displays,
    Transition, Startup, Location, Quitting, About.
- `[D-version-in-settings]` **About section,** last in Settings, below
  Launch & Quit, one line each:
  - **Version:** the app's version and build number, e.g. "0.1 (47)".
  - **Spec:** the SPEC.md draft the build was made against, e.g. "Draft 47".
  - **Built:** the date and time this copy of the app was built (taken
    from the app's executable file).
  - `[D-memory-in-about]` **Memory:** how much memory Phases is using,
    e.g. "142 MB". It's the process's physical footprint, the figure
    Activity Monitor shows in its Memory column (*verified* 2026-11-24
    by Robert and Claude: Activity Monitor showed Phases at 79.4 MB
    while `footprint` read its `phys_footprint` as 83,674,144 bytes,
    79.8 MB in 1024² units, which Phases rounds to "80 MB". Activity
    Monitor uses the same 1024² megabytes; in decimal megabytes it would
    have read about 83.7. The 0.4 MB gap is drift between the two
    readings, which weren't taken at the same moment.)
    - Read once each time Settings appears, not updated while it shows.
      The figure includes the open window's own cost (about 25 MB stayed
      after opening it, *measured*, LEARNINGS.md `[L-mem-window]`).
    - Reading it lives in the model, not the view. If it can't be read,
      the line is left out.
    - Shown in whole megabytes (1 MB = 1024² bytes, rounded), the same
      way here and in the low-memory note `[D-low-memory-note]`. The
      formatting is a pure function, unit-tested.
    - *Why a snapshot:* memory use doesn't depend much on the images'
      size, since covers are screen-sized `[D-cover-only-for-crossfade]`;
      a live figure would mostly catch a display being connected while
      Settings is open, which isn't worth a timer (author, 2026-11-24).
      Before the memory fixes each change also had a short full-size
      decode peak, purged within 40 s (*measured*, LEARNINGS.md
      `[L-mem-decode]`); a snapshot may catch one, and reopening Settings
      shows a fresh figure.
    - *Why:* lets someone see what Phases costs, and whether the
      low-memory note `[D-low-memory-note]` is worth acting on (GitHub
      issue #2).
  - *Why:* during testing, the author needs to tell which build is
    running. The build number *is* the spec draft, so Finder's Get Info,
    the standard About panel, and this section all name the same draft;
    the build time tells apart builds of one draft.
  - *Version scheme:* "0.1" until the author calls Phases finished; the
    build number is the SPEC.md draft number.
  - *How:* the draft number is set in one place, the build number
    (`CURRENT_PROJECT_VERSION`, the Phases target's build setting in the
    Xcode project `[D-xcode-project]`; in `Project.json` through draft
    58). The Info.plist takes
    its version and build number from those build settings rather than
    repeating them, and the Spec line reads the app's build number
    (`App/Model/AppVersion.swift`). A unit test reads SPEC.md's title and
    fails if the project's setting doesn't match it, so the number can't drift
    from the spec `[D-tests-carry-tags]`. Bump it with each new draft.
  - *Replaced:* through draft 46 the version was a fixed "1.0 (1)" on the
    theory that a personal app's version never changes, and the draft was
    a separate constant in the code. The constant was missed in the
    draft 46 change, leaving Settings at "Draft 45" (verified 2026-11-06
    by Claude: the unit test failed on `main`).

## Record: Phases window

*Verified* notes and other evidence moved here, word for word, from the
decisions above when the spec was split into files (2026-11-27), so a
decision reads as its rule and its *Why*. Each decision keeps a dated
pointer to its record here.

### Record for `[D-active-badge]`

- *Verified* 2026-11-06 by Claude on the experiment build (window
  screenshots, Highlight Color blue): white on the colored
  highlight; accent on the grey highlight with focus in the editor
  and with the window in the background (LEARNINGS.md
  `[L-row-own-selection]`, ERRATA.md `[Q-tint-on-highlight]`).
