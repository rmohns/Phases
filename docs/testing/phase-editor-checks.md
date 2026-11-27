# Phases testing: Phase editor checks

Part of the testing docs. [TESTING.md](../TESTING.md) has the rules every
hands-on check follows (`[D-hands-on-checks]`: any check alone, who runs
it, proving the input landed), the unit tests, and what to do when a
fixed bug comes back. Moved here word for word from TESTING.md
"Hands-on checks" on 2026-11-27.

## Phase editor checks (draft 63)

- `[D-editor-checks]` **The redesigned phase editor is checked by hand
  before it merges,** and after any change to the display tabs, the
  image header, or the Starts row. The UI tests can't add or remove
  displays, and nothing automated judges how the editor looks. Ask
  first, naming the checks. Checks 1–4 need several displays: real
  ones, or the author's tool that adds displays that aren't physically
  connected.
  - Build: the newest Bitrig Debug build, diagnostics on.
- **The checks:**
  1. **Tab row shows and hides** `[D-display-tabs-visibility]`: one
     display, the row is hidden; two or more, it shows Shared, the
     divider, then each display in macOS's order; back to one display
     after giving it its own images, the row shows Shared plus that
     display.
  2. **Shapes** `[D-display-tab-shapes]`: a rotated (portrait) display
     is drawn tall and an ultrawide wide, all at one height; a long name
     wraps, then truncates at the end, with the full name in the
     tooltip.
  3. **Overflow** `[D-display-tabs]`: with enough displays to overflow
     at the minimum window width, Shared and the divider stay put, the
     other tabs scroll sideways with a trackpad, and the edge fades on
     each side with tabs out of view. Note whether a mouse's scroll wheel
     scrolls the row without ⇧ (*recalled* that it doesn't; record what
     happens).
  4. **Disconnect and reconnect** `[D-connected-displays-only]`: with a
     display's tab selected and its own images chosen, disconnect it:
     Shared is selected and the tab is gone. Reconnect: the tab is back,
     "Own · N images", same selection.
  5. **Sharing checkbox** `[D-sharing-per-phase]`: dimmed when fewer than
     two connected displays use Shared; with two, turning it on gives the
     displays different images at the next change, per phase. A Mac
     upgraded from draft 62 with **Different picks per display** shows
     it on in every phase.
  6. **Own images** `[D-own-images-start-from-shared]`: turning on "Use
     different images on this display" shows the Shared selection
     already chosen, and the wallpaper doesn't change; turning it off
     shows "Uses the Shared images".
  7. **Pinned header** `[D-image-header]`: scrolled down a long grid, the
     tabs, checkbox, count, and Select All / Select None stay in view,
     with no thumbnail showing through; with a missing image, Remove
     Missing is in the header and works.
  8. **Starts row and messages** `[D-starts-row]` `[D-start-readout]`
     `[D-phase-status-inline]`: each trigger's row reads as a sentence;
     a dawn phase's "Today …" line matches Settings' dawn time minus
     the offset; with Location off, the message and Open System
     Settings… replace that line; a phase turned off shows its message
     under the name row only.
  9. **Fit and look** `[D-window-min-size]` `[D-editor-layout]`: at the
     minimum window width, the dawn Starts row and "Any | Light Mode |
     Dark Mode" fit without clipping; Light and Dark Mode both read
     well; the branding panel's top lines up with the name row
     `[D-brand-inset]`.
  10. **VoiceOver:** the name field reads "Name", the switch "Use this
      phase", the display tabs as one control with each tab's name,
      caption, and "selected".
- Record results with date and build in this section, as the other
  checks do.

### Runs

