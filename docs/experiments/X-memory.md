# `[X-memory]` Where Phases' memory goes

Part of "Memory" in [EXPERIMENTS.md](../EXPERIMENTS.md), the index of
experiments. Moved here word for word from EXPERIMENTS.md on
2026-11-27, when each record got its own file.
The group's introduction there applies to this record too; copied
here so the record reads on its own:

> Source for this section: branch `investigate/memory` (tag
> `archive/investigate/memory`), 2026-10-30,
> macOS 27.2, three displays (built-in, LG Ultrawide, Cinema HD). Measured
> on the installed Release build of `main` (built 2026-10-29; no `App/`
> changes on `main` since), the window closed unless noted. Two runs: one
> with `MallocStackLogging=1` so `malloc_history` could name allocators (it
> adds 16–64 MB of "Performance Tool Data", subtracted below), and a
> control run without it. Tools: `footprint`, `vmmap`, `heap`,
> `malloc_history`, `leaks`. Changes made with Change Now from the menu.
> Why we looked: Phases runs all day in the background, so it has to stay
> lean; see the *Why* under `[D-memory-flat]` in SPEC.md.


- **Question:** why did the installed `main` sit at 179 MB with its
  window closed, and what fixes it?
- **When, on what:** 2026-10-30 (investigation and fix runs) and
  2026-11-03 (draft 33 runs), macOS 27.2, two or three displays.
- **Branches:** `investigate/memory` (tag `archive/investigate/memory`);
  the fix on `fix/cover-memory` (tag `archive/fix/cover-memory`);
  draft 33 runs on `feature/persistent-cover-transitions` (tag
  `archive/feature/persistent-cover-transitions`).
- **Outcome:** the cover-memory fix landed on `main`, measured flat
  across ten changes `[D-memory-flat]`; the run procedure became
  `[D-memory-protocol]`. Promoted: `[Q-cover-image-copied]`,
  `[Q-iosurface-color-tag]`.
- **Findings:** `[L-main-memory]`, `[L-mem-timeline]`,
  `[L-mem-cover-windows-freed]`, `[L-mem-ca-copy]`,
  `[L-mem-pressure-relief]`, `[L-mem-no-upscale]`, `[L-mem-freed-held]`,
  `[L-mem-decode]`, `[L-mem-window]`, `[L-mem-thumbnails]`,
  `[L-mem-reconcile]`, `[L-mem-fix-ideas]`, `[L-mem-fix-runs]`,
  `[L-mem-draft33-runs]`.

- `[L-main-memory]` **The installed Release build of `main` measured
  179 MB with its window closed.** Answered: mostly crossfade images,
  plus the window's lasting cost; the entries below explain how.
  - **The reading** (*measured* 2026-10-30 with `footprint`): 82 MB large
    mallocs, 54 MB small, 9 MB QuickLook thumbnails. That's against
    23 MB for a fresh Debug launch that never opened the window.
  - **First guess:** the thumbnail grid isn't released when the window
    closes (*hypothesis*). Sent to its own branch (author, 2026-10-30).
  - **Update, same day: investigated** (the entries below). Mostly
    crossfade images, not the grid; the grid is about 25 MB of it.
  - **Correction, same day** (`[L-mem-fix-runs]`), *measured*:
    - "Mostly crossfade images" holds: with covers fixed, ten changes
      cost 2–3 MB instead of about 200.
    - "The grid is about 25 MB" doesn't: the 25 MB was the whole
      window's lasting cost, not the grid's. Releasing the grid gives
      back about 10 MB of a 40–50 MB lasting cost; the rest is the
      window itself and allocator-held memory.
- `[L-mem-timeline]` **Footprint rises and falls with crossfades; it
  isn't a steady leak on `main`.** *Measured.*
  - **Control run:** 23 MB idle; after successive changes 23 (nothing
    changed), 94, 148, 200, 207, 303 MB; window open 208, closed 168;
    three idle minutes later 134 MB.
  - **Logging run** (tool data subtracted): 55 at idle after a
    launch-time fade, then 89, 145, 218, 175 MB over four changes; flat
    at 174 after two idle minutes.
  - `leaks`: 0 leaks.
- `[L-mem-cover-windows-freed]` **`main`'s cover windows are freed after
  each fade.** `heap` finds no cover `NSWindow`, `CALayer`, or view after
  fades. So the guess that ordered-out, never-closed windows stay alive
  is wrong for `main`. *Measured.* Not checked on the spike's persistent
  covers, which are meant to stay.
