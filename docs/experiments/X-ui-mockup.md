# `[X-ui-mockup]` Interface mockup

Part of "UI mockup (issues #2, #3, #26, #27)" in [EXPERIMENTS.md](../EXPERIMENTS.md), the index of
experiments. Moved here word for word from EXPERIMENTS.md on
2026-11-27, when each record got its own file.
The group's introduction there applies to this record too; copied
here so the record reads on its own:

> An interface-only mockup, archived as tag `archive/experiment/ui-mockup`:
> mock views with throwaway state, nothing wired to the model, and a
> scheduler made read-only so it could run beside a real Phases.


- **Question:** do older Mac layout conventions, a split phase editor,
  and per-display tabs make the window better? (Issues #2, #3, #26, #27.)
- **When, on what:** 2026-11-08 to 2026-11-09, macOS 27.2.
- **Branch:** `experiment/ui-mockup`, tag `archive/experiment/ui-mockup`.
- **Outcome:** the old-style layout was dropped; streamlining continues
  with modern macOS conventions (author, 2026-11-09).
- **Findings:** `[L-classic-mac-layout]`, `[L-toolbar-items-crash]`,
  `[L-mock-known-displays]`.

- `[L-classic-mac-layout]` **Old-style Mac layouts were tried and
  dropped.** The mockup used a columns form (right-aligned labels),
  checkboxes instead of switches, and popups instead of segmented
  controls. It also split the phase editor (a short settings block over
  a grid that scrolls on its own), added display tabs drawn in each
  display's shape, and put tinted plates behind selected images with no
  file names. The author concluded that the old-school layout wasn't as
  good an idea as it seemed, and the streamlining continues with modern
  macOS conventions instead (author, 2026-11-09). The other ideas weren't
  judged on their own; they're in the tag if wanted.
- `[L-toolbar-items-crash]` **SwiftUI toolbar items crashed the window
  on open.** Two buttons in a `ToolbarItemGroup(placement:
  .primaryAction)` on the detail view: choosing Open Phases… raised an
  uncaught `NSRangeException` inside `-[NSWindow layoutIfNeeded]` while
  the window was ordering front (`_setUpFirstResponderBeforeBecomingVisible`
  → `updateConstraintsIfNeeded`). The reason text is redacted in the log,
  and no frame in the stack names the thrower. With the `.toolbar`
  modifiers removed and nothing else changed, the window opened.
  *Observed* 2026-11-08 by Claude, one launch each way. Hypothesis, not
  tested: it collides with `WindowLayoutConfigurator`, which installs
  its own `NSToolbar` when SwiftUI has none `[Q-no-items-no-toolbar]`
  and adjusts the split view items after. Toolbar buttons need this
  solved first.
- `[L-mock-known-displays]` **The known-displays list grows without
  bound.** On the author's Mac a tab per known display showed six:
  Built-in, Virtual 16:10, and four not connected (Cinema HD, LG
  Ultrawide, and two with empty names). Disconnected displays have no
  frame to measure, so the mockup drew them 16:10, wrong for the LG
  Ultrawide. Showing a disconnected display only when the phase gives it
  its own images cut the list to the connected ones. *Observed*
  2026-11-08 (window screenshots).
