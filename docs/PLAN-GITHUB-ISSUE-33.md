# Plan: Photos albums as wallpaper sources (issue #33)

Working plan for [issue #33](https://github.com/rmohns/Phases/issues/33),
"Allow using iCloud photo album as a source of wallpapers." This is a plan,
not the spec: what Phases does lands in SPEC.md, findings land in
LEARNINGS.md, and this file tracks the order of work and what's settled.
Written 2026-11-12 by Claude with the author.

## Status

- [x] Plan written (this file)
- [x] Phase 0: experiments X0–X6, rounds A and B (2026-11-12; see
  "Phase 0 results")
- [x] Decide: sandbox before merge #1? **No:** sandboxing is its own
  later change (author, 2026-11-12). The author's developer account is
  active again and Bitrig is signed in, but the sandboxed round B runs
  that need it (Photos and wallpaper-store entitlements) wait for that
  change. Draft 52 uses security-scoped bookmarks so it doesn't block it.
- [x] Phase 1a: spec for merge #1 written as **draft 52** (`031fda7`, then
  the amendments below). The author answered its four open calls and
  approved draft 52 on 2026-11-12.
- [x] Phase 2a: code for merge #1, tests, merged. Squash-merged into
  `main` 2026-11-12 with the author's yes, after the UI suite (19 of 20,
  then the undo test alone, passing) and the author's hands-on checks.
  Added on the way, at the author's request: drag folders in, drag to
  reorder, a context menu, two-line rows, one Tab stop, the shared 24 pt
  +/− bar, and undo for removing a source `[D-undo-remove-source]`.
  **Next:** Phase 1b, on a new branch from `main`.
  - For the sandbox change: `[D-scoped-bookmarks]` access is open while
    scanning, making thumbnails, and applying a wallpaper. A crossfade
    cover remade later (back on a Space) reads its file without it
    (`WallpaperScheduler.apply`, comment there). Harmless unsandboxed;
    the sandbox change has to revisit it.
  - Fable reviewed steps 1–6 (2026-11-12). Fixed: the folder picker lost
    its purpose (Add Folder… and Locate… did nothing), an undecodable
    source list was overwritten, a moved folder's location went stale,
    missing selections weren't marked with no reachable source, and a
    lone subfolder lost its heading. The draft 44 conversion it also
    flagged was dropped instead (author: no conversion needed).
- [ ] Phase 1b: spec for merge #2 (Photos albums), approved. Written
  as **draft 53** (renumbered **54** on 2026-11-13, when In order's redesign took 53) on branch `feature/33-photos-albums` (from `main` at
  `a5d06e9`), 2026-11-12: SPEC.md "Photos albums" (`[D-photos-sources]`,
  `[D-photos-order]`, `[D-photos-names]`, `[D-photos-version]`,
  `[D-photos-fetch-ahead]`, `[D-photos-cache]`, `[D-photos-permission]`,
  `[D-photos-changes]`), TESTING.md `[D-fake-photos]` and "Photos
  checks". The author answered the open calls 2026-11-12: 1 no, 2 yes,
  3 no, 4 yes (cache management revisited in its own issue), 5 yes,
  6 yes, 7 edited, always. On 6 the author asked what happens when a
  photo arrives late or not at all; Claude added the retry and 30-second
  wait to `[D-photos-fetch-ahead]`, pending approval. The calls, with
  Claude's defaults in brackets:
  1. **Whole-album selection:** should a phase be able to use "every
     photo in this album", so photos added later join the rotation by
     themselves? [Not in this draft: selections stay per image, as for
     folders. It would apply to folders too, so it's its own issue.]
  2. **Folders of albums as one source** [yes, with album headings].
  3. **Smart albums** [no, this draft].
  4. **Cache limit** [1 GB, least recently shown deleted first].
  5. **Cache in Application Support, not Caches** [yes; untested as a
     wallpaper location, Photos check 8].
  6. **Fetch-ahead lead** [2 minutes, or half the rotation interval].
  7. **Edited version, not the original** [edited].
  **Approved** by the author 2026-11-12, after adding the retry and
  30-second wait and the "removed is missing, not late" rule. A photo
  that keeps failing to download is left alone until it's seen (author:
  "let iCloud handle its own consistency").
