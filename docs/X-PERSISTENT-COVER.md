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

| # | Test | Steps | Looking for |
|---|---|---|---|
| E1 | Twitch | Change Now ×5 | No twitch at any point. |
| E2 | Menu bar text | Change Now between a light image and a dark one, `end` then `mid` | When the text color flips relative to the fade; whether `mid` looks better. Note any late restyle `[Q-menubar-restyle-on-app-switch]`. |
| E3 | Menu bar background | "Show menu bar background" on; Change Now, A then B | Whether the background follows the new image, and when. |
| E4 | Spaces | Change on Space 1; swipe to 2 and 3 | New image shown on every Space; how the swipe looks with a cover that stays put; whether menu bar text restyles (or blinks) on arriving at a Space whose real wallpaper was out of date. A blink there is acceptable (author, 2026-10-29); this records it, not fails on it. |
| E5 | Mission Control | Open it on each Space | What the main view and the Spaces strip thumbnails show: cover or real wallpaper. |
| E6 | Desktop | Icons, right-click on the desktop, drag a file to the desktop, "Click wallpaper to reveal desktop" | Icons above the cover; clicks reach the desktop as before. |
| E7 | Desktop widgets | Add a widget, widget style Automatic | Whether its tint matches the cover or the real wallpaper. |
| E8 | Lock screen and login window (author) | Lock (⌃⌘Q): on Space 1 right after a change; on Space 2 after arriving; on Space 2 after a change made on Space 1, before arriving. Then log out once | Which image the lock screen and the login window show in each case. |
| E9 | Full screen and Stage Manager | Full-screen an app; turn Stage Manager on | Nothing odd shows through or around. |
| E10 | Quit and crash | Quit; relaunch; Force Quit | What's on screen the moment the cover goes; restore-on-quit still behaves. |
| E11 | System Settings | Change wallpaper there while Phases runs | Expected: hidden by the cover. Confirm, and note how confusing it is. |
| E12 | Memory | `footprint` on Phases: on `main` at idle, then the branch with the cover up, A and B, one display and two | The real cost per display, against today's idle baseline. |

## Results

Filled in as runs happen: date, macOS version, variant, verified or
observed, and anything surprising.

| # | Result |
|---|---|
| E1 | |
| E2 | |
| E3 | |
| E4 | |
| E5 | |
| E6 | |
| E7 | |
| E8 | |
| E9 | |
| E10 | |
| E11 | |
| E12 | |

## Afterward

- Each finding about macOS behavior becomes a `[Q-…]` entry in ERRATA.md,
  marked verified with its date.
- If the hybrid holds up, a SPEC.md draft proposes it for approval:
  `[D-fade-in]` and `[D-cover-settle]` rewritten, "Different wallpaper per
  Space" in "Out of scope" replaced by "the same wallpaper on every Space",
  and what Pause and Quit do with the cover.
- **The branch stays until we both agree the findings are well understood
  by both of us.** I ask the author before deleting it, and don't delete
  it without a yes (author, 2026-10-29).
