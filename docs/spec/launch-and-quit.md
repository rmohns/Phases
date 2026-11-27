# Phases spec: Launch at login and quit

Part of the Phases specification. [SPEC.md](../SPEC.md) is its front
page: the draft number, the "Design decisions" rules, and the list of
spec files.

What's here: launch at login, and putting the original wallpaper back
on quit.

## Launch at login: explicit consent only

`[D-login-consent]`

- Preference **Launch at Login**, **off by default**.
- The app never turns it on by itself. Turning it on shows a confirmation that
  explains what it does ("Adds Phases to System Settings › General ›
  Login Items") before anything is registered.
- Implemented with `SMAppService.mainApp`, which registers the app itself as a
  standard Login Item. It does **not** install a LaunchAgent plist or any daemon,
  and the app installs no other agents, daemons, or helpers. If that ever
  changes, the app has to ask first.
- Turning it off unregisters it. If the user removes it in System Settings, the
  preference updates to match.

## Restore original wallpaper on quit

- At launch, before changing anything, Phases records each display's current
  wallpaper (image file plus fill/scaling options), keyed by display ID.
- The record is saved to disk and kept until it's been restored. After a crash
  or Force Quit, the next launch reuses it instead of recording Phases' own image.
- A wallpaper picked outside Phases while it runs replaces that display's
  entry in the record `[D-outside-change-pauses]`.
- `[D-restore-on-quit]` **App preference: Restore original wallpaper when
  quitting**, **on by default**. When on, an actual **Quit** restores each
  display's original and clears the record, and the next launch puts Phases'
  image back right away, even within the same rotation (until draft 53 it
  waited for the next change). When off, Quit leaves Phases'
  current image in place and clears the record, so the kept image becomes the
  "original" the next launch records.
  - *Why a preference:* restoring is what the author expects (Phases' images
    belong to Phases), but someone else may expect the wallpaper to stay as
    it is after the app quits. Both are valid ways to use the app. Draft 12
    and earlier always restored.
  - Logout, restart, shutdown, and **Pause** leave the current image in
    place regardless of the setting; at logout the record is kept for the
    next launch.
  - **Only the showing Space is restored.** The record holds each
    display's wallpaper on the Space showing at launch, and Quit restores
    whichever Space is showing on each display then. Other Spaces keep the
    image Phases last set while they were showing: macOS offers no way to
    set a Space that isn't showing (see "Platform notes and limitations").
    Accepted by the author (2026-10-31).
- `[D-aerials-untouched]` **Aerials and other system wallpapers:** Phases
  reads (never writes) macOS's
  wallpaper store to detect them. The public API can't restore them, so those
  displays are left alone on quit instead of getting a still frame.
  - From draft 58, a display whose wallpaper couldn't be checked (the store
    unreadable, or no entry for the display) is left alone the same way
    `[D-store-unreadable-safe]`. Until then an unreadable store read as
    "no system wallpapers."
- Displays that were disconnected in the meantime are skipped. If the original
  image file no longer exists, that display is skipped.
  - From draft 58, "no longer exists" means macOS says there's no such file;
    a file Phases isn't allowed to look at (sandbox) is restored anyway
    `[D-restore-file-check]`.