- [ ] Phase 2b: code for merge #2, tests, merged. On
  `feature/33-photos-albums`. Steps (build with
  `bitrig build -destination generic/platform=macOS` and `swift test` in
  `UnitTests/` after each):
  1. [x] Pure logic and the PhotoKit provider, not wired in (`fbd4b57`):
     `ImageSource.Kind`, `photosID`, `title`; `PhotoImageName`;
     `LibraryListing.Entry` (url nil for photos); `PhotoCacheRules`;
     `FetchAhead`; `PhotosProvider` protocol and types;
     `PhotoKitProvider` and `PhotoFileWriter`. Unit tests by Sonnet (29).
  2. [x] (`eacff95`) `FakePhotosProvider` `[D-fake-photos]` and `UITestMode`
     switches; `PhotoCache` (files, index of file → photo and last shown,
     in-flight fetches shared, cleanup using
     `WallpaperStoreWatcher`'s file names and the restore record);
     `ImageLibrary` reads Photos sources (reload, thumbnails, add, change
     observer, `name(for:)` for cache files). `NSPhotoLibraryUsageDescription`
     in `Project.json`.
  3. [x] (`cc0c61b`, with `AppVersion` 53) Scheduler: resolve photo picks through the cache; fetch-ahead
     timer event `[D-single-timer]`; 30 s wait, retry, fallback via
     `FetchAhead.replacement`; record what actually shows in
     `AppliedState`; cleanup after each change.
  4. [x] (`2a145e2`; captions use Photos' original file name) Views: + menu (Add Folder…, Add Photos Album…), the album sheet
     (`OutlineGroup`, shared albums in their own section, empty albums
     disabled, denied message with Open Privacy & Security Settings…),
     Photos rows (no switch, `Photos › Trips • 120 photos`, Can't open
     without Locate…, context menu Remove only), grid headings, removal
     alert wording for albums.
  - Opus review (2026-11-12) of steps 1–4, 14 findings. Fixed: a
    change waiting on photos going ahead after Pause or an outside pick;
    picks made ahead taken by Change Now or lost after any other apply,
    and never re-fetched; a held display re-applying at every check;
    cache cleanup not protecting cover files; thumbnails able to prompt
    before access; user smart albums offered; a late fetch timer skipping
    its change; removal wording for Photos folders; double-click adding
    the wrong album; dead code. **Left open:** a PhotoKit request that
    never calls back blocks that photo (no cap yet); `AppliedState`
    names photos during the 30 s wait (a crash then leaves the old
    wallpaper until the next change); `PHAsset.modificationDate` may
    change on favorite or title edits, missing the cache (needs a probe);
    the offline fallback checks the pool one photo at a time (slow for
    thousands of photos).
    - 2026-11-13, after the merge with `main`: fixed the stuck request
      (given up after 5 minutes, then fetched afresh) and the slow
      fallback (asks about photos only until it finds one on hand).
      Still open, by choice: the record during the wait (a crash in
      those 30 s only delays the photo to the next change; changing
      the record touches every check) and `modificationDate` (worst
      case a favorite or title edit downloads the photo once more;
      needs a hands-on probe of the author's library).
  5. [x] (`c91d14c`) UI tests with the fake library, written by Sonnet,
     compiled. *Verified* 2026-11-12 (Claude, author's yes, build of
     21:44:32 UTC): the fast suite passed 25 of 26; the miss was a test
     helper Tabbing out of a grid it had already focused (fixed,
     `9b0e40a`); the six Photos tests then passed 6 of 6 (70 s). Still
     to do: TESTING.md "What they cover"; UI tests with
     the fake library (harness builds the folder); ask before running.
  6. [ ] Review (fresh eyes), then the author's Photos checks, then merge
     with the author's yes. Photos checks so far (2026-11-12): 1
     permission passes (a grant reached Phases only after a relaunch,
     `[L-photos-grant-needs-relaunch]`); 2 adding passes; 3 In order
     follows the album's order; 4 on time ahead, about 1 s late on
     Change Now; 5 offline falls back but kept landing on the same photo
     (`[L-photos-offline-check]`); 6 edited, Live, ProRAW, DSLR RAW pass
     (`[L-photos-formats-check]`); 7 album changes pass, plus a fix for a
     photo from a just-deleted album being shown
     (`[L-photos-deleted-album-race]`); 8 cache across Spaces, a
     relaunch, and restore on quit passes (author, 22:26 build; each new
     build first needed the Photos grant again,
     `[L-photos-grant-per-build]`); 9 outside change passes (a System
     Settings pick paused Phases; after resuming, two of its own photo
     changes didn't pause it). **All nine Photos checks pass**
     (author, 2026-11-12, 22:26 build).
     - Resuming the checks: diagnostics are on in
       `~/Library/Preferences/<bundle ID>.plist` (written by path,
       because the sandbox container still redirects `defaults` by
       domain). Build, then quit Phases (`osascript -e 'tell application
       id "<bundle ID>" to quit'`) and `open -n` the newest build, picked
       by its executable's modification time (`ls -t` on the build
       folders picks the wrong one). A new build may ask for Photos
       again (`[L-photos-grant-per-build]`); allow it at Add Photos
       Album….
     - The author's test phase: "New Phase", In order, 1 minute; its
       selection is now only photos from a deleted album, so pick new
       ones before check 8.

**Before merge #2** (author, 2026-11-12), in this order:

1. **Restore drafts 45–50.** Bitrig's restore (`713ca49`, 2026-11-09)
   undid them by accident (author: "confused by Bitrig's UI"). They're
   commits `08eaa77`..`4b61ea5` (draft 45 Active badge #22, 46 brand
   egg #23, 47 version 0.1, 48 new Spaces aren't picks #29, 49–50 pause
   banner and notification opens the window, plus CLAUDE.md and doc
   changes). Own branch from `main`, one draft per commit, tests, the
   author's yes to merge. Found when the author saw the Active badge
   missing on the selected row.
2. **In order remembers its place.** The author expected In order to
   remember the last image and advance from it, not to work out the
   image from time since the phase began, which reset the position on
   every selection edit. Its own spec draft and branch from `main`. It
   also settles the offline fallback rule (`[L-photos-offline-check]`:
   skip what's showing), which waits for it.
3. Then bring `feature/33-photos-albums` up to date with `main`, finish
   Photos checks, and merge #2.

## Picking this up in a new conversation

Everything needed is in the repo; the conversation that wrote this isn't
needed.

1. Work on branch `bitrig/implement-github-issue-33`. Read CLAUDE.md, then
   this file, then SPEC.md's opening and "Design decisions", then the
   draft 52 tags: `[D-image-sources]`, `[D-source-names]`,
   `[D-source-location]`, `[D-scoped-bookmarks]`, and the ones they cite
   (`[D-follow-links]`, `[D-scan-each-folder-once]`,
   `[D-grid-one-tab-stop]`, `[D-grid-release-on-close]`,
   `[D-ui-test-mode]`). TESTING.md: "Unit tests", "Interface tests",
   "Launch arguments". LEARNINGS.md: "Photos library (issue #33)".
2. Ask the author to approve draft 52 (open it in Marked). No code before
   that yes.
3. Then Phase 2a below, on this same branch: code, tests, ERRATA notes
   if any quirk turns up. Merging into `main` needs the author's yes.
4. Draft numbering: draft 51 lives on branch `feature/compact-editor`, so
   this is 52 (author, 2026-11-12). A numbering convention for parallel
   branches is a later conversation; don't invent one.

Leftovers from Phase 0, none blocking:

- Branch `experiment/33-photokit` holds the probe
  (`App/Experiments/PhotoKitProbe.swift`, run with
  `open -n -W <app> --args -PhasesPhotoKitProbe x0…x6`, options
  `-PhasesProbeAlbum "<name>"`, `-PhasesProbeLimit`,
  `-PhasesProbeSeconds`, `-PhasesProbeSkipStoreCheck YES`). Its
  `Project.json` carries the app-sandbox entitlement. Never merge it; reuse
  it for the sandbox change and Photos work.
- A sandbox container from round B still exists at
  `~/Library/Containers/app.bitrig.new.ecd0db30-b411-4419-8736-9fe3d1c96268`.
  Deleting it was blocked by the permission system on 2026-11-12; the
  author may delete it. While it exists, `defaults` commands for the
  bundle ID go into it, not `~/Library/Preferences`
  (`[L-sandbox-prefs-move]`). So the TESTING.md diagnostics switch
  won't reach the real app until it's gone.
- The author's preferences backup from before round B:
  `~/Library/Caches/PhasesProbe/prefs-backup/`. The author confirmed
  Phases kept its settings, so it's only a spare.

## Base

- Work builds on `bitrig/implement-github-issue-33`, branched from `main`
  at `713ca49` (author, 2026-11-12).
- `713ca49` is a Bitrig restore (2026-11-09) back to spec draft 44
  (`1d075aa`). The 15 commits from `1d075aa` to `4b61ea5` (drafts 45–50,
  the pause banner, the docs reorganization) aren't on `main`
  (*verified*, `git log 1d075aa..4b61ea5`, 2026-11-12). The estimate
  comments on the issue were written at `4b61ea5`, so their line numbers
  and their mention of TEST-TOOLS.md don't match the current tree.

## Decisions so far

- **Alongside, with several sources.** Photos albums sit alongside local
  folders, and the library takes any mix, e.g. two iCloud albums and
  three local folders (author, 2026-11-12).
- **Two merges** (author, 2026-11-12):
  1. **Merge #1, multiple sources, folders only.** No new permissions and
     no iCloud risk, and it's testable with the existing UI tests.
  2. **Merge #2, Photos albums**, built on merge #1.
- **No source name depends on the path above the home folder** (author,
  2026-11-12). `~/Pictures/Wallpapers` is fine,
  `/Macintosh HD/Users/rmohns/Pictures/Wallpapers` is not. The proposal
  for the spec:
  - Each source gets a stable ID of its own (opaque, not a path). A saved
    image name is the source ID plus the image's name within that
    source: the relative path for a folder (`Winter/snow.jpg`, as
    `[D-relative-paths]` does today), or the Photos ID for a photo.
    Saved names hold no path at all.
  - The source record keeps the folder's bookmark (how it's found) and a
    home-relative path (`~/Pictures/Wallpapers`) to show and to fall back
    on if the bookmark breaks.
  - In a sandboxed app, "home" has to come from the real home folder,
    not `FileManager.homeDirectoryForCurrentUser`, which points into the
    app's container there (*recalled*; X0 checks it).
  - Open for the spec: what to store for a folder outside the home
    folder (an external drive, `/Volumes/…`).
- **Estimate:** about 8–10 sessions in all, plus about 1 for Phase 0
  (Claude's judgment, issue comments, 2026-11-09).

## Sandboxing

The author plans to sandbox Phases. It changes several things this work
touches, so the experiments run both unsandboxed and sandboxed.

What sandboxing changes (*recalled* unless marked):

- **Photos** needs the `com.apple.security.personal-information.photos-library`
  entitlement. The permission prompt should be the same.
- **The photo cache** moves into the app's container. Whether the
  wallpaper system will draw a file from there is unknown (X4).
- **Folder access** needs security-scoped bookmarks, with access started
  and stopped around use. Today's bookmark isn't one (*verified*,
  `ImageLibrary.swift` `setFolder` and `restoreBookmark`, options `[]`).
  Merge #1 rewrites this code anyway (a bookmark per source).
- **`[D-follow-links]`**: a link or alias inside a chosen folder that
  points outside it would become unreadable. That contradicts the
  decision, so the spec would have to change.
- **The wallpaper store**: Phases reads
  `~/Library/Application Support/com.apple.wallpaper/Store/Index.plist`
  through `homeDirectoryForCurrentUser` (*verified*,
  `WallpaperStoreWatcher.swift:16`, `SystemWallpaperInspector.swift:11`).
  In the sandbox that path points into the container, and the real store
  is outside it. That needs a temporary-exception entitlement, which is
  fine outside the App Store. Detecting outside changes depends on it
  (X0).
- **Location** needs `com.apple.security.personal-information.location`.

**Recommendation:** sandboxing as its own change (its own issue and
branch), after Phase 0 and before merge #1. Phase 0 shows whether
sandboxing has a blocker. Merge #1 can then write security-scoped
bookmarks from the start, so that code isn't written twice. Doing it
after #33 also works, at the cost of reworking the bookmark and link
code. Author's call, after Phase 0.

## Phase 0: experiments

Branch `experiment/33-photokit`, from `bitrig/implement-github-issue-33`,
never merged. The probe is `App/Experiments/PhotoKitProbe.swift`. A launch
with `-PhasesPhotoKitProbe <step>` runs one step and quits, without
starting the scheduler, so it never touches phases, settings, or the
wallpaper (except X4, which sets the wallpaper and puts it back). Each
step writes a report to `PhasesProbe/` in the app's Caches folder.
Findings go to LEARNINGS.md as they happen.

Two rounds: **A** unsandboxed (the build as it is), **B** sandboxed (the
same probe with the sandbox and Photos entitlements). Before round B,
back up Phases' preferences file in case the first sandboxed launch moves
it into a container (*recalled* risk, not tested).

| # | Question | Why it matters | Hands-on? |
|---|---|---|---|
| X0 | Sandboxed or not; what `homeDirectoryForCurrentUser` and the real home say; where Caches is; can Phases read the wallpaper store? | Sandboxing; the `~` rule; outside-change detection | No: reads only |
| X1 | Photos permission: status before, the prompt, status after. Does a new build ask again? | Cost of hands-on testing; the spec for refused or limited access | Yes: a system prompt |
| X2 | Albums, folders of albums, shared and smart albums; photo counts; does an album's default fetch order match its order in Photos? | Album picker; what "In order" means | Reads only, after X1 |
| X3 | Writing photos to disk, local vs. iCloud-only: time, size, format, edited vs. original, Live Photos; again offline | **The biggest unknown.** Whether to fetch photos ahead of time | Yes for the offline run (Wi-Fi off) |
| X4 | Set the wallpaper to a file in Phases' cache folder: does it show, and what does the store record? Then put the original back | Whether cached photos can be wallpapers, sandboxed or not; outside-change detection | **Yes: real wallpaper** |
| X5 | Does the change observer fire while Phases runs in the background, when a photo is added to or removed from an album? | Album changes | Yes: author edits an album in Photos |
| X6 | Do photo IDs stay the same across launches and builds? | What saved names store | Reads only |

### Phase 0 results

Full entries, with evidence labels, are in LEARNINGS.md "Photos library
(issue #33)". In short, all *verified* 2026-11-12 on macOS 27.2:

- **iCloud downloads are not the risk feared.** iCloud-only photos took
  0.5–1.4 s each online and failed in under 0.1 s offline, with no hang
  `[L-photos-x3-download]`. Fetching ahead is still worth it, but a short
  lead is enough. Untested: edited photos, Live Photos, HEIC, big files,
  slow connections.
- **A cached file works as a wallpaper,** sandboxed or not
  `[L-photos-x4-cache-wallpaper]` `[L-sandbox-x4-container-wallpaper]`.
- **Albums:** listed nested, in sidebar order; names repeat, so save by
  ID `[L-photos-x2-albums]`. An album's default order is its own order
  `[L-photos-album-order]`. Photo IDs held across builds and the sandbox
  `[L-photos-ids-stable]`.
- **The change observer fires in the background** `[L-photos-x5-observer]`.
- **Permission:** a new build asks again `[L-photos-new-build-asks]`, as
  location does. A sandboxed build read Photos without the Photos
  entitlement `[L-sandbox-photos-works]`.
- **Sandboxing's real blocker is the wallpaper store:** unreadable in the
  sandbox `[L-sandbox-x0-paths]`, and the exception that fixes it needs a
  development team `[L-sandbox-team-needed]`. Without it, detecting
  outside changes and Aerials (`[D-aerials-untouched]`) would silently
  stop.
- **The first sandboxed launch moves the settings** into the container
  `[L-sandbox-prefs-move]`. Sandboxing has to plan for that (it's
  harmless one way, but going back to unsandboxed needs the file put
  back).

Cleanup still to do: delete the sandbox container
(`~/Library/Containers/app.bitrig.new.ecd0db30-…`) once the author has
confirmed the installed Phases kept its settings.

## Phase 1a and 2a: merge #1, multiple sources (folders only)

Spec first (opened in Marked, approved before code):

- Sources: a list in Settings, add and remove, a bookmark per folder,
  Include subfolders per folder. Remove "Multiple folders or online
  image sources" from "Out of scope (v1)".
- Saved names: source ID plus name within the source (see "Decisions so
  far"), replacing `[D-relative-paths]`. Existing phases aren't
  converted (author, 2026-11-12); the folder is added again.
- What "In order" means across sources. What happens to selections when
  a source is removed (shown as missing, as today).
- Image grid: a heading per source, its subfolders under it.
  `[D-grid-one-tab-stop]` and `[D-grid-release-on-close]` still apply.

Written as draft 52 (see "Status"). Amended after the author's answers:
the source order is the user's, dragging to reorder is planned, and
nothing may assume a source's place is fixed.

Code (Sonnet for edits the approved spec pins down; Claude keeps review
and tagged decisions). Steps, each building with
`bitrig build -destination generic/platform=macOS` and passing
`swift test` in `UnitTests/` before the next:

1. **Pure logic first, in new files the unit tests reach** (symlink each
   into `UnitTests/Sources/PhasesLogic`, as the existing ones are):
   - `ImageSource` (a folder source: ID, bookmark data, location,
     includes subfolders) and the stored-name format
     `<source ID>:<relative path>` with split and join `[D-source-names]`.
   - `SourceLocation`: the `~/…` form from a URL and back, using the real
     home folder (`getpwuid`), not `homeDirectoryForCurrentUser`
     `[D-source-location]`.
   - `SourceMigration`: draft 44 settings (one bookmark, bare relative
     names in `Phase.imageNames`, `Phase.displayImageNames`, and
     `AppliedState.imagesByDisplay`) to one source plus prefixed names.
     Leaves the old bookmark key in place. *Dropped 2026-11-12: no
     conversion (author); written, then removed with its tests.*
2. **`ImageLibrary` holds a list of sources,** in a stored order of its
   own `[D-image-sources]`. The five calls the scheduler uses keep their
   meaning (`availableImages`, `url(for:)`, `name(for:)`, `thumbnail`,
   `reload`; `WallpaperScheduler.swift` lines 339, 380, 413, 441,
   *verified* 2026-11-12). `name(for:)` must map a file back to its
   source. Security-scoped bookmarks, with access opened only while
   reading `[D-scoped-bookmarks]`.
3. **Views:** the views use `folderURL`, `imageNames`, `groups`,
   `includesSubfolders`, and `setFolder` (*verified*, `ImageGrid.swift`,
   `SettingsView.swift`, `PhasesWindow.swift`, 2026-11-12). Settings
   gets the Image Sources list (+, −, per-row Include subfolders, image
   count, "Can't open" plus Locate…, a confirmation on removing a source
   in use). The grid gets a heading per source with subfolder headings
   under it.
4. **Test mode:** `-PhasesUITestImages` takes one path or a list
   (TESTING.md "Launch arguments", draft 52). `UITestMode.imageFolder`
   becomes a list. The harness (`UITests/Sources/PhasesUIDriver/TestImages.swift`,
   `PhasesApp.swift`) makes a second small folder.
5. **Draft number in code:** `App/Model/AppVersion.swift` holds the
   draft number, and `AppVersionTests` fails unless it matches SPEC.md's
   title. Set it to 52 `[D-version-in-settings]`.
6. Update code comments that cite `[D-relative-paths]`
   (`ImageLibrary.swift`, `FolderScan.swift`) to `[D-source-names]`.

### Test plan for merge #1

Unit tests (no permission needed; add to TESTING.md "What they cover"):

- Stored names: join and split, a file name with a colon, a name with
  no source part (draft 44 data) is recognised as old.
- `SourceLocation`: inside home gives `~/…`; outside home (`/Volumes/…`)
  keeps the full path; round trip; a sandboxed-looking home isn't used.
- `SourceMigration`: All Displays and per-display selections, the last
  applied image per display, empty settings (first launch: no source),
  running it twice changes nothing. *Dropped with the conversion.*
- Library order: sources in stored order, then each source's own order;
  reordering the stored list reorders the library without changing any
  saved name.
- Adding a folder that's already a source (same folder, reached by a
  symlink) is detected.
- `FolderScanTests` keep passing unchanged.

Interface tests (AX-driven, `UITests/`; a hands-on check, so list the
runs and ask the author first, per CLAUDE.md "Testing"):

- The existing suite passes with one source (the grid now has a source
  heading; adjust any test that counts headings).
- Two sources: both headings show, in order; arrow keys cross from the
  last image of the first source to the second `[D-grid-one-tab-stop]`;
  Select All selects both.
- Settings shows the two sources with their counts; turning Include
  subfolders on for one changes only that one.

Hands-on checks by the author (after the UI tests):

- First launch over draft 44 settings: no sources, old selections show
  as missing; add the folder again (no conversion, author 2026-11-12).
- A second real folder; a folder on an external drive, unplugged and
  plugged back (Can't open, then back); Locate… after moving a folder;
  renaming a folder while Phases runs updates its row.
- `[D-scoped-bookmarks]` in a build that isn't sandboxed: sources reopen
  after a relaunch. Rename the folder while Phases is quit, so only the
  bookmark can find it, and check the diagnostics log
  (category `sources`) says "found by its bookmark". Record the result as *verified* in SPEC.md (it's
  *recalled* there now).

## Phase 1b and 2b: merge #2, Photos albums

Spec first:

- Photos rules: "In order" for an album, edited or original, iCloud-only
  photos, offline, permission refused or limited, a deleted album or
  photo (missing, as today).
- The cache: where it lives, a size limit, cleanup that never deletes
  the current wallpaper or what restore on quit needs.
- Album picker: albums and folders of albums. A Photos folder shows like
  a subfolder heading.
- Testing: a fake Photos source for UI tests (proposal), plus the
  hands-on checks list.

Code:

1. The Photos source: usage description in `Project.json`, permission
   request, album list, thumbnails from Photos.
2. The export cache, and fetching ahead in the scheduler so crossfades
   still change on time. Cache rules in a logic-only file the unit tests
   can reach.
3. Watching albums for changes.

## Phase 3: testing (both merges)

- **Unit tests** (no permission needed): saved-name conversion, cache
  naming and cleanup, ordering, fetch-ahead timing.
- **UI tests**, with the fake Photos source for merge #2.
- **Hands-on checks** (each listed set needs the author's yes): the
  permission prompt, an iCloud-only photo, offline, a deleted album,
  crossfade timing, restore on quit, a wallpaper change made outside
  Phases.
- After each merge to `main`, a `bitrig build`.
