# Phases — Specification (draft 5)

A personal macOS menu bar app that changes the desktop wallpaper on a schedule.
Not intended for the App Store.

## 1. Core model: phases plus rotation

The schedule is a list of **phases**. Exactly one phase is active at any moment.

Each phase has:

| Field | Description |
|---|---|
| Name | e.g. "Morning", "Night" |
| Start trigger | When the phase begins (see §2) |
| Images | One or more images chosen from the image library (multi-select) |
| Order | Random or In order |
| Rotation | Optional: change to the next image every N minutes or hours while the phase is active |
| Appearance | Only in: **Any** (default), **Light**, or **Dark** mode (see §2a) |

**Which phase is active:** among phases whose appearance condition matches the
current system appearance, the one whose start trigger fired most recently
(looking back up to two days). So if "Night" starts at dusk and "Day" starts at
dawn, at 2 am "Night" is active. If no timed phase qualifies, the first matching
"Always" phase is used.

**Pure periodic changes** (no time-of-day switching) is just a single phase with
the "Always" trigger plus a rotation interval.

**When a phase starts**, the wallpaper changes immediately to that phase's first
image (in order) or a random one. Rotation then continues within the phase.

**In order** cycles through the phase's selected images in filename order and
remembers its position across launches. **Random** avoids repeating the current
image when there's more than one choice.

## 2. Start triggers

| Trigger | Example |
|---|---|
| Always | Used when no timed phase applies; for pure rotation or appearance-only setups |
| Clock time | 3:30 pm, every day |
| Civil dawn | Sun 6° below horizon, morning |
| Civil dusk | Sun 6° below horizon, evening |
| Dawn/dusk + offset | 30 minutes before dusk; 1 hour after dawn (−12 h to +12 h) |

- Dawn and dusk are calculated on the Mac (NOAA solar algorithm), with no network calls.
- Times are recalculated each day and whenever the location or time zone changes.
- If civil dawn or dusk doesn't happen on a given day (far north or south), that
  trigger is skipped that day and the previous phase stays active.

## 2a. Light and Dark Mode

- Each phase has an **Only in** setting: Any, Light, or Dark.
- The app listens for system appearance changes (including Auto switching) and
  re-evaluates immediately. If the switch makes a different phase active, the
  wallpaper changes right away; otherwise nothing happens.
- Examples:
  - *Dark images whenever Dark Mode is on:* two "Always" phases, one Light and one Dark.
  - *Dusk pictures, darker ones in Dark Mode:* two dusk phases, one Light and one Dark.
- The phase list shows a light/dark badge on phases with a condition.

## 3. Image library

- **App preference:** a single image folder, chosen with a standard folder picker.
- **App preference: Include subfolders** (off by default). When on, the folder is
  scanned recursively, skipping hidden folders and packages (app bundles, Photos
  libraries, etc.).
- Supported formats: JPEG, PNG, HEIC, TIFF.
- Images are identified by their path relative to the folder (e.g.
  `Winter/snow.jpg`), so top-level selections stay valid when subfolders are
  turned on. Turning subfolders off makes subfolder images show as missing
  rather than silently dropping them.
- Access to the folder persists across launches (bookmark).
- The Schedule window shows the library as a **thumbnail grid**, grouped under a
  heading per subfolder when subfolders are on. Click toggles an image in or out
  of the selection, ⇧-click selects a range, plus Select All / Select None buttons.
- If a selected image is later deleted or renamed, it's skipped and the phase
  editor marks it as missing. A phase with no available images is skipped
  (the wallpaper stays as it is).

## 4. Displays

