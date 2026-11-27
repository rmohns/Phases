# Phases — Experiments

The full record of every experiment, investigation, and retired design:
what we asked, how we set it up, each run, the numbers, the wrong
guesses and their corrections. LEARNINGS.md is the short digest of what
these found; this file is the evidence behind it. Nothing here is
trimmed or rewritten once written; corrections are added, not
substituted.

- **Not read by default.** Open a section when a LEARNINGS.md entry
  points to it, or when picking an experiment back up.
- **One file per record** (from 2026-11-27): each experiment's record is
  `docs/experiments/<tag>.md`, e.g. `docs/experiments/X-memory.md`,
  moved there word for word. This file is the index: each group's
  heading and introduction (copied into each of its records too), the
  notes that belong to no experiment, and one row per record with its
  question, when, and outcome, the last two shortened. The record is the
  full text. A new experiment gets a new file and a row here.
- Each experiment has an `[X-…]` tag, named after its branch where it had
  one, and a header: the question, when and on what, the branch and its
  `archive/…` tag, the outcome, and the `[L-…]` findings it produced.
- Entries keep their original `[L-…]` tags, so a search for a tag finds
  both the digest line in LEARNINGS.md and the full entry here.
- Before 2026-11-09 this file was LEARNINGS.md; its old layout is tag
  `archive/docs-before-refactor`.
- The rules for all of this (evidence labels, promotion and demotion,
  references by tag `[D-refs-by-id]`) are in CLAUDE.md.

## Wallpaper, covers, and the menu bar

Source for this section unless noted: the persistent-cover experiment,
2026-10-30, macOS 27.2, one built-in display (3024 × 1964); branch
`spike/persistent-cover` (tag `archive/spike/persistent-cover`),
`docs/X-PERSISTENT-COVER.md`. A "cover" is a
borderless, click-through window just above the desktop picture
`[D-cover-level]`.

