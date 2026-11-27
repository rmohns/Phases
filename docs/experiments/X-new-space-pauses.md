# `[X-new-space-pauses]` A new Space read as an outside change

Part of "Other investigations" in [EXPERIMENTS.md](../EXPERIMENTS.md), the index of
experiments. Moved here word for word from EXPERIMENTS.md on
2026-11-27, when each record got its own file.
The group's introduction there applies to this record too; copied
here so the record reads on its own:

> Until 2026-11-09 this section was called "Open questions"; most of what
> it held has since been answered. What's still open is under "Still
> open" at its end.


- **Question:** why does going full screen, or adding a desktop, pause
  Phases with the outside-change notice? (Issue #29.)
- **When, on what:** 2026-11-07, macOS 27.2; the author's observations
  and a read-only copy of the wallpaper store.
- **Branch:** none; read from the store and the code.
- **Outcome:** a new Space's store entries are copies, which the rule
  counted as picks; promoted to `[Q-new-space-copies-entry]`.
- **Findings:** `[L-new-space-pauses]`.

- `[L-new-space-pauses]` **Does a new Space read as an outside change?**
  (GitHub issue #29, macOS 27.2.) Promoted to `[Q-new-space-copies-entry]`
  (2026-11-07); the notes below stay as the record. Going full screen in any app pauses
  Phases with the outside-change notice (*observed* by the author in
  Fusion and Safari; screen resolution and menu bar hiding made no
  difference).
  - Hypothesis (Claude, 2026-11-07, from reading the code, not tested): a
    new Space gets new store entries, and `OutsideChangeRule.changes`
    counts any entry missing from the earlier reading as a pick, since
    only an existing entry's unmoved `LastSet` is skipped. Removed
    entries are never looked at, because the rule walks only the new
    reading's keys.
  - **New desktop from Mission Control (+) pauses Phases** (*observed* by
    the author, 2026-11-07). So it's any new Space, not full screen as
    such.
  - **Leaving full screen doesn't pause Phases** (*observed* by the
    author, 2026-11-07: started in full screen in Bitrig, resumed Phases,
    left full screen). The first explanation offered for this (entries
    removed, and the rule never reads removed entries) was wrong; see the
    store reading below.
  - **The store, read 2026-11-07 about 23:36 UTC** (copied, read only,
    by Claude with the author's go-ahead; *verified*):
    - **A new Space's entries are copies.** Spaces created at 23:28:36,
      23:28:37, and 23:32:02 each got a `default` entry and one for
      display `37D8832A`. Each carries the display's image and its
      `LastSet` of 13:30:02.893007, exactly as in `display/37D8832A`,
      which was Phases' last scheduled set. Only `LastUse` is the time
      the Space was made. macOS doesn't stamp a new `LastSet`.
    - So the rule sees keys missing from the earlier reading, with an
      image Phases didn't set in the last 10 seconds, and counts them.
      The `default` entry has no display, so every display pauses.
    - **Entries outlive their Spaces.** The store holds 381 Spaces,
      many last used in September and October. Leaving full screen
      doesn't pause Phases because no entry's `LastSet` moves; nothing
      is removed.
    - **Unexplained:** Space `2A1F37A9` got `IMG_0761.JPG` with `LastSet`
      23:31:54.7266 and `LastUse` 5 ms later, 1.5 s after Space
      `D37B581D` got `IMG_1971.JPG` (about when the author resumed
      Phases). Diagnostics were off (`PhasesDiagnostics = 0`), so there
      is no `phases-set` log to say whose sets these were.
  - Still open: whether a real pick on a never-picked Space stamps the
    current time in `LastSet` (expected, *hypothesis*), which the fix
    relies on.
