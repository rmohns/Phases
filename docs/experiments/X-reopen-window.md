# `[X-reopen-window]` Launching Phases again while it runs

Part of "Other investigations" in [EXPERIMENTS.md](../EXPERIMENTS.md), the index of
experiments. Moved here word for word from EXPERIMENTS.md on
2026-11-27, when each record got its own file.
The group's introduction there applies to this record too; copied
here so the record reads on its own:

> Until 2026-11-09 this section was called "Open questions"; most of what
> it held has since been answered. What's still open is under "Still
> open" at its end.


- **Question:** what happens when Phases is launched again while it's
  running, and can the menu bar icon's view open the window? (Issue #13.)
- **When, on what:** 2026-11-03, macOS 27.2; runs from Terminal with
  `open`, then `RelaunchTests`.
- **Branches:** `experiment/reopen-window`, tag
  `archive/experiment/reopen-window`; the feature on
  `feature/reopen-window`, tag `archive/feature/reopen-window`.
- **Outcome:** the menu bar icon's view handles the reopen request;
  promoted to `[Q-reopen-ignores-closed-window]`. Along the way the UI
  test harness's newest-build pick was found broken and fixed. Two early
  `RelaunchTests` failures are still unexplained (22 passes since).
- **Findings:** `[L-reopen-event]`.

