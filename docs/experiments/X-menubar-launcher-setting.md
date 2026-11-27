# `[X-menubar-launcher-setting]` Missing menu bar icon under Bitrig

Part of "Other investigations" in [EXPERIMENTS.md](../EXPERIMENTS.md), the index of
experiments. Moved here word for word from EXPERIMENTS.md on
2026-11-27, when each record got its own file.
The group's introduction there applies to this record too; copied
here so the record reads on its own:

> Until 2026-11-09 this section was called "Open questions"; most of what
> it held has since been answered. What's still open is under "Still
> open" at its end.


- **Question:** why did a Phases launched from Bitrig have no menu bar
  icon?
- **When, on what:** 2026-11-04, macOS 27.2.
- **Branch:** none.
- **Outcome:** Bitrig's own switch in System Settings → Menu Bar was off;
  a launched Phases follows it. Why is an untested hypothesis.
- **Findings:** `[L-menubar-launcher-setting]`.

- `[L-menubar-launcher-setting]` **A Phases launched by Bitrig follows
  Bitrig's own switch in System Settings → Menu Bar.**
  - **How it came up, 2026-11-04:** after the UI test runs, the build
    launched with Bitrig's Run button had no menu bar icon. The process
    was running, idle, and an accessory app (*verified*, `ps`,
    `sample`), and Accessibility reported no menu bar item for it at all
    (*verified*). The system log said nothing. Phases' own entry in
    Menu Bar settings was on.
  - **Cause (found by the author):** Bitrig's entry in that list was
    off. Turning it on made Phases' icon appear; toggling it shows and
    hides Phases' icon in step (*verified* by the author, repeated
    toggles).
  - **Why, hypothesis (author's, untested):** macOS charges a menu bar
    icon to the app that launched the process (its topmost parent), and
    the child inherits that app's setting. It fits how macOS attributes
    privacy permissions to a "responsible" app (*recalled*), but nothing
    here tested it.
  - **Apple's docs don't mention it** (searched 2026-11-04: the HIG's
    "Menu bar extras", `MenuBarExtra`, `NSStatusItem`). The HIG only
    says the system hides extras to make room, and that people can hide
    them.
  - **Not checked:** whether copies launched by the UI tests (`swift test`
    from Claude's shell inside Bitrig) follow the same switch. They had
    icons during today's runs, but when Bitrig's switch went off isn't
    known. Also unchecked: whether an installed copy opened from Finder
    is affected (it shouldn't be, if the hypothesis holds).
  - **If an icon is ever missing:** check the launching app's entry in
    Menu Bar settings, not just Phases'.
