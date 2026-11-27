# Phases — History

What each spec draft changed, oldest first: features, changes, bug fixes,
and test tooling. Work that landed between two drafts is listed under the
draft it landed on. Doc-process and rules changes are left out.

*Sources:* SPEC.md's title in git history (every draft from 1 to 64 is on
`main` except 25–27, which landed in one merge, and 51, which is only on an
abandoned branch), commit messages, ERRATA.md "Regressions found so far",
and LEARNINGS.md. Compiled by Claude from those records, 2026-11-27. These
are summaries of the records, *recalled* from them, not re-tested.

**Key:** **New** feature · **Changed** behavior · **Fix** bug fix ·
**Tests** test tooling

## October 2026

### Draft 1 (2026-10-25, `c2eaeab`)
- **New:** "Wallpaper Scheduler": a menu bar app running a list of phases,
  each starting at a clock time, dawn, or dusk (with offset), or Always.
  Images from one folder, Random or In order, optional rotation, per-display
  images, catch-up after sleep, launch at login.

### Draft 2 (2026-10-25, `570473c`)
- **Changed:** renamed to Phases; a separate Schedule window.
- **New:** Light/Dark Mode condition on phases; subfolder scanning.

### Draft 3 (2026-10-25, `4e86957`)
- **New:** restore the original wallpaper on quit (skipped at logout,
  restart, shutdown); location Update Now.
- **Fix:** long folder names truncated badly in Settings.

### Draft 4 (2026-10-26, `23d8129`)
- **New:** crossfade transition, using a cover window over the desktop.

### Draft 4.1 (2026-10-26, `b6526b2`)
- **Fix:** set the wallpaper only once the cover is on screen; no cover
  resize or appear animation.

### Draft 5 (2026-10-26, `505d2da`)
- **Fix:** crossfade flashed and twitched; now the new image fades in and
  the wallpaper is set at the end `[D-fade-in]`. Draft 4.1's workarounds
  removed.
- **Changed:** only Quit keeps a keyboard shortcut.

### Draft 6 (2026-10-27, `3c76bea`)
- **Changed:** one Phases window, Settings in its sidebar.
- **New:** image selections per display.

### Draft 7 (2026-10-27, `f7b1272`)
- **New:** app and menu bar icons; branding panel; App and Phases sidebar
  sections.
- **Changed:** compact menu status; Quit moves into the window.

### Draft 8 (2026-10-27, `160ce87`)
- **Changed:** legible menu bar icon; branding panel shows the wallpaper
  and scrolls with the sidebar.

### Draft 9 (2026-10-27, `e0919c0`)
- **Changed:** branding panel gets a bottom gradient (was a flat dim) and a
  tagline.

### Draft 10 (2026-10-27, `17ca9a3`)
- **Changed:** two-line tagline, 52 pt icon, fixed text sizes; sidebar
  width limited to 220–320 pt.
- **Fix:** tagline cut off after its first line.

### Draft 11 (2026-10-28, `95237de`)
- **Changed:** sidebar minimum 240 pt.

### Draft 12 (2026-10-28, `cb78485`)
- Design decisions get `[D-…]` tags, matched in code comments.

### Draft 13 (2026-10-28, `6a7ce87`)
- **New:** Restore original wallpaper on quit becomes a preference.
- **Fix:** dragging the divider collapsed the sidebar for good; the sidebar
  can no longer be hidden.

### Draft 14 (2026-10-28, `3c1242f`)
- **Fix:** sidebar − button stayed disabled; +/− bar is its own view.

### Draft 15 (2026-10-28, `83b5c9d`)
- **Changed:** +/− bar styled like System Settings' Login Items.

### Draft 16 (2026-10-28, `b7d260b`)
- **Fix:** deleting a phase selects the next one, not the first.

### Draft 17 (2026-10-28, `c34d385`)
- **Changed:** accessibility labels on sidebar + and −.

### Drafts 18–19 (2026-10-28, `9cee4fd`, `6e44bf0`)
- **Fix:** the Name field had focus with its text selected on open, so a
  keypress renamed the phase. Draft 18's fix failed; draft 19 focuses the
  sidebar a pass after the window appears.

### Draft 20 (2026-10-28, `7800da1`)
- **Fix:** Tab skipped off-screen thumbnails; the grid is one Tab stop with
  an arrow-key cursor.