- `[L-mem-ca-copy]` **Core Animation keeps its own full-screen copy of
  each cover image, and it outlives the window.**
  - **Where:** `malloc_history` puts the largest live blocks (9, 24,
    29–43, and 63 MB, one per display and image) in
    `CA::Render::copy_image` → `create_image_by_rendering`, during the
    commit that first draws the cover's layer. CA redraws the `CGImage`
    from `loadImage` into a new buffer instead of using it as is.
    *Measured.*
  - **How long:** copies from the last one or two changes were still
    resident after the fade, 175 MB of them after six changes.
    *Measured.*
  - **Purgeable, but still counted:** they sit in CoreGraphics'
    purgeable zone, and `footprint` counts most of them as "Reclaimable"
    (86–114 MB). macOS may drop them under memory pressure, but Activity
    Monitor still shows them. *Measured* (the column); *recalled* (what
    macOS does under pressure, not tested here).
  - **Open at the time:**
    - Why CA copies: a pixel-format or color-space mismatch between the
      decoded image and what CA wants (*guess*, not checked). **Update,
      same day: this guess was wrong; see `[L-mem-ca-copy-test]`.**
    - Who keeps the copy alive after the window is freed: not found
      (*guess*: a CA or CG image cache keyed by the image).
- `[L-mem-ca-copy-test]` Promoted to `[Q-cover-image-copied]` (2026-10-30).
- `[L-mem-iosurface-color]` Promoted to `[Q-iosurface-color-tag]` (2026-10-30).
- `[L-mem-pressure-relief]` **`malloc_zone_pressure_relief` didn't
  release the freed-but-held blocks.** It returned 0 every time: it
  doesn't help. Three rounds on installed `main`, 2026-10-30, all
  *measured*:
  - **Round 1, call made from `lldb`** inside the running app, after
    three changes (23 → 297, 229, 240 MB):
    - It returned 0 bytes released; "Malloc Large (empty)" stayed at
      32.6 MB.
    - Yet footprint fell from 239 to 110 MB within the same few seconds.
      The timing pointed to Core Animation's purgeable copies
      `[L-mem-ca-copy]` going, perhaps set off by the debugger pausing
      the app (*guess*), not to the call.
  - **Round 2, repeat without `lldb`:**
    - 23 → 83, 116, 144 MB over three changes, then flat at 143 MB for
      30 s.
    - A 2 s pause and resume (`kill -STOP`/`-CONT`) changed nothing
      (143 MB for 10 s more). Freed blocks 58.7 MB.
    - So round 1's drop wasn't a timer within 30 s, and wasn't the pause
      itself. Left open: something `lldb` does when it runs an
      expression, or the call freeing purgeable memory it doesn't count
      in its return value (*guesses*).
  - **Round 3, two runs of ten changes** (fresh launch each, 6 s apart):
    - Watch run: 23 → 83, 134, 141, 179, 184, 193, 216, 224, 257,
      296 MB; flat at 295 MB for 30 s after. Freed blocks 71 MB.
    - Relief run: 23 → 84, 94, 166, 190, 222, 261, 259, **157**, 177,
      190 MB. The call returned 0, and footprint stayed at 192 MB. Freed
      blocks 32.6 MB before and after.
  - **What it adds up to:**
    - Memory stacks up with each change, roughly 20–40 MB per change
      across three displays, and only sometimes falls back on its own.
      The relief run dropped 102 MB between changes 7 and 8 with no
      help.
    - That fits macOS purging CA's purgeable copies `[L-mem-ca-copy]`
      when it chooses (*guess*). So round 1's drop was likely the same
      thing happening by chance, not the call (*inference*).
    - Runs vary widely: the same three changes cost 297 MB in round 1 and
      144 MB in round 2. Unexplained.
    - Whether the climb has a ceiling is not known; 296 MB was the
      highest seen in ten changes.
