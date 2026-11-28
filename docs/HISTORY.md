# Phases — History

What changed on each day of work, oldest first: features, changes, bug
fixes, and test tooling. Each day lists the spec drafts that landed on it;
each item names its draft and commit. Work that landed between two drafts
is listed under the draft it landed on. Doc-process and rules changes are
left out.

**Key:** **New** feature · **Changed** behavior · **Fix** bug fix ·
**Tests** test tooling

## October 2026

### 2026-10-25 · Drafts 1–3
The first version: a menu bar wallpaper scheduler, renamed Phases the same
day and rounded out with appearance conditions and restoring the wallpaper
on quit.
- **New:** "Wallpaper Scheduler": a menu bar app running a list of phases,
  each starting at a clock time, dawn, or dusk (with offset), or Always.
  Images from one folder, Random or In order, optional rotation, per-display
  images, catch-up after sleep, launch at login (draft 1, `c2eaeab`).
- **New:** Light/Dark Mode condition on phases; subfolder scanning
  (draft 2, `570473c`).
- **New:** restore the original wallpaper on quit (skipped at logout,
  restart, shutdown); location Update Now (draft 3, `4e86957`).
- **Changed:** renamed to Phases; a separate Schedule window (draft 2,
  `570473c`).
- **Fix:** long folder names truncated badly in Settings (draft 3,
  `4e86957`).

### 2026-10-26 · Drafts 4–5
Crossfade transitions, and getting them to run without flashing.
- **New:** crossfade transition, using a cover window over the desktop
  (draft 4, `23d8129`).
- **Changed:** only Quit keeps a keyboard shortcut (draft 5, `505d2da`).
- **Fix:** set the wallpaper only once the cover is on screen; no cover
  resize or appear animation (draft 4.1, `b6526b2`).
- **Fix:** crossfade flashed and twitched; now the new image fades in and
  the wallpaper is set at the end `[D-fade-in]`. Draft 4.1's workarounds
  removed (draft 5, `505d2da`).

### 2026-10-27 · Drafts 6–10
One window for everything, and a visual identity: icons and a branding
panel, refined over several drafts.
- **New:** image selections per display (draft 6, `3c76bea`).
- **New:** app and menu bar icons; branding panel; App and Phases sidebar
  sections (draft 7, `f7b1272`).
- **Changed:** one Phases window, Settings in its sidebar (draft 6,
  `3c76bea`).
- **Changed:** compact menu status; Quit moves into the window (draft 7,
  `f7b1272`).
- **Changed:** legible menu bar icon; branding panel shows the wallpaper
  and scrolls with the sidebar (draft 8, `160ce87`).
- **Changed:** branding panel gets a bottom gradient (was a flat dim) and a
  tagline (draft 9, `e0919c0`).
- **Changed:** two-line tagline, 52 pt icon, fixed text sizes; sidebar
  width limited to 220–320 pt (draft 10, `17ca9a3`).
- **Fix:** tagline cut off after its first line (draft 10, `17ca9a3`).

### 2026-10-28 · Drafts 11–24
Paying down UI debt in the sidebar, keyboard focus, and window layout, and
laying groundwork: unit tests, diagnostic logging, and tagged decisions and
quirks.
- **New:** Restore original wallpaper on quit becomes a preference
  (draft 13, `6a7ce87`).
- **New:** version, spec draft, and build time in Settings (draft 23,
  `b7af797`).
- **Changed:** sidebar minimum 240 pt (draft 11, `95237de`).
- **Changed:** +/− bar styled like System Settings' Login Items (draft 15,
  `83b5c9d`).
- **Changed:** accessibility labels on sidebar + and − (draft 17,
  `c34d385`).
- **Changed:** tall unified toolbar; branding panel aligned with the
  selection highlight and traffic lights (draft 21, `b19efbf`).
- **Fix:** dragging the divider collapsed the sidebar for good; the sidebar
  can no longer be hidden (draft 13, `6a7ce87`).
- **Fix:** sidebar − button stayed disabled; +/− bar is its own view
  (draft 14, `3c1242f`).
- **Fix:** deleting a phase selects the next one, not the first (draft 16,
  `b7d260b`).
- **Fix:** the Name field had focus with its text selected on open, so a
  keypress renamed the phase. Draft 18's fix failed; draft 19 focuses the
  sidebar a pass after the window appears (drafts 18–19, `9cee4fd`,
  `6e44bf0`).
- **Fix:** Tab skipped off-screen thumbnails; the grid is one Tab stop with
  an arrow-key cursor (draft 20, `7800da1`).
- **Fix:** sidebar limits lost and short title bar after the toolbar work
  (one ordered window helper) (draft 21, `b19efbf`).
- **Fix:** crossfade twitch returned on macOS 27.2; cover held 1.5 s
  (draft 22, `23c768a`).
- **Fix:** hiding the Dock or toggling the menu bar background picked a new
  image; screen changes now just run the normal check (draft 22,
  `23c768a`).
