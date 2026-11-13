# Phases — Learnings

The short version of what we've found out that doesn't (or doesn't yet)
shape the code on `main`: one entry per finding, a line or three each.
The full record behind every entry (setup, runs, measurements, wrong
turns) is in EXPERIMENTS.md, under the `[X-…]` experiment each entry
names. SPEC.md says what Phases does; ERRATA.md holds the platform
quirks the code works around; TEST-TOOLS.md holds what we know about the
test tools.

- **Sorting test:** does it shape code on `main` right now? Yes → SPEC.md
  or ERRATA.md. No → here, with the record in EXPERIMENTS.md.
- Each entry has a stable `[L-…]` tag, its evidence label (verified,
  observed, or recalled, as the record has it), and its record `[X-…]`.
  The entry here is a summary: before relying on the details, read the
  record.
- A promoted entry stays as a one-line pointer to its `[Q-…]` or `[D-…]`.
- The rules for all of this (evidence labels, promotion and demotion,
  references by tag `[D-refs-by-id]`) are in CLAUDE.md.

## Wallpaper, covers, and the menu bar

A "cover" is a borderless, click-through window just above the desktop
picture `[D-cover-level]`. Measured on macOS 27.2.

- `[L-motion-waits-for-reveal]` **macOS seems to hold its wallpaper-change
  motion until the new wallpaper is first visible.** Measured; the "holds
  until visible" reading is a hypothesis. Record: `[X-persistent-cover]`.
- `[L-opaque-cover-freezes-menubar]` Promoted to `[Q-opaque-cover-freezes-menubar]` (2026-10-31).
- `[L-cover-all-spaces]` **A cover that joins all Spaces shows on every
  Space and in Mission Control, and slides with each Space like a real
  wallpaper.** Observed; setting the real wallpaper on arrival worked
  every time (verified). Record: `[X-persistent-cover]`.
- `[L-lockscreen-uses-real-wallpaper]` **The lock screen and login window
  show the real wallpaper, never an app's drawing.** Verified by the
  author. Record: `[X-persistent-cover]`.
- `[L-login-dims-wallpaper]` **At logout macOS redraws the wallpaper,
  slightly darkened, with a twitch.** Observed; not checked on `main`.
  Record: `[X-persistent-cover]`.
- `[L-desktop-through-cover]` **Desktop icons, widgets, the desktop menu,
  and click-to-show-desktop all work through a cover.** Observed.
  Record: `[X-persistent-cover]`.
- `[L-outside-change-hidden]` **A wallpaper set by anything else while a
  cover is up is hidden by the cover.** Observed. Record:
  `[X-persistent-cover]`.
- `[L-cover-memory]` **One full-screen cover image cost about 23 MB, held
  about three times over, and the spike leaked on every change.**
  Measured. Fixed later; see `[X-memory]`. Record: `[X-persistent-cover]`.
- `[L-menubar-lazy-restyle]` **macOS sometimes leaves menu bar text the
  wrong colour with no cover involved; a click in the menu bar corrects
  it.** Observed. Rule this out before blaming Phases. Record:
  `[X-persistent-cover]`.
- `[L-cover-three-displays]` **The 99% cover held up on three displays:**
  no twitch, menu bar tracked each display, Spaces synced on arrival.
  Measured/observed. Record one display at a time for twitch checks.
  Record: `[X-persistent-cover]`.
- `[L-cover-own-space]` **A cover that stays on its own Space can be
  removed unseen when you leave it.** Verified. Record:
  `[X-persistent-cover]`.
- `[L-space-notify-after-swipe]` Promoted to `[Q-space-notify-after-swipe]` (2026-10-31).
- `[L-space-leave-mid-fade]` **Leaving a Space mid-fade sends the change
  to the Space you arrive on.** Verified, two runs. Draft 33 holds the
  cover and sets on return instead `[D-change-stays-on-its-space]`.
  Record: `[X-persistent-cover]`.
- `[L-swipe-set-race]` Promoted to `[Q-set-target-decided-late]` (2026-11-03).
- `[L-swipe-set-read]` **Reading the wallpaper just before a set doesn't
  predict which Space the set reaches.** Falsified hypothesis, 16 trials.
  Record: `[X-set-target-read]`.
- `[L-misfire-not-seen]` **With `[D-reset-on-quick-return]` in, the
  misfire didn't happen in 24 trials** (before: 3 in 19). Measured;
  unexplained, since the change shouldn't affect where a set lands.
  Record: `[X-set-target-read]`.
- `[L-swipe-before-cover]` **A swipe that starts before the cover appears
  takes the change with it to the new Space.** Observed, two runs.
  Record: `[X-set-target-read]`.
- `[L-backdrop-private-store]` **Backdrop puts video on the lock screen
  through macOS's private wallpaper store.** From Cindori's support
  pages, not inspected. Rejected for Phases: no private operations
  `[D-aerials-untouched]`. Record: EXPERIMENTS.md "Notes outside any
  experiment".
- `[L-cover-settle-delay]` **Before draft 33, the cover came off 1.5 s
  after the set, clearing macOS's motion at 0.55–0.65 s; 0.5 s brought the
  twitch back.** Replaced by `[D-persistent-cover]`. Record:
  `[X-cover-settle]`.
- `[L-twitch-returns]` **On macOS 27.2 (draft 22) the twitch came back
  because the 0.5 s settle removed the cover just before macOS's own
  motion; the fix was the 1.5 s delay.** Measured from a frame-by-frame
  recording; that 27.2 slowed wallpaper changes is unconfirmed. Record:
  `[X-cover-settle]` "The twitch returns".

## Memory

From `[X-memory]` unless noted: macOS 27.2, two or three displays.

- `[L-main-memory]` **`main` at 179 MB with the window closed was mostly
  crossfade images plus the window's lasting cost.** Measured, with a
  same-day correction about the grid's share. Record: `[X-memory]`.
- `[L-mem-timeline]` **Footprint rose and fell with crossfades; not a
  steady leak.** Measured; `leaks` found none. Record: `[X-memory]`.
- `[L-mem-cover-windows-freed]` **`main`'s cover windows were freed after
  each fade.** Measured. Record: `[X-memory]`.
- `[L-mem-ca-copy]` **Core Animation kept its own full-screen copy of each
  cover image, outliving the window.** Measured. Record: `[X-memory]`.
- `[L-mem-ca-copy-test]` Promoted to `[Q-cover-image-copied]` (2026-10-30).
- `[L-mem-iosurface-color]` Promoted to `[Q-iosurface-color-tag]` (2026-10-30).
- `[L-mem-pressure-relief]` **`malloc_zone_pressure_relief` released
  nothing.** Measured, three rounds; runs vary widely. Record:
  `[X-memory]`.
- `[L-mem-no-upscale]` **`loadImage` never scales an image up.** Measured.
  Record: `[X-memory]`.
- `[L-mem-freed-held]` **Freed full-screen buffers stayed in the process
  for minutes and counted in `footprint`.** Measured; the allocator
  explanation is recalled. Record: `[X-memory]`.
- `[L-mem-decode]` **Each cover also decoded the file at full size first:
  a peak, purged within 40 s.** Measured. Record: `[X-memory]`.
- `[L-mem-window]` **Opening the window once added about 25 MB that stayed
  after closing.** Measured; later corrected in `[L-mem-fix-runs]`.
  Record: `[X-memory]`.
- `[L-mem-thumbnails]` **Thumbnails are small (4–9 MB for 22 images).**
  Measured. Record: `[X-memory]`.
- `[L-mem-reconcile]` **The mechanisms above account for the earlier
  figures.** Inference. Record: `[X-memory]`.
- `[L-mem-fix-ideas]` **The agreed fix order: tagged IOSurface covers,
  decode once, release the grid, measure ten changes per run.** Record:
  `[X-memory]`.
- `[L-mem-fix-runs]` **The fix held covers flat (2–3 MB over ten
  changes); the window still failed its check, and the grid isn't most
  of the window's cost.** Measured. Record: `[X-memory]`.
- `[L-mem-draft33-runs]` **Draft 33's persistent covers passed every
  `[D-memory-protocol]` check, the window just barely.** Measured.
  Record: `[X-memory]`.

## Sidebar rows

- `[L-tint-on-highlight]` Promoted to `[Q-tint-on-highlight]` (2026-11-06).
- `[L-background-prominence-mac-list]` Promoted to `[Q-tint-on-highlight]` (2026-11-06).
- `[L-row-styles-on-highlight]` **On the selection highlight, hierarchical
  styles and the row's Label icon turn white; `.multicolor` and explicit
  colours don't adapt.** Verified, screenshots. Record:
  `[X-active-badge-highlight]`.
- `[L-row-own-selection]` **Telling the row it's selected works, but the
  accent highlight also needs the sidebar to have focus.** Verified.
  Record: `[X-active-badge-highlight]`.
- `[L-row-selection-focus]` Promoted to `[Q-tint-on-highlight]` (2026-11-06).

## Pause banner

- `[L-pause-banner-inset]` **A top `.safeAreaInset` banner seemed to shift
  the window and stop following the pause.** Observed; its inset
  hypothesis was later refuted. Record: `[X-pause-banner-shift]`.
- `[L-pause-banner-runs]` **The UI tests didn't reproduce the author's
  shift; toolbar room arrives about 0.12 s after the first layout.**
  Verified. A flaky menu bar click led to a driver retry. Record:
  `[X-pause-banner-shift]`.
- `[L-pause-banner-stack-still-shifts]` **Moving the banner into a stack
  didn't fix the shift; the sidebar moved too.** Observed. Record:
  `[X-pause-banner-shift]`.
- `[L-pause-banner-above-window]` **The columns were placed above the
  window while scroll positions were normal.** Verified from the log.
  Record: `[X-pause-banner-shift]`.
- `[L-pause-banner-rigid-split]` Promoted to
  `[Q-fixed-size-text-rigid-split]` (2026-11-07). Record:
  `[X-pause-banner-shift]`.

## Notification clicks

- `[L-notice-click-launches-copy]` **Under development, a click on the
  pause notification can launch a second, differently registered copy
  of Phases, because `usernoted` brings the app forward by path.**
  Verified. A cold-launch click needs `FirstLaunchWindow.open`. Test
  notifications from the DerivedData build with stale registrations
  cleared. Record: `[X-notice-click]`.

## UI mockup (issues #2, #3, #26, #27)

- `[L-classic-mac-layout]` **Old-style Mac layouts were tried and
  dropped** in favour of modern macOS conventions (author, 2026-11-09).
  Record: `[X-ui-mockup]`.
- `[L-toolbar-items-crash]` **SwiftUI toolbar items crashed the window on
  open, likely colliding with `WindowLayoutConfigurator`'s own toolbar.**
  Observed; the cause is a hypothesis. Record: `[X-ui-mockup]`.
- `[L-mock-known-displays]` **The known-displays list grows without
  bound;** show a disconnected display only when the phase gives it
  images. Observed. Record: `[X-ui-mockup]`.

## Other investigations

- `[L-store-watch]` **Watching the wallpaper store hears System Settings
  picks within about 0.3 s.** Verified, one display. Promoted to
  `[Q-wallpaper-store]` (2026-11-06). Record: `[X-wallpaper-store-watch]`.
- `[L-new-space-pauses]` **A new Space's store entries are copies, which
  read as outside changes.** Verified. Promoted to
  `[Q-new-space-copies-entry]` (2026-11-07). Record:
  `[X-new-space-pauses]`.
- `[L-reopen-event]` **A menu bar accessory gets the reopen call; the menu
  bar icon's view can open the window in every case.** Verified. Promoted
  to `[Q-reopen-ignores-closed-window]` (2026-11-03). Also found: the
  harness's newest-build pick was broken (fixed). Two early test failures
  are unexplained. Record: `[X-reopen-window]`.
- `[L-menubar-launcher-setting]` **A Phases launched by Bitrig follows
  Bitrig's switch in System Settings → Menu Bar.** Verified by the
  author; why is a hypothesis. If an icon is missing, check the launching
  app's switch. Record: `[X-menubar-launcher-setting]`.
- `[L-menubar-overflow]` **On macOS 27.2 a crowded menu bar hides Phases'
  icon behind a chevron, still reachable; macOS 26 untested.** Observed.
  The harness's refusals were timing, fixed with a 2 s recheck. Record:
  `[X-menubar-overflow]`.
- `[L-hdr-wallpaper]` **macOS shows an HDR photo as wallpaper in SDR.**
  Observed by the author against a known-HDR control; no tool here
  measures HDR on screen. Record: `[X-hdr-wallpaper]`.
- `[L-first-launch-activation]` Promoted to `[Q-launch-activate-refused]`
  (2026-11-06). Record: `[X-first-launch-activation]`.

## Photos library (issue #33)

- `[L-photos-x0-paths]` **Not sandboxed, every way of finding home
  agrees,** and the wallpaper store is readable through
  `homeDirectoryForCurrentUser`. Verified. The sandboxed comparison is
  round B. Record: `[X-33-photokit]`.
- `[L-photos-x1-permission]` **The Photos prompt worked from the probe
  launch** (not sandboxed). Verified. Whether a new build asks again was
  untested in round A. Record: `[X-33-photokit]`.
- `[L-photos-x2-albums]` **PhotoKit lists the author's albums and folders
  of albums in sidebar order, nested,** plus shared and smart albums.
  Verified. Two albums share a name, so save an album by ID. Record:
  `[X-33-photokit]`.
- `[L-photos-x3-download]` **iCloud-only photos fail fast offline and
  download quickly online.** Verified. Open: whether a download leaves the
  photo local in Photos. Record: `[X-33-photokit]`.
- `[L-photos-x4-cache-wallpaper]` **A file in `~/Library/Caches` works as
  a wallpaper** (not sandboxed). Verified by the API, and on screen by the
  author. Record: `[X-33-photokit]`.
- `[L-photos-x5-observer]` **The change observer fires while Phases is in
  the background.** Verified. Record: `[X-33-photokit]`.
- `[L-photos-x6-ids]` **First record of IDs saved** (10 local IDs plus
  cloud IDs). No evidence label in the record; comparing across builds
  and the sandbox is round B. Record: `[X-33-photokit]`.
- `[L-photos-album-order]` **The default fetch follows the album's own
  order.** Verified; the author confirmed the first list matches the album
  in Photos. Record: `[X-33-photokit]`.
- `[L-sandbox-team-needed]` **Bitrig won't build the Photos or the
  wallpaper-store entitlement without a development team.** Verified (three
  builds, one entitlement set each). Record: `[X-33-sandbox]`.
- `[L-sandbox-x0-paths]` **In the sandbox, `homeDirectoryForCurrentUser`
  and `NSHomeDirectory()` both point into the container;** the wallpaper
  store can't be read either way. Verified. Record: `[X-33-sandbox]`.
- `[L-sandbox-prefs-move]` **The first sandboxed launch moved Phases'
  preferences into the container.** Verified (compared against a backup);
  the effect on the TESTING.md `defaults write` command is inferred, not
  tried. Record: `[X-33-sandbox]`.
- `[L-sandbox-x1-no-entitlement]` **Without the Photos entitlement, the
  sandboxed build still got a Photos prompt.** Verified (TCC log).
  Corrected 2026-11-12 by Claude. Record: `[X-33-sandbox]`.
- `[L-photos-new-build-asks]` **A new build asks for Photos again.**
  Verified (TCC log), for one rebuild that also added the sandbox. Record:
  `[X-33-sandbox]`.
- `[L-sandbox-photos-works]` **The sandbox-only build reads Photos.**
  Verified for this ad-hoc-signed Debug build; how the earlier prompt came
  to be allowed is not known. Record: `[X-33-sandbox]`.
- `[L-photos-ids-stable]` **Photo IDs held across builds and the
  sandbox.** Verified. Record: `[X-33-sandbox]`.
- `[L-sandbox-x4-container-wallpaper]` **A sandboxed Phases can set a file
  in its container as the wallpaper, and put back one outside it.**
  Verified by the API, and on screen by the author. Record:
  `[X-33-sandbox]`.
- `[L-photos-grant-needs-relaunch]` **Allowing Phases in System Settings ›
  Photos didn't reach a running Phases; a relaunch did.** Observed once;
  why is a hypothesis (perhaps `[L-photos-grant-per-build]`). Record:
  `[X-33-photos-checks]`.
- `[L-photos-grant-per-build]` **Each Bitrig build loses the Photos
  grant:** ad hoc signing pins it to the build's cdhash. Verified (tccd
  log). After a new build, allow Photos again through Add Photos Album….
  Record: `[X-33-photos-checks]`.
