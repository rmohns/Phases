# Wallpaper Scheduler — Specification (draft 1)

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

**Which phase is active:** the one whose start trigger fired most recently,
looking back through today and yesterday. So if "Night" starts at dusk and
"Day" starts at dawn, at 2 am "Night" is active.

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
| Always | The only phase; used for pure rotation |
| Clock time | 3:30 pm, every day |
| Civil dawn | Sun 6° below horizon, morning |
| Civil dusk | Sun 6° below horizon, evening |
| Dawn/dusk + offset | 30 minutes before dusk; 1 hour after dawn (−12 h to +12 h) |

- Dawn and dusk are calculated on the Mac (NOAA solar algorithm), with no network calls.
- Times are recalculated each day and whenever the location or time zone changes.
- If civil dawn or dusk doesn't happen on a given day (far north or south), that
  trigger is skipped that day and the previous phase stays active.

## 3. Image library

- **App preference:** a single image folder, chosen with a standard folder picker.
- Top-level files only (not subfolders). Supported formats: JPEG, PNG, HEIC, TIFF.
- Access to the folder persists across launches (security-scoped bookmark).
- The phase editor shows the folder as a **thumbnail grid**. Click to select,
  ⌘-click / ⇧-click for multi-select, plus Select All / Deselect All buttons.
- If a selected image is later deleted or renamed, it's skipped and the phase
  editor marks it as missing. A phase with no available images is skipped
  (the wallpaper stays as it is).

## 4. Displays

- Preference: **Same image on all displays** (default) or **Different image per
  display** (each display draws its own pick from the active phase's images).
- Changes apply to the current Space on each display (macOS limitation; see §9).

## 5. Missed changes: sleep, wake, unlock

On launch, wake from sleep, screen unlock, and time zone / clock changes, the app:

1. Works out which phase should be active right now.
2. If it differs from the last phase it applied, switches to it immediately.
3. If the same phase is active but a rotation came due while asleep, rotates once
   (it doesn't replay every missed rotation).

## 6. Location

- Uses Location Services. Permission is requested only when a phase first uses
  a dawn/dusk trigger, not at launch.
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
- **Settings…**
- **Quit**

### Settings window
- **General:** image folder, display mode, Launch at Login, location status
- **Phases:** list of phases (add, remove, reorder by start time) and an editor
  for the selected phase: name, trigger, offset, thumbnail grid, order, rotation

No Dock icon. The app runs as a menu bar accessory.

## 8. Launch at login: explicit consent only

- Preference **Launch at Login**, **off by default**.
- The app never turns it on by itself. Turning it on shows a confirmation that
  explains what it does ("Adds Wallpaper Scheduler to System Settings › General ›
  Login Items") before anything is registered.
- Implemented with `SMAppService.mainApp`, which registers the app itself as a
  standard Login Item. It does **not** install a LaunchAgent plist or any daemon,
  and the app installs no other agents, daemons, or helpers. If that ever
  changes, the app has to ask first.
- Turning it off unregisters it. If the user removes it in System Settings, the
  preference updates to match.

## 9. Platform notes and limitations

- `NSWorkspace.setDesktopImageURL(_:for:options:)` sets the image **per screen**,
  so different images per display are supported.
- It only affects the **currently active Space** on each screen. Other Spaces
  keep their own wallpaper. There is no public API to set every Space.
- With "Displays have separate Spaces" on (the macOS default), each display has
  its own current Space, and the app sets each one.
- Scheduling uses a single timer aimed at the next event, recalculated after
  every change, wake, or settings edit. No polling loop.

## 10. Persistence

All settings (folder bookmark, phases, preferences, in-order positions, last
applied phase, last location) are stored in UserDefaults as Codable data.

## 11. Out of scope (v1)

- Different schedules per weekday
- Subfolders, multiple folders, or online image sources
- Different wallpaper per Space
- Scaling/fill options (uses the current macOS fill setting)
