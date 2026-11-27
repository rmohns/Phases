# `[X-persistent-cover]` Keeping a cover up between changes

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


- **Question:** can a cover stay over the desktop all the time, so
  macOS's wallpaper-change motion never shows, and what does that break?
- **When, on what:** 2026-10-30 to 2026-10-31, macOS 27.2; one built-in
  display, then three displays.
- **Branch:** `spike/persistent-cover`, tag
  `archive/spike/persistent-cover`. Its own write-up,
  `docs/X-PERSISTENT-COVER.md`, is in that tag only.
- **Outcome:** became draft 33's persistent cover `[D-persistent-cover]`
  (tag `archive/feature/persistent-cover-transitions`). Promoted:
  `[Q-opaque-cover-freezes-menubar]`, `[Q-space-notify-after-swipe]`.
- **Findings:** `[L-motion-waits-for-reveal]`, `[L-cover-all-spaces]`,
  `[L-lockscreen-uses-real-wallpaper]`, `[L-login-dims-wallpaper]`,
  `[L-desktop-through-cover]`, `[L-outside-change-hidden]`,
  `[L-cover-memory]`, `[L-menubar-lazy-restyle]`,
  `[L-cover-three-displays]`, `[L-cover-own-space]`,
  `[L-space-leave-mid-fade]`; still open: `[L-cover-alpha-later]` (under
  "Open questions" below).

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
