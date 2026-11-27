# Phases spec: Image library

Part of the Phases specification. [SPEC.md](../SPEC.md) is its front
page: the draft number, the "Design decisions" rules, and the list of
spec files.

What's here: image sources (folders and Photos albums), library order,
the image grid, and how images are named and found again. Photos albums
in detail: [photos.md](photos.md).

## Image library

- `[D-image-sources]` **The library is a list of image sources.** A
  source is a folder, chosen with a standard folder picker, or (from
  draft 54) a Photos album or folder of albums `[D-photos-sources]`. The
  rules in this section are written for folders; "Photos albums" below
  (since the split into files, [photos.md](photos.md)) says where albums
  differ.
  - Settings shows the sources in an **Image Sources** list. Each row has
    two lines:
    - The folder's name, with its own **Include subfolders** switch at
      the end of the line.
    - Its location, a bullet, and how many images it has, in secondary
      text: `~/Pictures/Desktop Pictures • 77 images`
      (`[D-source-location]`). A long location truncates in the middle;
      the count never does. The full location is in a tooltip.
    - *Why:* two lines instead of three keeps the list compact (author,
      2026-11-12). The cost is that a long location shows less of
      itself, hence the truncation rule and the tooltip.
    - A source that can't be opened shows "Can't open" and **Locate…**
      in place of the count (see "A source that can't be opened" below).
  - **Adding, removing, and the context menu.**
    - **+** adds a folder and **−** removes the selected one. They follow
      `[D-sidebar-footer-style]`: each button is a 24 × 23 pt cell and
      the whole cell is clickable, with a divider between them.
    - **Dragging folders** from Finder onto the list adds them, the
      standard Mac way to fill a list (author, 2026-11-12). Each folder
      is added as + would add it. Files and anything else that isn't a
      folder are ignored.
    - **A context menu** on each row: **Show in Finder**, **Locate…**,
      then **Remove**, with a separator above Remove to keep the
      destructive item a little further from the pointer (author,
      2026-11-12). Locate… appears only for a source that can't be
      opened; one that's found has nothing to locate (author,
      2026-11-12). Show in Finder is only for sources in the file
      system (folders). A Photos source gets Remove only
      `[D-photos-sources]`. Remove asks first, as − does. Control-click and
      right-click work on any row, selected or not, as they do in the
      phase list `[D-phase-actions]` (author, 2026-11-12).
  - **The list is one Tab stop,** like the image grid
    `[D-grid-one-tab-stop]`: Tab moves into it and the next Tab moves
    past it. Up and down arrows move the selection, and ⌫ removes the
    selected source (asking first, as − does). The Include subfolders
    switches are reached by clicking, or through the selected row's
    accessibility actions, not by Tab.
    - *Why:* in testing, Tab moved into the list and never left it
      (author, 2026-11-12).
  - **The sources' order is the library's order,** for the grid and for
    In order. A new source goes at the end. **Dragging rows** up and
    down reorders them, the standard Mac way (author, 2026-11-12).
    - The order belongs to the user. Nothing may assume a source's place
      is fixed: the order is stored as its own list, source IDs say
      nothing about position, and saved selections don't depend on where
      a source sits. Reordering changes which image comes next In order,
      because In order follows library order.
  - Adding a folder that's already a source (the same folder on disk,
    however it was reached) selects the existing row instead of adding a
    second.
  - A folder inside another source is allowed. If that other source
    includes subfolders, its images are listed twice, once per source.
    That's accepted, as two links to one image already are
    `[D-follow-links]`.
  - Removing a source asks first when any phase uses its images, naming
    how many phases. Their selections of its images then show as missing
    (see the last bullet of this section). Adding the folder again later
    makes a new source, so they stay missing.
  - `[D-undo-remove-source]` **Removing a source can be undone** with
    Edit › Undo Remove “<name>” (⌘Z), however it was removed: −, ⌫, or
    the context menu, by mouse or keyboard. Undo puts back the same
    source (same ID, bookmark, location, Include subfolders) at its old
    place in the list, so every phase's selections of its images come
    back. Redo removes it again.
    - Scope: the window's undo, one step per removal, no history beyond
      what Edit › Undo already keeps. Undo follows keyboard focus, so
      after a removal, typing in a text field puts that typing first in
      line for ⌘Z (standard Mac behavior, *recalled*; author accepts it,
      2026-11-12).
    - *Why:* the removal warning only appears when a phase uses the
      source, so undo is the safety net for the rest (author,
      2026-11-12). The warning stays.
  - *Why:* the author wants several sources at once, such as two Photos
    albums and three folders (2026-11-12, issue #33). Folders come first,
    in their own change, because they need no new permissions and the
    existing UI tests can cover them.
- **Include subfolders** (per source, off by default). When on, the folder is
  scanned recursively, skipping hidden folders and packages (app bundles, Photos
  libraries, etc.).
  - *Verified* 2026-11-04 by the author (`main` at `3ec6dee`, issue #15), with
    a folder two levels deep: turning the setting on shows the subfolder
    images at once, under one heading per folder path; rotation sets the
    wallpaper correctly for top + first level, top + first + second, first +
    second, and top + second; arrow keys cross subfolder headings. Symlinked
    folders weren't followed at the time (issue #17; this note said #18 by
    mistake until draft 35); see `[D-follow-links]`.
- Supported formats: JPEG, PNG, HEIC, TIFF.
- `[D-follow-links]` **Symlinks and Finder aliases count as what they point
  to,** for images and for folders.
  - A link or alias to an image is listed under its own name, in the
    folder that holds it: `_link.png`, or `Winter/_link.png`.
  - A link or alias to a folder counts as a subfolder, even though the file
    system says it's something else (author, 2026-11-04). Phases follows it
    only when Include subfolders is on, and lists its images under the
    link's name, e.g. `Linked/snow.jpg` `[D-source-names]`.
  - The other subfolder rules apply to what a link points to: hidden
    links, and links to hidden folders or packages, are skipped.
  - Broken links and aliases, and ones pointing at anything other than a
    supported image or a folder, are skipped like any other unsupported
    file.
  - A link to something macOS protects (Desktop, Documents, Downloads,
    iCloud Drive, network or removable drives) may make macOS ask for
    permission the first time (*recalled*, not tested with Phases). If
    access is refused, that item is skipped. Whether to show it as "can't
    open" instead is open (issue #20).
  - In the sandbox (draft 58), a link or alias pointing outside the source
    folder is refused the same way, and the diagnostics log names it
    `[D-links-outside-refused]`.
  - Two links to the same image list it twice, once under each name.
    That's accepted (author, 2026-11-04).
  - *Why:* until draft 35 the scan skipped every symlink and alias, so
    images and folders reached that way never appeared (issue #17;
    *verified* 2026-11-04 by Claude with a test folder: symlinks report
    the type `public.symlink`, aliases `com.apple.alias-file`, and the
    scan didn't descend into a symlinked folder).
  - *Verified* 2026-11-04 by the author, draft 35 build, on the real
    wallpaper folder with Finder aliases: "seems to be working fine."
    Symlinks and loops are covered by the unit tests, not checked by
    hand.
- `[D-scan-each-folder-once]` **Each folder is scanned at most once,**
  identified by where it really is, not the path that reached it. This
  includes the chosen folder itself, so a link back to it, or to a folder
  above it, adds nothing, and the scan always ends.
  - When a folder can be reached both directly and through a link, the
    direct path names it (author, 2026-11-04).
  - When only links reach it, the first one in display order names it
    (top-level first, then Finder sort order).
  - *Why:* following links makes loops possible (a folder linked to itself,
    or A → B → A). Without this rule the scan would never end, or would
    list one folder's images over and over.
- `[D-source-names]` **A saved image is named by its source and its path
  within that source,** e.g. source `K3F9`, image `Winter/snow.jpg`.
  - The source part is an ID Phases makes when the source is added. It's
    not a path, so moving or renaming the folder, or a different home
    folder, doesn't change it.
  - The image part is the path relative to the source's folder, so
    top-level selections stay valid when subfolders are turned on.
    Turning subfolders off makes subfolder images show as missing rather
    than silently dropping them.
  - Saved names hold no path above the source folder (author,
    2026-11-12).
  - Replaces `[D-relative-paths]` (drafts up to 44), which named images
    by their path relative to the one library folder. The image part
    keeps that rule.
  - Settings from draft 44 and earlier aren't converted: the folder has
    to be added again, and phases' old selections show as missing
    (Remove Missing clears them). *Why:* Phases has one user, who can
    reconfigure it easily (author, 2026-11-12). Draft 52 first planned a
    one-time conversion; dropped the same day, before any code shipped.
  - *How* (stored form, not shown to users): `<source ID>:<relative
    path>`. The ID never contains a colon, so the name splits at the
    first one, even when a file name has a colon in it.
- `[D-source-location]` **Each source remembers where its folder is in two
  ways:** a bookmark, which is how Phases finds it, and its location
  relative to the home folder (`~/Pictures/Wallpapers`), shown in Settings
  and used to find it again if the bookmark stops working. A folder
  outside the home folder (another drive) keeps its full path, e.g.
  `/Volumes/Art/Wallpapers`.
  - "Home" is the user's real home folder. A sandboxed app's
    `homeDirectoryForCurrentUser` points into its container instead
    (LEARNINGS.md `[L-sandbox-x0-paths]`).
  - *Why:* nothing saved should depend on the path above the home
    folder (author, 2026-11-12).
- `[D-scoped-bookmarks]` **Source bookmarks are security-scoped,** and
  Phases opens access to a source only while reading from it.
  - *Why:* the author plans to sandbox Phases, where only these bookmarks
    keep access to a folder across launches (*recalled*). They also work
    in an app that isn't sandboxed (*recalled*, to be checked with this
    draft's build). Using them now means the sandbox change doesn't
    rewrite this code. Draft 44 and earlier saved a plain bookmark.
  - *Verified* 2026-11-14 by the author and Claude, draft 54 build, not
    sandboxed: a security-scoped bookmark reopens a folder after a
    relaunch. With Phases quit, the author renamed `~/Pictures/Desktop
    Pictures X` to `Desktop Pictures Y`, so the saved location led
    nowhere. On relaunch the diagnostics log said "source 2872UXTY found
    by its bookmark (stale)", and the saved location became
    `~/Pictures/Desktop Pictures Y`. Earlier, with Phases running, a
    rename to `Desktop Pictures X` showed up as it happened.
  - From draft 58 (sandboxed `[D-sandboxed]`), new bookmarks are made
    read-only, to match the read-only folder entitlement
    `[D-sandbox-entitlements]`. Bookmarks saved earlier are kept as they
    are; one that doesn't open in the sandbox shows "Can't open" with
    Locate… `[D-sandbox-settings-move]`.
- **A source that can't be opened** (a drive that isn't connected, a
  folder that was deleted or moved somewhere its bookmark and location
  can't find) shows "Can't open" in its Settings row, with a **Locate…**
  button that picks the folder again and keeps the source's ID, so its
  selections come back. Until then its images count as missing.
  - Renaming a folder Phases can still reach updates its row: verified
    2026-11-12 by the author, for a local folder while Phases ran. On a
    file server, a renamed folder showed "Can't open" instead, and
    Locate… brought its phase's selections back (verified, same day).
    The bookmark doesn't follow a rename there (LEARNINGS.md
    `[L-nas-bookmark-rename]`).
- The Phases window shows the library as a **thumbnail grid**, grouped under a
  heading per source (its folder's name), and under that a heading per
  subfolder when that source includes subfolders. With one source, the
  source heading still shows, so the grid looks the same however many
  sources there are. Click toggles an image in or out
  of the selection, ⇧-click selects a range, plus Select All / Select None buttons
  (in the pinned image header from draft 63, `[D-image-header]`). Every
  heading can collapse `[D-grid-collapse]` (draft 64).
- `[D-grid-collapse]` **Every heading in the grid can collapse,** source
  headings and subheadings (subfolders, "Top Level", and the albums of a
  Photos folder) alike, the way Finder's list view folds folders (GitHub
  issue #37; the author's answers of 2026-11-26).
  - **The triangle:** each heading starts with a disclosure triangle,
    pointing right when collapsed and down when expanded, the one Finder
    and System Settings use (`chevron.right`, turned 90° when expanded).
    Clicking the triangle or anywhere on the heading's line toggles it.
    The triangle turns with a short animation; the images below appear
    or go at once.
    - *Why at once:* animating hundreds of thumbnails in a lazy grid may
      stutter (*hypothesis*, not tested). If it doesn't, the author can
      ask for the images to animate too.
  - **Spacing: tight.** Every subheading sits 6 pt below what's above
    it: the source heading, or the section before (its images, or its
    collapsed heading) (author, 2026-11-26). *Why:* the first build put
    the first subheading 6 pt under the source heading but later ones
    about 20 pt apart (*observed* by the author; the 20 is from the
    code: the grid's 12 pt row spacing plus 8 pt). They ought to match,
    "everything tight, not everything loose" (author). A first fix
    loosened them all to 20 pt instead; replaced the same day.
  - **Collapsing a source** hides its subheadings and all its images.
    Its subheadings keep their own state, so expanding the source shows
    them as they were, as Finder does (*recalled*).
  - **Subheadings stay flat.** A subfolder heading names the whole path
    (`Winter/Snow`), and `Winter` and `Winter/Snow` are separate
    headings at the same level, as now. Collapsing `Winter` hides only
    the images directly in `Winter`.
    - *Why:* nesting the headings into a tree would be a grid redesign of
      its own; the author asked for collapsible subfolders, not a tree
      (Claude's reading, for the author to confirm).
  - **⌥-click** on a source heading collapses or expands it and all its
    subheadings together, as ⌥-click does on a Finder triangle
    (*recalled*). On a subheading it does what a plain click does.
    (Claude's proposal, for the author to confirm.)
  - **A collapsed heading shows its count** after its name, in secondary
    text: "12 of 80 selected" when any of its images are selected,
    otherwise "80 images" ("80 photos" for Photos, as in Settings
    `[D-photos-sources]`). A collapsed source counts every image under
    it, its subfolders' too. Expanded headings show no count; their
    images are in view.
    - *Why:* a collapsed section shouldn't hide what's selected in it
      (author, 2026-11-26).
  - **Kept:** the state is saved and stays after the window closes and
    after quitting `[D-grid-collapse-saved]`.
  - **One state for the whole grid,** not per phase or per display tab:
    it's about the library, not a phase. Switching phases or display tabs
    leaves headings as they were.
  - **New sources and subfolders start expanded.** So does a subfolder
    or album that's renamed, since its heading is a new one; accepted.
  - **Select All and Select None act on every image, collapsed or not,**
    and the "9 of 293 selected" count includes collapsed images
    (author, 2026-11-26). *Why:* otherwise collapsing a section would
    quietly change what Select All means.
  - **⇧-click and ⇧-Space skip collapsed images:** a range selects (or
    deselects) only the images showing between the two ends (author,
    2026-11-26). If the last toggled image is now in a collapsed section,
    ⇧-click acts as a plain click, since the range has no visible start
    (Claude's proposal, for the author to confirm).
  - **VoiceOver** reads a heading as a heading with its name, whether
    it's collapsed or expanded, and its count when collapsed; its action
    toggles it. Each heading has an accessibility identifier for the UI
    tests `[D-ui-test-ids]`.
  - **Icons:** source headings keep their symbols: `folder` for a
    folder, `rectangle.stack` for a Photos album (the symbol Photos uses
    for albums, the author's choice 2026-11-26; already used since draft
    54), and `folder` for a Photos folder of albums. Subheadings gain the
    same symbols, in secondary color: `folder` for a subfolder and "Top
    Level", `rectangle.stack` for an album in a Photos folder. (Adding
    them to subheadings is Claude's proposal, so an album reads as an
    album beside its triangle.)
  - *Replaced:* drafts up to 63, where headings couldn't collapse
    (collapsing was set aside from the editor redesign, author,
    2026-11-25).
- `[D-grid-collapse-saved]` **The collapsed headings are saved** in
  UserDefaults with the other settings (see "Persistence"), as a list of
  collapsed headings, each named by its source ID and subheading path
  (`K3F9` for a source, `K3F9:Winter` for a subfolder), never by position
  `[D-image-sources]`. Removing a source leaves its entries, so undoing
  the removal `[D-undo-remove-source]` brings its headings back as they
  were; entries for sources that are gone do nothing.
- `[D-grid-one-tab-stop]` **Keyboard: the thumbnail grid is one Tab stop.**
  Tab moves into the grid and the next Tab moves past it, the way Finder's
  icon view and Photos work. Inside the grid:
  - **The cursor** (the highlighted item) is on an image or a heading.
    Headings are stops in reading order; images in collapsed sections
    are skipped, but the collapsed headings aren't (author, 2026-11-26,
    `[D-grid-collapse]`).
  - **Arrow keys on an image:** left and right step through items in
    order (images and headings), wrapping across rows. Up and down move by
    one row; a heading is a row of its own. Moving onto an image row
    keeps the column the cursor was in, even after passing over
    headings; on a shorter row the cursor lands on its last image.
  - **Arrow keys on a heading,** as in Finder's list view: → expands a
    collapsed heading, and on an expanded one moves to the next item. ←
    collapses an expanded heading, and on a collapsed one moves to the
    previous item. ⌥→ and ⌥← on a source heading expand or collapse it
    with all its subheadings, like ⌥-click (*recalled* from Finder; Claude's
    proposal). Up and down move by one row, as on an image.
  - **Space** toggles the highlighted image, or expands or collapses the
    highlighted heading (author, 2026-11-26). **⇧-Space** on an image
    selects a range from the last toggled image, the same as ⇧-click
    `[D-grid-collapse]`; on a heading it does what Space does.
  - The window scrolls to keep the highlighted item visible.
  - The highlight shows only while the grid has keyboard focus. Clicking an
    image or a heading moves the highlight there and focuses the grid.
  - Collapsing the section the cursor is in (by clicking its heading)
    moves the cursor to that heading.
  - Tabbing into the grid puts the cursor on the first image that
    shows, as before, or on the first heading when every section is
    collapsed. *Added while building* (Claude, 2026-11-26): the approved
    draft didn't say; keeping the first image keeps Space selecting an
    image straight away, as it always has.
  - *Changed in draft 64:* up to draft 63, only images were stops, and up
    and down crossed headings in the same column.
  - Images are not individual Tab stops, and VoiceOver still sees each image
    as a toggleable button with its file name.
  - *Why:* in draft 19 each image was its own button, and Tab couldn't get
    through a grid larger than the window (found in testing, 2026-10-28).
    Making every image a reachable Tab stop would cost one keypress per
    image to get past a large folder. One Tab stop with arrow keys matches
    macOS collection views and adds arrow-key movement. macOS fights the
    per-image approach; see `[Q-lazy-grid-tab]`.
  - *Verified* 2026-10-28 by the author: Tab enters and leaves the grid in
    one stop, arrows (including up/down column math) and ⇧-Space work, and
    the window scrolls to follow the cursor.
- `[D-grid-release-on-close]` **Closing the Phases window releases the
  grid's thumbnails.** Reopening it loads them again.
  - *Why:* the closed window kept every thumbnail and its view for as
    long as Phases ran: about 25 MB for a 22-image folder (measured
    2026-10-30, LEARNINGS.md `[L-mem-window]`), and more for bigger
    folders. Phases spends most of its life with the window closed.
  - *Cost:* thumbnails reload when the window reopens. Expected to be
    quick, since QuickLook keeps its own thumbnail cache (*recalled*, not
    measured).
- If a selected image is later deleted or renamed, or its source is removed
  or can't be opened, it's skipped and the phase editor marks it as
  missing. A phase with no available images is skipped (the wallpaper
  stays as it is).
  - The editor says how many: "2 selected images are missing", with a
    **Remove Missing** button that takes them out of the selection. The
    line shows only when something is missing; from draft 63 it's in
    the pinned image header, above the count line `[D-image-header]`.