- Preference: **Same image on all displays** (default) or **Different image per
  display** (each display draws its own pick from the active phase's images).
- Changes apply to the current Space on each display (macOS limitation; see §9).

## 4a. Transitions

- **App preference: Transition**: None or **Crossfade** (default).
- **App preference: Duration**: 0.5 to 3 seconds (default 1 second), shown
  only when Crossfade is selected.
- macOS has no transition for wallpapers set by apps, so Phases does it itself
  by **fading the new image in over the old wallpaper**:
  1. **Cover:** on each screen whose image is changing, a borderless,
     click-through window shows the *incoming* image, fully transparent. It
     sits just above the desktop picture and below the desktop icons, so icons
     and windows don't flicker. It covers the full screen, including under the
     menu bar.
  2. **Fade in:** the cover fades to fully opaque over the chosen duration.
     The real wallpaper hasn't changed yet.
  3. **Switch:** the new wallpaper is set behind the now-opaque cover, which
     shows the identical image.
  4. **Remove:** after a short settle delay (0.5 s) to let macOS finish drawing
     the new wallpaper, the cover is removed. This is invisible, since the
     cover and the wallpaper match.
- The cover draws the incoming image the way macOS will, using that screen's
  scaling (fill, fit, stretch, or center) and fill color.
- The cover is drawn from the image file. No screenshots and no Screen
  Recording permission.
- **No fade (instant switch) when:**
  - Transition is set to None
  - Reduce Motion is on (System Settings › Accessibility › Display)
  - The incoming image file can't be read (that screen only)
  - A screen's image isn't actually changing (that screen only)
  - Restoring the original wallpaper on quit (§8a)
- If another change starts while a fade is running, the running fade finishes
  instantly (its wallpaper is set and its cover removed) and the new change
  starts its own fade.

### Why fade in, not fade out (design history)

Draft 4 did the reverse: it covered the screen with the *outgoing* image, set the
new wallpaper immediately, and faded the cover out. Testing found two problems:

1. **Flash and twitch.** The new wallpaper could reach the screen before the
   cover did, briefly showing the new image (and macOS's own wallpaper-change
   motion) before the fade. Draft 4.1 worked around this by waiting for the
   cover to be on screen and suppressing window resize/appear animations.
2. **Menu bar blink.** macOS picks the menu bar's text color and shadow from
   the *actual* wallpaper, ignoring windows above it. Setting the wallpaper at
   the start of the fade switched the menu bar immediately, while the screen
   still showed the old image (most visible going from light to dark).

Fading the new image in and setting the wallpaper at the end fixes both: the
wallpaper changes behind an identical image, and the menu bar switches once, at
the end, just as it does when changing wallpaper in System Settings. The menu
bar's own switch is still instant; macOS doesn't animate it. The draft 4.1
workarounds were removed as no longer needed.

A side benefit: the old wallpaper is never redrawn, so crossfades now work when
the outgoing wallpaper is an Aerial.

## 5. Missed changes: sleep, wake, unlock

On launch, wake from sleep, screen unlock, and time zone / clock changes, the app:

1. Works out which phase should be active right now.
2. If it differs from the last phase it applied, switches to it immediately.
3. If the same phase is active but one or more rotations came due while asleep,
   it applies only the **most recent** missed rotation: the image that would be
   showing now had the Mac stayed awake. For In order, that means skipping ahead
   by the number of missed rotations; for Random, a single new random pick. The
   rotation clock stays aligned to the original schedule.

## 6. Location

- Uses Location Services. Permission is requested only when a phase first uses
  a dawn/dusk trigger, not at launch.
- Settings shows the current location, today's civil dawn and dusk, when the
  location was last updated, and an **Update Now** button.
- Uses low-accuracy, infrequent updates. The last known location is saved so
  dawn/dusk still work offline or after a restart.
- If permission is denied: dawn/dusk phases are disabled and marked with a
  warning, and the menu explains how to turn it on in System Settings. Clock and
  "Always" phases keep working.

## 7. Interface

### Menu bar menu
- Icon: SF Symbol (e.g. `photo.on.rectangle`)
- Active phase name and current image name
- "Next change: Dusk phase at 6:12 pm" (or the next rotation time)
- **Change Now**: advances to the next image in the active phase
- **Pause / Resume** scheduling (saved across launches)
- **Schedule…**: opens the Schedule window
- **Settings…**
- **Quit Phases** (⌘Q)

Only Quit has a keyboard shortcut. Shortcuts in a menu bar extra's menu work
only while that menu is open, so others would be mostly decoration; Apple's own
menu bar extras don't show them. ⌘Q stays as a familiar convention. No global
hotkey.

### Schedule window (used most often)
- Its own resizable window.
- Phase list on the left, sorted by start time (add, remove), with the active
  phase marked.
- Editor for the selected phase: name, trigger, offset, appearance condition,
  order, rotation, and the thumbnail grid.

### Settings window
- Image folder and Include subfolders
- Display mode
- Transition and duration
- Launch at Login
- Location status, with today's civil dawn and dusk

No Dock icon. The app runs as a menu bar accessory.

## 8. Launch at login: explicit consent only

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

## 8a. Restore original wallpaper on quit

- At launch, before changing anything, Phases records each display's current
  wallpaper (image file plus fill/scaling options), keyed by display ID.
- The record is saved to disk and kept until it's been restored. After a crash
  or Force Quit, the next launch reuses it instead of recording Phases' own image.
- On an actual **Quit**, Phases restores each display's original and clears the
  record. Logout, restart, shutdown, and **Pause** leave the current image in
  place; at logout the record is kept for the next launch.
- **Aerials and other system wallpapers:** Phases reads (never writes) macOS's
  wallpaper store to detect them. The public API can't restore them, so those
  displays are left alone on quit instead of getting a still frame.
- Displays that were disconnected in the meantime are skipped. If the original
  image file no longer exists, that display is skipped.

## 9. Platform notes and limitations

- `NSWorkspace.setDesktopImageURL(_:for:options:)` sets the image **per screen**,
  so different images per display are supported.
- It only affects the **currently active Space** on each screen. Other Spaces
  keep their own wallpaper. There is no public API to set every Space.
- With "Displays have separate Spaces" on (the macOS default), each display has
  its own current Space, and the app sets each one.
- Scheduling uses a single timer aimed at the next event, recalculated after
  every change, wake, or settings edit, with an hourly re-check as a safety net
  against clock drift. No polling loop.

## 10. Persistence

All settings (folder bookmark, phases, preferences, in-order positions, last
applied phase, last location) are stored in UserDefaults as Codable data.

## 11. Out of scope (v1)

- Different schedules per weekday
- Multiple folders or online image sources
- Different wallpaper per Space
- Scaling/fill options (uses the current macOS fill setting)

## 12. Known issues

- Unreproduced: the desktop once turned black. Source folder is local storage
  (not a cloud-synced folder). No change until it can be reproduced.
- Restoring an Aerial isn't supported yet (see §8a). Possible approach: back up
  and restore macOS's wallpaper store file and restart the wallpaper process.
  Undocumented, so it needs explicit approval before building.
