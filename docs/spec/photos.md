# Phases spec: Photos albums

Part of the Phases specification. [SPEC.md](../SPEC.md) is its front
page: the draft number, the "Design decisions" rules, and the list of
spec files.

What's here: Photos albums as an image source (a part of "Image
library", in [image-library.md](image-library.md)).

## Photos albums

Draft 54, issue #33 merge #2; the cache rules redone in draft 65 (issue
#35). Evidence for this section is LEARNINGS.md "Photos library (issue
#33)", unless noted.

- `[D-photos-sources]` **A Photos album, or a folder of albums, can be an
  image source,** alongside folders, in any mix and any order
  `[D-image-sources]`.
  - **Adding:** + becomes a menu with **Add Folder…** and **Add Photos
    Album…**. Add Photos Album… opens a sheet listing the library the way
    Photos' sidebar does: folders of albums, nested, in sidebar order,
    each album with its photo count. Shared albums are listed in their
    own group after them. Smart albums (Favorites, Recents, and the
    user's own) aren't offered in this draft.
  - The sheet lists albums with no photos (videos only, or empty) but
    they can't be chosen.
  - Choosing a **folder of albums** adds the folder as one source. Its
    albums, nested ones too, are listed under it the way a folder
    source's subfolders are, each under a heading with its path
    (`Trips / Iceland`). There's no Include subfolders switch for it: a
    Photos folder holds only albums, so turning it off would leave
    nothing (*recalled*, Photos' folder rules).
  - Adding an album or folder that's already a source selects its row,
    as for folders.
  - **Only still images.** Videos are left out, and a Live Photo counts
    as its still image. Counts in Settings and the sheet are of photos,
    not items (an album of 61 photos showed 63 items to PhotoKit,
    *verified*).
  - **The Settings row:** line one is the album's (or folder's) name,
    with no switch. Line two reads `Photos › Trips • 120 photos`: where
    it sits in Photos' sidebar, then the count. A shared album reads
    `Shared Album • 40 photos`.
  - **Context menu:** **Remove** only. Show in Finder doesn't apply, and
    macOS has no public way to open Photos at a given album (*recalled*),
    so there's no Show in Photos. Locate… doesn't apply either (see
    "A Photos source Phases can't open", below).
  - Removing and undoing a removal work as they do for folders
    `[D-undo-remove-source]`.
  - *Why albums and folders but not smart albums:* the issue asks for
    albums, and the author keeps wallpapers in albums (two named
    "Walllpapers & Desktop Pictures"). Smart albums change by
    themselves, which makes In order hard to follow. Easy to add later.
- `[D-photos-order]` **In order follows the album's own order,** the
  order Photos shows it in. For a folder of albums: its albums in
  sidebar order, each in its own order. *Verified:* the default fetch
  returns an album's own order, including one sorted by hand
  `[L-photos-album-order]`.
- `[D-photos-names]` **A saved photo is named by its source, its album,
  and the photo's ID in the Photos library** `[D-source-names]`.
  - Photos' own IDs, not names: two albums can share a name (the
    author's library has two pairs), and photo IDs held across builds
    and the sandbox `[L-photos-ids-stable]`. Album IDs are assumed
    stable the same way (*recalled*, not checked).
  - The album is part of the name, so a photo in two albums of a folder
    source is listed twice, once per album, as two links to one image
    are `[D-follow-links]`.
  - Renaming or moving an album in Photos changes nothing saved; its row
    and headings follow the new name.
  - *How* (stored form): `<source ID>:<album ID>:<photo ID>`, using
    PhotoKit's local identifiers (shape `AF0F5151-…/L0/001`, no colon;
    *verified* on 10 IDs from Phase 0). The name splits at its first two
    colons.