- `[L-photos-offline-check]` **Offline, the fallback worked, but kept
  landing on the same photo.** Verified (diagnostics log). From draft 54
  In order's fallback skips what the display already shows. Record:
  `[X-33-photos-checks]`.
- `[L-photos-formats-check]` **Edited, Live, ProRAW+HEIC, and DSLR RAW
  photos all showed the way Photos shows them.** Observed by the author.
  Record: `[X-33-photos-checks]`.
- `[L-photos-deleted-album-race]` **A photo from an album being deleted
  was set as the wallpaper.** Verified (log); a race is a hypothesis.
  Phases now rereads its Photos sources just before showing. Record:
  `[X-33-photos-checks]`.

## Image sources (issue #33, merge 1)

- `[L-nas-bookmark-rename]` **A security-scoped bookmark to a folder on a
  file server doesn't follow a rename; one to a local folder does.**
  Verified by the author, on screen; why is recalled, not tested. No code
  change. Record: `[X-33-image-sources]`.
- `[L-closed-menu-stale]` **A closed menu's items, read through AX, keep
  the title and enabled state from when the menu last opened.** Verified by
  `undoPutsBackASourceRemovedWithTheMouse` (two runs) and by the author;
  why is recalled, and the record has a same-day correction. Promoted to
  `[Q-undo-menu-ax]` (2026-11-12). Record: `[X-33-image-sources]`.

## Open questions

- `[L-cover-alpha-later]` **Could the 99% cover go to 100% once the menu
  bar has restyled, and does it matter?** Untested; measure before acting.
  Record: EXPERIMENTS.md "Still open".
- Design questions raised by the persistent-cover experiment are GitHub
  issues labeled "planning", not here.

## Test tools

Findings about the test tools themselves (`[L-nswindow-screen-rect]`,
`[L-test-window-height]`, `[L-memory-tools]`, `[L-twitch-measurement]`,
`[L-settings-panes]`, `[L-synthetic-clicks]`, `[L-cover-check-driving]`,
`[L-no-fullscreen-apps]`) are in TEST-TOOLS.md "Driving and measuring
the Mac in tests".
