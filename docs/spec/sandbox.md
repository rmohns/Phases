# Phases spec: Sandbox

Part of the Phases specification. [SPEC.md](../SPEC.md) is its front
page: the draft number, the "Design decisions" rules, and the list of
spec files.

What's here: the App Sandbox, its entitlements, what changes inside it,
moving settings into it, and the first sandboxed build's hands-on checks.

## Sandbox

`[D-sandboxed]` **Phases runs in the macOS App Sandbox** (draft 58,
GitHub issue #19).

- *Why:* containment. Phases runs all day with access to the wallpaper,
  the user's picture folders, Photos, and location; the sandbox limits
  what a bug (or anything that takes over the process) can reach to
  what Phases needs. It is **not** a step toward the App Store: Phases
  still isn't intended for it (see the opening), so App Review's dislike
  of temporary exceptions isn't a constraint (author, issue #19).
- **Signing:** the sandbox's privacy entitlements and the temporary
  exception need a development team (`[L-sandbox-team-needed]`,
  *verified* 2026-11-12, three builds). From draft 59 the Xcode project
  sets `DEVELOPMENT_TEAM = Y382W2CA47` (the author's team) on the Phases
  target. Through draft 58 `Project.json` set no team, and Bitrig signed
  with the team saved for the project in Bitrig.
  - *Resolved 2026-11-22:* the author approved setting the team in the
    project. The next build signed `Apple Development`, team Y382W2CA47,
    with the six entitlements plus `get-task-allow` (*verified* by Claude,
    codesign). The note below is kept as written.
  - *Open, 2026-11-22 by Claude:* the code doesn't meet this yet. Since
    the conversion `[D-xcode-project]`, Bitrig's Mac builds of the Xcode
    project are signed ad hoc with no team: Bitrig passed the saved team
    on the command line for `Project.json` builds, but doesn't for the
    Xcode project, even after `bitrig build --provision` registered the
    new ID (*verified*, three builds and their logs; `--provision` itself
    did get the team). Proposed fix, awaiting the author: set
    `DEVELOPMENT_TEAM = Y382W2CA47` on the Phases target, and change this
    line to say the project sets it. See LEARNINGS.md
    `[L-convert-xcode-project]`.

### Entitlements

`[D-sandbox-entitlements]` **Only these, each for something Phases does.**
Set in the entitlements file the Phases target's `CODE_SIGN_ENTITLEMENTS`
names (`App/Phases.entitlements`), edited directly, since `xcrun
xcodeproj` edits the project, not that file. Not through sandbox build
settings such as `ENABLE_APP_SANDBOX`, so all six stay in one place
(Debug builds use a copy with one test folder added
`[D-debug-test-folder]`). Build
settings that point at the file are changed with `xcrun xcodeproj`,
never by hand in the project file `[D-xcode-project]`.

- *Replaced:* through draft 58 the entitlements were set in
  `Project.json` (`entitlements`), and Bitrig generated the file from it
  on every build.

| Entitlement | Why Phases needs it |
|---|---|
| `com.apple.security.app-sandbox` | Turns the sandbox on. |
| `com.apple.security.files.user-selected.read-only` | Add Folder… and Locate… open a folder the user picks. Phases only reads image folders, never writes to them, so read-only. |
| `com.apple.security.files.bookmarks.app-scope` | Keeps access to those folders across launches through security-scoped bookmarks `[D-scoped-bookmarks]`. Apple's documentation lists it as needed for app-scoped bookmarks (*recalled* from the docs, read 2026-11-22; whether current macOS enforces it is untested). |
| `com.apple.security.personal-information.location` | Local dawn and dusk `[D-location-on-demand]` (see "Location"). |
| `com.apple.security.personal-information.photos-library` | Photos albums as sources (see "Photos albums"). |
| `com.apple.security.temporary-exception.files.home-relative-path.read-only` = `/Library/Application Support/com.apple.wallpaper/Store/` | Reading macOS's wallpaper store, read only: Aerials detection `[D-aerials-untouched]`, outside changes `[D-outside-change-rule]`, and the photo cache's keep list `[D-photos-cache]`. The folder, not just `Index.plist`, because macOS replaces the file on every write, so Phases watches the folder `[Q-wallpaper-store]`. Nothing wider. |

- **Not added, because Phases doesn't need them** (each a *hypothesis*
  until the first sandboxed run, see the hands-on checks below):
  - `network.client`: Phases makes no network requests of its own.
    iCloud photos are downloaded by macOS's Photos services on Phases'
    behalf (*recalled*).
  - Anything for Launch at Login: `SMAppService.mainApp` works in the
    sandbox (*recalled*).
  - Anything for setting the wallpaper: `setDesktopImageURL` works
    sandboxed, for files inside and outside the container
    (`[L-sandbox-x4-container-wallpaper]`, *verified* 2026-11-12).
  - Anything for notifications (user notifications, and listening for
    `com.apple.screenIsUnlocked`) (*recalled*).
  - Read-write file access, Apple Events, or any other exception.
- A new entitlement needs a row here, with its reason, before it's added.
- `[D-debug-test-folder]` **Debug builds can also read one test folder;
  Release builds, the ones that ship, can't** (draft 62). Debug builds
  sign with `App/Phases-Debug.entitlements`: the six above, plus
  `/Library/Caches/PhasesUITests/` added to the same home-relative
  read-only exception as the wallpaper store. Release builds keep
  `App/Phases.entitlements`, unchanged. The Phases target's
  `CODE_SIGN_ENTITLEMENTS` names one file per configuration.
  - *Why:* the UI tests run Debug builds and hand Phases image folders
    and a fake Photos library by launch argument `[D-ui-test-mode]`.
    Sandboxed, Phases can't open folders it wasn't given through the
    open panel or a bookmark, so 11 of 32 UI tests failed (2026-11-24,
    EXPERIMENTS.md `[X-ui-tests-sandboxed]`). The test runner can't
    write into Phases' container instead `[Q-container-closed-to-tests]`.
  - *Cost:* Debug and Release sandboxes differ by that one folder, which
    holds nothing but test images. A hands-on sandbox check on a Debug
    build sees the shipping sandbox plus that folder (TESTING.md
    "Sandbox checks").
  - *Guarded by* a unit test that Debug's entitlements are Release's
    plus exactly that path, so the two files can't drift apart.
  - *Rejected:* giving Bitrig Full Disk Access (every agent in every
    project could then reach every file); driving Add Folder…'s open
    panel in every test (slow and fragile).
- *Verified* 2026-11-22 by Claude: `bitrig build` signs with team
  Y382W2CA47 (no signing change needed), and `codesign -d --entitlements -`
  on the built app lists exactly these six, plus `get-task-allow`, which
  Debug development signing adds.

### What changes inside the sandbox

- **"Home" is the container.** The sandbox points
  `homeDirectoryForCurrentUser` and `NSHomeDirectory()` into
  `~/Library/Containers/<bundle ID>/Data` `[Q-sandbox-container-home]`.
  Everything Phases reads in the user's real home (the wallpaper store,
  saved locations `[D-source-location]`) is found from the real home,
  from the user database.
