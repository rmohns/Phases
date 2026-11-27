# `[X-set-target-read]` Which Space a set reaches during a swipe

Part of "Wallpaper, covers, and the menu bar" in [EXPERIMENTS.md](../EXPERIMENTS.md), the index of
experiments. Moved here word for word from EXPERIMENTS.md on
2026-11-27, when each record got its own file.
The group's introduction there applies to this record too; copied
here so the record reads on its own:

> Source for this section unless noted: the persistent-cover experiment,
> 2026-10-30, macOS 27.2, one built-in display (3024 × 1964); branch
> `spike/persistent-cover` (tag `archive/spike/persistent-cover`),
> `docs/X-PERSISTENT-COVER.md`. A "cover" is a
> borderless, click-through window just above the desktop picture
> `[D-cover-level]`.


- **Question:** when the user swipes to another Space mid-change, can
  Phases tell which Space its wallpaper set will land on?
- **When, on what:** 2026-11-03, macOS 27.2, Release builds, one display
  with two Spaces; trials with a 1 s fade and ⌃→ 0.3–0.5 s after the
  cover appeared.
- **Branch:** `spike/set-target-read` (`f05ebef`), tag
  `archive/spike/set-target-read`; later trials on draft 33's build
  `3c891b6`.
- **Outcome:** no check at the moment of the set can be trusted; the race
  is `[Q-set-target-decided-late]`, handled by `[D-reset-on-quick-return]`.
- **Findings:** `[L-swipe-set-read]`, `[L-misfire-not-seen]`,
  `[L-swipe-before-cover]`; promoted: `[L-swipe-set-race]`.

- `[L-swipe-set-race]` Promoted to `[Q-set-target-decided-late]` (2026-11-03).
- `[L-swipe-set-read]` **Reading the wallpaper just before a set doesn't
  predict which Space the set reaches.** Hypothesis: if
  `desktopImageURL(for:)` still returns the departing Space's image, the
  set goes there too, so a mismatch could hold the change as pending.
  *Falsified* 2026-11-03: branch `spike/set-target-read` (`f05ebef`; tag
  `archive/spike/set-target-read`) logged
  the read just before each set; 16 trials as in `[Q-set-target-decided-late]`
  (1 s fade, ⌃→ 0.3–0.45 s after the cover appeared), Release build,
  macOS 27.2.
  - **Trial h10, decisive:** Space 1 had Angelie, Space 2 Tokyo. The read
    returned Angelie (Space 1's) with `isOnActiveSpace` true, the set
    went out 0.48 s after the key press, and the new image (Misty Rocks)
    landed on Space 2; Space 1 kept Angelie.
  - **Trial h2:** a second misfire, uninformative for the read (both
    Spaces had Angelie).
  - **The other 11 informative trials** landed on Space 1, with sets
    from 0.1 s before to 0.4 s after the key press.
  - **Likely reason** (*inference*): the set call returns at once and
    macOS's wallpaper agent picks the target Space when it handles it,
    later. So no check made at the moment of the set can be trusted.
  - Misfire rate across both sittings: 3 in 19 informative trials.
- `[L-misfire-not-seen]` **With `[D-reset-on-quick-return]` in, the
  misfire didn't happen in 24 informative trials** (build `3c891b6`,
  same setup and timings as `[L-swipe-set-read]`, swipe 0.3–0.5 s after
  the cover appeared). Before, it hit 3 of 19. By chance alone, 0 in 24
  at that rate is about 2% (*calculation*). The change shouldn't affect
  where a set lands: Space 2 is read 6 s after the swipe, before the
  return. Unexplained; what differs between sittings isn't known.
  *Measured* 2026-11-03.
- `[L-swipe-before-cover]` **A swipe that starts before the cover appears
  takes the change with it.** Change Now's cover appeared 0.6–1.15 s
  after the menu click (the image decode). Twice, ⌃→ sent 0.3–0.4 s after
  the click put the new cover on Space 2: it was later removed on leaving
  Space 2, and the wallpaper set landed there, while Space 1 kept its
  image. *Observed* 2026-11-03, two runs, both with Space 2's own image
  picked, so nothing visible changed. With different images, Space 2
  would fade to the change made on Space 1. Bears on the spec's "a
  change only starts on the Space showing".
