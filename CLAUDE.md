# Phases: project rules

- **Spec first, always.** Update SPEC.md before changing the app, commit it, then
  build. The build must meet the spec, not the other way around. If the code
  needs to differ from the spec, change the spec first and say so.
- Never install launch agents, daemons, or helpers without asking the user first.
- Launch at Login stays opt-in, with a confirmation before registering.
- Open SPEC.md for review with Marked: `/opt/homebrew/bin/mk SPEC.md`.