- **Phases' own files live in the container:** preferences, and the photo
  cache `[D-photos-cache]`.
- `[D-store-unreadable-safe]` **"Couldn't read the store" is never taken
  for "no Aerials".** When Phases can't read the wallpaper store (the
  exception missing, a macOS change, a file mid-replace), each display's
  wallpaper counts as **unchecked**, not as a plain image. An unchecked
  display is treated like an Aerial at Quit: left alone, never given a
  still frame `[D-aerials-untouched]`. The same goes for a display the
  store has no entry for.
  - The decision is a pure function, unit-tested `[D-tests-unhosted]`.
  - The diagnostics log says so (category `restore`), naming each
    display left alone and why.
  - Outside changes `[D-outside-change-rule]` can't be heard while the
    store can't be read; the log says so once, at launch (category
    `store`). The photo cache already keeps 30 days of files when the
    store can't be read `[D-photos-cache]`.
  - *Why:* in a sandboxed build without the exception, the store read
    fails silently (`[L-sandbox-x0-paths]`, *verified* 2026-11-12), and
    until draft 58 a failed read meant "no system wallpapers," so Quit
    would have replaced an Aerial with a still frame. A wallpaper Phases
    couldn't check is one it mustn't replace (author, issue #19).
- `[D-restore-file-check]` **Restoring checks a file is gone before
  skipping it.** Quit skips a display whose original image file no
  longer exists (see "Restore original wallpaper on quit"). Inside the
  sandbox, Phases may not be allowed to look at that file at all (it's
  rarely in a source folder). "Not allowed to look" isn't "gone": Phases
  restores it anyway, since macOS can set a file Phases can't read
  (`[L-sandbox-x4-container-wallpaper]`). Only "no such file" skips.
  Pure function, unit-tested.
- **Covers redrawn after a display change read with source access open**
  `[D-cover-follows-displays]` `[D-scoped-bookmarks]`. Until draft 58
  the redraw read its file without it, which worked only unsandboxed.
  Covers on a Space change don't read a file: a settled cover is
  removed, and a pending one just sets its wallpaper, which needs no
  access (`[L-sandbox-x4-container-wallpaper]`).
  - The crossfade reads only the incoming image, never the wallpaper it
    replaces, so a previous wallpaper outside every source doesn't stop
    a fade (*observed* in the code, 2026-11-22: the outgoing side is the
    real desktop or the existing cover).
- `[D-links-outside-refused]` **Links and aliases that point outside the
  source folder can't be read in the sandbox** (macOS says "not
  permitted"; *recalled*, issue #19 evaluation). Phases skips them, as
  it skips any item it can't open `[D-follow-links]`, and the
  diagnostics log names each one (category `library`) so a missing image
  can be explained. The same for a subfolder link whose folder can't be
  listed.
  - *Correction 2026-11-22 by Claude, after the code:* the category is
    `sources`, the library's existing one, not `library`. A broken link
    (target gone) is still skipped silently; only "not permitted" is
    logged.
  - Getting access to them (a second folder picker aimed at the target,
    and a second bookmark) is a later change, with issue #17.
- **A folder found only by its saved location can't be read in the
  sandbox,** because only a bookmark or a fresh pick grants access
  `[D-source-location]`. When the bookmark fails and the location leads
  to a folder Phases isn't allowed to list, the source shows "Can't
  open" with **Locate…** (see "Image library"), instead of looking
  empty. Outside the sandbox this changes nothing: a folder Phases finds
  it can list.
- **New bookmarks are read-only** (`securityScopeAllowOnlyReadAccess`),
  matching the read-only entitlement `[D-scoped-bookmarks]`.

### Settings when switching to the sandboxed build

- `[D-sandbox-settings-move]` **Existing settings carry over, by moving.**
  On the first sandboxed launch macOS moves Phases' preferences file from
  `~/Library/Preferences/` into the container's `Library/Preferences/`
  (`[L-sandbox-prefs-move]`, *verified* 2026-11-12 against a backup).
  Phases does nothing itself; it reads them as before. After that,
  `defaults` commands for the bundle ID read and write the container's
  copy (*verified* for `defaults import`; *inferred* for the others).
  - **Folder sources:** bookmarks made by an unsandboxed build may not
    open in the sandbox (*hypothesis*). If one doesn't, its source shows
    "Can't open"; **Locate…** picks it again and keeps its ID, so phases'
    selections come back. Bookmarks made inside the sandbox are
    read-only.
  - **Photos:** each new build asks for Photos access again
    (`[L-photos-grant-per-build]`, *verified*). Album and photo IDs carry
    over (`[L-photos-ids-stable]`, *verified*).
  - **Photo cache:** the sandboxed build starts a new, empty cache in the
    container and fetches as needed. The old cache at `~/Library/
    Application Support/Phases/Photos/` is left where it is (macOS moves
    only preferences, *observed* in round B), because other Spaces may
    still show files from it. It can be deleted by hand once no Space
    shows a photo from it.
  - **The restore record** is in the preferences, so it carries over.
  - **Location** may be asked for again (*hypothesis*).
- **Going back to an unsandboxed build** means moving the settings back
  by hand; macOS doesn't. With Phases quit:
  1. `defaults export com.robertmohns.phases ~/Desktop/phases-settings.plist`
     (reads the container's copy, *inferred*).
  2. Move the container out of the way:
     `mv ~/Library/Containers/com.robertmohns.phases ~/Desktop/`.
     Once it's gone, `defaults` addresses `~/Library/Preferences` again
     (*observed* by the author and Claude, 2026-11-14).
  3. `defaults import com.robertmohns.phases ~/Desktop/phases-settings.plist`.
  4. Build without the entitlements and launch. Folder sources whose
     bookmarks don't open show "Can't open"; Locate… fixes each.
  - The steps are *untested*; checking them is one of the first
    sandboxed launch's hands-on checks.
  - *Note 2026-11-22:* the author chose not to test them: Phases is meant
    to run sandboxed, and going back isn't a path it supports. The steps
    stay as a starting point, still *untested*.
  - *Note, draft 59:* the steps name the bundle ID from draft 59
    `[D-bundle-id]`. Through draft 58 they named Bitrig's placeholder,
    `app.bitrig.new.ecd0db30-b411-4419-8736-9fe3d1c96268`.

### Hands-on checks of the first sandboxed build

*Verified* 2026-11-22 by the author, on a build from
`feature/19-sandbox` with diagnostics on (the list is in TESTING.md
"Sandbox checks"):

- **Settings moved on first launch** `[D-sandbox-settings-move]`: phases
  appeared as before (*observed*). The container itself couldn't be
  inspected: macOS refused to list it, even with `sudo` (see TEST-TOOLS.md
  "Diagnostics").
- **Aerials left alone** `[D-aerials-untouched]` `[D-store-unreadable-safe]`:
  the store was read through the exception, and Quit left the Aerial
  display alone and restored the other, both logged. This confirms the
  temporary exception works.
- **Folder sources** `[D-scoped-bookmarks]`: open after a relaunch
  (*observed*, "appears to work as intended").
- **Photos** source: works, nothing logged as failing. So
  `network.client` wasn't needed for this run (whether an iCloud-only
  photo was among those shown wasn't recorded).
- **Crossfade** after a Space switch and after a resolution change: no
  errors logged.
- **Restore on quit** from an original outside every source
  `[D-restore-file-check]`: restored, nothing failing logged.
- **Links** `[D-links-outside-refused]`: a symlink to an image outside
  the folder doesn't appear and is logged as not permitted; one to an
  image inside the folder appears.
- **Location** `[D-location-on-demand]`: works.
- **Outside change** `[D-outside-change-rule]`: picking a wallpaper in
  System Settings paused Phases, so the store watcher works through the
  exception. *Not checked:* a change missed while locked being applied at
  unlock (no way to produce one by hand).
- **Going back:** not checked, by choice (above).