- `[D-photos-version]` **The wallpaper is the photo as it looks in
  Photos:** with the user's edits, at full size, as a still image.
  - Phases writes it to a file in its photo cache `[D-photos-cache]` and
    sets that file as the wallpaper. *Verified* that macOS shows a
    wallpaper from a file Phases wrote, sandboxed or not
    `[L-photos-x4-cache-wallpaper]` `[L-sandbox-x4-container-wallpaper]`.
  - A photo whose file isn't one of the supported formats (a RAW
    original, for example) is written as HEIC.
  - Editing a photo in Photos makes Phases fetch it again the next time
    it's used.
    - Other changes may count as edits: the cache name follows
      `PHAsset.modificationDate`, which may also change when a photo is
      favorited or retitled (*recalled*, not tested here). Fetching again
      then is fine: "If the user changed a photo, then we are simply
      respecting their action" (author, 2026-11-14).
  - *Why edits:* the photo should look the way the user made it look.
    Untested: edited photos, Live Photos, HEIC, RAW, very large files
    (Phase 0's test album had none).
- `[D-photos-fetch-ahead]` **Phases fetches photos before they're needed,
  so scheduled changes still happen on time.**
  - **Scheduled changes** (a phase start or a rotation): Phases picks the
    next image for each display 2 minutes ahead (or half the rotation
    interval, if that's shorter), fetches it, and shows that pick when
    the change comes. A Random pick is made then, not at the change.
  - If anything that affects the pick changes in between (the phase,
    its images, the displays, Light/Dark), the pick is made again. That
    includes the picked photo being removed from its album or deleted
    in Photos `[D-photos-changes]`.
  - **A photo removed from its album, or deleted,** is missing, not
    late: Phases never picks it or waits for it. Its cached copy isn't
    shown either, since a photo that's gone from the album shouldn't go
    on showing. This holds whether it was removed while Phases ran (the
    change is reported at once) or while it was quit (the album is read
    again at launch).
  - **Changes that can't be foreseen** (Change Now, editing the active
    phase, waking, resuming): the photo is fetched then, and the change
    starts when it arrives. *Verified* cost: 0.5–1.4 s per iCloud-only
    photo, online `[L-photos-x3-download]`.
  - **A fetch that fails ahead of time** (offline, say) is tried once
    more at the change, in case the network came back.
  - **A fetch still running at the change:** the change waits for it, up
    to 30 seconds. If it arrives, the change happens then, a little
    late. If not, the display is treated as below, and the download is
    left to finish and kept in the cache for next time. A fetch with no
    answer after 5 minutes is given up on, and the photo is fetched
    afresh the next time it's needed, so a request Photos never answers
    can't block that photo for good (draft 54, from the 2026-11-12
    review; a request like that hasn't been seen).
  - `[D-record-after-wait]` **A change is saved only once it shows.**
    While a change waits on photos, its picks are held in memory as a
    pending change, and the saved record (the image each display shows,
    see "Persistence") still names what's on screen. The record is saved
    when the change shows, at the end of the wait or at once when
    nothing needs fetching.
    - The checks that run during the wait (the wallpaper check, display
      and Space changes, waking) compare against the pending change, so
      they don't start a second change for the same slot
      `[D-screen-change-no-reroll]`. A newer change replaces it.
    - Pausing, or the phase no longer running, drops the pending
      change. Resuming then applies the phase again.
    - A display whose photo never arrives and that keeps its wallpaper
      still gets the planned pick in its record, so later checks don't
      apply again before the next change.
    - *Why:* draft 54 saved the planned picks before the wait. If Phases
      crashed or was force-quit during it, the next launch read a record
      saying the new photos were showing and applied nothing, so the old
      wallpaper stayed until the next change. Now a crash loses only the
      pending change, and the next launch makes it again (issue #36,
      found in review 2026-11-12, *observed* in the code, not
      reproduced; draft 55).
  - **A photo that can't be fetched** (offline and only in iCloud,
    deleted, or not there in 30 seconds): that display gets another image from the same selection
    that's on hand (in the cache, or from a folder), chosen as Random or
    In order would. In order takes the next one on hand after the
    missing photo, never the image the display already shows unless
    it's the only one on hand `[D-in-order-remembers]`. In order still
    remembers the missing photo as the last one shown, so the next
    change carries on after it and the order comes back once the photo
    can be fetched. If
    nothing is on hand, the display keeps its wallpaper. Offline,
    fetching fails in under 0.1 s, so this costs no wait (*verified*).
  - Phases fetches only what it's about to show, not whole albums, so a
    large iCloud album doesn't fill the disk.
  - This adds a second kind of event to the one timer: it aims at
    whichever comes first, the next fetch or the next change
    `[D-single-timer]`.
