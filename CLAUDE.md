# Phases: project rules

- **Start of every conversation:** read `docs/SPEC.md` and `docs/ERRATA.md`
  first. Both live in `docs/`, along with README images (`docs/images/`).
  SPEC.md is the source of truth for what the app does and why. ERRATA.md
  holds what macOS/SwiftUI/AppKit do to Phases and how it routes around
  them: platform quirks, workaround mechanics, design history, diagnostic
  procedures, and the regressions list.
- **Which file:** if a future macOS fixed the bug, would the line still be
  true? Yes → SPEC.md. No → ERRATA.md.
- **Spec first, always.** SPEC.md changes are approved by the user before
  any code is written, then land in the same commit as the code. The build
  must meet the spec, not the other way around. If the code needs to differ
  from the spec, change the spec first and say so.
- **One branch per change, squash-merged.** Start each change on its own
  branch: the spec edit goes first (open it in Marked for review), then
  code and ERRATA notes follow on the same branch. Squash-merge into `main`
  so each change lands as one commit with spec, code, and errata together.
  Verification notes found after a merge ride along with the next change's
  commit instead of getting their own. A squash merge counts as merging
  into `main`: build right after it.
- Never install launch agents, daemons, or helpers without asking the user first.
- Launch at Login stays opt-in, with a confirmation before registering.
- Open the specs for review with Marked: `/opt/homebrew/bin/mk docs/SPEC.md`
  and `/opt/homebrew/bin/mk docs/ERRATA.md`.
- **Design principle:** keep a clear separation between content and tools.
  Controls must never blend into the content behind them; don't follow
  Liquid Glass-style translucency where it costs legibility or findability.
- **Tagged decisions:** deliberate choices carry a `[D-…]` tag in SPEC.md and
  in a comment on the code that enforces them (see SPEC.md "Design
  decisions"). Before changing tagged code, re-read the decision; if the
  change contradicts it, say so and update the spec first. Tag new deliberate
  choices when adding them to the spec.
- **Platform quirks:** framework/OS quirks live in ERRATA.md, each with a
  stable `[Q-…]` ID, marked verified (with date) or recalled, and citing
  the `[D-…]` decisions it shapes. Check there before blaming or working
  around SwiftUI/AppKit behavior. Add new quirks there with a new `[Q-…]`
  ID; the affected decision in SPEC.md gets one line: "macOS fights this;
  see `[Q-…]`." Code comments carry both tags where relevant.
- **No section numbers.** Refer to sections by `[D-…]` or `[Q-…]` tag or
  by quoted section title, in both files and in code comments; never "§4"
  or "section 4". Headings are unnumbered on purpose `[D-refs-by-id]`.
- **Spec draft number:** when bumping the draft in SPEC.md's title, bump
  `AppVersion.specDraft` too; a unit test enforces the match
  `[D-version-in-settings]`.
- **Every regression gets a guard.** When a fix for a regression lands,
  its branch also adds (a) a row to ERRATA.md "Regressions found so far"
  and (b) a test that fails without the fix: a UI test, a unit test, or a
  geometry or screenshot check, named in the row's "Guarded by" column.
  Show the test failing against the broken code once (revert the fix
  locally) before trusting it. If no test is practical, "Guarded by" says
  why (for example, frame timing) and names the manual procedure; a bare
  "Nothing yet" isn't allowed. A regression fix doesn't merge without one
  or the other. UI test runs drive the mouse and keyboard, so ask before
  each run (see SPEC.md "Layer 2: UI tests").
- **Diagnostics:** logging is built in and off by default
  `[D-diagnostics-switch]` (SPEC.md "Diagnostics"). Add log lines with
  `Diagnostics.logger(…)`; never write new logging infrastructure.