### Draft 21 (2026-10-28, `b19efbf`)
- **Tests:** unit tests, as a Swift package `[D-tests-unhosted]`.
- **Changed:** tall unified toolbar; branding panel aligned with the
  selection highlight and traffic lights.
- **Fix:** sidebar limits lost and short title bar after the toolbar work
  (one ordered window helper).

### Draft 22 (2026-10-28, `23c768a`)
- **Fix:** crossfade twitch returned on macOS 27.2; cover held 1.5 s.
- **Fix:** hiding the Dock or toggling the menu bar background picked a new
  image; screen changes now just run the normal check.

### Draft 23 (2026-10-28, `b7af797`)
- **New:** version, spec draft, and build time in Settings.
- **Fix:** sidebar limits lost again (SwiftUI rewrites them); a watcher
  puts them back.
- **Tests:** built-in diagnostic logging, off by default
  `[D-diagnostics-switch]`.

### Draft 24 (2026-10-28, `2b31671`)
- Platform quirks move to ERRATA.md with `[Q-…]` tags. No app change.

### Drafts 25–27 (2026-10-29, merged in `f6bd7a6`)
- **New:** Dock icon and app menu while the window is open; Quit asks to
  confirm.
- **Changed:** Quit leaves the window for the app menu; no File menu;
  the one-item View menu stays (removing it failed).

### Draft 28 (2026-10-29, `a4fa0d3`)
- **Changed:** Open Phases… brings the window to the current Space, closed
  or open (several approaches failed first).

### Draft 29 (2026-10-29, `ac38c83`)
- **Tests:** launch argument to skip the location prompt.

### Draft 30 (2026-10-29, `e719b77`)
- **Changed:** closing the window hands focus to an app on the current
  Space.

### Draft 31 (2026-10-29, `9593cc8`)
- **Tests:** UI regression tests driving Phases through Accessibility, a
  test mode with its own settings `[D-ui-test-runner]`; TESTING.md.
- **Fix:** a long folder name squeezed Choose… to a sliver (found by the UI
  tests).

### Draft 32 (2026-10-30, `ecd7f70`)
- **Fix:** memory grew with each crossfade; covers now draw into an
  IOSurface `[D-cover-iosurface]`, and closing the window frees the grid.
  Ten changes cost 2–3 MB (was about 200).

## November 2026

### Draft 33 (2026-11-03, `9ea26db`)
- **Changed:** the crossfade cover stays up while its Space shows, belongs
  to its Space, and follows display changes `[D-persistent-cover]`.
- **Tests:** hands-on checks split from unit tests `[D-hands-on-checks]`;
  cover and memory checks.

