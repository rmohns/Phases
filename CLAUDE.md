# Phases: project rules

- **Start of every conversation:** read SPEC.md first. It is the source of
  truth for what the app does and why (including design history).
- **Spec first, always.** Update SPEC.md before changing the app, commit it, then
  build. The build must meet the spec, not the other way around. If the code
  needs to differ from the spec, change the spec first and say so.
- Never install launch agents, daemons, or helpers without asking the user first.
- Launch at Login stays opt-in, with a confirmation before registering.
- Open SPEC.md for review with Marked: `/opt/homebrew/bin/mk SPEC.md`.
- **Design principle:** keep a clear separation between content and tools.
  Controls must never blend into the content behind them; don't follow
  Liquid Glass-style translucency where it costs legibility or findability.
- **Tagged decisions:** deliberate choices carry a `[D-…]` tag in SPEC.md and
  in a comment on the code that enforces them (see SPEC.md "Design
  decisions"). Before changing tagged code, re-read the decision; if the
  change contradicts it, say so and update the spec first. Tag new deliberate
  choices when adding them to the spec.
- **Platform quirks:** framework/OS quirks live in SPEC.md under the "Platform quirks" heading, each marked
  verified (with date) or recalled. Check there before blaming or working
  around SwiftUI/AppKit behavior, and add new quirks there when found.
- **No section numbers.** Refer to spec sections by `[D-…]` tag or by
  quoted section title, in the spec and in code comments; never "§4" or
  "section 4". Spec headings are unnumbered on purpose `[D-refs-by-id]`.
- **Spec draft number:** when bumping the draft in SPEC.md's title, bump
  `AppVersion.specDraft` too; a unit test enforces the match
  `[D-version-in-settings]`.
