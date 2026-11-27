# Phases spec: Project, platform, and storage

Part of the Phases specification. [SPEC.md](../SPEC.md) is its front
page: the draft number, the "Design decisions" rules, and the list of
spec files.

What's here: the Xcode project and bundle ID, what the wallpaper API
can and can't do, the single timer, persistence, and memory.

## Project and bundle ID

- `[D-xcode-project]` **Phases is an Xcode project** (the `.xcodeproj`
  in the repository root, from draft 59), built with `bitrig build`.
  Build settings, targets, and `INFOPLIST_KEY_` settings are changed
  with `xcrun xcodeproj`, never by editing the project file by hand; the
  Info.plist and entitlements files are edited directly
  (`[D-sandbox-entitlements]`).
  - *Replaced:* through draft 58 the project was defined by
    `Project.json`, Bitrig's older format, from which Bitrig generated a
    fresh Xcode project on every build. It was converted with
    `bitrig convert-to-xcode-project`.
  - *Why:* `Project.json` is Bitrig's legacy format (*recalled* from
    Bitrig's guidance): a project regenerated on every build can't build
    incrementally, and `bitrig test` can't see test targets in it
    `[Q-bitrig-test-targets]` (GitHub issue #42). An Xcode project fixes
    the first and opens the way to the second; adding a test target is a
    change of its own.
  - The Phases target skips Xcode's App Intents metadata step, since
    Phases has no App Intents; Xcode fights this, see
    `[Q-app-intents-metadata]`.
  - The project lists the unit test package, `UnitTests/`, as a folder
    reference, so `bitrig test -package UnitTests` runs it; nothing in
    the app links it (2026-11-24, GitHub issue #42; TEST-TOOLS.md
    `[Q-bitrig-test-targets]`).
- `[D-bundle-id]` **The bundle ID is `com.robertmohns.phases`** (draft
  59), all lowercase, and permanent: preferences, the sandbox container,
  and privacy grants are all keyed to it.
  - *Why:* the author controls `robertmohns.com`, so the ID is his.
    Through draft 58 Phases used Bitrig's placeholder,
    `app.bitrig.new.ecd0db30-b411-4419-8736-9fe3d1c96268`, which Bitrig
    generates for a new project and isn't meant to be kept.
  - Phases' code never names the bundle ID (*verified* 2026-11-22 by
    Claude, by searching the code). The UI tests' preferences suite and
    the input driver read it at run time.
  - The project folder and Bitrig's `origin` repository are named for
    Bitrig's project ID, not the bundle ID, so neither changes
    (*inferred* from the names).
