# Phases testing: Cover checks

Part of the testing docs. [TESTING.md](../TESTING.md) has the rules every
hands-on check follows (`[D-hands-on-checks]`: any check alone, who runs
it, proving the input landed), the unit tests, and what to do when a
fixed bug comes back. Moved here word for word from TESTING.md
"Hands-on checks" on 2026-11-27.

## Cover checks (draft 33)

- `[D-cover-checks]` **The persistent cover is checked by hand before it
  merges, and again after any change to `CrossfadeController`.** Frame
  timing and Space behavior are out of reach of the unit and Interface
  tests.

### When

- Before merging cover work, and after any change to
  `CrossfadeController`. Checks marked **(3)** are repeated on three
  displays, usually as their own sitting.

### Setup

- Ask first, naming the checks `[D-hands-on-checks]`. Techniques:
  TEST-TOOLS.md `[L-synthetic-clicks]`, `[L-twitch-measurement]`,
  `[L-settings-panes]`.
- Quit the installed Phases (two copies would both set the wallpaper),
  then launch a Release build fresh, with diagnostics on (`cover`
  category), Crossfade, and one display with three Spaces and no window
  covering the desktop.

### Reading results

- Each Space's wallpaper is read back by switching to it and asking
  `NSWorkspace.desktopImageURL(for:)`. Cover windows are listed with
  `CGWindowListCopyWindowInfo`: owner Phases, one level above the desktop
  picture.

### The checks

Each with what passes:

1. **Twitch (3):** five changes, each display recorded on its own.
   Frames before and after each fade's end match at noise level
   (about 40 dB or better). `[D-persistent-cover]`
2. **Menu bar (3):** text, and with "Show menu bar background"
   turned on for the test, the background restyle to each image at
   the end of its fade. A late restyle that a menu bar click fixes is
   macOS's own (`[L-menubar-lazy-restyle]`), not a failure. Put the
   setting back after. `[D-cover-opacity]`
3. **Own Space:** change on Space 1, then visit 2 and 3. Each keeps
   its own image; the log shows Space 1's cover removed on leaving;
   no frame changes at the removal or on returning.
   `[D-cover-per-space]`
4. **Leave mid-fade:** 3 s fade, ⌃→ about 0.3 s in, then again about
   1.5 s in. Space 2 never changes (no hard cut); the log shows the
   change held pending; back on Space 1 the log shows it set, and the
   read-back gives the new image there and the old one on Space 2.
   `[D-change-stays-on-its-space]`
5. **Fade ends during the swipe:** 1 s fade, ⌃→ about 0.5 s in, timed
   from the cover window appearing, not the click; at least ten trials
   where Spaces 1 and 2 had different images. Every trial ends with
   Space 1 showing the new image once you're back, set directly or on
   return. Space 2 hard-cutting to the new image now and then is
   macOS's own `[Q-set-target-decided-late]`, not a failure; the log
   should show the change pending again and set on return.
   `[D-reset-on-quick-return]`
6. **Pending dropped:** leave mid-fade as in 4, then set Transition to
   None; repeat, then Quit. Each time the log shows the covers
   removed, no cover windows remain, and Space 1 keeps its old image.
7. **No crossfades, no covers:** with Transition: None, and again
   with Reduce Motion on, changes apply at once and no cover windows
   exist. Turning Reduce Motion on with a cover up removes it.
   `[D-cover-only-for-crossfade]`
8. **Displays (3):** change one display's resolution: its cover is
   redrawn and fits (screenshot). Disconnect a display: the log shows
   its cover removed. Hide the Dock: no redraw in the log.
   `[D-cover-follows-displays]`
9. **Quit:** with restore on, a hard cut to the original and no cover
   windows left; with restore off, nothing visible. `[D-cover-pause-quit]`

### Afterward

- Reduce Motion and "Show menu bar background" as they were, Transition
  back to the author's setting, diagnostics back to the author's setting,
  the test build quit, and the installed Phases relaunched.

### Record

- Results as *Verified* notes, with date, on the decision each check
  covers in SPEC.md, and anything unexpected recorded in EXPERIMENTS.md
  with a digest line in LEARNINGS.md (until 2026-11-09: "anything
  unexpected in LEARNINGS.md").

### Why by hand

- The evidence is recordings, the log, and wallpapers read back per
  Space. None of it fits an automated test that wouldn't be flaky
  (author's standing approach for the twitch since draft 4).