- 2026-11-25, checks 1–4 (Claude, with the author's yes; Debug build 63
  `1795653866893-A59A58A0`, a test-mode copy, so no real wallpaper or
  settings touched). Displays: the built-in (1300 × 845) and BetterDisplay
  virtual screens, driven through BetterDisplay's command line (the author
  turned its CLI integration on): "Virtual 16:10" (1366 × 768), then four
  made for the run, "Phases Test Portrait" (9:16), "Phases Test
  Ultrawide Display With a Deliberately Long Name" (21:9), "Phases Test
  4:3", and "Phases Test 16:9". Evidence is screenshots of the test
  window (*observed*), except where noted. Diagnostics weren't on.
  - **Check 1, passed.** Two displays: Shared, the divider, Built-in,
    Virtual 16:10, in `NSScreen.screens` order. Down to one display
    using Shared: the row hidden. Down to one display with its own
    images: Shared plus that display.
  - **Check 2, passed, with one flaw.** Portrait drawn tall, ultrawide
    wide, every outline one height; the long name wraps to two lines,
    then truncates at the end ("Ultrawide Displa…"); hovering shows the
    full name as a tooltip. *Flaw:* a tab whose name wraps is taller
    than the others, and the row centers tabs vertically, so its outline
    and caption sit higher than its neighbours'.
  - **Check 3, mostly passed.** At 790 pt (the minimum) six displays
    overflow; Shared and the divider stay put; arrow keys move the
    selection and scroll it into view; the trailing edge fades with tabs
    out of view there, the leading edge once tabs are hidden on that
    side. *Flaw:* the chosen tab scrolls only just into view, so it can
    sit under the 24 pt trailing fade. *Not settled:* a synthetic
    two-finger swipe (new `phases-drive swipe`, continuous pixel deltas
    with began/changed/ended phases) didn't scroll the row, and neither
    did a synthetic mouse wheel without ⇧ (`phases-drive wheel`). Per
    `[D-input-lands]` neither is a finding: nothing shows the swipe was
    delivered as a real trackpad's would be. A real trackpad and mouse
    are the author's to try. After Tab / Shift-Tab, and after a click on
    a tab, Right Arrow worked every time (5 presses, *observed*).
    - **Finding, open:** three Right Arrow presses at about
      23:10:00–23:10:08 did nothing, and the author heard beeps then
      ("about eleven ten and a few seconds past", *observed* by the
      author; the screenshot after them is stamped 23:10:08). A beep is
      macOS refusing an unhandled key, so the presses reached Phases and
      nothing took them, while the row was drawn with focus. Before them:
      a click on a tab (23:08), the AX resize to 790 pt, then the
      synthetic swipe and wheel over the row. *Hypothesis, untested:* the
      resize or the scroll events left focus drawn on the row while key
      focus was elsewhere. The unified log showed no beep entry.
      Reproduce before fixing.
  - **Check 4, passed.** Virtual 16:10's tab selected with its own 4
    images, then disconnected: the row hid (one display left, using
    Shared), with Shared's grid shown. Reconnected: the tab back, "Own ·
    4 images", all 4 still chosen. The tab came back *selected*: the
    editor remembers the chosen display while it's away
    (`DisplayTabs.selection` falls back to Shared only while the tab is
    missing). The spec doesn't say whether it should.
  - Also seen: at one moment just after the AX resize to 790 pt, the
    row's focus ring ran past the image box's right edge to the
    window's; on the next screenshot it fit. Taken as mid-resize, not a
    finding.
  - **Both flaws fixed** the same day (author's go-ahead): the tab row
    is top-aligned, and the chosen tab scrolls to the row's center
    instead of just into view. Rechecked on Debug build 63
    `1795666506719-097FA50C` at 790 pt with the same six displays
    (*observed*, screenshots): every outline and name level, wrapped or
    not; the ultrawide, chosen by arrow keys, centered clear of both
    fades; at the far end the last tabs fully in view and no trailing
    fade. The four test displays were then discarded.
  - **Reconnect, changed** (author, 2026-11-25): a reconnected display's
    tab now comes back unselected, Shared staying chosen
    (`[D-connected-displays-only]`). Rechecked on Debug build 63
    `1795666739618-64C3AE82`: Virtual 16:10's tab chosen, disconnected,
    reconnected; Shared chosen (*observed*).
- 2026-11-25, checks 5–10 (Claude, with the author's yes; Debug build 63
  `1795666739618-64C3AE82`, test mode, diagnostics on; the built-in
  display and Virtual 16:10; 790 pt window; a 60-image copy of the test
  folder). Screenshots throughout (*observed*).
  - **Check 5, passed in part.** With two displays using Shared the
    sharing checkbox is on and live; with Virtual 16:10 on its own images,
    dimmed. *Upgrade:* launched with a draft-62 store passed as launch
    arguments (`-phases <data>` holding one old phase with no
    `displayMode`, plus `-displayMode differentPerDisplay`); the phase
    opened with "Each display shows a different image" on. One phase,
    not several. *Not run:* "different images at the next change," since
    test mode never sets the wallpaper; that needs a real run.
  - **Check 6, passed.** Turning on own images for Virtual 16:10 showed
    Shared's 60 already chosen ("Own · 60 images"), and the branding
    panel's picture didn't change (test mode sets no wallpaper, so the
    panel is the evidence). Turning it off showed "Uses the Shared
    images".
  - **Check 7, passed.** Wheel-scrolled down the grid: the tabs,
    checkbox, count, and Select All / Select None pinned under the
    toolbar, no thumbnail showing through. One image file deleted, then
    the window closed and reopened (the library rescans on open; it
    didn't notice the deletion while open): "1 selected image is
    missing" with Remove Missing in the header; clicking it cleared the
    line, 59 of 59. The synthetic wheel scrolled the editor, so
    `phases-drive wheel` is shown to land (TEST-TOOLS.md), which makes
    check 3's wheel result a finding: a plain mouse wheel doesn't scroll
    the display tabs sideways, as recalled.
  - **Check 8, passed in part.** Always: "Used when no timed phase
    applies." Dawn, at: "Starts [at] [Dawn]", "Today 6:17 AM"; before:
    "[30] [minutes] [before] [Dawn]", "Today 5:47 AM (dawn 6:17 AM)",
    matching Settings' civil dawn, 6:17 AM. Turned off: "This phase is
    turned off, so it's skipped." under the name row only. *Not run:*
    Location off (it means changing the Mac's privacy settings). *Seen:*
    the trigger menu lists Always, Clock Time, Dawn, Dusk, where
    `[D-starts-row]` lists Clock Time, Dawn, Dusk, and Always; whether
    the spec meant an order isn't clear.
  - **Check 9, passed.** At 790 pt the dawn Starts row and "Any | Light
    Mode | Dark Mode" fit unclipped; Dark and Light Mode both read well
    (the Mac switched to Light Mode for one screenshot and straight
    back); the Settings header's top lines up with the branding panel's.
  - **Check 10, read from the accessibility tree, not with VoiceOver
    running.** The switch: "Use this phase". The display tabs: one radio
    group, each tab "name, caption", Shared selected. *Gap:* the name
    field's only label is its placeholder, "Name" (no description), so
    VoiceOver likely reads "Old, text field" without "Name"
    (*recalled* that placeholders are spoken only when empty; not
    tested). `[D-name-row]` says it's labelled "Name". The radio group
    has no name of its own either. Not fixed yet.
- 2026-11-25, follow-ups (author's answers; branch
  `fix/editor-spec-gaps`):
  - **Trackpad:** scrolling the display tabs sideways works with a real
    trackpad (*observed* by the author). Check 3 is complete.
  - **The arrow-key beeps** (check 3's open finding): dropped by the
    author, not pursued.
  - **Fixed to match the spec:** the name field carries the
    accessibility label "Name" (read back from the accessibility tree,
    *observed*); the trigger menu lists Clock Time, Dawn, Dusk, Always,
    as `[D-starts-row]` does (screenshot, *observed*). Debug build 63
    `1795667585641-33B38DA7`: unit tests 239 of 239, and the
    `PhaseEditorTests` and `FocusTests` UI tests 8 of 8 (94 s,
    *verified*).
  - *Left behind:* the image copy,
    `~/Library/Caches/PhasesUITests/Phases Editor Check Images` (deleting
    it was refused).
  - *Process note:* the spoken warnings before and after driving
    (`[D-hands-on-checks]`) were missed for the first clicks of this
    sitting and used from the key presses on.
- 2026-11-26, name row polish (branch `fix/editor-spec-gaps`; Claude
  measured screenshots of test copies, 2× pixels halved to points):
  - **Alignment:** the name's capitals sat 1.25 pt above the switch and
    the pencil's square 1.5 pt below the capitals. A first fix (a
    cap-height guide on the name, caa133e) moved nothing (*verified*,
    the author's screenshot). Putting the field on the sizing text's
    baseline and centering the pencil on its cap height brought all
    four (capitals, pencil, "On", switch) within 0.5 pt (*verified*).
  - **Pencil highlight:** `.accessoryBarAction` drew a gray box at rest
    that didn't change under the pointer; `.accessoryBar` shows nothing
    at rest and a highlight under the pointer (*verified*, screenshots
    with the pointer moved by `phases-drive move`).
  - **Gap:** the highlight started 17.5 pt after the name's last letter;
    5.5 pt nearly touched it; 9 pt settled (author asked to pull it in).
    While editing, the insertion point fits after the last letter
    (*observed*, a screenshot frame caught it).
  - **UI tests:** `nameEditsInPlace` first failed at launch, before any
    input, timing out on the test copy's menu bar item while the
    author's own copy was running. With it quit, it passed (*observed*;
    hypothesis: the author's copy's item crowded the menu bar,
    `[L-menubar-overflow]`, not tested). One rerun to read that error
    was started without the spoken warning (it failed at the same
    launch step, sending no input).
  - At 9 pt, `PhaseEditorTests` and `FocusTests` 8 of 8 (93.9 s,
    *verified*). An earlier run of the same build was stopped after the
    author heard a system beep and their own input may have landed in
    it; which step beeped wasn't found.
  - **8 pt and the mini switch** (author's choices): the highlight
    starts 8 pt after the last letter; the switch measures 35.5 × 15.5
    pt (was 53.5 × 23.5), its right edge unmoved, and "On" keeps its
    size and its 9.5 pt from the switch. The rows below sit back where
    they were before the highlight (the 0.5 pt drop is gone). All
    *verified* from screenshots. `PhaseEditorTests` and `FocusTests` 8
    of 8 (93.0 s, *verified*).
- 2026-11-26, System Settings pop-ups `[D-editor-popups]` (branch
  `fix/editor-spec-gaps`, commit `e2e4c7b`; Claude, with the author's
  go-ahead and spoken warnings):
  - Hands-on checks in test copies: the look at rest and under the
    pointer, a nine-click sweep across Change images, and its width
    with "minutes" chosen. All *verified*; details in EXPERIMENTS.md
    `[X-settings-popup-look]`. The author checked the Dawn and Dusk
    row's menus in the preview (*observed*).
  - The preview copy was still running when the run was due; the author
    quit it first, as `[L-menubar-overflow]` advises.
  - `PhaseEditorTests` and `FocusTests` 8 of 8 (94.5 s, *verified*),
    including `startsRowFollowsTheTrigger` and
    `rotationTurnsOffAndBackOn`, which choose items in the trigger,
    before / after / at, and Change images menus through the new
    control.
- 2026-11-26, the beep right after the window opens (Claude, with the
  author's go-ahead and spoken warnings; Debug build 63
  `1795709407449-AAE1B9E1`):
  - **Question:** the author heard a system beep at the start of a
    `PhaseEditorTests` / `FocusTests` run, just after the window opened
    from the menu bar (*observed*, author), the same beep that stopped
    the name row run above.
  - **Hypothesis:** `FocusTests.typingRightAfterOpenDoesNotRenameThePhase`
    presses X about 1 s after the window opens, with the sidebar
    focused; no phase starts with X, so the list's type-to-select finds
    no match and macOS beeps, as the author found by hand on 2026-11-04
    (EXPERIMENTS.md `[L-menubar-overflow]`).
  - **Run:** that test alone, twice (12:18:51, author away; 12:33:03).
    Both passed; "Focused on open" named the sidebar outline both times.
    On the second, the author heard the beep (*verified*, author).
  - **Answer:** the beep is the test's own X press reaching the sidebar,
    as the test intends. Not a failure; nothing changed. *Not checked:*
    that the beep in the earlier runs came from this test rather than
    another; it's the only step that presses an unmatched key right after
    the window opens.
  - *Option, not taken:* pressing the first letter of the starting
    phase's name instead of X would likely keep the selection and not
    beep (*recalled*, untested), and would still catch a focused Name
    field. Left for the author.
  - **Decided** (author, 2026-11-26): keep X and the beep; the test
    stays as it is.
