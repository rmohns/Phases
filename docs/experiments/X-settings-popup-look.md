# `[X-settings-popup-look]` Can the editor's pop-ups look like System Settings'?

Part of "Phase editor pop-up look" in [EXPERIMENTS.md](../EXPERIMENTS.md), the index of
experiments. Moved here word for word from EXPERIMENTS.md on
2026-11-27, when each record got its own file.


- **Question:** the author asked for the settings block's pop-up menus
  to look like System Settings' (the chevron in a circle, no box, a
  rounded box under the pointer), from two screenshots of its Sidebar
  icon size menu, at rest and under the pointer. Is there a standard
  SwiftUI style for it?
- **When, on what:** 2026-11-26, macOS 27.2, by Claude, at the author's
  request ("Let's give it a try"). Each try was a build of
  `fix/editor-spec-gaps` with uncommitted changes, shown in a test copy
  (`-PhasesUITestMode`) and screenshotted by window; the hover shot moved
  the pointer through `phases-drive move`, with spoken warnings.
- **Branch:** `fix/editor-spec-gaps` (trial changes not committed; the
  result landed there as `SettingsPopUp`).
- **Outcome:** no standard style outside a grouped `Form`; promoted to
  `[Q-settings-popup-look]`, shaping `[D-editor-popups]`. What landed is
  run 9's AppKit pop-up with run 10's resting chevron and run 12's width
  fix, not run 7's `Menu` (*correction* added 2026-11-26; this line
  first said only the first sentence, when run 7 was the plan).
- **Runs** (each *verified* by screenshot):
  1. `.buttonStyle(.borderless)` on the trigger picker: no box; a bare
     chevron, no circle.
  2. `.buttonStyle(.accessoryBar)` on Change images: the gray box, as by
     default.
  3. The Change images picker, unstyled, inside
     `Form { … }.formStyle(.grouped)` (360 × 70 pt): the System Settings
     look, the chevron in a circle. The first try (300 pt wide) cut the
     control off at the window's edge.
  4. A probe listing the window's `NSPopUpButton`s, logged through
     `Diagnostics.logger("trial")` (a file in the app's temporary folder
     wasn't found, so the logger was used): two, the trigger menu
     (`SwiftUIPopupButton`, bezel style 1, `isBordered` false) and the
     sidebar's ⋯ pull-down. The picker inside the `Form` wasn't one, so
     SwiftUI draws that look itself; no AppKit setting reproduces it.
     - *Correction* (Claude, 2026-11-26): "no AppKit setting reproduces
       it" went too far. Run 9 found AppKit settings that draw the
       hover state; only the resting chevron is missing.
  5. `.buttonStyle(.glass)`: the gray box. `.buttonStyle(.plain)`: the
     text alone, nothing marking a menu. A picker in its own small
     grouped `Form`, with `.listRowBackground(Color.clear)`,
     `.listRowInsets(EdgeInsets())`, `.scrollContentBackground(.hidden)`
     and `.scrollDisabled(true)`: the row's box and margins still drew,
     and the control was clipped.
  6. A custom `ButtonStyle` (the look drawn in `makeBody`) on the menu
     picker: ignored; the gray box drew.
  7. A `Menu` with `.menuStyle(.button)`, `.buttonStyle(.plain)` and
     `.menuIndicator(.hidden)`, its label the text and a chevron in a
     20 pt circle, holding an inline `Picker` of the choices; the hover
     box drawn behind it with `.onHover`. At rest it matched the
     screenshots; under the pointer the box was 23 pt tall (46 px) and
     the circle went away. Kept.
     - *Correction* (Claude, 2026-11-26): "Kept" didn't last. The
       author's screen recording of the preview (21 s, read as frames
       at 2 per second) showed clicks between the text and the chevron,
       on the chevron, and in the box's margins doing nothing (the
       click circle, no menu), while clicks on the text opened it, and
       the menu opening below the control like a pull-down. The author
       ruled both out: "It should act like the old pop-up, and look like
       Mac System Settings", and suggested searching for a solution
       already found to work. *Hypothesis* for the dead zones: the
       hover box and its margins were drawn outside the `Menu`, and a
       plain-style label takes clicks only where it draws something.
  8. **Search** (web and Apple's documentation): Apple Developer Forums
     thread 788097, "Draw SwiftUI.Form style pop-up button with
     NSPopUpButton in AppKit" (June–September 2025), asks for exactly
     this. Its author found only a private API (`semanticContext`) and
     filed FB18401945. A reply (not from Apple) suggested
     `bezelStyle = .flexiblePush` and
     `showsBorderOnlyWhileMouseInside = true`; a later reply said that
     on macOS 26 the arrows no longer draw until the pointer is over the
     button, and come back with `UIDesignRequiresCompatibility` set to
     YES in Info.plist (*recalled* there, not tried here). Nobody
     confirmed the settings worked.
  9. An `NSPopUpButton` in an `NSViewRepresentable`, with those two
     settings, on Change images: under the pointer, System Settings' box
     and chevron exactly; at rest, the text alone with no chevron.
  10. The same, plus a SwiftUI overlay at the trailing edge: the chevron
      (`chevron.up.chevron.down`) in a 20 pt `.fill.tertiary` circle,
      `.allowsHitTesting(false)`, hidden while `.onHover` reports the
      pointer inside. At 9 pt bold the chevron was 9 px wide and 18 px
      tall, against AppKit's 11 × 21 px, and its center sat 1 px left;
      at 11 pt semibold with 3.5 pt trailing padding its top arm
      covered the same pixels as AppKit's (1007–1017 in the crop), and
      it was 1 px taller. Kept. The circle matched System Settings'
      size and color (40 px, 0.92).
  11. **Click sweep** on Change images: nine clicks at 2, 10, 25, 50,
      70, 80, 86, 92 and 98% across the 213 pt control, each followed by
      reading the open menu through AX, then a second click at the same
      point. All nine opened the menu, each with "Only when the phase
      starts" checked at y 288, the control's own y, and the second
      click picked it and closed the menu.
  12. Width: choosing "minutes" left the control 213 pt wide, its text
      far from its chevron. An `NSPopUpButton` subclass whose
      `intrinsicContentSize` takes off the difference between the
      widest item's title and the selected one's (measured with the
      button's font), invalidated on each update: 96 pt for "minutes",
      the menu still opening with "minutes" checked over the control,
      the hover box fitting the narrower control.
  13. The trigger menu (items with SF Symbols) at rest and under the
      pointer: the symbol, title and chevron as on Change images.
- **The author's check** of the preview, 2026-11-26: "I am very happy
  with the current state, and checked the dawn/dusk row and their
  variations. It all looks great!" (*observed* by the author; the
  minutes / hours and before / after / at menus weren't screenshotted
  by Claude).
- **Measurements of the author's screenshots** (2× pixels, light mode):
  the circle 40 px (20 pt) across, 26 px after the text's last ink; the
  hover box 192 × 46 px, from 26 px before the text's first ink to 7 px
  past where the circle was, its corners about 12 px (6 pt) in radius;
  the box and circle both luminance 0.92 on a 0.98 background. In
  Phases' editor box the background is 0.96 and `.fill.tertiary` came
  out 0.92, the same as System Settings'.
- **Options put to the author:** a custom look (chosen), rebuilding
  the settings block as a grouped `Form` (set aside: the editor scrolls
  as one page under a pinned header), or `.borderless`. After run 7
  failed, the author asked that it act like the old pop-up and accepted
  that a later macOS may need another look (2026-11-26).