- `[L-mem-no-upscale]` **`loadImage` never scales an image up.** The
  max-pixel option only caps size, so a 2880 × 2160 file stays 2880 ×
  2160 (24.9 MB) on a larger screen; CA scales it when compositing.
  *Measured* (decoded sizes of the author's files, 2026-10-30). That
  explains block sizes that don't match any display.
- `[L-mem-freed-held]` **Freed full-screen buffers stay in the process
  for minutes.** `vmmap` shows "Malloc Large (empty)": blocks already
  freed but still resident and dirty, which `footprint` counts in full.
  24 MB at idle after one launch fade; 40–95 MB after changes; 62 MB
  still there after three idle minutes. *Measured.* That's the system
  allocator keeping freed large blocks for reuse rather than handing the
  pages back (*recalled* allocator behavior; when and whether it returns
  them is not tested).
- `[L-mem-decode]` **Each cover also decodes the file at full size
  first.** `CGImageSourceCreateThumbnailAtIndex` draws the full-size
  source image, leaving a decoded copy in CoreGraphics' purgeable zone
  (24 and 22 MB after the launch fade). They were already purged
  (resident 0) 40 s later, so they cost a peak, not a steady state.
  *Measured.* `footprint` reported a 161 MB peak at launch from one fade.
- `[L-mem-window]` **Opening the window adds about 25 MB that stays after
  it closes.** Small allocations went from 28 to 55 MB (logging run) and
  21 to 45 MB (control); closing gave none of it back. `heap` still finds
  the grid's 17 `ThumbnailCell` views and their images after the close,
  so SwiftUI keeps the closed `Window`'s view tree. *Measured.* A second
  open and close added only about 2 MB of small allocations, plus 4 MB
  each of CoreAnimation and QuickLook thumbnails, so it's one-time, not
  per open. *Measured.* Whether SwiftUI ever releases it: unknown.
- `[L-mem-thumbnails]` **Thumbnails are small:** the folder has 22
  images; QuickLook Thumbnails measured 4–9 MB. *Measured.*
- `[L-mem-reconcile]` **This accounts for the earlier figures.** The
  179 MB in `[L-main-memory]` (82 MB large, 54 MB small, 9 MB thumbnails)
  fits: CA copies plus freed-but-held blocks for "large", the window's
  retained tree for "small". The spike's growth in `[L-cover-memory]`
  fits the same mechanisms, plus the images the persistent cover holds
  on purpose. *Inference* from the numbers above, not measured on the
  spike branch.
- `[L-mem-fix-ideas]` **Recommended fix, in order (agreed with the
  author 2026-10-30; untested in Phases).** Earlier versions of this
  entry suggested a matching CGImage and an allocator call; both are
  ruled out (`[L-mem-ca-copy-test]`, `[L-mem-pressure-relief]`).
  1. Covers draw into an IOSurface tagged with the image's color space
     (`[L-mem-iosurface-color]`); drop our decoded image once drawn;
     release the surface when the cover goes. Removes CA's copy, most
     of the per-change pile-up.
  2. Decode once, straight into that surface, without ImageIO's
     full-size intermediate (`kCGImageSourceShouldCache` off). Should
     also shrink the freed-but-held blocks, which mostly come from
     those buffers (*inference*).
  3. Release the grid's thumbnails when the window closes (about
     25 MB, `[L-mem-window]`).
  4. Measure with ten changes per run, at least two runs before and
     two after: runs vary widely (`[L-mem-pressure-relief]`).

  For the persistent cover, one tagged surface per display is the floor
  it can't avoid: about 25–63 MB per display at the author's sizes
  (*inference* from the decoded sizes). A SPEC.md decision (proposed
  name `[D-cover-iosurface]`) comes first, for approval.

