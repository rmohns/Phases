# Phases testing: Photos checks

Part of the testing docs. [TESTING.md](../TESTING.md) has the rules every
hands-on check follows (`[D-hands-on-checks]`: any check alone, who runs
it, proving the input landed), the unit tests, and what to do when a
fixed bug comes back. Moved here word for word from TESTING.md
"Hands-on checks" on 2026-11-27.

## Photos checks (draft 54)

- `[D-photos-checks]` **Real Photos behavior is checked by hand before
  merge #2 merges,** and after any change to the Photos source or the
  photo cache. The fake library `[D-fake-photos]` can't show what
  PhotoKit, iCloud, and the wallpaper do. Ask first, naming the checks;
  some change the real wallpaper and need the author at the Mac.
- **Start the build with `open`, not Bitrig's Run:** quit Phases, then
  `open "<the build's folder>/Phases.app"` in Terminal (or open it from
  Finder). Started by Bitrig's Run, the build reads Photos access as
  refused and never asks, whatever System Settings says; started with
  `open`, it asks and works (*verified* by the author, 2026-11-26;
  `[L-photos-bitrig-vs-installed]`). Approved by the author 2026-11-26.
- **The checks**, on the author's library:
  1. **Permission:** a fresh build, Add Photos Album… shows the prompt;
     Don't Allow shows the sheet's message and every Photos row "Can't
     open"; allowing it in System Settings brings them back.
  2. **Adding:** an album, a folder of albums (headings per album), a
     shared album; an album already added selects its row.
  3. **In order:** an album sorted by hand rotates in its Photos order.
  4. **iCloud-only photo:** shows on time at a scheduled change (fetched
     ahead), and with Change Now (late by the download).
  5. **Offline:** Wi-Fi off, a scheduled change falls back to a photo on
     hand, or keeps the wallpaper if none is.
  6. **Edited photo, Live Photo, HEIC, RAW:** each shows as it looks in
     Photos. Phase 0 tested none of these.
  7. **Album changes:** adding, removing, and reordering photos in Photos
     updates the grid while Phases runs; deleting the album shows "Can't
     open"; a deleted photo shows as missing.
  8. **Cache:** the file path of a showing photo is under Application
     Support; it survives a change on another Space and a relaunch;
     Restore original wallpaper on quit puts back the original.
  9. **Outside change:** picking a wallpaper in System Settings while a
     photo shows still pauses Phases, and Phases' own photo changes
     don't `[D-outside-change-rule]`.
- Record results with date and build in this section, as the other
  checks do.
- *Verified* 2026-11-12 by the author, builds from 16:44 to 22:26 local
  on `feature/33-photos-albums` (draft 53 there, before the move to 54),
  Claude reading the diagnostics log: **all nine pass.** Notes, with the
  records in EXPERIMENTS.md `[X-33-photos-checks]`:
  - 1: a grant made in System Settings reached Phases only after a
    relaunch `[L-photos-grant-needs-relaunch]`; each new build needs the
    grant again `[L-photos-grant-per-build]`.
  - 4: on time when fetched ahead; about 1 s late with Change Now.
  - 5: fell back, but kept landing on the same photo
    `[L-photos-offline-check]`. Draft 54 skips what's showing; not yet
    checked by hand.
  - 7: passed after a fix for a photo from a just-deleted album being
    shown `[L-photos-deleted-album-race]`.
  - 9: a System Settings pick paused Phases; after resuming, two of its
    own photo changes didn't.
  - The checks ran before the merge with draft 53's In order
    `[D-in-order-remembers]`, which changed how fetching ahead picks.
    Check 4 is worth repeating on the merged build.
- *Verified* 2026-11-13 by the author, on screen, and by Claude from the
  diagnostics log, draft 54 build (`87ef762`, merged with `main`):
  checks 4 and 5 again. 4: fetched ahead 30 s early (0.39 s) and set on
  the minute; Change Now fetched in 0.91 s and showed about 1 s late.
  5: offline, each failed photo fell back to a cached one, alternating
  between the two on hand instead of repeating
  `[L-photos-offline-check]`. The UI suite passed 29 of 29 (247 s) on
  the same build.