- **Fix:** sidebar limits lost again (SwiftUI rewrites them); a watcher
  puts them back (draft 23, `b7af797`).
- **Tests:** unit tests, as a Swift package `[D-tests-unhosted]` (draft 21,
  `b19efbf`).
- **Tests:** built-in diagnostic logging, off by default
  `[D-diagnostics-switch]` (draft 23, `b7af797`).
- Design decisions get `[D-…]` tags, matched in code comments (draft 12,
  `cb78485`).
- Platform quirks move to ERRATA.md with `[Q-…]` tags. No app change
  (draft 24, `2b31671`).

### 2026-10-29 · Drafts 25–31
Making Phases behave like a regular Mac app (Dock icon, menus, Quit, and
window focus across Spaces), and the first UI regression tests.
- **New:** Dock icon and app menu while the window is open; Quit asks to
  confirm (drafts 25–27, merged in `f6bd7a6`).
- **Changed:** Quit leaves the window for the app menu; no File menu;
  the one-item View menu stays (removing it failed) (drafts 25–27, merged
  in `f6bd7a6`).
- **Changed:** Open Phases… brings the window to the current Space, closed
  or open (several approaches failed first) (draft 28, `a4fa0d3`).
- **Changed:** closing the window hands focus to an app on the current
  Space (draft 30, `e719b77`).
- **Fix:** a long folder name squeezed Choose… to a sliver (found by the UI
  tests) (draft 31, `9593cc8`).
- **Tests:** launch argument to skip the location prompt (draft 29,
  `ac38c83`).
- **Tests:** UI regression tests driving Phases through Accessibility, a
  test mode with its own settings `[D-ui-test-runner]`; TESTING.md
  (draft 31, `9593cc8`).

### 2026-10-30 · Draft 32
- **Fix:** memory grew with each crossfade; covers now draw into an
  IOSurface `[D-cover-iosurface]`, and closing the window frees the grid.
  Ten changes cost 2–3 MB (was about 200) (draft 32, `ecd7f70`).

## November 2026

### 2026-11-03 · Drafts 33–34
The crossfade cover becomes a lasting window, and hands-on checks split off
from the unit tests.
- **New:** launching Phases while it runs shows the window (#13) (draft 34,
  `7b22353`).
- **Changed:** the crossfade cover stays up while its Space shows, belongs
  to its Space, and follows display changes `[D-persistent-cover]`
  (draft 33, `9ea26db`).
- **Tests:** hands-on checks split from unit tests `[D-hands-on-checks]`;
  cover and memory checks (draft 33, `9ea26db`).
- **Tests:** UI tests recheck menu bar ownership before refusing a click
  (draft 34, `7b22353`).

