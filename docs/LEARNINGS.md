# Phases — Learnings

What we've found out along the way that doesn't (or doesn't yet) shape the
shipping code. SPEC.md says what Phases does; ERRATA.md holds the platform
quirks the code works around. This file keeps everything else we learned,
so it isn't lost when an experiment branch is deleted or a design goes
another way.

- **Sorting test:** does it shape code on `main` right now? Yes → SPEC.md
  or ERRATA.md. No → here.
- Each entry has a stable `[L-…]` tag, a date and macOS version, and says
  how we know: **verified** (tested or measured, by whom), **observed**
  (seen, not measured or repeated), or **recalled** (believed from past
  knowledge, not tested here). Hypotheses are labeled as such.
- Entries cite the `[D-…]` and `[Q-…]` tags they relate to, and where the
  evidence lives (an experiment doc, a branch).
- **Promotion:** when a learning starts shaping code, it moves to ERRATA.md
  as a `[Q-…]` entry (or to SPEC.md as a decision) in the same change, and
  leaves a one-line pointer here: "Promoted to `[Q-…]` (date)."
- **Demotion:** when the code a `[Q-…]` entry shapes is removed from
  `main`, the entry moves here in the same change, keeping its `[Q-…]` tag
  alongside a new `[L-…]` tag so old comments and commits still find it,
  and leaves a one-line pointer in ERRATA.md: "Demoted to `[L-…]` (date)."
  ERRATA.md holds only quirks the current code depends on. ERRATA.md
  carries a deliberate copy of this rule; keep the two in sync.
- Keep corrections and history; don't silently rewrite an entry.
- Cross-references use a tag or a quoted section title, never a section
  number `[D-refs-by-id]`.

## Wallpaper, covers, and the menu bar

Source for this section unless noted: the persistent-cover experiment,
2026-10-30, macOS 27.2, one built-in display (3024 × 1964); branch
`spike/persistent-cover`, `docs/X-PERSISTENT-COVER.md`. A "cover" is a
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
- `[L-opaque-cover-freezes-menubar]` **A fully opaque full-screen cover
  stops the menu bar restyling for new wallpapers; a 99% opaque one
  doesn't.** *Measured* from recordings.
  - **100% opaque:** menu bar text stayed one color through every change
    (white in one run, black in another). With "Show menu bar
    background" on, the background kept an earlier image's color through
    changes, app switches, and 15 s.
  - **Control,** without the persistent cover: restyled normally.
  - **99% opaque:** text and background restyled promptly for every
    change, with or without the background setting. No twitch: frames
    before and after each fade matched at noise level (43 dB).
  - **Related:** refines `[Q-menubar-bg-follows-window]` and
    `[Q-menubar-reads-wallpaper]`; possibly related to
    `[Q-menubar-restyle-on-app-switch]`. Fits
    `[L-motion-waits-for-reveal]`: macOS may treat a fully covered
    desktop as not visible.
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
- `[L-backdrop-private-store]` **Backdrop (Cindori) puts video on the
  lock screen by registering entries in macOS's private wallpaper store,**
  `~/Library/Application Support/com.apple.wallpaper/Store/aerials/manifest/entries.json`,
  so macOS plays them like Aerials. Cleanup after uninstalling means
  deleting that file and restarting. From Cindori's own support pages,
  2026-10-29; not inspected. **Rejected for Phases** (author, 2026-10-29):
  no private macOS operations, consistent with `[D-aerials-untouched]`.

## Memory

Source for this section: branch `investigate/memory`, 2026-10-30,
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
  = Release of `fix/cover-memory` (code as of `18130ee`), run from its
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

## Open questions

- `[L-menubar-overflow]` **Is Phases' menu bar icon hidden when the menu
  bar runs out of room?** On macOS 27.2, no: a chevron reveals it. Still
  open for macOS 26. Tracked as GitHub issue #11; no action for now.
  - **How it came up:** a UI test run on `fix/cover-memory`, 2026-10-30,
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
- `[L-no-fullscreen-apps]` Activity Monitor doesn't support full screen
  (it only zooms); use Calendar to test full screen. Author, 2026-10-30.
