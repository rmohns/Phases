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
  doesn't.** With the opaque cover, menu bar text stayed one color
  through every change (white in one run, black in another), and with
  "Show menu bar background" on, the background kept an earlier image's
  color through changes, app switches, and 15 s. A control without the
  persistent cover restyled normally. At 99% opacity, text and background
  restyled promptly for every change, with or without the background
  setting, and no twitch showed (frames before and after each fade
  matched at noise level, 43 dB). *Measured* from recordings. Refines
  `[Q-menubar-bg-follows-window]` and `[Q-menubar-reads-wallpaper]`;
  possibly related to `[Q-menubar-restyle-on-app-switch]`. Fits
  `[L-motion-waits-for-reveal]`: macOS may treat a fully covered desktop
  as not visible.
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
- `[L-desktop-through-cover]` **Desktop features work through a cover:**
  icons and widgets draw above it; right-click on the desktop opens
  Finder's desktop menu; "Click wallpaper to show desktop" works; widgets
  turn translucent over it when an app is in front; Calendar in full
  screen and Stage Manager (turned on for the test) behaved normally.
  *Observed.* Quitting Phases removes a cover in a hard cut; a Force Quit
  shows nothing if the real wallpaper underneath matches.
- `[L-outside-change-hidden]` **A wallpaper set by anything else while a
  cover is up is hidden by the cover.** *Observed* (set through System
  Events). A user changing wallpaper in System Settings would see nothing
  happen.
- `[L-cover-memory]` **One full-screen cover image costs about 23 MB at
  3024 × 1964, and the experiment held it about three times** (Core
  Animation, a large malloc buffer, and CG raster data, about 23 MB each).
  Debug build, `footprint`: 23 MB with no cover; 86–93 MB with a cover at
  launch; 102 MB after three changes (window-per-change version), growth
  unexplained. *Measured.* Releasing Phases' own copies once the layer
  has the image might bring it to about one copy (*hypothesis*).
- `[L-backdrop-private-store]` **Backdrop (Cindori) puts video on the
  lock screen by registering entries in macOS's private wallpaper store,**
  `~/Library/Application Support/com.apple.wallpaper/Store/aerials/manifest/entries.json`,
  so macOS plays them like Aerials. Cleanup after uninstalling means
  deleting that file and restarting. From Cindori's own support pages,
  2026-10-29; not inspected. **Rejected for Phases** (author, 2026-10-29):
  no private macOS operations, consistent with `[D-aerials-untouched]`.

## Open questions

- `[L-main-memory]` **The installed Release build of `main` measured
  179 MB with its window closed** (82 MB large mallocs, 54 MB small, 9 MB
  QuickLook thumbnails), against 23 MB for a fresh Debug launch that never
  opened the window. *Measured* 2026-10-30 with `footprint`. Possibly the
  thumbnail grid isn't released when the window closes (*hypothesis*).
  To investigate on its own branch (author, 2026-10-30).

## Driving and measuring the Mac in tests

How the experiment's UI runs were done, for next time. Test-suite
techniques belong in TESTING.md; these are the ad hoc ones.

- `[L-twitch-measurement]` **Measuring a twitch:** record with
  `screencapture -v -V <seconds> -x out.mov` (60 fps, variable frame rate;
  no permission prompt, since the shell already had Screen Recording
  access, 2026-10-29). Per-frame differences with ffmpeg's `tblend`
  difference plus `signalstats` (average luma) over a region with no
  windows find motion; `psnr` between two frames tells a real shift
  (about 26 dB) from noise (about 43 dB). Tiling menu bar crops at 4
  frames per second shows restyle timing. *Verified* 2026-10-30.
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