- `[D-bundle-id-settings-move]` **Settings move to the new ID once, by
  hand, from the shell.** Phases has no migration code: one person uses
  it, and moves once. A new bundle ID means a new, empty container; the
  old one stays on disk untouched, and setting the old ID back would find
  it again (*inferred* from how containers work, not tested). With Phases
  quit, and before any build with the new ID has launched (a launch makes
  an empty container, and the import would have to go into it instead):
  1. `defaults export app.bitrig.new.ecd0db30-b411-4419-8736-9fe3d1c96268 ~/Desktop/phases-settings-old-id.plist`.
     This reads the old container's copy (*inferred*) and doubles as the
     backup. If it fails or comes back empty, stop.
     - *Correction 2026-11-22 by Claude:* run from Bitrig's shell, it came
       back empty: macOS wouldn't let that process read the old container
       (`[L-defaults-container-blocked]`, *verified*). The route that
       worked (2026-11-22): the author copied the old container's
       `Data/Library/Preferences/<old ID>.plist` to the Desktop in Finder
       (Go › Go to Folder…, Option-drag), and step 2 imported that copy.
  2. `defaults import com.robertmohns.phases ~/Desktop/phases-settings-old-id.plist`.
     With no container yet, this writes
     `~/Library/Preferences/com.robertmohns.phases.plist`, which macOS
     moves into the new container on first launch, as it did for the
     first sandboxed build `[D-sandbox-settings-move]`.
  3. Launch the new build and check phases, sources, and options. If
     they're missing, quit, run step 2 again (it then writes the
     container's copy), and relaunch.
  - **What doesn't carry over:**
    - **Folder sources:** bookmarks belong to the app that made them, so
      each probably shows "Can't open" (*recalled*). One **Locate…** per
      source; it keeps the source's ID, so phases' selections come back.
    - **Photos and location:** macOS asks again, as it does for each new
      build (`[L-photos-grant-per-build]`). Album and photo IDs are in
      the settings, so Photos sources come back once allowed
      (`[L-photos-ids-stable]`).
    - **Launch at Login:** off until turned on again in Phases
      `[D-login-consent]`. System Settings › General › Login Items may
      keep a leftover entry for the old ID.
    - **Photo cache:** starts empty in the new container and fills as
      needed `[D-photos-cache]`.
  - **The old container stays.** Nothing deletes it; the author can
    remove it by hand later.
  - **Done 2026-11-22.** The import wrote
    `~/Library/Preferences/com.robertmohns.phases.plist`, identical to the
    copy, and it was gone from there once the new build launched
    (*verified* by Claude; that macOS moved it into the container is
    *inferred*, since the container can't be listed). The author then
    *verified* in the app: settings came over; folder sources reopened
    after Locate…; location and Launch at Login back on. Photos stayed
    blocked though System Settings shows it allowed, which the author has
    seen before when the Bitrig build and the installed copy compete
    (`[L-photos-bitrig-vs-installed]`). It counts as passing unless it
    persists after installing to /Applications. Sandbox checks 1–3 are
    deferred to GitHub issue #43.

## Platform notes and limitations

- `NSWorkspace.setDesktopImageURL(_:for:options:)` sets the image **per screen**,
  so different images per display are supported.
- It only affects the **currently active Space** on each screen. Other Spaces
  keep their own wallpaper. There is no public API to set every Space, or
  to set or restore a Space that isn't showing.
- With "Displays have separate Spaces" on (the macOS default), each display has
  its own current Space, and the app sets each one.
- `[D-single-timer]` Scheduling uses a single timer aimed at the next event (a change, or from draft 54 a photo fetch ahead of one `[D-photos-fetch-ahead]`), recalculated after
  every change, wake, or settings edit, with an hourly re-check as a safety net
  against clock drift. No polling loop.

## Persistence

All settings (image sources with their bookmarks and locations, or Photos album and folder IDs, phases including per-display selections,
preferences, in-order positions (the image each selection last showed
`[D-in-order-remembers]`), the grid's collapsed headings
`[D-grid-collapse-saved]`, last applied phase and image per display, known
displays and their names, last location) are stored in UserDefaults as Codable
data. Phases saved by earlier versions load unchanged (no per-display images).
The image folder setting from draft 44 and earlier isn't carried over
`[D-source-names]`.

## Memory

- `[D-memory-flat]` **Memory doesn't build up with wallpaper changes.**
  Between changes, with the window closed, Phases should sit near its idle
  launch figure, not climb change after change.
  - **With crossfades on,** the figure after a change includes at most one
    cover buffer per display `[D-persistent-cover]`. During a fade it holds
    one more per changing display `[D-cover-iosurface]`, and gives the old
    one back when the fade ends. Leaving a Space gives its cover's buffer
    back `[D-cover-per-space]`, unless its change is still pending
    `[D-change-stays-on-its-space]`.
  - **With Transition: None or Reduce Motion,** no cover buffers at all
    `[D-cover-only-for-crossfade]`. Turning crossfades off gives them back.
  - **Target:** after ten changes, footprint is within 30 MB of what it
    was after the first change (approved by the author, 2026-10-30).
  - Checked by hand, with at least two runs before a change and two after,
    because runs vary widely (one run measured 297 MB after three changes,
    another 144 MB). Procedure: TESTING.md `[D-memory-protocol]`.
  - *Verified* 2026-11-03, draft 33 with persistent covers, three
    displays: two runs pass (137 → 100 MB and 113 → 87 MB, first change
    to tenth). Figures in LEARNINGS.md `[L-mem-draft33-runs]`.
  - *Why:* Phases runs all day in the background. Draft 31 reached about
    300 MB after ten changes on three displays (measured 2026-10-30,
    LEARNINGS.md "Memory").
  - The persistent-cover experiment grew about 25–30 MB per change on
    three displays (`[L-cover-memory]`). It drew covers from CGImages, which
    Core Animation copies `[Q-cover-image-copied]`; that copy is the likely
    cause (*inference*, not measured on the experiment). The shipping
    cover uses `[D-cover-iosurface]`, and must pass the target above before
    it merges.