- `[D-photos-cache]` **The photo cache** holds the files Phases sets as
  wallpapers.
  - **Where:** `~/Library/Application Support/Phases/Photos/` (in the
    container, once sandboxed). Not Caches: macOS may empty Caches when
    the disk is low (*recalled*), and a Space that isn't showing keeps
    its wallpaper as a file path, so it would lose its wallpaper.
    *Untested:* a wallpaper from Application Support (X4 tested Caches;
    expected to be the same, since both are ordinary files).
  - `[D-photos-cache-cleanup]` **What's deleted** (draft 65, GitHub
    issue #35). The cache should hold about what the current sources
    show, and give space back when the Mac needs it. Each cleanup applies
    these rules in order:
    1. **Gone from the sources:** a file whose photo is no longer in any
       Photos source (taken out of its album, deleted in Photos, or its
       source removed from Phases), and the older file of a photo edited
       since `[D-photos-version]`. This rule is skipped while any Photos
       source can't be opened, and at launch until every Photos source
       has been read, so a passing failure (access off, the library not
       ready) never empties the cache.
    2. **Not shown in 30 days.** A file fetched but never shown counts
       from when it was fetched.
    3. **Over 500 MB** (500,000,000 bytes, as Finder counts): the least
       recently shown files go first, until the cache is under it.
    4. **Low disk:** if the disk holding the cache has less than 5 GB
       available, everything that may be deleted is deleted.
  - **Never deleted,** by any rule, Clear… included `[D-cache-in-about]`:
    - a file showing on any display;
    - a file any entry in macOS's wallpaper store names, which covers
      Spaces that aren't showing `[Q-wallpaper-store]`;
    - a file in the restore record `[D-restore-on-quit]`, which happens
      when Restore original wallpaper is off and Phases' photo becomes
      the next launch's original;
    - a file fetched ahead and waiting for its change.
  - If the wallpaper store can't be read (as in a sandboxed build
    without its exception, `[L-sandbox-x0-paths]`), files shown in the
    last 30 days are kept too, by every rule. Older ones may then go even
    though a Space that isn't showing still uses them; through draft 64
    that could happen only over the size limit. Shipping builds read the
    store, so this is a fallback.
  - **When cleanup runs:** after each change (as before draft 65), at
    launch once the sources have been read, after a source is added or
    removed, and after an album changes `[D-photos-changes]`. No timer of
    its own `[D-single-timer]`: a Mac that runs short of space between
    those moments gets its space back at the next one.
  - A cached file maps back to its photo, so Phases knows its own photo
    when it's showing: Random still avoids repeating it, and a change
    to it isn't taken for a pick made outside Phases
    `[D-outside-change-rule]`.
  - Removing a source deletes its photos' files at the cleanup that
    follows, except those the rules above keep. Undoing the removal
    `[D-undo-remove-source]` brings the source back, and its photos are
    fetched again as they're needed (0.5–1.4 s each online
    `[L-photos-x3-download]`; offline, another image on hand shows
    instead, as for any photo that can't be fetched).
  - **No size setting.** The rules above keep the cache near what's in
    use, and Settings shows the size and can clear it
    `[D-cache-in-about]`. A setting would ask people for a number they
    can't really choose (proposed by Claude 2026-11-27, pending the
    author's review of draft 65).
  - *Why 30 days:* long enough that a desk monitor left through a usual
    trip comes back to photos still on hand, without fetching them again
    (author, 2026-11-27).
  - *Why 500 MB:* rules 1 and 2 keep the cache near what's in use, so
    the size limit is a backstop for unusual cases: a large album rotated
    quickly on several displays, or very large originals. 500 MB is about
    300 photos at the 1.6 MB average of the author's cache (*verified*
    2026-11-27 by Claude: 20 photos in 31 MB). Author, 2026-11-27.
  - *Why the low-disk rule:* when space is truly short, giving the cache
    back is the considerate thing to do, and photos can be fetched again
    (author, 2026-11-27: "I despise apps that waste their user's storage
    space"). Phases does it itself rather than using `~/Library/Caches`,
    because macOS emptying Caches wouldn't spare the files other Spaces
    use (see **Where**), and whether and when macOS empties Caches is
    *recalled*, not tested. The 5 GB threshold is a starting point
    (Claude, 2026-11-27, not measured against when macOS itself warns of
    a full disk).
  - *Replaced:* drafts 54–64 had one rule, a 1 GB limit with the least
    recently shown files deleted first, applied only after a change.
    1 GB was Claude's suggested default in the issue #33 plan, approved
    2026-11-12 with cache management left to its own issue (#35). With
    no other rule, the cache kept every photo shown until it reached
    1 GB, including photos of removed sources.
- `[D-photos-permission]` **Phases asks for Photos access the first time
  it's needed:** when the user chooses Add Photos Album…, never at launch.
  - The usage text: "Phases shows photos from the albums you choose as
    your wallpaper."
  - **Refused, or turned off later in System Settings:** the sheet says
    "Phases doesn't have access to Photos" with an **Open Privacy &
    Security Settings…** button. Every Photos source shows "Can't open"
    the same way, and its photos count as missing. Folder sources carry
    on.
  - macOS has no limited-library mode for Photos access, only all or
    nothing (*recalled*; iOS has one).
  - A new build of Phases asks again `[L-photos-new-build-asks]`. That
    matters for testing, not for users of one build.
- **A Photos source Phases can't open** (access refused, or the album or
  folder deleted in Photos) shows "Can't open" in its row, with no
  Locate… (an album isn't somewhere to look for). Its photos count as
  missing, as a folder's do. A deleted photo, or one taken out of the
  album, shows as missing in the phase editor, as a deleted file does.
- `[D-photos-changes]` **Album changes show up while Phases runs.** Adding
  photos to an album, removing them, reordering it, or renaming it
  updates the grid, the counts, and the headings, with no reload.
  *Verified:* PhotoKit reports album changes while Phases is in the
  background `[L-photos-x5-observer]`.
  - New photos aren't added to any phase's selection by themselves, as
    with a folder's new files.
- **The grid** shows a Photos source like a folder: a heading with the
  album's name, and for a folder of albums a heading per album.
  Thumbnails come from Photos. `[D-grid-one-tab-stop]`,
  `[D-grid-collapse]`, and `[D-grid-release-on-close]` apply.
  - Thumbnails of iCloud-only photos should still show offline, since
    Photos keeps small versions locally (*recalled*, not tested).
