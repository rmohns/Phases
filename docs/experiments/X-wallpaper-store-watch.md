# `[X-wallpaper-store-watch]` Hearing outside wallpaper changes

Part of "Other investigations" in [EXPERIMENTS.md](../EXPERIMENTS.md), the index of
experiments. Moved here word for word from EXPERIMENTS.md on
2026-11-27, when each record got its own file.
The group's introduction there applies to this record too; copied
here so the record reads on its own:

> Until 2026-11-09 this section was called "Open questions"; most of what
> it held has since been answered. What's still open is under "Still
> open" at its end.


- **Question:** can Phases hear a wallpaper change made in System
  Settings by watching macOS's wallpaper store? (Issue #5.)
- **When, on what:** 2026-11-06, macOS 27.2, one display, Debug build
  `ebe00f8`.
- **Branch:** `experiment/wallpaper-store-watch`; no `archive/…` tag
  exists for it, and the branch is gone (checked 2026-11-09).
- **Outcome:** yes; promoted to `[Q-wallpaper-store]`. Two displays
  untested.
- **Findings:** `[L-store-watch]`.

- `[L-store-watch]` **Can Phases hear a wallpaper change made in System
  Settings by watching macOS's wallpaper store?** (Issue #5, macOS 27.2.)
  Promoted to `[Q-wallpaper-store]` (2026-11-06); the notes below stay as
  the record, and two displays is still untested. Experiment on branch `experiment/wallpaper-store-watch`, started
  2026-11-06. Agreed behavior if it works (author, 2026-11-06): an outside
  change pauses all of Phases; how to tell the user is undecided.
  - Setup: `WallpaperStoreWatcher` watches
    `~/Library/Application Support/com.apple.wallpaper/Store/` (folder,
    for atomic replaces) and `Index.plist` in it (in-place writes,
    reopened after a replace), with `DispatchSource` file-system sources,
    no polling. On each event it logs the flags, every store Desktop entry
    that changed (provider, image file, LastSet, LastUse), and each
    screen's `desktopImageURL`. `WallpaperSetter` logs `phases-set` just
    before each of Phases' own sets. Diagnostics category `store`; runs
    only with diagnostics on. Logs only, changes nothing.
  - Questions: (1) does picking a picture in System Settings fire an
    event, and how soon; (2) do Phases' own sets fire one too (likely,
    *hypothesis*), and can they be told apart from outside ones; (3) do
    Space switches fire one (LastUse may change); (4) is the file
    replaced or written in place; (5) choosing an Aerial or dynamic
    wallpaper: what changes.
  - Hypothesis (*recalled*, not tested): System Settings writes
    Index.plist when a picture is chosen.
  - **Results, one display, Debug build `ebe00f8`** (2026-11-06, read
    from the `store` log by Claude; picks made by the author; *verified*):
    - **(1) Yes.** Picks at 08:17:51 and 08:29:38 each fired a folder
      event within about 0.3 s. The display's Desktop entry got a new
      image and a new `LastSet`, with no `phases-set` line before it.
    - **(2) Yes, Phases' own sets fire one too,** about 0.25 s after the
      `phases-set` line, with the same shape (new image, new `LastSet`).
      Five of five.
    - **(4) Replaced, not written in place:** every change is a folder
      `write` plus a `delete` on the old file. Watching the folder is
      what works; the file watch only sees the old copy go.
    - **Opening and quitting System Settings** (pane opened at 08:23:30
      and 08:29:36, quit at 08:23:38 and 08:29:42) each write the store
      twice in a row, changing only `LastUse`. So "the store changed"
      isn't an outside change by itself; a new `LastSet` with an image
      Phases didn't just set is.
    - **Phases overrode both picks** at its next change: 9 s later
      (08:18:00) and 23 s later (08:30:02). The current behavior issue #5
      describes.
    - **(5) Aerials** (2026-11-06, Golden Gate Sunset picked at 09:06:23
      with `phases-drive click`, confirmed by screenshot; *verified* from
      the log by Claude): a folder event within about 1 s, and the
      current Space's entry got a new `LastSet`, so the detection rule
      catches it. The entry reads provider `default` with no file URL,
      and `desktopImageURL` reports `DefaultDesktop.heic`: only the store
      says what was picked. Phases didn't override it in 105 s
      (*observed*; its next scheduled change may simply not have come).
      Picking the canyon still back at 09:08:12 looked like any other
      pick.
    - **Spaces keep their own entries** (*verified*, same log): picks
      changed only `space/D37B581D/…`; `space/272B14E4/…` kept its image.
      So the rule has to read the current Space's entry.
    - **(3) Space switch, first try failed** (09:08:24, Claude): System
      Settings still had focus, so `phases-drive key right control`
      moved its thumbnail selection and set the next photo (Ergo Proxy),
      on this Space only. No switch happened. Whether synthetic
      Control+arrow reaches Mission Control at all is untested. Next try:
      quit System Settings and focus the desktop first.
    - **(3) Second try, also no switch** (09:10:44, Claude): System
      Settings quit, a `phases-drive click` on bare desktop made Finder
      frontmost, then `key right control`. The click itself set off
      "Click wallpaper to reveal desktop" (all windows pushed to the
      edges; the author named it), which looked like a switch in the
      screenshot. But the wallpaper stayed this Space's Ergo Proxy and
      the store logged nothing after the keypress (*verified*). So
      synthetic Control+Right didn't reach Mission Control (*observed*,
      one clean try). To focus the desktop, use `osascript -e 'tell app
      "Finder" to activate'`, never a wallpaper click. Space switches
      are left to the author's hands.
    - **(3) Space switches are noise** (2026-11-06; the author switched
      by hand at 09:11:24 and back at 09:11:35, the other Space showing
      the canyon; *verified* from the log by Claude): each switch wrote
      the store twice about 1 s apart, changing only `LastUse` on both
      Spaces' entries, never `LastSet`. The rule holds. But
      `desktopImageURL` reported Ergo Proxy (this Space's image) through
      all four events, including while the canyon Space was showing
      (*observed*; it may lag the switch, or not follow Spaces). Another
      reason to read the store, not `NSWorkspace`.
    - Still open: two displays.
  - **Driving System Settings failed** (2026-11-06, Claude). An AX press
    on a "Your Photos" thumbnail returned without error and did nothing.
    CGEvent clicks from a one-off helper (`/tmp`, same calls as
    `SyntheticInput`) didn't move the pointer (author watching). The
    helper passed `AXIsProcessTrusted` and `CGPreflightPostEventAccess`,
    and the shell can write outside the project, so a file sandbox isn't
    it. Cause unknown; earlier CGEvent clicks worked
    (`[L-synthetic-clicks]`).
    - *Follow-up* (2026-11-06, about 08:33): a move-only version of the
      same helper, and `SyntheticInput.move` run from `swift test`, both
      read back on target, but the author saw no pointer move either time
      (*observed*). Only one display was connected.
    - *Follow-up* (about 08:40): `phases-drive move` (same
      `SyntheticInput`) moved the pointer twice; the author saw both, and
      `screencapture -C` showed it at each target (*verified*). Why the
      08:33 moves didn't show is still unknown. Driving now goes through
      `phases-drive` (TESTING.md `[D-input-driver]`, `[D-input-lands]`).
    - *Follow-up* (09:06): `phases-drive click` on a System Settings
      thumbnail worked twice, confirmed by screenshot and the store log
      (*verified*). The author didn't notice the first change; the
      screenshot is the proof `[D-input-lands]` asks for.
