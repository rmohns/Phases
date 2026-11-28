# Phases — Specification (draft 65)

A personal macOS menu bar app that changes the desktop wallpaper on a schedule.
Not intended for the App Store.

The spec (this file and the files in `docs/spec/`, listed in "The spec, by
area" below) says what Phases does and why. What macOS, SwiftUI, and AppKit do
to Phases, and how Phases routes around it, lives in **ERRATA.md**: platform
quirks, workaround mechanics, the design history behind them, diagnostic
procedures, and the regressions list. Sorting test: if a future macOS fixed
the bug, would the line still be true? Yes → here. No → ERRATA.md.

## Design decisions

Deliberate choices that would be easy to "fix" by accident are tagged in
this spec, e.g. `[D-sidebar-width]`. The code that enforces each one carries
the same tag in a comment. Search for `[D-` to list them all, in the spec and
in the code.

- The reasoning lives here, next to the tag, not in the code comment.
- Before changing tagged code, re-read its decision. If the change
  contradicts it, update the decision here first (with the new reason),
  then the code.
- When a decision is replaced, keep a short note of what it replaced and
  why, as the existing *Why* and design-history notes do.
- New deliberate choices get a tag when they're added to the spec.
- **Platform quirks** carry a `[Q-…]` tag in ERRATA.md. A decision whose
  implementation fights the platform says so in one line ("macOS fights
  this; see `[Q-…]`"), and its *How* lives in ERRATA.md. Code comments
  carry both tags where relevant, so one search finds spec, errata, and
  code.
- `[D-refs-by-id]` **Cross-references use a `[D-…]` or `[Q-…]` tag or a
  section title, never a section number,** in every file in `docs/` and in
  code comments. Sections aren't numbered, so adding one never breaks a
  reference. Prefer the tag when one covers the point; otherwise quote the
  section title, e.g. see "Persistence".
  - *Why:* drafts up to 22 numbered sections (§4a and so on) and cited
    them by number, which breaks whenever a section is added or moved
    (author's rule, 2026-10-28).
  - **Docs split across files** (from 2026-11-27): a reference that
    names SPEC.md and quotes a section title means the spec as a whole,
    SPEC.md and every file in `docs/spec/`; likewise `TESTING.md` with
    `docs/testing/` and `EXPERIMENTS.md` with `docs/experiments/`. So
    references written before a split stay right, and nothing has to be
    rewritten when a section moves between files. New references may
    name the file instead, e.g. `spec/window.md "Pause banner and
    Settings"`. Section titles stay unique within the spec, so a title
    names one place. `DocIndexTests` checks both `[D-doc-check]`.
    - *Why:* splitting the docs into smaller files (author, 2026-11-27)
      would otherwise break dozens of references, including ones in
      records that aren't rewritten.

## The spec, by area

The spec is this file plus one file per area in `docs/spec/` (split
2026-11-27, when it reached about 3,000 lines). Tags work across all of
them: search `docs/` for a tag to find its decision, or look it up in
[INDEX.md](INDEX.md) `[D-doc-check]`.

| File | Covers |
|---|---|
| [spec/schedule.md](spec/schedule.md) | Core model: phases plus rotation; Start triggers; Light and Dark Mode; Missed changes: sleep, wake, unlock; Location |
| [spec/image-library.md](spec/image-library.md) | Image library: sources, order, the grid |
| [spec/photos.md](spec/photos.md) | Photos albums |
| [spec/displays.md](spec/displays.md) | Displays: per-display images, display identity, sharing, display changes |
| [spec/transitions.md](spec/transitions.md) | Transitions; The persistent cover; A change, step by step |
| [spec/outside-change.md](spec/outside-change.md) | Wallpaper changed outside Phases |
| [spec/interface.md](spec/interface.md) | Interface; Icons; Menu bar menu; Dock icon and app menu |
| [spec/window.md](spec/window.md) | Phases window: sidebar, toolbar, pause banner, Settings |
| [spec/phase-editor.md](spec/phase-editor.md) | Phase editor |
| [spec/launch-and-quit.md](spec/launch-and-quit.md) | Launch at login: explicit consent only; Restore original wallpaper on quit |
| [spec/sandbox.md](spec/sandbox.md) | Sandbox: entitlements, what changes, settings move, hands-on checks |
| [spec/project.md](spec/project.md) | Project and bundle ID; Platform notes and limitations; Persistence; Memory |

## Out of scope (v1)

- Different schedules per weekday
- Online image sources other than Photos albums (draft 54)
- Smart albums as sources `[D-photos-sources]`
- Choosing different images per Space within a phase. Planned as a later
  enhancement (author, 2026-10-31); `[D-cover-per-space]` keeps the way
  open. Needs a way to tell Spaces apart, which the public API doesn't
  offer (*recalled*).
- Scaling/fill options (uses the current macOS fill setting)

## Known issues

- Unreproduced: the desktop once turned black. Source folder is local storage
  (not a cloud-synced folder). No change until it can be reproduced.
- Restoring an Aerial isn't supported yet (see `[D-aerials-untouched]`). Possible approach: back up
  and restore macOS's wallpaper store file and restart the wallpaper process.
  Undocumented, so it needs explicit approval before building.
- The menu bar blinks once at the end of each change, and sometimes doesn't
  restyle until the frontmost app changes. Both are macOS behavior that
  Phases can't fix; see `[Q-menubar-blank]` and
  `[Q-menubar-restyle-on-app-switch]` (FB25326597). macOS also sometimes
  leaves menu bar text the wrong color with no cover involved
  (LEARNINGS.md `[L-menubar-lazy-restyle]`).
- At logout, a twitch was seen just as the login window appeared
  (*observed* by the author with the experiment build, 2026-10-30,
  `[L-login-dims-wallpaper]`). Not checked on draft 32; may be macOS
  redrawing the wallpaper for the login window.

## The other docs

What lives outside the spec. How to choose the file for something new is
in CLAUDE.md's "Which file" rule.

- **ERRATA.md:** platform quirks and how Phases routes around them.
- **TESTING.md** with `docs/testing/`: how Phases is tested.
  **TEST-TOOLS.md:** the tools those tests use.
- **LEARNINGS.md:** findings that don't shape the code; their full
  records are in `docs/experiments/`, indexed in EXPERIMENTS.md.
- **INDEX.md:** every tag and where it's defined, generated by the unit
  tests `[D-doc-check]`.
- **HISTORY.md:** what each spec draft changed. Not a core doc: routine
  work doesn't need to read or update it. The author updates it from time
  to time, as he chooses (author, 2026-11-27).

### Platform quirks

Moved to ERRATA.md, each with a `[Q-…]` ID.

### Testing and diagnostics

Moved to TESTING.md: the unit and UI test layers, test-only launch
arguments, and diagnostic logging, with their `[D-…]` tags. Since
2026-11-09 the launch arguments, diagnostic logging, and the input
driver are in TEST-TOOLS.md; the test layers stay in TESTING.md.