### 2026-11-04 · Draft 35
- **New:** symlinks and Finder aliases followed in the image folder (#17)
  (draft 35, `1df1652`).

### 2026-11-05 · Draft 36
Small items from the GitHub issue list, and one driver for all test input.
- **New:** dawn/dusk phases with no location are flagged in the sidebar
  (#16) (draft 36, `b7ea773`).
- **Fix:** Random could repeat the image already showing (#10) (draft 36,
  `b7ea773`).
- **Tests:** `phases-drive` command; all input goes through one driver
  `[D-input-driver]` (draft 36, `b7ea773`).

### 2026-11-06 · Drafts 37–47
A long run through the GitHub issue list: pausing when someone picks their
own wallpaper, the first-launch experience, and managing phases.
- **New:** a wallpaper picked in System Settings pauses Phases, with a
  notification and a badge on the menu bar icon (#5)
  `[D-outside-change-pauses]`; Settings gets a schedule switch (draft 37,
  `4f4f075`).
- **New:** minimum window size (#12) (draft 38, `beeab2d`).
- **New:** the window opens on first launch (#14) (draft 39, `55bcd1a`).
- **New:** duplicate a phase; phase action menu and context menu (#24)
  (draft 41, `a210f13`).
- **New:** turn a phase off without deleting it (#21) (draft 42,
  `54391ce`).
- **New:** new users start with Morning, Afternoon, and Evening (draft 43,
  `65971eb`).
- **New:** brand panel easter egg `[D-brand-egg]` (#23) (draft 46,
  `1afd6f1`).
- **Changed:** new phases start at the current time (#25) (draft 40,
  `8029498`).
- **Changed:** version 0.1; the build number is the spec draft (draft 47,
  `aa5991b`).
- **Fix:** the first-launch window stayed behind other apps (#14)
  (draft 44, `07771b0`).
- **Fix:** "Active" unreadable on the selection highlight; warning triangle
  dropped (#22) (draft 45, `08eaa77`).

### 2026-11-07 · Drafts 48–49
Follow-ups to pausing on an outside wallpaper change.
- **New:** pause banner at the top of the window, with Resume
  `[D-window-pause-banner]` (draft 49, `a5f593b`).
- **Fix:** a new Space or full-screen app paused Phases as if a wallpaper
  had been picked (#29) (draft 48, `00aa9b9`).
- **Fix:** opening the window while paused drew everything shifted up
  (#30) (draft 49, `a5f593b`).

### 2026-11-08 · Draft 50
- **New:** clicking the pause notification opens the window (draft 50,
  `92c376a`).

### 2026-11-09 · Draft 51 (never landed)
A setback: an accidental restore, and a proposed redesign that was set
aside.
- Drafts 45–50 were undone by an accidental restore (`713ca49`).
- Draft 51 proposed a compact phase editor, display tabs, image source
  list, and a Settings cleanup; spec only, on the abandoned
  `feature/compact-editor` (draft 51, `be659ce`). Parts came back in
  drafts 52, 60, and 63.

### 2026-11-12 · Draft 52
Recovering the lost drafts, and images from more than one folder.
- **New:** several image sources (folders), with an Image Sources list,
  drag in from Finder, reorder, undo removal `[D-image-sources]` (#33)
  (draft 52, `a5d06e9`).
- Drafts 45–50 put back after the 2026-11-09 restore (`84997cd`).

### 2026-11-13 · Drafts 53–54
More ways to pick images: Photos albums as a source, and In order picks up
where it left off.
- **New:** Photos albums as image sources, fetched ahead and cached (#33)
  (draft 54, `1148bed`).
- **Changed:** In order remembers the last image it showed and steps from
  there `[D-in-order-remembers]` (draft 53, `a93c301`).
- **Tests:** fake Photos library for the UI tests; Photos hands-on checks
  (draft 54, `1148bed`).

### 2026-11-14 · Drafts 55–57
Polish: a crash fix and smaller UI refinements.
- **Changed:** the Reduce Motion note shows only when it's on, dims
  Transition, and offers Open Motion Settings…; layered app icon
  (draft 56, `775cd7d`).
- **Changed:** the easter egg reverts after 30 seconds or a wallpaper
  change (draft 57, `20f39e5`).
- **Fix:** a crash while waiting on a photo left the old wallpaper until the
  next change; the record is saved only once a change shows
  `[D-record-after-wait]` (#36) (draft 55, `06dc3e7`).

### 2026-11-22 · Drafts 58–59
Platform groundwork: the App Sandbox and a move to an Xcode project.
- **Changed:** runs in the macOS App Sandbox `[D-sandbox-entitlements]`
  (#19); displays Phases can't check are left alone at Quit (draft 58,
  `d955ce5`).
- **Changed:** Xcode project `[D-xcode-project]`; bundle ID
  `com.robertmohns.phases`, settings moved over once (draft 59,
  `524eb58`).
- **Tests:** Sandbox hands-on checks (draft 58, `d955ce5`).

### 2026-11-24 · Drafts 60–62
A Settings cleanup, and getting the test tools working again after the
sandbox move.
- **New:** low-memory note on Transition; location privacy note; memory use
  in About (draft 60, `514da3f`).
- **Changed:** Settings cleanup: Pause wallpaper changes switch, Launch &
  Quit section, new order (draft 60, `514da3f`).
- **Changed:** pause banner only for an outside-change pause; the pause
  switch is disabled while it shows (draft 61, `1dcded5`).
- **Fix:** UI tests failed on the sandboxed build; Debug builds can read one
  test folder `[D-debug-test-folder]` (draft 62, `cc70059`).
- **Tests:** launch argument to fake the Mac's memory size (draft 60,
  `514da3f`).
- **Tests:** unit tests run with `bitrig test`; UI driver picks the newest
  build by folder time and checks its build number (draft 61, `1dcded5`).
- **Tests:** UI driver presses modifier keys as real keys (stuck Shift
  fixed); synthetic clicks sent with click state 1
  `[D-input-click-state]` (draft 62, `cc70059`).

### 2026-11-25 · Draft 63
- **Changed:** phase editor redesigned: name row with On/Off, sentence-style
  Starts, display tabs; display sharing moves into each phase (#27)
  (draft 63, `bbf9b1e`; polished in `bb7df2c`).

### 2026-11-26 · Draft 64
- **New:** collapsible folder and album headings in the image grid, saved
  across launches `[D-grid-collapse]` (#37) (draft 64, `c163148`).

### 2026-11-27 · Draft 64
- **Fix:** Quit restored a still image over an Aerial; each display is
  judged by its own store entries `[Q-store-kind-lastset]` (#43) (on
  draft 64, `d0391dd`).

---

*Sources:* SPEC.md's title in git history (every draft from 1 to 64 is on
`main` except 25–27, which landed in one merge, and 51, which is only on an
abandoned branch), commit messages, ERRATA.md "Regressions found so far",
and LEARNINGS.md. Compiled by Claude from those records, 2026-11-27;
regrouped by date 2026-11-28. These are summaries of the records,
*recalled* from them, not re-tested.
