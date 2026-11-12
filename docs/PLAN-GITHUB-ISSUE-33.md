# Plan: Photos albums as wallpaper sources (issue #33)

Working plan for [issue #33](https://github.com/rmohns/Phases/issues/33),
"Allow using iCloud photo album as a source of wallpapers." This is a plan,
not the spec: what Phases does lands in SPEC.md, findings land in
LEARNINGS.md, and this file tracks the order of work and what's settled.
Written 2026-11-12 by Claude with the author.

## Status

- [x] Plan written (this file)
- [ ] Phase 0: experiments X0–X6
- [ ] Decide: sandbox before merge #1? (see "Sandboxing")
- [ ] Phase 1a: spec for merge #1 (multiple sources, folders only), approved
- [ ] Phase 2a: code for merge #1, tests, merged
- [ ] Phase 1b: spec for merge #2 (Photos albums), approved
- [ ] Phase 2b: code for merge #2, tests, merged

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

## Phase 1a and 2a: merge #1, multiple sources (folders only)

Spec first (opened in Marked, approved before code):

- Sources: a list in Settings, add and remove, a bookmark per folder,
  Include subfolders per folder. Remove "Multiple folders or online
  image sources" from "Out of scope (v1)".
- Saved names: source ID plus name within the source (see "Decisions so
  far"), replacing `[D-relative-paths]`. Existing phases are converted
  once and keep their images.
- What "In order" means across sources. What happens to selections when
  a source is removed (shown as missing, as today).
- Image grid: a heading per source, its subfolders under it.
  `[D-grid-one-tab-stop]` and `[D-grid-release-on-close]` still apply.

Code (Sonnet for edits the approved spec pins down; Claude keeps review
and tagged decisions):

1. A source layer behind `ImageLibrary`, folders only, no visible change.
   The seam is wider than the scheduler's calls: the views use
   `folderURL`, `imageNames`, `groups`, `includesSubfolders`, and
   `setFolder` too (*verified*, `ImageGrid.swift`, `SettingsView.swift`,
   `PhasesWindow.swift`, 2026-11-12).
2. Multiple sources, the conversion of saved names, the Settings list,
   grid headings.

Tests: unit tests for the conversion and naming. UI tests need a setup
with two or more folders (`UITestMode.imageFolder` takes one today).

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