### Draft 34 (2026-11-03, `7b22353`)
- **New:** launching Phases while it runs shows the window (#13).
- **Tests:** UI tests recheck menu bar ownership before refusing a click.

### Draft 35 (2026-11-04, `1df1652`)
- **New:** symlinks and Finder aliases followed in the image folder (#17).

### Draft 36 (2026-11-05, `b7ea773`)
- **New:** dawn/dusk phases with no location are flagged in the sidebar
  (#16).
- **Fix:** Random could repeat the image already showing (#10).
- **Tests:** `phases-drive` command; all input goes through one driver
  `[D-input-driver]`.

### Draft 37 (2026-11-06, `4f4f075`)
- **New:** a wallpaper picked in System Settings pauses Phases, with a
  notification and a badge on the menu bar icon (#5)
  `[D-outside-change-pauses]`; Settings gets a schedule switch.

### Draft 38 (2026-11-06, `beeab2d`)
- **New:** minimum window size (#12).

### Draft 39 (2026-11-06, `55bcd1a`)
- **New:** the window opens on first launch (#14).

### Draft 40 (2026-11-06, `8029498`)
- **Changed:** new phases start at the current time (#25).

### Draft 41 (2026-11-06, `a210f13`)
- **New:** duplicate a phase; phase action menu and context menu (#24).

### Draft 42 (2026-11-06, `54391ce`)
- **New:** turn a phase off without deleting it (#21).

### Draft 43 (2026-11-06, `65971eb`)
- **New:** new users start with Morning, Afternoon, and Evening.

### Draft 44 (2026-11-06, `07771b0`)
- **Fix:** the first-launch window stayed behind other apps (#14).

### Draft 45 (2026-11-06, `08eaa77`)
- **Fix:** "Active" unreadable on the selection highlight; warning triangle
  dropped (#22).

### Draft 46 (2026-11-06, `1afd6f1`)
- **New:** brand panel easter egg `[D-brand-egg]` (#23).

### Draft 47 (2026-11-06, `aa5991b`)
- **Changed:** version 0.1; the build number is the spec draft.

### Draft 48 (2026-11-07, `00aa9b9`)
- **Fix:** a new Space or full-screen app paused Phases as if a wallpaper
  had been picked (#29).

### Draft 49 (2026-11-07, `a5f593b`)
- **New:** pause banner at the top of the window, with Resume
  `[D-window-pause-banner]`.
- **Fix:** opening the window while paused drew everything shifted up
  (#30).

### Draft 50 (2026-11-08, `92c376a`)
- **New:** clicking the pause notification opens the window.
- *2026-11-09:* drafts 45–50 were undone by an accidental restore
  (`713ca49`) and put back on 2026-11-12 (`84997cd`).

### Draft 51 (2026-11-09, `be659ce`, never landed)
- Proposed a compact phase editor, display tabs, image source list, and a
  Settings cleanup; spec only, on the abandoned `feature/compact-editor`.
  Parts came back in drafts 52, 60, and 63.

### Draft 52 (2026-11-12, `a5d06e9`)
- **New:** several image sources (folders), with an Image Sources list,
  drag in from Finder, reorder, undo removal `[D-image-sources]` (#33).

### Draft 53 (2026-11-13, `a93c301`)
- **Changed:** In order remembers the last image it showed and steps from
  there `[D-in-order-remembers]`.

### Draft 54 (2026-11-13, `1148bed`)
- **New:** Photos albums as image sources, fetched ahead and cached (#33).
- **Tests:** fake Photos library for the UI tests; Photos hands-on checks.

### Draft 55 (2026-11-14, `06dc3e7`)
- **Fix:** a crash while waiting on a photo left the old wallpaper until the
  next change; the record is saved only once a change shows
  `[D-record-after-wait]` (#36).

### Draft 56 (2026-11-14, `775cd7d`)
- **Changed:** the Reduce Motion note shows only when it's on, dims
  Transition, and offers Open Motion Settings…; layered app icon.

### Draft 57 (2026-11-14, `20f39e5`)
- **Changed:** the easter egg reverts after 30 seconds or a wallpaper
  change.

### Draft 58 (2026-11-22, `d955ce5`)
- **Changed:** runs in the macOS App Sandbox `[D-sandbox-entitlements]`
  (#19); displays Phases can't check are left alone at Quit.
- **Tests:** Sandbox hands-on checks.

### Draft 59 (2026-11-22, `524eb58`)
- **Changed:** Xcode project `[D-xcode-project]`; bundle ID
  `com.robertmohns.phases`, settings moved over once.

### Draft 60 (2026-11-24, `514da3f`)
- **Changed:** Settings cleanup: Pause wallpaper changes switch, Launch &
  Quit section, new order.
- **New:** low-memory note on Transition; location privacy note; memory use
  in About.
- **Tests:** launch argument to fake the Mac's memory size.

### Draft 61 (2026-11-24, `1dcded5`)
- **Changed:** pause banner only for an outside-change pause; the pause
  switch is disabled while it shows.
- **Tests:** unit tests run with `bitrig test`; UI driver picks the newest
  build by folder time and checks its build number.

### Draft 62 (2026-11-24, `cc70059`)
- **Fix:** UI tests failed on the sandboxed build; Debug builds can read one
  test folder `[D-debug-test-folder]`.
- **Tests:** UI driver presses modifier keys as real keys (stuck Shift
  fixed); synthetic clicks sent with click state 1
  `[D-input-click-state]`.

### Draft 63 (2026-11-25, `bbf9b1e`)
- **Changed:** phase editor redesigned: name row with On/Off, sentence-style
  Starts, display tabs; display sharing moves into each phase. Polished in
  `bb7df2c` (#27).

### Draft 64 (2026-11-26, `c163148`)
- **New:** collapsible folder and album headings in the image grid, saved
  across launches `[D-grid-collapse]` (#37).
- **Fix** (2026-11-27, `d0391dd`): Quit restored a still image over an
  Aerial; each display is judged by its own store entries
  `[Q-store-kind-lastset]` (#43).
