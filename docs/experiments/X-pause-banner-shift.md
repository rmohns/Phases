# `[X-pause-banner-shift]` Window content shifted up while paused

Part of "Pause banner" in [EXPERIMENTS.md](../EXPERIMENTS.md), the index of
experiments. Moved here word for word from EXPERIMENTS.md on
2026-11-27, when each record got its own file.
The group's introduction there applies to this record too; copied
here so the record reads on its own:

> Source: the author's hands-on look at draft 49's first build (commit
> 78b17b9, branch `feature/window-pause-banner`), 2026-11-07. That build
> put the banner in a `.safeAreaInset(edge: .top)` on the detail pane,
> with `if scheduler.isPaused` inline in the inset's closure.


- **Question:** why did the window open with its content shifted up
  under the toolbar while Phases was paused?
- **When, on what:** 2026-11-07, macOS 27.2; the author's hands-on
  looks and screen recordings, Claude's UI test runs and logs.
- **Branches:** `feature/window-pause-banner` (draft 49);
  `experiment/pause-banner-shift`, tag
  `archive/experiment/pause-banner-shift`.
- **Outcome:** the banner reason's `.fixedSize` made the split view rigid
  and too tall; dropping it fixed the shift. Promoted to
  `[Q-fixed-size-text-rigid-split]`, guarded by `PauseBannerTests`.
- **Findings:** `[L-pause-banner-inset]` (its inset hypothesis refuted),
  `[L-pause-banner-runs]`, `[L-pause-banner-stack-still-shifts]`,
  `[L-pause-banner-above-window]`; promoted:
  `[L-pause-banner-rigid-split]`.

- `[L-pause-banner-inset]` **A top `.safeAreaInset` banner broke the
  window two ways.** *Observed* by the author, not measured:
  - **Everything under the toolbar.** Opening the window while already
    paused, including on a fresh launch with no clicks or scrolling,
    drew the banner, sidebar, and form shifted up: the branding panel
    under the traffic lights, the banner's text cut off under the title.
    The toolbar's title was still drawn in place, so the toolbar seemed
    present and the content's room for it missing (Claude, from the
    screenshots). Pausing and resuming with the window open usually
    looked right.
  - **The banner stopped following the pause.** It toggled with the
    menu's Pause and Resume, then after about a dozen toggles stopped
    appearing. After a click on the notification's body (not its Resume
    button) opened the window without the banner, it never came back
    in that run.
  - *Hypotheses* (Claude, not tested): the inset's content isn't
    tracked for redraw `[Q-safe-area-inset-refresh]`; an inset present
    at the first layout keeps SwiftUI from making room for the toolbar
    the window helper attaches a moment later `[D-window-helper-order]`.
  - *Next:* draft 49's banner moves into a plain stack above the pane,
    reading `isPaused` in its own view, with diagnostics (category
    `window`) and UI tests (`PauseBannerTests`). Run the tests against
    78b17b9 to watch them fail, then against the fix.
