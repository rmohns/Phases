# `[X-33-photokit]` Photos library from a not-sandboxed Phases (round A)

Part of "Photos library (issue #33)" in [EXPERIMENTS.md](../EXPERIMENTS.md), the index of
experiments. Moved here word for word from EXPERIMENTS.md on
2026-11-27, when each record got its own file.


- **Question:** not recorded as one question. This is Phase 0 of the issue
  #33 plan (`docs/PLAN-GITHUB-ISSUE-33.md`, now in tag
  `archive/feature/33-photos-albums`), round A, not sandboxed.
- **When, on what:** 2026-11-12, macOS 27.2; the author's library with
  "Optimize Mac Storage" on, album "NIN 2013" (61 images, 63 items); probe
  build cdhash `9808ae12`. Run by Claude with the author's yes.
- **Branch:** `experiment/33-photokit` (probe in
  `App/Experiments/PhotoKitProbe.swift`); `archive/…` tag not recorded.
  - *Added 2026-11-14 by Claude:* archived as tag
    `archive/experiment/33-photokit` (branch deleted the same day). Every
    `[L-…]` tag on the branch's LEARNINGS.md is on `main` (*verified*,
    tag lists compared, 2026-11-14).
- **Outcome:** not recorded.
  - *Added 2026-11-14 by Claude:* fed spec drafts 52 and 54, which merged
    as `a5d06e9` and `1148bed`; issue #33 closed 2026-11-13.
- **Findings:** `[L-photos-x0-paths]`, `[L-photos-x1-permission]`,
  `[L-photos-x2-albums]`, `[L-photos-x3-download]`,
  `[L-photos-x4-cache-wallpaper]`, `[L-photos-x5-observer]`,
  `[L-photos-x6-ids]`, `[L-photos-album-order]`.

Source for this section unless noted: Phase 0 of the issue #33 plan
(`docs/PLAN-GITHUB-ISSUE-33.md`, now in tag `archive/feature/33-photos-albums`),
round A (not sandboxed), 2026-11-12,
macOS 27.2, the author's library with "Optimize Mac Storage" on, album
"NIN 2013" (61 images, 63 items). Probe: `App/Experiments/PhotoKitProbe.swift`
on branch `experiment/33-photokit`, build cdhash `9808ae12`. Run by Claude
with the author's yes.

- `[L-photos-x0-paths]` **Not sandboxed, every way of finding home agrees,**
  and the wallpaper store is readable through `homeDirectoryForCurrentUser`
  (`/Users/rmohns` from that, `NSHomeDirectory()`, and `getpwuid`). Caches
  is `~/Library/Caches`. *Verified.* The sandboxed comparison is round B.
- `[L-photos-x1-permission]` **The Photos prompt worked from the probe
  launch** (`open -n`, menu bar app, not sandboxed): "not determined" →
  prompt → "authorized" in 10 s, the author choosing full access.
  *Verified.* Whether a new build asks again is untested (round B
  rebuilds).
- `[L-photos-x2-albums]` **PhotoKit lists the author's albums and folders of
  albums in sidebar order, nested,** plus 16 shared albums (subtype 101)
  and the smart albums. Item counts include videos; filtering to images
  works. Two albums have the same name ("Hydra" twice; "Walllpapers &
  Desktop Pictures" twice, in different folders), so an album has to be
  saved by ID, not name. *Verified.*
  - **Album order is still open.** "NIN 2013" came back in the same order
    with no sort and with a date sort, so this album can't tell whether
    the default order is the album's own order. Needs an album sorted by
    hand in Photos.
- `[L-photos-x3-download]` **iCloud-only photos fail fast offline and
  download quickly online.** All 10 test photos (2013 JPEGs, 3264 × 2448)
  were iCloud-only. *Verified.*
  - Network off: no data at once, `PHImageResultIsInCloudKey` true, and
    `PHPhotosErrorDomain` 3164 (with network access not allowed), or "The
    Internet connection appears to be offline" (with it allowed), both
    in under 0.1 s. No hang.
  - Online: 0.51–1.43 s per photo, 927–1493 KB each, the original JPEG at
    full size, 2–4 progress callbacks. Written to Caches and read back at
    full size.
  - Open: whether a download leaves the photo local in Photos. The online
    run's "in cloud" check came *before* each download, so it says
    nothing about after. (Corrected 2026-11-12 by Claude: the first
    version of this entry claimed a later run showed the photo still in
    the cloud, but no such run took place.) Either way, Phases should keep
    its own copy, since Photos can drop local originals at any time
    (*recalled*).
  - Not covered: edited photos, Live Photos, HEIC, large files, a slow
    connection. None of the 10 had an edit or a Live Photo.
- `[L-photos-x4-cache-wallpaper]` **A file in `~/Library/Caches` works as a
  wallpaper** (not sandboxed). `setDesktopImageURL` raised no error, and
  `desktopImageURL` read back the cached file after 3 s. The original
  (`~/Pictures/Desktop Pictures/Peter Lik - Bamboo Forest Path.jpg`) was
  put back with no error. *Verified* by the API, and on screen by the
  author: the concert photo showed, then the Bamboo Forest came back.
  - **The store reading was inconclusive.** The latest desktop entry the
    probe found named `~/Pictures/Desktop Pictures/IMG_0761.JPG`, neither
    the cached file nor the original, so the probe's walk probably picked
    another Space's or display's entry. Not a finding about the store.
- `[L-photos-x5-observer]` **The change observer fires while Phases is in
  the background.** Adding a photo to the album, then removing it, gave
  five notifications in 3 minutes: one "inserted 1" (62 images), one
  "removed 1" (61), and three that didn't touch the album. *Verified.*
- `[L-photos-x6-ids]` **First record of IDs saved** (10 local IDs plus
  cloud IDs) in `~/Library/Caches/PhasesProbe/x6-ids.txt`. Comparing
  across builds and the sandbox is round B.
- `[L-photos-album-order]` **The default fetch follows the album's own
  order.** "Gift Ideas" (4 photos, put in a hand-made order by the
  author on 2026-11-12) came back with no sort as 6045, 2737, 6046,
  2736, and sorted by date as 2736, 2737, 6045, 6046. *Verified*: the
  author confirmed the first list matches the album in Photos. So "In
  order" for an album can mean the album's own order.