- `[L-mem-fix-runs]` **`[D-memory-protocol]` runs of the fix, 2026-10-30.**
  macOS 27.2; two displays (LG Ultrawide, Cinema HD rotated; no built-in),
  Different per Display, Crossfade 1 s, diagnostics switched on (author's
  setting). Before = installed Release of `main` (built 2026-10-29); after
  = Release of `fix/cover-memory` (tag `archive/fix/cover-memory`; code
  as of `18130ee`), run from its
  build folder, not installed. Ten Change Now clicks 6 s apart, then 30 s
  idle, then the window check. *Measured:*

  | Run | Idle | After changes 1–10 (MB) | 30 s idle | Window: before, open, closed 30 s |
  |---|---|---|---|---|
  | before 1 | 66 | 96 109 141 144 161 260 230 257 280 291 | 291 | 291, 236, 236 |
  | before 2 | 21 | 59 66 137 169 137 170 189 221 230 272 | 272 | 272, 314, 291 |
  | after 1 | 22 | 28 30 30 30 31 31 31 31 31 31 | 31 | 31, 81, 71 |
  | after 2 | 21 | 28 29 30 30 30 30 30 30 30 30 | 30 | 30, 81, 71 |

  - **Covers pass `[D-memory-flat]`:** 3 MB and 2 MB from change 1 to 10,
    against a 30 MB allowance; `main` rose 195 and 213 MB.
  - **Window fails** the `[D-memory-protocol]` window check: 40 MB above
    the pre-open reading after closing, against 30. (Before-run window
    figures are swamped by cover purges and say nothing.)
  - **The grid is released.** Diagnostic run (after build, no changes):
    open 81, closed 71 MB. `heap` shows 22 `ThumbnailCell` view lists
    while open and none 30 s after closing. *Measured.*
  - **What stays:** Malloc Small 13 → 45 MB, unchanged by the close; live
    heap 7.8 → 27.7 MB (56k → 173k allocations). So about 20 MB is still
    live (the window's other SwiftUI and AppKit objects: sidebar, toolbar,
    hosting views, 104 CGImages, 48 NSImages) and about 17 MB is freed but
    held `[L-mem-freed-held]`. CoreAnimation 11 → 6.6 MB and QuickLook
    9.3 → 5.2 MB on close. *Measured*; the split into live and held is
    *inference* from `heap` against `footprint`.
  - The 30 MB window bar assumed the grid was most of the window's cost
    (`[L-mem-window]`); at 22 images it isn't.
  - **Whole-window release, same day.** Experiment: the window's entire
    content dropped 1 s after closing, not just the detail pane (Release
    build, window only, no changes). Kept as a measurement only.
    - Readings: idle 22; open 81, closed 30 s 60; open again 84, closed
      30 s 62 MB. *Measured.*
    - 11 MB better than dropping the pane alone, but still 38–40 MB over
      idle, so it also fails the 30 MB bar. A second open and close
      added 2 MB.
    - After the second close: live heap 23.2 MB (idle 7.8), Malloc Small
      48 MB dirty, CoreAnimation 1.1 MB. So most of what stays is
      freed-but-held allocator memory `[L-mem-freed-held]` (about 25 MB,
      *inference*) plus about 15 MB of live objects Phases no longer
      references (*inference*: SwiftUI and AppKit caches).
    - The code went back to releasing the pane (author, 2026-10-30):
      11 MB isn't worth rebuilding the sidebar and its fragile helpers
      on every reopen.
  - **Pane-only confirmation, same day,** under the new window check
    (Release, window only, two rounds): idle 24; open 80 (31
    `ThumbnailCell` view lists in `heap`), closed 30 s 70 (none); open 83
    (31), closed 30 s 73 (none). *Measured.* Passes: the grid is released
    each time, and the second close is 3 MB above the first (limit 5).
- `[L-mem-draft33-runs]` **`[D-memory-protocol]` runs of draft 33
  (persistent covers), 2026-11-03.** Release build of
  `feature/persistent-cover-transitions` (tag
  `archive/feature/persistent-cover-transitions`) from Bitrig's build folder,
  macOS 27.2, three displays (LG Ultrawide 5160×2160 px with three
  Spaces, built-in 3024×1964, Cinema HD 2200×3520), 30 images, Crossfade
  1 s, schedule paused for the run, `footprint` in MB. *Measured.*
  - **Run A:** idle 23; changes 1–10: 137, 98, 110, 87, 141, 95, 99, 95,
    100, 100; 30 s idle 100. Passes (tenth below first).
  - **Run B:** idle 23; 113, 98, 98, 98, 140, 99, 117, 87, 99, 87; 30 s
    idle 87. Passes.
  - **Covers' cost and release** (after run B): leaving the Space 87 → 63
    (only the main display has other Spaces; its cover held the
    2880×2160 image, about 25 MB, so the full size came back). Back on
    the Space: 63, no cover returned. Window open and close with
    Crossfade: 124. One change: 194 (covers about 101 MB: 66 + 24 + 11
    from decoded sizes). Transition: None, window closed, 30 s: 80, a
    114 MB drop. Passes.
  - **Baseline, Transition: None:** idle 23, 28–29 after every change.
  - **Window** (Morning, grid scrolled to the end): before 28; open 86,
    closed 30 s 84; open 92, closed 89; a third round: open 93, closed
    90. `heap` found 34 `ThumbnailCell` lines with the window open and
    none after any close. Second close 5 MB above the first, at the
    limit; the third added 1 MB. Passes, just.
  - Nothing near 500 MB.