- `[L-reopen-event]` **What happens when Phases is launched again while
  it's running, and can the menu bar icon's view open the window?**
  (Issue #13, macOS 27.2.) Answered; experiment on branch
  `experiment/reopen-window` (tag `archive/experiment/reopen-window`),
  started 2026-11-03.
  - Promoted to `[Q-reopen-ignores-closed-window]` (2026-11-03).
  - Setup: an app delegate logs `applicationShouldHandleReopen`, then the
    window's state 0.5 s later, under diagnostics category `reopen`.
    Mode switch `PhasesReopenMode`: `none` (log only, AppKit and SwiftUI
    defaults) or `label` (the menu bar icon's view opens the window the
    way "Open Phases…" does).
  - Questions: does a menu bar accessory get the reopen call at all; does
    SwiftUI already show a `.suppressed` `Window` on reopen; does the
    label view stay alive to act on a request while the window is closed;
    does activation succeed `[Q-launch-activate-refused]`.
  - Run 1, mode `none`, window never opened (2026-11-03, Claude, `open`
    from Terminal, read from the log; *verified*): the reopen call
    arrives (`hasVisibleWindows=false`), Phases becomes active, still an
    accessory (policy 1), and SwiftUI creates no window, so nothing
    shows. So a menu bar accessory does get reopen, and activation is
    granted on a relaunch, unlike `[Q-launch-activate-refused]`.
  - Run 2, mode `none`, window open behind Bitrig (2026-11-03, same
    method; *verified* from the log): Phases became active (regular,
    policy 0) and the window came forward as key, on the active Space.
    Plain activation already covers this case; nothing to add. The
    author saw the window come to the front (*observed*, same run).
  - Run 3, mode `none`, window closed after being open (2026-11-03,
    same method; *verified* from the log): reopen arrives
    (`hasVisibleWindows=false`), Phases becomes active as an accessory
    (policy 1), and the kept, hidden window stays hidden. SwiftUI doesn't
    re-show it. Same gap as run 1. The author saw focus leave Bitrig and
    nothing else (*observed*, same run): today a relaunch takes focus
    from the user's app and shows nothing in exchange.
  - Run 4, mode `none`, window minimized (2026-11-03, same method;
    *verified* from the log): reopen arrives with
    `hasVisibleWindows=true` even though the only window is minimized
    (AppKit counts it), and AppKit's default handling un-minimizes it:
    0.5 s later it's visible, key, not minimized. The author saw it come
    up from the Dock with focus (*observed*, same run). Nothing to add.
  - Run 5a, mode `label`, window never opened (2026-11-03, same method;
    *verified* from the log): the menu bar icon's view received the
    request in the same millisecond as the reopen call and opened the
    window. 0.5 s later Phases was regular (policy 0), the window
    visible, key, and on the active Space. So the label view is alive
    and able to call `openWindow` while no window exists. The author saw
    the window open (*observed*, same run).
  - Run 5b, mode `label`, window closed with ⌘W (2026-11-03, same
    method; *verified* from the log): the label re-showed the kept
    window; 0.5 s later Phases was regular and the window visible and
    key on the active Space. The author saw it (*observed*, same run).
  - Run 5c, mode `label`, window minimized (2026-11-03, same method;
    *verified* from the log): the label's open routine un-minimized it;
    0.5 s later visible, key, not minimized. The author saw it come back
    up from the Dock (*observed*, same run).
  - **Answer (2026-11-03):** a menu bar accessory does get the reopen
    call, and activation is granted. SwiftUI and AppKit handle the open
    and minimized cases on their own but ignore a closed or never-opened
    window. Handing the request to the menu bar icon's view, which runs
    the "Open Phases…" routine, covers all three. The mode switch was
    deleted after the runs (the running process had already read
    `label`, so run 6 still used it).
  - Run 6, mode `label`, window moved to Space 2 and closed there, author
    back on Space 1 (2026-11-03, author's request, same method;
    *verified* from the log): the window was off the active Space, the
    `[D-open-here]` flag moved it, and it arrived on Space 1 140 ms
    later, visible and key. The author saw it open on Space 1 and called
    that acceptable (*observed*, same run). It's what `[D-open-here]`
    already promises for "Open Phases…".
  - **UI test failure, 2026-11-03, `feature/reopen-window` at `d4b73d3`**
    (tag `archive/feature/reopen-window`)
    (Claude): `RelaunchTests/relaunchWithTheWindowClosedShowsIt` failed
    twice (the second run was an accident of a piped command). The test
    sends the reopen Apple event straight to the process. The log shows
    the handler fired and the opening routine ran (`relaunched`, then
    the Space mover's line), but the window never showed and Phases
    ended with no Dock icon (*verified*). Unlike the experiment's `open`,
    nothing activated Phases first: in every experiment run, "became
    active" was logged *before* the reopen call (*verified*), so Launch
    Services activates, then reopens. Hypothesis, untested: the routine
    fails when Phases isn't already active.
  - Rerun with state logging, 2026-11-03 18:00 (Claude, one run): the
    test **passed**, with `active=false policy=1` logged at the reopen
    call (*verified*). So "fails when not active" is wrong: the routine
    can show the window from an inactive accessory. Two failures and one
    pass on the same code point to something intermittent (*hypothesis*).
    The +0.5 s and +2 s lines never logged: the test force-quits Phases
    as soon as the window appears (*likely*, not checked).
  - Five more runs, 2026-11-03 18:02–18:04 (Claude), the test holding
    Phases 3 s after the window appears: **5 of 5 passed** (*verified*).
    Each logged inactive accessory at the reopen call, then active,
    regular, and the window visible and key 0.5 s later. So: 6 of 6
    pass on the build with the delayed log lines, 0 of 2 on the build
    without them.
  - *Hypothesis* (untested): the delayed log lines are what make it
    work. They're timers that wake Phases' main run loop; without them,
    an inactive menu bar app may sit idle with SwiftUI's `openWindow`
    queued and never carried out. The experiment build had a delayed
    log line too, and `open` activates Phases first, which also wakes it.
  - Timers-off check, 2026-11-03 18:06 (Claude, 3 runs): **invalid.** All
    3 passed, but every run logged the +0.5 s and +2 s lines, so the
    harness launched an older build, not the timers-off one built at
    18:06 (*verified* from the log).
  - **Cause: the harness's "newest build" pick is broken** (*verified*,
    `stat`, 18:07). It compares the `Phases.app` bundles' modification
    dates, but Bitrig gives every bundle the same date (12:36:03 for all
    three builds present), so the pick among ties follows directory
    order: effectively arbitrary. Only the executable inside carries the
    build time (17:47, 18:00, 18:06). Any UI test run made while several
    builds sat in the Builds folder may have tested an older build than
    intended. Which build each earlier relaunch run used is known only
    from its log format.
  - Harness fixed (pick by executable date, print the build). Timers-off
    check redone, 2026-11-03 18:09–18:10 (Claude, 3 runs, build of
    18:09:32 confirmed by the harness's printout and by the missing
    timer lines): **3 of 3 passed** (*verified*). The timer hypothesis is
    wrong.
  - The experiment Phases (pid 79653) quit at 17:48:36, before the
    failing runs (*verified*, system log), so a second instance wasn't
    the cause either.
  - **Still unexplained:** the two 17:49 failures ran the same relaunch
    code (their log format shows it) and never got the window. Since
    then, 12 of 12 runs passed (1 + 5 + 3 + 3; all ran this relaunch
    code, 9 of them with the timer lines). The failing runs logged nothing after the
    opening routine started, so where it stopped is unknown. The only
    known difference: they were the session's first relaunch test runs.
  - Ten more runs, 2026-11-03 18:19–18:22 (Claude, author's request,
    pinned with `PHASES_APP` to the 18:11:16 build of the committed
    code, since another conversation was active in the workspace):
    **10 of 10 passed** (*verified*). Tally since the two failures: 22 of
    22.
