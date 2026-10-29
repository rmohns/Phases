# Phases: project rules

- **Start of every conversation:** read `docs/SPEC.md` and `docs/ERRATA.md`
  first. Both live in `docs/`, along with README images (`docs/images/`).
  SPEC.md is the source of truth for what the app does and why. ERRATA.md
  holds what macOS/SwiftUI/AppKit do to Phases and how it routes around
  them: platform quirks, workaround mechanics, design history, diagnostic
  procedures, and the regressions list.
- **Which file:** if a future macOS fixed the bug, would the line still be
  true? Yes → SPEC.md. No → ERRATA.md.
- **Spec first, always.** Update SPEC.md before changing the app, commit it, then
  build. The build must meet the spec, not the other way around. If the code
  needs to differ from the spec, change the spec first and say so.
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
- **Diagnostics:** logging is built in and off by default
  `[D-diagnostics-switch]` (SPEC.md "Diagnostics"). Add log lines with
  `Diagnostics.logger(…)`; never write new logging infrastructure.
