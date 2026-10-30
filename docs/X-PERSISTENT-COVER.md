# Experiment: persistent cover

A throwaway test of keeping the crossfade cover on screen for as long as
Phases runs, instead of removing it after each change. It lives on the
branch `spike/persistent-cover`, which **never merges**. Findings go to
ERRATA.md (new `[Q-…]` entries) and ride along with the next real change;
any change to how Phases works goes through SPEC.md first, as usual.

Not QA: TESTING.md stays for the tests that guard the shipping app.

## The question

Can Phases own what's on the desktop, with a cover that never comes off, and
leave macOS's wallpaper underneath only for the things that read it?

If it can, three problems go away or shrink:

- **The twitch** `[Q-wallpaper-motion-delay]`: macOS's motion always plays
  behind an opaque cover, so `[D-cover-settle]`'s 1.5 s delay goes away.
- **Spaces:** the cover already appears on every Space
  (`.canJoinAllSpaces`), so every Space shows the current image.
- **Menu bar text timing:** the real wallpaper can be set whenever suits
  the menu bar best, since it's never seen.

## The hybrid being tested

1. **The cover stays up.** After a fade, the last cover on each screen
   stays up instead of being removed.
2. **The real wallpaper is still set,** behind the cover, so the things
   that read it (menu bar text `[Q-menubar-reads-wallpaper]`, the lock
   screen, desktop widgets) see the right image.
3. **Space-arrival sync.** On `NSWorkspace.activeSpaceDidChangeNotification`,
   if a screen's real wallpaper on the new Space isn't the current image,
   Phases sets it, invisibly, behind the cover.

No private APIs or files. Phases still reads macOS's wallpaper store only
as it does today, and never writes it `[D-aerials-untouched]`.

## Changes on the branch

Kept as small as possible, all behind one launch argument so a normal
launch of the branch build behaves like `main`:

- `-PhasesPersistentCover A` or `B` (one launch only, like
  `[D-test-no-location-prompt]`):
  - **A: one window, content changes.** Each screen keeps a single cover
    window; a change crossfades a new image layer inside it.
  - **B: new window per change.** Each change fades in a new cover window,
    as today, and the previous one is removed once the fade ends. One
    cover always remains.
  - Why both: `[Q-menubar-bg-follows-window]` says the menu bar background
    restyles when the *window* under it changes. A may never trigger a
    restyle; B should.
- `-PhasesWallpaperTiming end` (default) or `mid`: set the real wallpaper
  at the end of the fade, or halfway through.
- Space-arrival sync, on only with the persistent cover.
- Diagnostic lines in a `spike` category (`Diagnostics.logger("spike")`):
  each Space change, each real-wallpaper set (screen, file, and whether it
  was a sync), and each cover created or removed. Turn on with
  `[D-diagnostics-switch]`.

Code: `App/Model/PersistentCover.swift`, plus a two-line hand-off in
`CrossfadeController`. At launch the cover goes up over whatever
wallpaper is showing, so it's in place before the first change. Launch
with `open <Phases.app> --args -PhasesPersistentCover A
-PhasesWallpaperTiming mid` (quit any running Phases first).

Known gaps, on purpose: no handling of display connect/disconnect or
resolution changes (a mismatched cover is expected there), and no Settings
UI.

## Test plan

**Who runs what.** I drive E1–E7 and E9–E12, with the author's go-ahead
(2026-10-29). The author checks E8, the lock screen and login window,
since I can't see or use the Mac while it's locked.

- Before each run I say what I'll do and roughly when, then wait for an
  explicit yes. When it's done I announce it out loud.
- My tools: keystrokes and menu clicks (Space switching with ⌃←/⌃→,
  Mission Control, Change Now), screenshots, and screen recordings read
  frame by frame for anything timing-related (the twitch, the menu bar
  flip), the same method as "The twitch returns" in ERRATA.md. Plus the
  diagnostic log and `footprint` for memory.
- Screenshots and recordings need Screen Recording permission for the
  process I run commands from. That's not checked yet; if it's missing,
  macOS will ask, and that's the author's call.
