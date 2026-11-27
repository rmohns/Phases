# Phases testing: Sandbox checks

Part of the testing docs. [TESTING.md](../TESTING.md) has the rules every
hands-on check follows (`[D-hands-on-checks]`: any check alone, who runs
it, proving the input landed), the unit tests, and what to do when a
fixed bug comes back. Moved here word for word from TESTING.md
"Hands-on checks" on 2026-11-27.

## Sandbox checks (draft 58)

- **When:** after any change to the entitlements `[D-sandbox-entitlements]`,
  to how Phases reads the wallpaper store, sources, or the original
  wallpaper, and before a change to the sandbox merges. Unit tests cover
  the decisions (`SystemWallpaperCheckTests`, the refusal cases in
  `FolderScanTests`), but only a launched, sandboxed build shows what
  macOS allows. Ask first, naming the checks; most change the real
  wallpaper and need the author at the Mac.
- **Which build's sandbox:** a Debug build's sandbox also reads
  `~/Library/Caches/PhasesUITests/` `[D-debug-test-folder]`. That changes
  nothing these checks look at, but a check of exactly what ships runs
  on a Release build.
- **Setup:** diagnostics on; read the log with
  `/usr/bin/log show --last 10m --style compact --predicate 'subsystem == "PhasesDiag"'`.
- **The checks:**
  1. **Settings:** phases, sources, and options are as they were.
  2. **Aerials left alone:** an Aerial on one display, a still on
     another. No "can't read the wallpaper store" line (`restore`,
     `store`); `store` says "watching the store: N entries". Quit with
     Restore on: the Aerial display logs "left alone on quit: system
     wallpaper", the other "restored". This is the check that the store
     exception works.
  3. **Folder sources** open, and still open after quit and relaunch
     (the log says "found by its bookmark").
  4. **Photos:** Change Now onto a Photos phase, an iCloud-only photo
     among them if one is handy. A failure only on iCloud photos points
     at a missing `network.client`.
  5. **Crossfade** on: Change Now, switch Spaces and back, change a
     display's resolution. No "cover: no surface" in `cover`.
  6. **Restore on quit** from an original outside every source (in
     `/System/Library/Desktop Pictures/` or `~/Downloads`): it comes
     back, logged "restored", not "file no longer exists".
  7. **Links:** a symlink or alias to an image outside the folder is
     missing from the grid, and `sources` logs "not permitted to read
     <name>"; one to an image inside the folder shows.
  8. **Location:** a dawn/dusk phase gets times once allowed.
  9. **Outside change:** a System Settings pick pauses Phases.
- **Not in the list:** a change missed while locked being applied at
  unlock has no hand-made way to produce it, and going back to an
  unsandboxed build isn't supported (SPEC.md `[D-sandbox-settings-move]`).
- Record results with date and build in this section.
- *Verified* 2026-11-22 by the author, build from `feature/19-sandbox`
  (draft 58), diagnostics on: **all nine pass**, with nothing failing in
  the log. 1: the container couldn't be inspected (TEST-TOOLS.md
  "Diagnostics"), so settings were checked in the app. 4: whether an
  iCloud-only photo was shown wasn't recorded. Details in SPEC.md
  "Hands-on checks of the first sandboxed build".
- 2026-11-22, build from `feature/xcode-project` (draft 59, bundle ID
  `com.robertmohns.phases`, after the settings move): checks 1–3
  **deferred** by the author to GitHub issue #43. The launch log showed
  the store read ("watching the store: 988 entries"), and the author
  *verified* settings and folder sources after Locate… in the app
  (SPEC.md `[D-bundle-id-settings-move]`).
- 2026-11-27, checks 1–3 from GitHub issue #43, on `main` at `c163148`
  (draft 64), a Bitrig Debug build started with `open`, diagnostics on,
  two displays:
  - 1 **passes** (*verified* by the author in the app).
  - 2 **fails**, twice: the store read fine ("watching the store: 1046
    entries"), but Quit logged "display 1 restored: DefaultDesktop.heic"
    for the built-in display's Aerial instead of "left alone on quit:
    system wallpaper"; the other display was "restored" correctly. Cause
    `[Q-store-kind-lastset]`, record `[X-43-aerial-kind]`.
  - 2 on the first fix (`fix/aerial-kind-lastset` at `0499087`), Aerial
    on the virtual display: that display **passes** ("left alone on quit:
    system wallpaper"), but the built-in display, showing a still, was
    also read as a system wallpaper (left alone for the wrong reason;
    no visible harm this time). Refined on the same branch.
  - 2 on the refined fix (`fix/aerial-kind-lastset` at `2b1dd1a`)
    **passes both ways round** (*verified* by Claude from the log; picks
    by the author): Aerial on the built-in (Quit 11:56:33: built-in "left
    alone on quit: system wallpaper", virtual "restored"), then Aerial on
    the virtual display (Quit 11:58:51: virtual left alone, built-in
    "restored"). The new `kind` lines named each display's own entry at
    every pick. Record `[X-43-aerial-kind]`, runs 5 and 6.
  - 3 **passes**: "found by its bookmark" for both folder sources at
    every launch (10:51, 11:00, 11:03, 11:20, 11:27; *verified* by
    Claude), and both folders show their images in the app after
    relaunching (*verified* by the author).
