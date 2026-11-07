# Phases — Learnings

What we've found out along the way that doesn't (or doesn't yet) shape the
shipping code. SPEC.md says what Phases does; ERRATA.md holds the platform
quirks the code works around. This file keeps everything else we learned,
so it isn't lost when an experiment branch is deleted or a design goes
another way.

- **Sorting test:** does it shape code on `main` right now? Yes → SPEC.md
  or ERRATA.md. No → here.
- Each entry has a stable `[L-…]` tag, a date and macOS version, and an
  evidence label: verified, observed, or recalled.
- Entries cite the `[D-…]` and `[Q-…]` tags they relate to, and where the
  evidence lives (an experiment doc, a branch).
- The rules for all of this (evidence labels, promotion and demotion,
  references by tag `[D-refs-by-id]`) are in CLAUDE.md.

## Wallpaper, covers, and the menu bar

Source for this section unless noted: the persistent-cover experiment,
2026-10-30, macOS 27.2, one built-in display (3024 × 1964); branch
`spike/persistent-cover` (tag `archive/spike/persistent-cover`),
`docs/X-PERSISTENT-COVER.md`. A "cover" is a
borderless, click-through window just above the desktop picture
`[D-cover-level]`.

- `[L-motion-waits-for-reveal]` **macOS seems to hold its wallpaper-change
  motion until the new wallpaper is first visible, not play it on a
  timer.** With a fully opaque cover held over a newly set wallpaper,
  then removed for 100 ms, the shift (`[Q-wallpaper-motion-delay]`)
  played at the moment of reveal, whether the cover came off 1.5 s or 4 s
  after the set. *Measured* from 60 fps recordings (building and crane
  visibly offset in the reveal frame). The "holds until visible" reading
  is a *hypothesis*. Bears on `[D-cover-settle]`: a longer settle delay
  alone may not be what fixes the twitch; partial visibility during the
  delay might be. Unproven.
- `[L-opaque-cover-freezes-menubar]` Promoted to `[Q-opaque-cover-freezes-menubar]` (2026-10-31).
- `[L-cover-all-spaces]` **A cover with `.canJoinAllSpaces` and
  `.stationary` shows on every Space and in Mission Control, and slides
  with each Space during a swipe like a real wallpaper.** *Observed.*
  Setting the real wallpaper on arrival (`NSWorkspace
  .activeSpaceDidChangeNotification`, then `setDesktopImageURL`) worked on
  every arrival (*verified* in the diagnostic log). On arrival the menu
  bar kept the previous image's style for about 0.5 s, blinked, then
  restyled (*observed* once, 99% cover). Bears on "Different wallpaper per
  Space" in SPEC.md "Out of scope".
- `[L-lockscreen-uses-real-wallpaper]` **The lock screen and the login
  window show the real wallpaper of the Space you were on, not anything
  drawn by an app.** With a cover up and the real wallpaper kept in sync
  underneath, the lock screen was correct from two Spaces and the login
  window from one. *Verified* by the author, 2026-10-30. So the lock
  screen can follow Phases through the public API alone.
- `[L-login-dims-wallpaper]` **At logout, macOS redraws the wallpaper for
  the login window, slightly darkened, with a visible twitch.** The
  twitch appeared just as the login window did. *Observed* by the author
  2026-10-30 with the experiment build; the redraw explanation is
  *recalled*, not tested. Not checked on `main`.
- `[L-desktop-through-cover]` **Desktop features work through a
  cover.** *Observed.*
  - Icons and widgets draw above it.
  - Right-click on the desktop opens Finder's desktop menu.
  - "Click wallpaper to show desktop" works.
  - Widgets turn translucent over it when an app is in front.
  - Calendar in full screen and Stage Manager (turned on for the test)
    behaved normally.
  - Quitting Phases removes a cover in a hard cut; a Force Quit shows
    nothing if the real wallpaper underneath matches.
- `[L-outside-change-hidden]` **A wallpaper set by anything else while a
  cover is up is hidden by the cover.** *Observed* (set through System
  Events). A user changing wallpaper in System Settings would see nothing
  happen.
- `[L-cover-memory]` **One full-screen cover image costs about 23 MB at
  3024 × 1964, and the experiment held it about three times.**
  - **The three copies:** Core Animation, a large malloc buffer, and CG
    raster data, about 23 MB each.
  - **One display** (Debug build, `footprint`), *measured*:
    - 23 MB with no cover.
    - 86–93 MB with a cover at launch.
    - 102 MB after three changes (window-per-change version); the growth
      is unexplained.
  - **Idea:** releasing Phases' own copies once the layer has the image
    might bring it to about one copy (*hypothesis*).
  - **Update, three displays (2026-10-30, 99% cover B): it's a leak.**
    *Measured:*
    - 77 MB with no cover.
    - 140–187 MB with the cover at launch.
    - Then about 25–30 MB more with every change, reaching 373 MB after
      about nine changes. Old cover windows or their images aren't
      released.
    - Must be fixed before any persistent cover ships (author,
      2026-10-30).
  - **Loose ends, to pin down when fixing it:**
    - The 77 MB no-cover figure, against 23 MB on one display, isn't
      explained.
    - Later in the same run, Activity Monitor showed 242 MB with no
      further changes (*observed* by the author). So memory may be
      released slowly rather than leaked, or Activity Monitor and
      `footprint` measure differently.
- `[L-menubar-lazy-restyle]` **macOS sometimes leaves menu bar text
  the wrong color for the wallpaper, with no cover involved, in either
  direction.** Rule this out before blaming Phases for wrong menu bar
  text.
  - **Seen with no cover:** on the ultrawide, the white Ergo Proxy image
    got white text on a light grey bar, with or without the cover. In
    the control, the wallpaper was set directly with nothing from Phases
    running, and the text was still white 8 s later. *Observed*
    2026-10-30, three displays.
  - **Other direction:** the author has also seen dark text on a very
    dark wallpaper (*observed*, several times before 2026-10-30).
  - **Why we call it lazy:** the text corrects itself the moment any
    part of the menu bar is clicked (*observed* by the author). That
    fits `[Q-menubar-restyle-on-app-switch]` (FB25326597): macOS doesn't
    always restyle until something else happens, such as an app switch
    or a click in the menu bar.
- `[L-cover-three-displays]` **The 99% cover held up on three
  displays.** *Measured/observed* 2026-10-30.
  - **Setup:** ultrawide main with three Spaces, built-in, and portrait
    Cinema HD, each with its own image.
  - **Results:**
    - No twitch on any display (44–50 dB before and after each fade).
    - Menu bar text and background tracked each display's image.
    - Every ultrawide Space synced on arrival without touching the
      other displays.
    - Mission Control showed the covers on all three.
  - **Not tested:** more than one Space on the built-in or portrait
    display.
  - **Method note:** recording all three displays at once starves
    `screencapture` (two dropped to a few frames per second). Record one
    display at a time for twitch checks `[L-twitch-measurement]`.
- `[L-cover-own-space]` **A cover without `.canJoinAllSpaces` stays on
  its own Space, and can be removed when you leave it with nothing
  visible.** On `activeSpaceDidChangeNotification` the departed Space's
  cover reported `isOnActiveSpace` false every time (three of three), and
  removing it then changed no frame. Each Space kept its own real
  wallpaper through changes on the others. *Verified* 2026-10-31, macOS
  27.2, one display, three Spaces, 99% cover, branch
  `spike/persistent-cover` (tag `archive/spike/persistent-cover`;
  "Covers on their own Space" in `docs/X-PERSISTENT-COVER.md`). Supports
  `[D-cover-per-space]` on `feature/persistent-cover-transitions` (tag
  `archive/feature/persistent-cover-transitions`). Not seen at first: the cover
  sliding with its Space (an app window hid it). **Update, run 2 the same
  day:** the cover slid away with its Space during the swipe; Space 2
  came in showing its own image (*observed*). But see
  `[L-space-leave-mid-fade]`.
- `[L-space-notify-after-swipe]` Promoted to `[Q-space-notify-after-swipe]` (2026-10-31).
- `[L-space-leave-mid-fade]` **Leaving a Space mid-fade sends the
  change to the wrong Space.** With a 3 s fade and ⌃→ at 0.3 s or 1.5 s
  in, the notification arrived about 0.9 s after the key press, mid-fade;
  the own-Space cover was removed, and the end-of-fade
  `setDesktopImageURL` landed on the Space just arrived on. The Space left
  behind kept its old image. When the images differed, the arrival Space
  hard-cut to the new image about 0.9 s after the swipe ended, with no
  fade. *Verified* 2026-10-31, macOS 27.2 (log, each Space's wallpaper
  read back, recordings; two runs). Breaks `[D-cover-per-space]` as
  drafted: the public API sets the wallpaper only on the active Space
  (*recalled*), so a change can't be finished on a Space after leaving it.
  Untested ideas: set the real wallpaper at the start of the fade, under
  a cover still showing the old image; or, on leaving mid-fade, skip the
  set and leave that Space unchanged until its next change. **Update,
  same day:** draft 33 takes neither; it holds the cover and sets the
  wallpaper on return `[D-change-stays-on-its-space]` (untested).
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
- `[L-backdrop-private-store]` **Backdrop (Cindori) puts video on the
  lock screen by registering entries in macOS's private wallpaper store,**
  `~/Library/Application Support/com.apple.wallpaper/Store/aerials/manifest/entries.json`,
  so macOS plays them like Aerials. Cleanup after uninstalling means
  deleting that file and restarting. From Cindori's own support pages,
  2026-10-29; not inspected. **Rejected for Phases** (author, 2026-10-29):
  no private macOS operations, consistent with `[D-aerials-untouched]`.

## Memory

Source for this section: branch `investigate/memory` (tag
`archive/investigate/memory`), 2026-10-30,
macOS 27.2, three displays (built-in, LG Ultrawide, Cinema HD). Measured
on the installed Release build of `main` (built 2026-10-29; no `App/`
changes on `main` since), the window closed unless noted. Two runs: one
with `MallocStackLogging=1` so `malloc_history` could name allocators (it
adds 16–64 MB of "Performance Tool Data", subtracted below), and a
control run without it. Tools: `footprint`, `vmmap`, `heap`,
`malloc_history`, `leaks`. Changes made with Change Now from the menu.
Why we looked: Phases runs all day in the background, so it has to stay
lean; see the *Why* under `[D-memory-flat]` in SPEC.md.

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

## Sidebar rows

Source for this section: the issue #22 experiment, 2026-11-06, macOS
27.2, branch `experiment/active-badge-highlight` (commit 204231c), run by
Claude with the author's yes. Highlight Color was blue. Each run
relaunched Phases with a launch switch choosing the variant, selected
the active phase (Nighttime) by clicking Dusk and pressing Down, and
took window screenshots with the window in front and behind Finder.

- `[L-tint-on-highlight]` Promoted to `[Q-tint-on-highlight]` (2026-11-06).
- `[L-background-prominence-mac-list]` Promoted to `[Q-tint-on-highlight]` (2026-11-06).
- `[L-row-styles-on-highlight]` **What does adapt on the highlight.**
  *Verified* (screenshots):
  - Hierarchical styles (`.primary`, `.secondary`) and a symbol with no
    style of its own turn white or near white on the highlight, and
    grey otherwise (run 4's triangle, the trigger line).
  - The row's leading `Label` icon is accent-coloured normally and white
    on the highlight, with no code of ours doing it.
  - A `.multicolor` `exclamationmark.triangle.fill` is yellow with a
    dark mark and stays yellow on the highlight (run 3). Readable on
    blue, not adaptive.
  - An explicit `.orange` stays orange (runs 1–2), so it would vanish
    on an orange highlight (*hypothesis*, not run).
- `[L-row-own-selection]` **Telling the row it's selected works, but the
  accent highlight also needs the sidebar to have focus.** Run 5
  (commit b880f57): `PhaseRow` gets `isSelected` from the sidebar's
  `selection` and reads `appearsActive`; the badge is `.primary` when
  both are true, `.tint` otherwise. *Verified* (screenshots, log):
  - Selected, window in front, sidebar focused: blue highlight, badge
    white and readable. The log showed `isSelected` and `appearsActive`
    following the clicks and the switch to Finder.
  - Selected, window in front, focus moved to the editor (clicked the
    Name field): the highlight turned **grey**, like a background window,
    but the badge stayed white, since both flags were still true.
    Readable, but it doesn't match the background-window look (accent
    badge on grey).
  - Window behind Finder: grey highlight, accent badge.
  - So the accent highlight follows "selected, window in front, and the
    sidebar has focus" (*verified* for these three cases). Adding the
    window's existing `sidebarFocused` to the condition should match all
    three (*hypothesis*, not run). Confirmed by run 6, below.
- `[L-row-selection-focus]` Promoted to `[Q-tint-on-highlight]` (2026-11-06). Run 6 (commit 7693bb0): sidebar focused, blue highlight and white badge; focus in the Name field, grey and accent; back on the row, blue and white; window behind Finder, grey and accent.

## Open questions

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

- `[L-new-space-pauses]` **Does a new Space read as an outside change?**
  (GitHub issue #29, macOS 27.2.) Going full screen in any app pauses
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
    left full screen). Fits the hypothesis: a Space going away removes
    entries, which the rule never reads. Nothing on the display-change
    path is involved.
  - Still open: a snapshot diff of `Index.plist` across a new Space, to
    confirm new `space/<id>/…` keys and see which image and `LastSet`
    they carry; and whether a real pick on a never-picked Space also
    shows up only as a new key, which decides the fix.

- `[L-reopen-event]` **What happens when Phases is launched again while
  it's running, and can the menu bar icon's view open the window?**
  (Issue #13, macOS 27.2.) Answered; experiment on branch
  `experiment/reopen-window` (tag `archive/experiment/reopen-window`),
  started 2026-11-03.
  - Promoted to `[Q-reopen-ignores-closed-window]` (2026-11-03).
  - Setup: an app delegate logs `applicationShouldHandleReopen`, then the
    window's state 0.5 s later, under diagnostics category `reopen`.
    Mode switch `PhasesReopenMode`: `none` (log only, AppKit and SwiftUI
    defaults) or `label` (the menu bar icon's view opens the window the
    way "Open Phases…" does).
  - Questions: does a menu bar accessory get the reopen call at all; does
    SwiftUI already show a `.suppressed` `Window` on reopen; does the
    label view stay alive to act on a request while the window is closed;
    does activation succeed `[Q-launch-activate-refused]`.
  - Run 1, mode `none`, window never opened (2026-11-03, Claude, `open`
    from Terminal, read from the log; *verified*): the reopen call
    arrives (`hasVisibleWindows=false`), Phases becomes active, still an
    accessory (policy 1), and SwiftUI creates no window, so nothing
    shows. So a menu bar accessory does get reopen, and activation is
    granted on a relaunch, unlike `[Q-launch-activate-refused]`.
  - Run 2, mode `none`, window open behind Bitrig (2026-11-03, same
    method; *verified* from the log): Phases became active (regular,
    policy 0) and the window came forward as key, on the active Space.
    Plain activation already covers this case; nothing to add. The
    author saw the window come to the front (*observed*, same run).
  - Run 3, mode `none`, window closed after being open (2026-11-03,
    same method; *verified* from the log): reopen arrives
    (`hasVisibleWindows=false`), Phases becomes active as an accessory
    (policy 1), and the kept, hidden window stays hidden. SwiftUI doesn't
    re-show it. Same gap as run 1. The author saw focus leave Bitrig and
    nothing else (*observed*, same run): today a relaunch takes focus
    from the user's app and shows nothing in exchange.
  - Run 4, mode `none`, window minimized (2026-11-03, same method;
    *verified* from the log): reopen arrives with
    `hasVisibleWindows=true` even though the only window is minimized
    (AppKit counts it), and AppKit's default handling un-minimizes it:
    0.5 s later it's visible, key, not minimized. The author saw it come
    up from the Dock with focus (*observed*, same run). Nothing to add.
  - Run 5a, mode `label`, window never opened (2026-11-03, same method;
    *verified* from the log): the menu bar icon's view received the
    request in the same millisecond as the reopen call and opened the
    window. 0.5 s later Phases was regular (policy 0), the window
    visible, key, and on the active Space. So the label view is alive
    and able to call `openWindow` while no window exists. The author saw
    the window open (*observed*, same run).
  - Run 5b, mode `label`, window closed with ⌘W (2026-11-03, same
    method; *verified* from the log): the label re-showed the kept
    window; 0.5 s later Phases was regular and the window visible and
    key on the active Space. The author saw it (*observed*, same run).
  - Run 5c, mode `label`, window minimized (2026-11-03, same method;
    *verified* from the log): the label's open routine un-minimized it;
    0.5 s later visible, key, not minimized. The author saw it come back
    up from the Dock (*observed*, same run).
  - **Answer (2026-11-03):** a menu bar accessory does get the reopen
    call, and activation is granted. SwiftUI and AppKit handle the open
    and minimized cases on their own but ignore a closed or never-opened
    window. Handing the request to the menu bar icon's view, which runs
    the "Open Phases…" routine, covers all three. The mode switch was
    deleted after the runs (the running process had already read
    `label`, so run 6 still used it).
  - Run 6, mode `label`, window moved to Space 2 and closed there, author
    back on Space 1 (2026-11-03, author's request, same method;
    *verified* from the log): the window was off the active Space, the
    `[D-open-here]` flag moved it, and it arrived on Space 1 140 ms
    later, visible and key. The author saw it open on Space 1 and called
    that acceptable (*observed*, same run). It's what `[D-open-here]`
    already promises for "Open Phases…".
  - **UI test failure, 2026-11-03, `feature/reopen-window` at `d4b73d3`**
    (tag `archive/feature/reopen-window`)
    (Claude): `RelaunchTests/relaunchWithTheWindowClosedShowsIt` failed
    twice (the second run was an accident of a piped command). The test
    sends the reopen Apple event straight to the process. The log shows
    the handler fired and the opening routine ran (`relaunched`, then
    the Space mover's line), but the window never showed and Phases
    ended with no Dock icon (*verified*). Unlike the experiment's `open`,
    nothing activated Phases first: in every experiment run, "became
    active" was logged *before* the reopen call (*verified*), so Launch
    Services activates, then reopens. Hypothesis, untested: the routine
    fails when Phases isn't already active.
  - Rerun with state logging, 2026-11-03 18:00 (Claude, one run): the
    test **passed**, with `active=false policy=1` logged at the reopen
    call (*verified*). So "fails when not active" is wrong: the routine
    can show the window from an inactive accessory. Two failures and one
    pass on the same code point to something intermittent (*hypothesis*).
    The +0.5 s and +2 s lines never logged: the test force-quits Phases
    as soon as the window appears (*likely*, not checked).
  - Five more runs, 2026-11-03 18:02–18:04 (Claude), the test holding
    Phases 3 s after the window appears: **5 of 5 passed** (*verified*).
    Each logged inactive accessory at the reopen call, then active,
    regular, and the window visible and key 0.5 s later. So: 6 of 6
    pass on the build with the delayed log lines, 0 of 2 on the build
    without them.
  - *Hypothesis* (untested): the delayed log lines are what make it
    work. They're timers that wake Phases' main run loop; without them,
    an inactive menu bar app may sit idle with SwiftUI's `openWindow`
    queued and never carried out. The experiment build had a delayed
    log line too, and `open` activates Phases first, which also wakes it.
  - Timers-off check, 2026-11-03 18:06 (Claude, 3 runs): **invalid.** All
    3 passed, but every run logged the +0.5 s and +2 s lines, so the
    harness launched an older build, not the timers-off one built at
    18:06 (*verified* from the log).
  - **Cause: the harness's "newest build" pick is broken** (*verified*,
    `stat`, 18:07). It compares the `Phases.app` bundles' modification
    dates, but Bitrig gives every bundle the same date (12:36:03 for all
    three builds present), so the pick among ties follows directory
    order: effectively arbitrary. Only the executable inside carries the
    build time (17:47, 18:00, 18:06). Any UI test run made while several
    builds sat in the Builds folder may have tested an older build than
    intended. Which build each earlier relaunch run used is known only
    from its log format.
  - Harness fixed (pick by executable date, print the build). Timers-off
    check redone, 2026-11-03 18:09–18:10 (Claude, 3 runs, build of
    18:09:32 confirmed by the harness's printout and by the missing
    timer lines): **3 of 3 passed** (*verified*). The timer hypothesis is
    wrong.
  - The experiment Phases (pid 79653) quit at 17:48:36, before the
    failing runs (*verified*, system log), so a second instance wasn't
    the cause either.
  - **Still unexplained:** the two 17:49 failures ran the same relaunch
    code (their log format shows it) and never got the window. Since
    then, 12 of 12 runs passed (1 + 5 + 3 + 3; all ran this relaunch
    code, 9 of them with the timer lines). The failing runs logged nothing after the
    opening routine started, so where it stopped is unknown. The only
    known difference: they were the session's first relaunch test runs.
  - Ten more runs, 2026-11-03 18:19–18:22 (Claude, author's request,
    pinned with `PHASES_APP` to the 18:11:16 build of the committed
    code, since another conversation was active in the workspace):
    **10 of 10 passed** (*verified*). Tally since the two failures: 22 of
    22.

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

- `[L-menubar-overflow]` **Is Phases' menu bar icon hidden when the menu
  bar runs out of room?** On macOS 27.2, no: a chevron reveals it. Still
  open for macOS 26. Tracked as GitHub issue #11; no action for now.
  - **How it came up:** a UI test run on `fix/cover-memory` (tag
    `archive/fix/cover-memory`), 2026-10-30,
    two external displays (no built-in), Bartender not running.
    - The driver found Phases' menu bar item at x = 2630 but refused to
      click it ("isn't this test instance's"). *Measured.*
    - That failed `deleteRemovesANewlyAddedPhase` and, most likely, one
      `FocusTests` test whose message wasn't kept. A rerun of
      `FocusTests` alone passed all three.
    - Suspected cause (*guess*): the author runs the Cinema HD at
      1000 × 1600, narrow enough that macOS may push status items off the
      menu bar.
  - **Why it matters beyond tests:** on that display a person might not
    reach Phases' menu at all.
  - **Update, same day:** the author checked the narrow display. It had
    run out of room, and macOS showed a chevron that expands the hidden
    icons when clicked, so Phases stays reachable on macOS 27.2
    (*observed* by the author).
  - **Seen again, 2026-11-03** (Claude, `feature/reopen-window`, fast
    suite twice): the same refusal, "the menu bar item at (2541.0, 31.5)
    isn't this test instance's," at launch. 17:51: `brandingPanelScreenshot`
    (build not known, see the harness note under `[L-reopen-event]`).
    18:11: `brandingPanelScreenshot` and `gridIsOneTabStopAndArrowsScroll`
    (build of 18:11:16, printed by the harness); the other 11 passed
    (*verified*). Same x every time, wide display, no leftover Phases
    afterward. *Guess:* the previous test's force-quit instance still
    owns that spot for a moment.
  - **Seen again, 2026-11-04** (Claude, `main` at `63249c1`, Debug build
    of 22:53:03 printed by the harness, built-in display only, 3024 ×
    1964 Retina with the notch): `deletingAMiddlePhaseSelectsTheOneBelow`
    refused "the menu bar item at (987.0, 15.5) isn't this test
    instance's." The fast suite logged 2 issues; the other's message
    was lost (output cut off), so which test it hit is unknown. The
    installed Phases (`/Applications`, pid 99271) was running throughout
    (*verified* afterward, `pgrep`). *Hypotheses*, untested: the item
    found was the installed Phases' icon, or the notch left too little
    room right of it and hid the test instance's icon.
  - **Rerun, 2026-11-04** (Claude, same build, built-in display only, the
    notch area disabled by the author's resolution, no other Phases
    running, *verified* with `pgrep` before the run): 11 of 13 passed.
    `brandingPanelScreenshot` and `typingAfterReopeningDoesNotRenameThePhase`
    refused "the menu bar item at (1023.0, 15.5) isn't this test
    instance's"; `deletingAMiddlePhaseSelectsTheOneBelow`, which failed
    the first run, passed. That rules out the installed Phases and the
    notch. Both failing tests were the second in their suite, right after
    another test's instance was force-quit (*observed*, two cases).
    *Hypothesis*, untested: the harness hit-tests the item while the menu
    bar is still re-laying out after the old instance's item went away,
    so the point briefly belongs to something else. The refusal message
    doesn't name the owner it found, so the log can't confirm this.
  - The author heard a system beep the 2nd and 4th time a window
    appeared in this run (*observed*, author). *Hypothesis*, untested:
    the Focus tests press X to prove it doesn't rename the phase, and a
    key nothing handles beeps. The run's output has no timestamps, so
    which tests the beeps came from is unknown.
  - Beeps again in the 13-of-13 run (author). The run's output shows the
    sidebar outline had focus at every X press (*verified*, the tests'
    "Focused on" lines; 3 presses in that run, 2 in the rerun before it,
    where the reopen test failed before pressing). No phase starts with
    X, and a list's type-to-select beeps when nothing matches
    (*recalled*, not tested here). That fits, but nothing ties a beep to
    a press yet.
  - **Answered, 2026-11-04:** the author pressed keys in the sidebar by
    hand: focus behaves as the tests expect, and a key that matches no
    phase beeps (*verified* by the author). The beeps are macOS's, not a
    failure.
  - **Harness fix, 2026-11-04** (`fix/menubar-hit-retry`, tag `archive/fix/menubar-hit-retry`, approved by the
    author): the ownership check rechecks for up to 2 s and names the
    owner when it refuses. First run with it: 13 of 13 (*verified*).

- `[L-hdr-wallpaper]` **How does macOS draw an HDR photo (an iPhone
  HEIC with a gain map) as wallpaper: SDR, or with HDR headroom?**
  - **Answer: SDR,** by the author's eye against a known-HDR control
    (2026-10-30, below). No tool here could measure it.
  - **Why it matters:** bears on `[D-cover-iosurface]`. An 8-bit SDR
    cover surface is right only if macOS shows the wallpaper as SDR.
  - **Apple's documentation doesn't say.** Read 2026-10-30, macOS 27.0
    SDK:
    - `NSWorkspace` desktop-image pages and `DesktopImageOptionKey`: only
      scaling, clipping, and fill color.
    - "Enhancing high dynamic range image rendering": how an app shows
      HDR, not the wallpaper.
  - **What the SDK offers a cover, if it ever needs to match HDR:**
    - `kCGImageSourceDecodeRequest` = `kCGImageSourceDecodeToHDR`:
      decodes with the gain map applied.
    - `kIOSurfaceContentHeadroom`: tags a surface's headroom.
    - `CALayer.preferredDynamicRange` (macOS 26+): defaults to
      `.standard`, which per the header tone-maps `contents` with
      headroom above 1.0 down to SDR.
  - **The test photo** (author's iPhone HEIC): 4032 × 3024, Display P3,
    8-bit base, ISO gain map. *Measured:*
    - HDR decode: headroom 4.1.
    - ImageIO's default decode: 8-bit, headroom 1.0, so the default is
      SDR. (The headers don't say; first noted as *recalled*, now
      measured.)
  - **What we saw** with it as wallpaper on the built-in display:
    - It "looks pretty SDR" (*observed* by the author).
    - It was set with Finder's Services › Set Desktop Background, not
      by Phases, so this is macOS's own rendering: what a cover has to
      match.
    - A screen capture matched the default SDR decode by eye
      (*observed*). Weak evidence: `screencapture` output is SDR, so it
      can't show HDR either way (*recalled*).
    - The built-in display's
      `maximumExtendedDynamicRangeColorComponentValue` read 1.2
      (potential 16). A wallpaper using the photo's 4.1 headroom would
      likely push that higher (*recalled*, not calibrated).
  - **Known-HDR control, same day:** the same photo open full screen in
    Preview on the built-in display, its bright areas visibly brighter
    than SDR white (*observed* by the author). So the display does show
    this photo as HDR, and the wallpaper doesn't: the author's
    side-by-side is the evidence for "SDR".
    - The EDR reading stayed at 1.2 with Preview showing HDR. It reports
      headroom available, not headroom in use, so it can't tell the two
      apart. *Measured.*
    - ScreenCaptureKit per-window capture with `.hdrLocalDisplay` (16-bit
      half float, extended linear Display P3) also topped out at SDR
      white for Preview's window (max 1.09, under 0.01% of pixels above
      1.05), the same as the wallpaper window. So it didn't see Preview's
      HDR either and can't settle this. *Measured.* Why not: unknown
      (*guess*: Preview's HDR content isn't in the window's captured
      surface, or per-window capture tone-maps). A whole-display capture
      wasn't tried.
    - A ⌘⇧3 screenshot with Preview showing HDR also came out SDR
      (*observed* by the author).
    - No tool here measures HDR on screen yet; only the eye does.
  - **How macOS does HDR, as far as we know:**
    - SDR is the baseline. Pixel value 1.0 is SDR white, shown below the
      panel's peak; values above 1.0 use the leftover headroom
      (extended dynamic range, EDR). *Recalled.*
    - Content gets the headroom only if it carries values above 1.0
      *and* its layer opts in. `CALayer.preferredDynamicRange` defaults
      to `.standard`, which tone-maps it down to SDR. *Read* in the SDK
      header, 2026-10-30.
    - Screenshots and our captures clip at SDR white, so they can't
      show the difference (*observed*; the clipping explanation is
      *recalled*).
    - So the wallpaper showing SDR fits either of two causes: macOS
      decodes it without the gain map, or its layer doesn't opt in.
      Which one doesn't matter to Phases (*inference*).
  - **Still open:**
    - Whether Phases' `setDesktopImageURL` gets the same rendering as
      Finder: *inference* that it does (macOS draws the wallpaper either
      way), not tested. The new cover will show it: an HDR photo should
      look the same before and after the cover comes off.
- `[L-cover-alpha-later]` **Could the 99% cover go to 100% once the menu
  bar has restyled, and does it matter?** Untested. Measure before
  acting on any of this (author and Mike, 2026-10-30).
  - **Risks,** from `[L-opaque-cover-freezes-menubar]`:
    - An opaque cover might stop the menu bar restyling on Space arrival
      and on macOS's own late restyles `[L-menubar-lazy-restyle]`.
    - Every change would have to drop back to 99% first.
  - **Memory: probably no difference.** The window's backing store is
    the same size either way, and the experiment's covers were already
    marked non-opaque (`isOpaque = false`) at both settings (*recalled*
    AppKit behavior, not measured).
  - **GPU:** blending costs compositing work, which is near zero while
    the desktop is still (*believed*).
- Design questions raised by the experiment (what System Settings
  changes do under the cover, display changes, a switch to turn the cover
  off, same-on-every-Space versus per Space, and how Pause, Quit, and
  Transition: None treat the cover) are tracked as GitHub issues labeled
  "planning" (author, 2026-10-30), not here.
- `[L-first-launch-activation]` First-launch window staying behind:
  promoted to `[Q-launch-activate-refused]` (2026-11-06). The run-by-run
  record is on `experiment/first-launch-activation`.

## Driving and measuring the Mac in tests

How the experiment's UI runs were done, for next time. Test-suite
techniques belong in TESTING.md; these are the ad hoc ones.

- `[L-nswindow-screen-rect]` **`NSWindow(contentRect:…, screen:)` reads
  the rect relative to that screen, not in global coordinates.** A
  harness window meant for the built-in display (global x −1396) landed
  at −2908, off the display, shifted by the screen's own −1512 origin.
  *Measured* 2026-10-30. Pass global coordinates without `screen:`.
- `[L-test-window-height]` **A borderless 240 pt harness window came out
  241 pt tall on two displays** (240 on the third), leaving a 1 pt strip
  of window background: the white line seen across the color-test panes.
  *Measured* 2026-10-30; why macOS added the point is unknown. Fill the
  whole content view, or skip edge rows when comparing pixels.
- `[L-memory-tools]` **Measuring memory:** `footprint -p <pid>` (what
  Activity Monitor shows), `vmmap --summary` (look for "Malloc Large
  (empty)"), `heap` (live objects by class), `malloc_history <pid>
  <address>` and `-allBySize` (who allocated it; needs the app launched
  with `MallocStackLogging=1`, which adds 16–64 MB of its own), `leaks`.
  All work on the installed build because it carries `get-task-allow`.
  Changes were made by clicking the menu bar item's Change Now with real
  mouse events, positions read through System Events.

- `[L-twitch-measurement]` **Measuring a twitch:** record with
  `screencapture -v -V <seconds> -x out.mov` (60 fps, variable frame rate;
  no permission prompt, since the shell already had Screen Recording
  access, 2026-10-29). Per-frame differences with ffmpeg's `tblend`
  difference plus `signalstats` (average luma) over a region with no
  windows find motion; `psnr` between two frames tells a real shift
  (about 26 dB) from noise (about 43 dB). Tiling menu bar crops at 4
  frames per second shows restyle timing. *Verified* 2026-10-30.
  The recording only adds frames when the screen changes (a few per
  second while still, up to 60 during motion), so a twitch can't fall
  between frames, but frame counts aren't a time base: use the frame
  timestamps. Recording several displays at once starves the encoder;
  record one at a time (`-D<n>`, where 1 is the main display, which isn't
  the same numbering as `NSScreenNumber`).
- `[L-settings-panes]` **Opening System Settings panes directly:**
  `open "x-apple.systempreferences:com.apple.ControlCenter-Settings.extension"`
  (Menu Bar, including "Show menu bar background") and
  `…com.apple.Desktop-Settings.extension` (Desktop & Dock, including Stage
  Manager). Toggle positions depend on where the window lands, so read
  its position with System Events and check a screenshot before
  clicking. Turning Stage Manager on the first time shows an intro sheet
  with its own Turn On button. Verify the result
  (`defaults read com.apple.WindowManager GloballyEnabled` for Stage
  Manager, or a screenshot) and put every setting back after the test.
  *Verified* 2026-10-30.
- `[L-synthetic-clicks]` **Synthetic input that works:** CGEvent clicks
  on a menu bar extra need about 60 ms between mouse down and up, or the
  menu opens but the item doesn't fire. ⌃← and ⌃→ to switch Spaces need
  the Secondary Fn and Numeric Pad flags set along with Control. Read
  the menu bar item's position from accessibility each time; it moves as
  other items come and go. Check what's under the pointer
  (`CGWindowListCopyWindowInfo`) before each click. *Verified*
  2026-10-30. See also "Open here" in ERRATA.md on System Events clicks.
- `[L-cover-check-driving]` **What the 2026-11-03 cover checks needed.**
  - **Change Now's fade starts 0.6–1.15 s after the click** (decode), so
    "⌃→ 0.3 s into the fade" has to be timed from the cover window
    appearing (poll `CGWindowListCopyWindowInfo`), not from the click
    (`[L-swipe-before-cover]`).
  - **Random picks often repeat a Space's current image,** which makes a
    trial uninformative; read the wallpaper first and repeat.
  - **The 30-minute rotation** fired mid-trial at 11:00; pause the
    schedule for the run (Change Now still works) and put it back.
  - **Transition is a segmented picker:** AX radio buttons "None" and
    "Crossfade". Reduce Motion is the `AX_REDUCE_MOTION` checkbox on
    `x-apple.systempreferences:com.apple.Accessibility-Settings.extension?Motion`
    (not the Display pane, macOS 27.2).
  - **The test build asks for location** (its own signature), a prompt
    left unanswered on screen.
  - *Verified* 2026-11-03.
- `[L-no-fullscreen-apps]` Activity Monitor doesn't support full screen
  (it only zooms); use Calendar to test full screen. Author, 2026-10-30.