- Menu clicks have to be real mouse events, not System Events
  accessibility actions (see "Open here" in ERRATA.md).

**Not in this test:**

- Bartender: the author has stopped using it (2026-10-29), so
  `[Q-bartender-menubar]` doesn't apply.
- Light and Dark Mode: believed (not tested) to no longer affect the menu
  bar's styling on macOS 26 and 27, and the cover doesn't change how
  Phases picks phases.

Setup: two or three Spaces on the main display, a phase with a mix of
light and dark images, Crossfade at 1 s, diagnostics on. Where it matters,
test both A and B.

### Display configurations

Agreed with the author 2026-10-29:

- **One display: the full run, E1–E12.** The baseline.
- **Three displays: the tests that depend on display count,** E1, E3,
  E4, E5, E8, and E12. Each display has its own Spaces, lock screen
  image, and cover, so these can differ.
- **Two displays: skipped,** unless the three-display run shows something
  odd. Three exercises everything two would, and one and three are enough
  to work out memory per display.
- E6, E7, E9, E10, and E11 are believed (not tested) not to depend on
  display count.
- The test build doesn't handle displays changing (see "Changes on the
  branch"). Between configurations: quit Phases, change the displays,
  relaunch.

| # | Test | Steps | Looking for |
|---|---|---|---|
| E1 | Twitch | Change Now ×5 | No twitch at any point. |
| E2 | Menu bar text | Change Now between a light image and a dark one, `end` then `mid` | When the text color flips relative to the fade; whether `mid` looks better. Note any late restyle `[Q-menubar-restyle-on-app-switch]`. |
| E3 | **Fails with "Show menu bar background" on, in both A and B.** 2026-10-30, background turned on for the test and back off after. Across three changes per variant, the background kept the color of an earlier image (dark purple, then olive) while the cover showed others, and stayed wrong after two app switches and 15 s. Control, same session, no persistent cover: one change and the background restyled to match. *Observed* from recordings and screenshots. So the menu bar background follows the real wallpaper only when no window covers it, or after some event the persistent cover never produces; cause unknown. Untested idea: drop the cover briefly once the real wallpaper has settled, then put it back (invisible, since the images match). With the background off (the author's usual setting) the menu bar shows the cover live, with no lag. |
| E4 | Spaces | Change on Space 1; swipe to 2 and 3 | New image shown on every Space; how the swipe looks with a cover that stays put; whether menu bar text restyles (or blinks) on arriving at a Space whose real wallpaper was out of date. A blink there is acceptable (author, 2026-10-29); this records it, not fails on it. |
| E5 | Mission Control | Open it on each Space | What the main view and the Spaces strip thumbnails show: cover or real wallpaper. |
| E6 | Desktop | Icons, right-click on the desktop, drag a file to the desktop, "Click wallpaper to reveal desktop" | Icons above the cover; clicks reach the desktop as before. |
| E7 | Widgets draw above the cover. With an app in front, they turn translucent and show the cover through them, so they match it. *Observed* 2026-10-30. |
| E8 | Lock screen and login window (author) | Lock (⌃⌘Q): on Space 1 right after a change; on Space 2 after arriving; on Space 2 after a change made on Space 1, before arriving. Then log out once | Which image the lock screen and the login window show in each case. |
| E9 | 2026-10-30, 99% cover B: Calendar into and out of full screen looked normal; the cover showed around the windows during the exit animation, nothing odd. *Observed.* (Activity Monitor can't go full screen; it only zooms.) **Stage Manager** (turned on for the test, then off): three changes crossfaded normally beside the strip, no twitch seen; clicking the wallpaper revealed the desktop (Finder frontmost) and clicking again brought the stage back. *Observed* 2026-10-30, 99% cover B. Footprint during the test about 104 MB (Activity Monitor). |
| E10 | Quit and crash | Quit; relaunch; Force Quit | What's on screen the moment the cover goes; restore-on-quit still behaves. |
| E11 | System Settings | Change wallpaper there while Phases runs | Expected: hidden by the cover. Confirm, and note how confusing it is. |
| E12 | Memory | `footprint` on Phases: on `main` at idle, then the branch with the cover up, A and B, one display and three | The real cost per display, against today's idle baseline. |

## Results

Run 2, 2026-10-30, macOS 27.2, one display (built-in, 3024 × 1964), Debug
build, driven by me with the author's go-ahead. Run 1 earlier the same
morning was restarted from scratch at the author's request; where it
agreed, it's noted. Recordings are 60 fps, variable frame rate, analyzed
by per-frame differences over the desktop area.

| # | Result |
|---|---|
| E1 | **No twitch**, A and B. *Verified*: three fades each (A `end`, B `mid`), nothing above noise after any fade ends. Run 1 (A) agreed. |
| E2 | **Menu bar text never changed color during a run.** Black for every image in run 2 (A and B), white for every image in run 1, including a mostly white image and a solid black real wallpaper. `mid` made no visible difference. *Observed* at 4 samples per second. The text seems to restyle only on other events (launch, Space arrival), which fits `[Q-menubar-restyle-on-app-switch]`; not proven. |
| E3 | The menu bar area showed the cover fading live, with no lag, in A and B. Not yet checked with "Show menu bar background" known to be on. |
| E4 | **Space-arrival sync works** (*verified* in the log every time). Swipes look native: the cover slides with each Space (run 1 frames). On arriving at a Space just synced to the same image, the menu bar had a different style (grey bar, white text) than that image had on the other Space (black text). *Observed* once. |
| E5 | Mission Control shows the cover as the background. The Spaces strip showed names only, no thumbnails. |
| E6 | **Desktop works through the cover.** Icons and widgets draw above it; right-click on the desktop opens Finder's desktop menu (Change Wallpaper…, Edit Widgets…). *Observed.* |
| E7 | Widgets draw above the cover in full color. Tint behavior with an app in front not checked. |
| E8 | **Lock screen correct from both Spaces tested; login window correct** (logged out from one Space). *Verified* by the author, 2026-10-30, cover B, `mid`. **New, observed by the author:** a twitch during logout, appearing to start after logout finished, just as the login window appeared. Not investigated yet. The author sees the login window darken the wallpaper slightly, which fits macOS redrawing its own wallpaper for the login window (recalled, not tested). Check whether `main` does the same. |
| E9 | Not run: no full-screen app at run time; Stage Manager not toggled. |
| E10 | **Quit: hard cut** from the cover to the restored wallpaper, no fade. **Force Quit: nothing visible**, because the real wallpaper underneath matched the cover on that Space. |
| E11 | A wallpaper set from outside Phases (System Events) is **hidden by the cover**, as expected. Confusing for a user changing wallpaper in System Settings. |
| E12 | 23 MB without the cover. With it: **A 93 MB** at launch; **B 86 MB** at launch, **102 MB after three changes**. The image is held about three times (CoreAnimation, Malloc Large, CG Raster Data, about 23 MB each), so likely reducible. Growth after changes not explained yet. |

### Fixes for the menu bar background (E3)

2026-10-30, one display, cover B, "Show menu bar background" on.

- **Brief uncover** (`-PhasesUncover 100`: take the cover off for 100 ms
  once the wallpaper has settled). The background restyled at the
  uncover, but **the twitch came back at that moment**: macOS's shift
  played when the wallpaper was revealed (crane and building visibly
  offset in the frame, 26 dB against the frame before). Same with a 4 s
  settle (`-PhasesUncoverDelay 4000`). *Measured.* So the motion isn't
  on a timer: macOS seems to hold it until the new wallpaper is first
  seen. Hypothesis, not proven: macOS treats a fully opaque full-screen
  cover as hiding the desktop and defers presenting the wallpaper
  (motion and menu bar restyle) until it's revealed. That would also
  explain the logout twitch (E8). Rejected.
- **99% cover** (`-PhasesCoverAlpha 0.99`). **The background and text
  restyled promptly for every change**, matching each image (olive, light
  grey with black text, dark purple and blue with white text), across two
  recordings of three changes each. **No twitch:** the frame after each
  fade matched the frame before at noise level (43 dB). The 1% of real
  wallpaper showing through is the same image once set, so it can't be
  seen. *Measured.* The candidate fix. Untested: whether 99% also fixes
  the menu bar text with the background off (E2), Space arrival, and
  three displays.
- The second 99% recording was meant to have the background off, but a
  Safari window opened by something else appeared as I clicked the
  toggle, so the click probably missed. The bars in the recording show
  the background still on. I stopped driving there.
- **99% with the background off** (the author's usual setting, turned
  off by the author). **Menu bar text now follows the image**: white on
  the autumn trees, sky, and neon planet, black on the pale Misty Rocks.
  This fixes E2, where an opaque cover left the text stuck. No twitch
  after the fades. *Observed* from a recording, three changes.
- **99% on Space arrival:** arriving at a Space just synced to a new
  image, the menu bar kept the old image's style for about half a
  second, blinked, then restyled correctly. The author had accepted a
  blink here (E4). *Observed* once.

### Three displays

2026-10-30, macOS 27.2, 99% cover B (`-PhasesCoverAlpha 0.99`), Debug
build. Displays: LG Ultrawide (main, 2580 × 1080 pt, three Spaces, Dock
at the bottom), built-in (1512 × 982 pt, one Space), Cinema HD portrait
(1100 × 1760 pt, one Space). "Different picks per display", so each
display changed to its own image every time.

| # | Result |
|---|---|
| E1 | **No twitch on any display.** *Measured:* frames before and after each fade's end matched at noise level, 44–50 dB, on all three. Recording all three at once starves the encoder (the built-in and portrait recordings dropped to a few frames per second), so the built-in and portrait displays were re-recorded one at a time. |
| E2 | Menu bar text followed each display's image on all three (*observed* from per-second menu bar crops). The two inactive menu bars show dimmed text, as macOS always does. |
| E3 | **With "Show menu bar background" on, all three backgrounds tracked their images** (olive over trees, purple over the neon planet, blue over sky), three changes, *observed*. On the ultrawide over the very white Ergo Proxy image, macOS drew white text on a light grey bar; a control with no cover (wallpaper set directly) did the same, so that's macOS's own choice. Background turned back off afterward (verified in Settings). |
| E4 | Every Space on the ultrawide showed the current image, synced on arrival (*verified* in the log); the other two displays were unaffected. |
| E5 | Mission Control showed the cover images on all three displays. |
| E8 | Lock screen and login window fine on three displays (*verified* by the author, 2026-10-30). |
| E12 | **Grows with every change: a leak in the experiment.** No cover: 77 MB right after launch. Cover at launch: 140–187 MB (two launches). After about nine changes: 344, then 373 MB; a fresh launch plus four changes: 336 MB. About 25–30 MB per change across three displays, so old cover windows or their images aren't being released. Must be fixed before any of this ships. The 77 MB no-cover figure, against 23 MB on one display, isn't explained either. Later the same run, Activity Monitor showed 242 MB with no further changes (author): memory may be released slowly rather than leaked, or Activity Monitor's figure differs from `footprint`. Not yet measured. |

## Afterward

- Each finding about macOS behavior becomes a `[Q-…]` entry in ERRATA.md,
  marked verified with its date.
- If the hybrid holds up, a SPEC.md draft proposes it for approval:
  `[D-fade-in]` and `[D-cover-settle]` rewritten, "Different wallpaper per
  Space" in "Out of scope" replaced by "the same wallpaper on every Space",
  and what Pause and Quit do with the cover.
- **Follow-up, not part of this experiment: memory on `main`.** The
  installed Release build measured 179 MB on 2026-10-30, with its window
  closed (82 MB Malloc Large, 54 MB Malloc Small, 9 MB QuickLook
  Thumbnails), against 23 MB for a fresh Debug launch with no window
  opened. Something may not be released after the window closes, such as
  the thumbnail grid. Investigate on its own branch (author, 2026-10-30).
  This note must reach `main` with the findings, so it isn't lost when the
  branch goes.
- **The branch stays until we both agree the findings are well understood
  by both of us.** I ask the author before deleting it, and don't delete
  it without a yes (author, 2026-10-29).
