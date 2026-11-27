# Phases testing: Outside change check

Part of the testing docs. [TESTING.md](../TESTING.md) has the rules every
hands-on check follows (`[D-hands-on-checks]`: any check alone, who runs
it, proving the input landed), the unit tests, and what to do when a
fixed bug comes back. Moved here word for word from TESTING.md
"Hands-on checks" on 2026-11-27.

## Outside change check (draft 37)

- `[D-outside-change-check]` **Pausing for a wallpaper picked elsewhere
  is checked by hand** before it merges, and after any change to
  `WallpaperStoreWatcher`, `OutsideChangeRule`, `PauseNotifier`, or
  `WindowRequest`. It needs the real wallpaper and System Settings, out
  of reach of the unit tests.
  - Build: the newest Bitrig Debug build, crossfades on, diagnostics on
    (log category `store`).
  - 1. Let Phases change once (Change Now): no outside change logged.
  - 2. Pick a still in System Settings › Wallpaper: the cover fades out,
    the pick shows, the menu bar icon gets its pause badge, one
    notification appears, the menu header reads "Paused · wallpaper
    changed in System Settings", and Settings' switch is off with the time.
  - 3. Open and quit System Settings, and switch Spaces: nothing more is
    logged as an outside change.
  - 4. Resume from the notification, the menu, and the Settings switch
    in turn (re-pausing with a pick each time): the phase's image comes
    back at once with a crossfade, the badge goes, the schedule resumes.
  - 5. Pick an Aerial: same as step 2.
  - 6. With restore on, pick a still, then Quit: the pick stays (it's the
    new original).
  - 7. `[D-notice-opens-window]` Click the notification's body (not
    Resume), re-pausing with a pick each time: with the window closed,
    minimized, and open on another Space, the window comes to the front
    on the current Space with the pause banner showing, and Phases stays
    paused. The log (category `reopen`) shows one "window requested by
    notification" per click; a second "by relaunch" line would mean
    macOS also sent a reopen (harmless, but note it in EXPERIMENTS.md
    `[X-notice-click]`; LEARNINGS.md until 2026-11-09).
  - 8. Re-pause with a pick, Quit Phases, then click the notification in
    Notification Center: Phases launches and its window opens with the
    banner. (Added draft 50, GitHub issue #31.)
  - *Verified* 2026-11-08 by the author, steps 7–8 only, one display:
    every body click opened the window in front with the banner. Step 7
    (closed, minimized, another Space) on the build of e6336d6; step 8
    (after a quit) and step 7 again (closed) on the build of d57f146,
    which fixed step 8's window staying behind. Claude checked the log: one notification
    request per click, plus macOS's relaunch when Phases was running;
    no second copy. Run the build Launch Services knows; see
    `[L-notice-click-launches-copy]` in EXPERIMENTS.md `[X-notice-click]`
    (LEARNINGS.md until 2026-11-09).
  - *Verified* 2026-11-06 by the author on the draft 37 build: picks in
    System Settings paused Phases with one notification each, Resume
    worked from the notification and Settings, and the new menu header
    and Resume Schedule item read correctly. Claude checked steps 1–2 in
    the log (detection about 2 s after the pick, no false pause on
    Phases' own sets). Two displays untested.