- `[L-pause-banner-runs]` **UI test runs, 2026-11-07 21:48–21:54**
  (Claude, author's yes, diagnostics on):
  - Run 1, `PauseBannerTests` against 78b17b9's build: the toggle test
    **passed** (10 pauses, 10 resumes); the first-open test failed, but
    its message wasn't saved. Run 2, against 56bf366's build, failed the
    same test on the harness: after Pause Schedule, the next click on
    the menu bar item didn't open the menu, and "Open Phases…" read as
    (0, 982) (*verified*, output). So run 1's failure may have been the
    harness, not the bug; it proves nothing either way. The driver now
    clicks the menu bar item again when the menu doesn't open.
  - Run 3, the fast suite against 56bf366's build with that driver fix:
    14 of 15 passed, both `PauseBannerTests` included; the retry was
    needed once (*verified*). `RelaunchTests` failed on a missing Dock
    icon, the intermittent failure recorded under `[L-reopen-event]`
    (2026-11-03); this change doesn't touch reopening (*hypothesis* that
    it's unrelated, not rerun).
  - **Toolbar room arrives after the first layout** (*verified*, log,
    every window open in run 3): the detail pane's top safe area went
    0 → 32 → 52 pt within about 0.12 s, the 52 pt landing just after
    "toolbar installed". With the fix, the banner opened while paused
    followed it: top at 0, 32, then 52 pt. That fits the inset
    hypothesis above but doesn't prove the inset was the cause.
  - **The toggle bug didn't reproduce under test** on the old build.
    What stopped the banner in the author's session (perhaps the click
    on the notification's body) is still open.
  - Run 4, 21:56, `PauseBannerTests` against 78b17b9's build again, with
    the driver fix (Claude, author's yes): **both passed** (*verified*;
    the build is the old code: its binary lacks the new `window` log
    text). So neither test reproduces what the author saw; they aren't
    guards yet. Differences from the author's repro, any of which could
    matter (*untested*): his pause was saved from an earlier launch, not
    chosen in the same session; the harness clears the saved window
    frame and turns off state restoration; test mode uses its own store;
    and the AX frames may not show a purely visual shift.
- `[L-pause-banner-stack-still-shifts]` **The stack fix didn't fix the
  shift** (author's hands-on look, build of a257a51, 2026-11-07, about
  22:05; *observed*, screenshots):
  - Pause, quit, run from Bitrig, open from the menu: once it opened
    right; the next two times it opened shifted up again. Once like
    before (banner under the toolbar, branding panel under the traffic
    lights); once worse: the sidebar's branding panel gone above the
    top, the Settings row under the traffic lights, the banner out of
    sight above the form, and the form's Name row behind the toolbar.
  - Resume from the menu put the window right; pausing again after that
    put the banner in the right place.
  - Paused by an outside change, then opened from the menu: no banner
    visible. Likely the same shift with the banner pushed out of sight
    (Claude, *hypothesis*), not the redraw bug. The notification isn't
    needed to reproduce (author).
  - So `[L-pause-banner-inset]`'s inset hypothesis is **refuted** for
    the shift: the sidebar moves too, and the banner isn't in it. The
    columns' different shift amounts in the worse case look like each
    scroll view keeping a scroll position that's off by its top
    margin, not a window frame moving (Claude, *hypothesis*).
  - Clicking the notification's body only dismisses it. SPEC.md gives
    the notification a Resume action and says nothing about the body
    (as specified, not a bug).
- `[L-pause-banner-above-window]` **With logging: the content sits
  above the window, the scroll positions are normal** (build of
  77a9cd8, author's repro with a screen recording, 2026-11-07
  22:44:19, first open, shifted; *verified* from the log, matched to
  the recording by its menu bar clock):
  - Both columns' top safe areas settled at 52 pt, with the title area
    52 pt and the toolbar installed.
  - The banner's top settled at **−64.5 to −67 pt** in the window, above
    its top edge, though the detail pane's safe area said 52 pt.
  - The sidebar's scroll view had the usual 52 pt inset and scroll
    position (−52), yet the recording shows its branding panel gone
    above the top. So the scroll positions were fine; the columns
    themselves were placed too high. That refutes the scroll position
    hypothesis in `[L-pause-banner-stack-still-shifts]`.
  - During the first 0.3 s the banner's top passed through 129, 0, 416,
    537.5, −84.5 pt as the window was set up.
  - The author found that making the window tall enough brings the
    banner on screen. *Hypothesis* (Claude): SwiftUI laid out the
    window's content taller than the window and centered it, so the
    top runs off the window; the pause makes the content taller.
    Untested. What sets that height is unknown.
- `[L-pause-banner-rigid-split]` Promoted to
  `[Q-fixed-size-text-rigid-split]` (2026-11-07). Guard runs, 2026-11-07
  (Claude, author's yes): the new
  `windowOpenedWhilePausedByOutsideChangeStartsBelowTheToolbar` failed
  on the build without the fix (both checks, one at −93.5 pt), then all
  three `PauseBannerTests` passed on the fix (*verified*, output). The
  notes below stay as the record. **The split view goes rigid at 943 pt
  when the banner's reason wraps** (build of f0bb2bc on
  `experiment/pause-banner-shift`, archived as tag
  `archive/experiment/pause-banner-shift`; the author's screen recording
  2026-11-07 23:00:08–23:01:53, matched to the log by its menu bar
  clock; Claude):
  - **Content taller than the window, centered: confirmed** (*verified*,
    log). The `NavigationSplitView`'s own frame was **943 pt tall**
    while the `.frame(minHeight: 480)` around it followed the window
    (672–848 pt). Its top sat at 52 + (container − 943) / 2, e.g. −83.5
    in a 672 pt container: SwiftUI centers an oversized child. The
    window, content view, layout rect, and `contentMinSize`
    (700 × 532) were all normal; the hosting view's fitting size read
    0 × 0. So the window doesn't know the content is too tall.
  - **The 943 never changed** while the author dragged the window from
    741 to 999 pt wide and through many heights, paused (*verified*,
    log, about 300 frames). On resume it snapped back to the container
    (598 pt in a 650 pt window).
  - **Shifted only with the two-line reason** (*observed*, three opens):
    23:00:25, paused from the menu, "Paused from the menu." on one
    line: opened right, split view following the window. 23:00:48 and
    23:01:18 (a relaunch), paused by an outside change, the reason
    wrapped to two lines: both opened shifted. The banner's reason text
    is the only view with `.fixedSize(horizontal: false, vertical:
    true)`.
  - *Hypothesis* (Claude, untested): while sizing the column, SwiftUI
    measures that text at a very narrow width, where it wraps to many
    lines, and the resulting rigid height becomes the split view's
    height. Why a one-line reason doesn't trigger it, and why the
    number is 943, are unexplained. `[L-pause-banner-inset]`'s first
    sighting may fit too, if that pause came from an outside change
    (not recorded). *Observed* later (Claude, 2026-11-07, from the
    author's screenshots): every shifted screenshot shows the outside
    change reason, "…because the wallpaper was changed in System
    Settings.", the first sighting included.
  - **Dropping the `.fixedSize` fixed it** (build of 54b28b1, the
    author's runs 2026-11-07 23:09–23:21, with a screen recording from
    23:18:47; Claude, from the log and the recording). Five opens while
    paused by an outside change, window closed beforehand, two of them
    after a relaunch (23:19:19, 23:19:45, 23:20:07, 23:21:19, plus a
    reopen at 23:19:59): every one settled with the split view filling
    the window (583 pt in a 635 pt window) and the banner's top at 52 pt
    (*verified*, log); the recording shows all three opens it covers
    drawn right (*observed*). The reason still wraps to two lines at
    the 460 pt minimum editor width: banner 460 × 67 pt (*verified*,
    log; *observed*, the author's screenshot), not cut off.
  - **Why the UI tests missed it:** `PauseBannerTests` pause from the
    menu, so the reason is one line ("Paused from the menu."), the case
    that never shifted. A guard needs an outside-change pause at launch.
  - Still unexplained: the 943 pt figure, and why a one-line reason
    under the same `.fixedSize` never triggered it.
