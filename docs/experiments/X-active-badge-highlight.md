# `[X-active-badge-highlight]` The Active badge on the selection highlight

Part of "Sidebar rows" in [EXPERIMENTS.md](../EXPERIMENTS.md), the index of
experiments. Moved here word for word from EXPERIMENTS.md on
2026-11-27, when each record got its own file.
The group's introduction there applies to this record too; copied
here so the record reads on its own:

> Source for this section: the issue #22 experiment, 2026-11-06, macOS
> 27.2, branch `experiment/active-badge-highlight` (commit 204231c), run by
> Claude with the author's yes. Highlight Color was blue. Each run
> relaunched Phases with a launch switch choosing the variant, selected
> the active phase (Nighttime) by clicking Dusk and pressing Down, and
> took window screenshots with the window in front and behind Finder.


- **Question:** how can the sidebar's accent-coloured Active badge stay
  readable on the accent-coloured selection highlight? (Issue #22.)
- **When, on what:** 2026-11-06, macOS 27.2, blue Highlight Color, six
  runs with window screenshots.
- **Branch:** `experiment/active-badge-highlight`, tag
  `archive/experiment/active-badge-highlight` (archived 2026-11-09).
- **Outcome:** the row is told it's selected and whether the sidebar
  has focus; promoted to `[Q-tint-on-highlight]`.
- **Findings:** `[L-row-styles-on-highlight]`, `[L-row-own-selection]`;
  promoted: `[L-tint-on-highlight]`, `[L-background-prominence-mac-list]`,
  `[L-row-selection-focus]`.

- `[L-tint-on-highlight]` Promoted to `[Q-tint-on-highlight]` (2026-11-06).
- `[L-background-prominence-mac-list]` Promoted to `[Q-tint-on-highlight]` (2026-11-06).
- `[L-row-styles-on-highlight]` **What does adapt on the highlight.**
  *Verified* (screenshots):
  - Hierarchical styles (`.primary`, `.secondary`) and a symbol with no
    style of its own turn white or near white on the highlight, and
    grey otherwise (run 4's triangle, the trigger line).
  - The row's leading `Label` icon is accent-coloured normally and white
    on the highlight, with no code of ours doing it.
  - A `.multicolor` `exclamationmark.triangle.fill` is yellow with a
    dark mark and stays yellow on the highlight (run 3). Readable on
    blue, not adaptive.
  - An explicit `.orange` stays orange (runs 1–2), so it would vanish
    on an orange highlight (*hypothesis*, not run).
- `[L-row-own-selection]` **Telling the row it's selected works, but the
  accent highlight also needs the sidebar to have focus.** Run 5
  (commit b880f57): `PhaseRow` gets `isSelected` from the sidebar's
  `selection` and reads `appearsActive`; the badge is `.primary` when
  both are true, `.tint` otherwise. *Verified* (screenshots, log):
  - Selected, window in front, sidebar focused: blue highlight, badge
    white and readable. The log showed `isSelected` and `appearsActive`
    following the clicks and the switch to Finder.
  - Selected, window in front, focus moved to the editor (clicked the
    Name field): the highlight turned **grey**, like a background window,
    but the badge stayed white, since both flags were still true.
    Readable, but it doesn't match the background-window look (accent
    badge on grey).
  - Window behind Finder: grey highlight, accent badge.
  - So the accent highlight follows "selected, window in front, and the
    sidebar has focus" (*verified* for these three cases). Adding the
    window's existing `sidebarFocused` to the condition should match all
    three (*hypothesis*, not run). Confirmed by run 6, below.
- `[L-row-selection-focus]` Promoted to `[Q-tint-on-highlight]` (2026-11-06). Run 6 (commit 7693bb0): sidebar focused, blue highlight and white badge; focus in the Name field, grey and accent; back on the row, blue and white; window behind Finder, grey and accent.
