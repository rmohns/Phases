# Phases spec: Wallpaper changed outside Phases

Part of the Phases specification. [SPEC.md](../SPEC.md) is its front
page: the draft number, the "Design decisions" rules, and the list of
spec files.

What's here: noticing a wallpaper set by something else, and pausing.

## Wallpaper changed outside Phases

- `[D-outside-change-pauses]` **When someone picks a wallpaper in System
  Settings (or any other app), Phases pauses everything** and steps
  aside until it's resumed. Nothing is asked first.
  - *Why:* picking a wallpaper is a clear statement of what the person
    wants on screen now. Before this, Phases hid the pick behind its cover
    and then overrode it at its next change, 9 s and 23 s later in the
    experiment (*verified* 2026-11-06, LEARNINGS.md `[L-store-watch]`), so
    the pick looked broken. Pausing is the author's call (2026-11-06,
    GitHub issue #5).
- **What pausing does:**
  - Scheduled changes stop, exactly as with **Pause Wallpaper Changes** in the menu: it's the
    same paused state, saved across launches, with a reason attached
    (see "Interface" below; since the split into files,
    [interface.md](interface.md) and [window.md](window.md)).
  - Any cover on the changed display fades out over the Transition
    duration, revealing the pick. Covers on other displays stay, as with
    Pause `[D-cover-pause-quit]`. With Transition set to None it's a cut.
  - The pick becomes that display's "original" in the restore record, so
    Quit restores it, not the wallpaper from before Phases launched
    `[D-restore-on-quit]`. An Aerial pick marks the display as an Aerial,
    which Quit leaves alone `[D-aerials-untouched]`.
- **Resuming** (any of the controls under "Interface") applies the active
  phase's image right away, with the usual transition, and the schedule
  carries on. The restore record keeps the pick.
- **Change Now while paused** changes the image once and stays paused, as
  it does with Pause Wallpaper Changes. Change Now is a deliberate one-off,
  so pausing doesn't block it; that's why the pause controls say "Pause
  wallpaper changes", not "Pause all wallpaper changes"
  `[D-menu-pause-verb]`.
- `[D-outside-change-rule]` **How a change is recognised:** Phases watches
  macOS's wallpaper store (read only, as `[D-aerials-untouched]` already
  does), event-driven with no polling. A change counts as outside when an
  entry for a display (macOS only sets the showing Space's) gets a new
  "last set" time and its image isn't one Phases set on that display in
  the last 10 seconds. Store details: ERRATA.md `[Q-wallpaper-store]`.
  - A new Space doesn't count. Making a desktop in Mission Control or
    taking an app full screen gives the new Space copies of the
    display's entries, keeping their old "last set" time, so an entry
    Phases hasn't seen before counts only when it was set later than
    anything already in the store. A real pick on a new Space still
    counts. Store details: ERRATA.md `[Q-new-space-copies-entry]`
    (draft 48, GitHub issue #29).
  - Writes that change only the "last used" time are ignored: opening or
    quitting System Settings and switching Spaces make them (*verified*
    2026-11-06, `[L-store-watch]`).
  - The store, not `NSWorkspace`, is the source: for an Aerial,
    `desktopImageURL` reports a placeholder (`DefaultDesktop.heic`), and
    it kept reporting one Space's image while another Space was showing
    (*observed* 2026-11-06).
  - The rule is a pure function, unit-tested `[D-tests-unhosted]`.
  - A pick of the same image Phases already shows isn't noticed. Nothing
    on screen changes, so nothing needs to.
- `[D-outside-change-notice]` **Telling the user:**
  - **Once, when it happens:** one macOS notification: "Phases paused.
    You chose a new wallpaper in System Settings. Phases won't change it
    until you resume." with a **Resume** action. Permission is asked the
    first time it's needed, not at launch. If it's denied, the lasting
    signs below still show.
  - `[D-notice-opens-window]` **Clicking the notification opens the
    Phases window,** exactly as "Open Phases…" does
    `[D-reopen-shows-window]`. It doesn't resume; the window's pause
    banner `[D-window-pause-banner]` offers that. Choosing **Resume**
    resumes and opens nothing.
    - If Phases isn't running (quit while the notification was still
      showing), the click launches it and the window opens once the
      launch finishes, as on the first launch
      `[D-first-launch-shows-window]`.
    - *Why:* the notification says what happened; the window is where
      the reason and the way back live. Until draft 50 a click on the
      notification only dismissed it (*observed* by the author,
      2026-11-07, `[L-pause-banner-stack-still-shifts]`; GitHub issue
      #31). Resume is a "just do it" action, so a window on top of it
      would be noise (author, 2026-11-08).
  - **Lasting:** the menu bar icon's paused look, the menu's status line,
    and the pause banner at the top of the Phases window
    `[D-window-pause-banner]` (see "Interface"). Draft 48 and earlier
    showed it only at the top of Settings.
  - *Why both:* the pick itself is what the person was looking at, so a
    notification is the only sign they'll get in the moment; the lasting
    signs answer "why isn't it changing?" later without nagging.