| Record | When | Question | Outcome |
|---|---|---|---|
| [`[X-persistent-cover]` Keeping a cover up between changes](experiments/X-persistent-cover.md) | 2026-10-30 to 2026-10-31, macOS 27.2; one built-in display, then three displays. | can a cover stay over the desktop all the time, so macOS's wallpaper-change motion never shows, and what does that break? | became draft 33's persistent cover `[D-persistent-cover]` (tag `archive/feature/persistent-cover-transitions`). Promoted: `[Q-opaque-cover-freezes-menubar]`, `[Q-space-n… |
| [`[X-set-target-read]` Which Space a set reaches during a swipe](experiments/X-set-target-read.md) | 2026-11-03, macOS 27.2, Release builds, one display with two Spaces; trials with a 1 s fa… | when the user swipes to another Space mid-change, can Phases tell which Space its wallpaper set will land on? | no check at the moment of the set can be trusted; the race is `[Q-set-target-decided-late]`, handled by `[D-reset-on-quick-return]`. |

### Notes outside any experiment

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

| Record | When | Question | Outcome |
|---|---|---|---|
| [`[X-memory]` Where Phases' memory goes](experiments/X-memory.md) | 2026-10-30 (investigation and fix runs) and 2026-11-03 (draft 33 runs), macOS 27.2, two o… | why did the installed `main` sit at 179 MB with its window closed, and what fixes it? | the cover-memory fix landed on `main`, measured flat across ten changes `[D-memory-flat]`; the run procedure became `[D-memory-protocol]`. Promoted: `[Q-cover-image-copi… |

## Sidebar rows

Source for this section: the issue #22 experiment, 2026-11-06, macOS
27.2, branch `experiment/active-badge-highlight` (commit 204231c), run by
Claude with the author's yes. Highlight Color was blue. Each run
relaunched Phases with a launch switch choosing the variant, selected
the active phase (Nighttime) by clicking Dusk and pressing Down, and
took window screenshots with the window in front and behind Finder.

| Record | When | Question | Outcome |
|---|---|---|---|
| [`[X-active-badge-highlight]` The Active badge on the selection highlight](experiments/X-active-badge-highlight.md) | 2026-11-06, macOS 27.2, blue Highlight Color, six runs with window screenshots. | how can the sidebar's accent-coloured Active badge stay readable on the accent-coloured selection highlight? (Issue #22.) | the row is told it's selected and whether the sidebar has focus; promoted to `[Q-tint-on-highlight]`. |

## Pause banner

Source: the author's hands-on look at draft 49's first build (commit
78b17b9, branch `feature/window-pause-banner`), 2026-11-07. That build
put the banner in a `.safeAreaInset(edge: .top)` on the detail pane,
with `if scheduler.isPaused` inline in the inset's closure.

| Record | When | Question | Outcome |
|---|---|---|---|
| [`[X-pause-banner-shift]` Window content shifted up while paused](experiments/X-pause-banner-shift.md) | 2026-11-07, macOS 27.2; the author's hands-on looks and screen recordings, Claude's UI te… | why did the window open with its content shifted up under the toolbar while Phases was paused? | the banner reason's `.fixedSize` made the split view rigid and too tall; dropping it fixed the shift. Promoted to `[Q-fixed-size-text-rigid-split]`, guarded by `PauseBan… |

## Notification clicks

| Record | When | Question | Outcome |
|---|---|---|---|
| [`[X-notice-click]` What a click on the pause notification does](experiments/X-notice-click.md) | 2026-11-08, macOS 27.2, draft 50's hands-on check; the log, `ps`, `lsregister -dump`, and… | why did a click on the pause notification's body sometimes do nothing, or open the window behind other apps? | every notification click goes through `FirstLaunchWindow.open` (draft 50). The second copy is a development artifact of stale Launch Services registrations. |

## UI mockup (issues #2, #3, #26, #27)

An interface-only mockup, archived as tag `archive/experiment/ui-mockup`:
mock views with throwaway state, nothing wired to the model, and a
scheduler made read-only so it could run beside a real Phases.

| Record | When | Question | Outcome |
|---|---|---|---|
| [`[X-ui-mockup]` Interface mockup](experiments/X-ui-mockup.md) | 2026-11-08 to 2026-11-09, macOS 27.2. | do older Mac layout conventions, a split phase editor, and per-display tabs make the window better? (Issues #2, #3, #26, #27.) | the old-style layout was dropped; streamlining continues with modern macOS conventions (author, 2026-11-09). |

## Other investigations

Until 2026-11-09 this section was called "Open questions"; most of what
it held has since been answered. What's still open is under "Still
open" at its end.

| Record | When | Question | Outcome |
|---|---|---|---|
| [`[X-wallpaper-store-watch]` Hearing outside wallpaper changes](experiments/X-wallpaper-store-watch.md) | 2026-11-06, macOS 27.2, one display, Debug build `ebe00f8`. | can Phases hear a wallpaper change made in System Settings by watching macOS's wallpaper store? (Issue #5.) | yes; promoted to `[Q-wallpaper-store]`. Two displays untested. |
| [`[X-new-space-pauses]` A new Space read as an outside change](experiments/X-new-space-pauses.md) | 2026-11-07, macOS 27.2; the author's observations and a read-only copy of the wallpaper s… | why does going full screen, or adding a desktop, pause Phases with the outside-change notice? (Issue #29.) | a new Space's store entries are copies, which the rule counted as picks; promoted to `[Q-new-space-copies-entry]`. |
| [`[X-reopen-window]` Launching Phases again while it runs](experiments/X-reopen-window.md) | 2026-11-03, macOS 27.2; runs from Terminal with `open`, then `RelaunchTests`. | what happens when Phases is launched again while it's running, and can the menu bar icon's view open the window? (Issue #13.) | the menu bar icon's view handles the reopen request; promoted to `[Q-reopen-ignores-closed-window]`. Along the way the UI test harness's newest-build pick was found brok… |
| [`[X-menubar-launcher-setting]` Missing menu bar icon under Bitrig](experiments/X-menubar-launcher-setting.md) | 2026-11-04, macOS 27.2. | why did a Phases launched from Bitrig have no menu bar icon? | Bitrig's own switch in System Settings → Menu Bar was off; a launched Phases follows it. Why is an untested hypothesis. |
| [`[X-menubar-overflow]` Menu bar overflow and the test harness](experiments/X-menubar-overflow.md) | 2026-10-30 to 2026-11-04, macOS 27.2, several display setups. Tracked as issue #11. | is Phases' menu bar icon hidden when the menu bar runs out of room, and why does the UI test harness sometimes refuse to click it? | on macOS 27.2 a chevron reveals hidden icons; macOS 26 untested. The harness now rechecks ownership for up to 2 s. The test beeps are macOS's type-to-select. |
| [`[X-hdr-wallpaper]` HDR photos as wallpaper](experiments/X-hdr-wallpaper.md) | 2026-10-30, macOS 27.2, built-in display, the author's iPhone HEIC. | does macOS draw an HDR photo as wallpaper in SDR or with HDR headroom? | SDR, by the author's eye against a known-HDR control; no tool here could measure it. Bears on `[D-cover-iosurface]`. |
| [`[X-stale-app-icon]` Old app icon in the brand panel after an icon change](experiments/X-stale-app-icon.md) | 2026-11-14, macOS 27.2, Debug build launched by `bitrig preview` from Bitrig's DerivedDat… | after the switch to the Icon Composer icon (`70390c6`), why did the sidebar brand panel show the old PNG icon while the About panel showed the new one? | a stale icon cache outside Phases (hypothesis); fixed by refreshing the bundle's date and registration. No code change. |
| [`[X-first-launch-activation]` First-launch window staying behind](experiments/X-first-launch-activation.md) | recorded in the tag, not here. | why does the window open behind the frontmost app on a first launch? | promoted to `[Q-launch-activate-refused]` (2026-11-06). |

### Still open

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

## Photos library (issue #33)

| Record | When | Question | Outcome |
|---|---|---|---|
| [`[X-33-photokit]` Photos library from a not-sandboxed Phases (round A)](experiments/X-33-photokit.md) | 2026-11-12, macOS 27.2; the author's library with "Optimize Mac Storage" on, album "NIN 2… | not recorded as one question. This is Phase 0 of the issue #33 plan (`docs/PLAN-GITHUB-ISSUE-33.md`, now in tag `archive/feature/33-photos-albums`), round A, not sandbox… | not recorded. - *Added 2026-11-14 by Claude:* fed spec drafts 52 and 54, which merged as `a5d06e9` and `1148bed`; issue #33 closed 2026-11-13. |
| [`[X-33-sandbox]` Photos library from a sandboxed Phases (round B)](experiments/X-33-sandbox.md) | 2026-11-12, macOS 27.2; builds cdhash `586935f0`, and `615f31ef` for the wallpaper check.… | not recorded as one question. The same probe as round A, built with `com.apple.security.app-sandbox` only. | not recorded. - *Added 2026-11-14 by Claude:* sandboxing became its own change, issue #19 (author, 2026-11-12); these findings are summarized there. - *Added 2026-11-22… |
| [`[X-33-photos-checks]` Merge #2 Photos checks](experiments/X-33-photos-checks.md) | 2026-11-12, macOS 27.2; builds from 16:44 local on, not sandboxed. Run by the author, wit… | do Photos sources behave as the draft 54 spec says (then draft 53 on the branch) with the author's real settings and library? Nine hands-on checks, listed in TESTING.md… | all nine checks passed; two fixes landed on the branch (the brand panel during a wait, and rereading Photos sources before showing). |

## Image sources (issue #33, merge 1)

| Record | When | Question | Outcome |
|---|---|---|---|
| [`[X-33-image-sources]` Image sources: findings from merge 1 of issue #33](experiments/X-33-image-sources.md) | 2026-11-12, macOS 27.2; draft 52 build, not sandboxed (the NAS entry); the closed-menu en… | not recorded as one question; these are findings from merge 1 of issue #33, not a planned experiment. | not recorded as one outcome. `[L-nas-bookmark-rename]` needed no code change; `[L-closed-menu-stale]` was promoted to `[Q-undo-menu-ax]` (2026-11-12), per the entries be… |

## Project conversion (draft 59)

| Record | When | Question | Outcome |
|---|---|---|---|
| [`[X-convert-xcode-project]` What `bitrig convert-to-xcode-project` did to Phases](experiments/X-convert-xcode-project.md) |  | does converting from `Project.json` to an Xcode project keep every setting, entitlement, and the signing of `main`'s builds? | settings carried over; two unwanted settings added and removed; team signing lost and not yet restored (needs the author's call). Finding: `[L-convert-xcode-project]`. |

## UI tests on the sandboxed build

| Record | When | Question | Outcome |
|---|---|---|---|
| [`[X-ui-tests-sandboxed]` First fast-suite run since the sandbox](experiments/X-ui-tests-sandboxed.md) |  | does the UI test harness still work now that Phases is sandboxed (draft 59 on), and does the #47 build pick choose the right build? | the build pick works; the image-folder tests fail under the sandbox. Digest: LEARNINGS.md `[L-ui-tests-sandboxed]`. Not fixed. *Update 2026-11-24:* promoted to TEST-TOOL… |

## UI driver click state (issue #39 follow-up)

| Record | When | Question | Outcome |
|---|---|---|---|
| [`[X-click-state]` Do Phases' synthetic clicks need `mouseEventClickState`?](experiments/X-click-state.md) | 2026-11-25, macOS 27.2, by Claude with Robert's go-ahead (he quit the installed Phases fi… | `SyntheticInput` posts mouse up with click state 0 (TEST-TOOLS.md, under `[D-input-modifier-keys]`). Does any click in Phases fail because of it? The image grid's tile c… | **not needed.** A tile click toggles the tile with click state 0 on mouse up, the same as with 1. No driver change. |

## Phase editor pop-up look

| Record | When | Question | Outcome |
|---|---|---|---|
| [`[X-settings-popup-look]` Can the editor's pop-ups look like System Settings'?](experiments/X-settings-popup-look.md) | 2026-11-26, macOS 27.2, by Claude, at the author's request ("Let's give it a try"). Each… | the author asked for the settings block's pop-up menus to look like System Settings' (the chevron in a circle, no box, a rounded box under the pointer), from two screens… | no standard style outside a grouped `Form`; promoted to `[Q-settings-popup-look]`, shaping `[D-editor-popups]`. What landed is run 9's AppKit pop-up with run 10's restin… |

## Sandbox check 2 on draft 64 (issue #43)

| Record | When | Question | Outcome |
|---|---|---|---|
| [`[X-43-aerial-kind]` Why did Quit restore a still over an Aerial?](experiments/X-43-aerial-kind.md) | 2026-11-27, macOS 27.2, two displays (built-in, display 1, UUID `37D8832A…`; a virtual di… | in TESTING.md "Sandbox checks" 2, the Aerial display logged "restored: DefaultDesktop.heic" instead of "left alone on quit: system wallpaper". Why? | cause found; promoted to `[Q-store-kind-lastset]`. The fix landed on `main` as `d0391dd` (2026-11-27). |

## Retired designs

Designs that were on `main` and have since been replaced. Moved here
from ERRATA.md "Design history" when the code they explain was gone.

| Record | When | Question | Outcome |
|---|---|---|---|
| [`[X-cover-settle]` Crossfade settle timing (drafts 5–32)](experiments/X-cover-settle.md) |  |  |  |
