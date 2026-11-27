# Phases spec: Transitions

Part of the Phases specification. [SPEC.md](../SPEC.md) is its front
page: the draft number, the "Design decisions" rules, and the list of
spec files.

What's here: the crossfade, the persistent cover, and a change step
by step.

## Transitions

- **App preference: Transition**: None or **Crossfade** (default).
- **App preference: Duration**: 0.5 to 3 seconds (default 1 second), shown
  only when Crossfade is selected.
- `[D-reduce-motion-note]` **Settings says when Reduce Motion turns
  transitions off.** With Reduce Motion on (System Settings ›
  Accessibility › Display), the Transition section shows: "Transitions
  are off because Reduce Motion is on in System Settings." With it off,
  no note. The note follows the system setting while Settings is open.
  - While Reduce Motion is on, the Transition and Duration controls are
    dimmed and can't be changed: they'd have no effect
    `[D-no-fade-cases]`, and a control that does nothing shouldn't look
    usable (author, 2026-11-14).
  - Their values are kept, defaults included, and show again unchanged
    when Reduce Motion is turned off. Reduce Motion never writes to
    either preference.
  - Under the note, an **Open Motion Settings…** button opens System
    Settings › Accessibility › Motion, where Reduce Motion lives. It only
    opens the pane when clicked; Phases never opens it, or asks about it,
    by itself. If that pane can't be opened directly, the button opens
    Accessibility instead.
    - A button rather than a link in the note: it matches the Location
      section's **Open Location Settings…** and Launch & Quit's **Open Login
      Items…**, and the HIG suggests "a button that opens it directly"
      for the system Settings app (HIG "Settings"). Asked for by the
      author, 2026-11-14.
    - The link is `x-apple.systempreferences:com.apple.Accessibility-Settings.extension?Motion`.
      *Verified* 2026-11-14 by the author, macOS 27.2: it opens
      Accessibility › Motion. The fallback to Accessibility is untested.
  - *Verified* 2026-11-14 by the author, draft 56 build: turning Reduce
    Motion on and off in System Settings shows and hides the note and
    dims and restores both controls live, with their values kept.
  - *Why:* drafts up to 55 always showed "Changes are instant when
    Reduce Motion is on.", whatever the setting, so it never said
    whether it applied (issue #32, draft 56).
- `[D-low-memory-note]` **On a Mac with less than 16 GB of memory,
  Settings suggests turning transitions off.** Directly under the
  None / Crossfade control, a note: "You can disable transitions to
  reduce Phases' memory usage. Current memory use: 142 MB", with
  Phases' actual figure, the same snapshot as About's Memory line
  `[D-memory-in-about]`. If the figure can't be read, the note ends
  after the first sentence.
  - The note shares the control's row: no separator between them, in
    the normal text size (secondary color), not a caption.
  - *Why:* the note is about that control, so it sits visually joined
    to it; the figure shows what's at stake without scrolling to About
    (author, 2026-11-24, after seeing draft 60's first build, where it
    was a separate caption row).
  - Shown only when all three hold: the Mac's physical memory is under
    16 GB (16 × 1024³ bytes; a 16 GB Mac reports exactly that, so it
    gets no note), Transition is Crossfade, and Reduce Motion is off.
    With None selected, or Reduce Motion on `[D-reduce-motion-note]`,
    transitions are already off and the note would be noise.
  - The decision is a pure function in the model, unit-tested
    `[D-tests-unhosted]`; the view only shows the text. The memory
    size can be faked in test mode so a UI test can see the note appear
    and disappear (TEST-TOOLS.md `[D-test-memory-size]`).
  - *Why the note is true:* crossfades are what cost Phases memory
    between changes, one cover buffer per display (see "The persistent
    cover", *Cost*), and before the cover fixes crossfade images were
    most of `main`'s 179 MB (*measured*, LEARNINGS.md `[L-main-memory]`).
    With Transition set to None no covers are kept
    `[D-cover-only-for-crossfade]`.
  - *Why:* on smaller Macs, Phases' memory use is a reasonable thing to
    trade against a fade (author, 2026-11-24, GitHub issue #2).
- macOS has no transition for wallpapers set by apps, so Phases does it itself
  by **fading the new image in over the old one** `[D-fade-in]`
  (see *Why fade in* below), on a cover that then stays up while its
  Space is showing `[D-persistent-cover]`.

### The persistent cover

- `[D-persistent-cover]` **After a crossfade, the cover stays up for as
  long as its Space is showing.** It isn't removed after a settle delay;
  it goes when the next change on that display replaces it, or when you
  leave its Space `[D-cover-per-space]`. The real wallpaper is still set
  behind it, so the menu bar text, the lock screen, and the login window
  read the right image.
  - **The cover:** a borderless, click-through window showing the image.
    `[D-cover-level]` It sits just above the desktop picture and below the
    desktop icons, so icons and windows don't flicker. It covers the full
    screen, including under the menu bar. Desktop icons, widgets,
    right-clicks on the desktop, and "Click wallpaper to reveal desktop"
    work through it (*observed* 2026-10-30, LEARNINGS.md
    `[L-desktop-through-cover]`).
  - *Why:* two problems go away.
    - **The twitch** `[Q-wallpaper-motion-delay]`: a visible cover never
      comes off, so macOS's motion after a change plays behind it, never
      in view. Retires `[D-cover-settle]`. Measured: no twitch on one
      display or three (`[L-cover-three-displays]`, with covers that
      joined every Space; see `[D-cover-per-space]`).
    - **The menu bar background lag:** with the old cover, the background
      restyled only when the cover came off, 1.5 s after the fade
      `[Q-menubar-bg-follows-window]`. Now it restyles at the end of the
      fade `[D-cover-opacity]`.
  - *Cost:* memory. At most one cover buffer per display between changes
    `[D-cover-iosurface]`, about 25–63 MB each at the author's display
    sizes (*inference* from decoded image sizes, LEARNINGS.md
    `[L-mem-fix-ideas]`). That's why there's a cover only when crossfades
    are on `[D-cover-only-for-crossfade]`.
  - Tested on branch `spike/persistent-cover`, now tag
    `archive/spike/persistent-cover` (docs/X-PERSISTENT-COVER.md there),
    2026-10-30, macOS 27.2, one display and three.
  - *Verified* 2026-11-03; the record is under "Record for `[D-persistent-cover]`"
    at the end of this file.
- `[D-cover-per-space]` **Each Space keeps its own wallpaper.** A cover
  belongs to the Space it was made on, and is removed once that Space is
  no longer showing on its display. The Space keeps its real wallpaper,
  which Phases set at the end of the fade, so it's the same image.
  - Arriving on a Space shows its own real wallpaper, with no cover, the
    same as without Phases. The next change made there fades in a new
    cover over it.
  - Removing the cover happens off screen, so it can't be seen: no frame
    changed when it went, or after returning (*measured* 2026-10-31,
    `[L-cover-own-space]`).
  - *Why:* the author wants each Space to be able to show its own
    wallpaper, toward a future choice of images per Space within a phase
    (author, 2026-10-31). A cover that joins every Space shows one image
    on all of them, which rules that out. The experiment's covers did
    that, along with syncing each Space's real wallpaper on arrival
    (`[L-cover-all-spaces]`); neither is used.
  - *Also:* holds memory to one buffer per display, not one per Space,
    apart from pending changes `[D-change-stays-on-its-space]`.
  - A cover without `.canJoinAllSpaces` stays on the Space it was made
    on, slides away with it during a swipe, and reports itself off the
    active Space once macOS announces the change (*verified* 2026-10-31,
    one display, three Spaces, `[L-cover-own-space]`). Not yet tried on
    more than one display.
  - Phases tells whether a cover's Space is showing by asking its window
    (`isOnActiveSpace`) whenever macOS reports a Space change. There's no
    public API that names Spaces (*recalled*), so the future per-Space
    choice needs its own investigation.
  - *Verified* 2026-11-03; the record is under "Record for `[D-cover-per-space]`"
    at the end of this file.
- `[D-change-stays-on-its-space]` **A change belongs to the Space it was
  made on, even if you leave mid-fade.** When a fade ends (or is cut short
  by another change), each display's new cover is checked:
  - **Still showing:** the wallpaper is set and the old cover removed, as
    in "A change, step by step".
  - **Its Space is no longer showing:** the wallpaper isn't set yet. The
    new cover stays on its Space, fully faded in, and the change is
    **pending**. When that Space shows again, Phases sets the wallpaper
    behind the cover, and from then on it's an ordinary cover
    `[D-cover-per-space]`.
  - `[D-reset-on-quick-return]` **Left just after the set:** if its Space
    stops showing within 1.5 s of its wallpaper being set, the cover
    isn't removed. It goes back to pending, and the wallpaper is set
    again when that Space shows again.
    - *Why:* a set made early in a swipe can land on the Space you're
      arriving on, even though the cover still reports its own Space as
      showing (3 of 19 trials, 2026-11-03). Nothing Phases can check at
      the moment of the set tells it where the set will go. Setting
      again on return makes sure the Space the change was made on gets
      it. If the first set did land there, the second changes nothing
      visible apart from the usual menu bar blink `[Q-menubar-blank]`.
      macOS fights this; see `[Q-set-target-decided-late]`.
    - *What it can't fix:* in that misfire, the Space you arrive on
      hard-cuts to the new image and keeps it until its own next change.
      Phases never learns what that Space showed before, so it can't put
      it back.
    - *1.5 s:* longer than the 0.5–1.1 s macOS takes to announce a Space
      change `[Q-space-notify-after-swipe]`, so every set made during a
      swipe falls inside it. *Cost:* that cover's buffer is held until
      you return, as for any pending change.
    - *Rejected:* reading the wallpaper just before the set and holding
      the change if it no longer matches the Space's image. The read
      pointed at the right Space while the set went to the other
      (LEARNINGS.md `[L-swipe-set-read]`).
    - *Verified* 2026-11-03; the record is under "Record for `[D-reset-on-quick-return]`"
      at the end of this file.
  - A cover whose fade is still running, or whose change is pending, is
    not removed on leaving its Space. The old cover under a pending one
    is removed as usual (off screen).
  - The Space you arrive on is left alone: it keeps its own image.
  - *Why:* the public API sets the wallpaper only on the Space showing
    (*recalled*), and macOS announces a Space change only after the swipe,
    about 0.9–1.1 s after the key press (*verified*,
    `[Q-space-notify-after-swipe]`). With draft 33's first version, a
    3 s fade left mid-way set the wallpaper on the arrival Space, which
    hard-cut to the new image with no fade, while the Space left behind
    never got it (*measured* 2026-10-31, `[L-space-leave-mid-fade]`).
    Holding the cover keeps what you saw on the Space you left; setting
    on return finishes the change where it was made. macOS fights this;
    see `[Q-space-notify-after-swipe]`.
  - *Cost:* on returning, the menu bar keeps the old image's style until
    the set lands, about 1 s after the swipe starts, then blinks and
    restyles (*inference* from `[Q-space-notify-after-swipe]` and
    `[Q-menubar-blank]`). Each pending change holds a cover buffer until
    you return: at most one per Space per display.
  - *Rejected:* setting the real wallpaper when the fade starts, under a
    cover still showing the old image. The menu bar would switch up to
    3 s before the screen does, the draft 4 problem `[D-fade-in]`
    `[Q-menubar-reads-wallpaper]`. Also rejected: dropping the change on
    the Space left behind, because a fade you watched start would be
    undone when you came back.
  - **How long a pending change lives:** only in memory, never saved. It
    waits until its Space shows again, however long that takes, unless
    it's dropped first. Dropped means its cover goes and its Space keeps
    the older image. That happens on:
    - Quit, logout, restart, shutdown, Force Quit, or a crash
      `[D-cover-pause-quit]`;
    - crossfades turning off (Transition: None or Reduce Motion)
      `[D-cover-only-for-crossfade]`;
    - its display disconnecting `[D-cover-follows-displays]`.
      Reconnecting doesn't bring it back.
  - **Pending changes can't pile up.** A change only starts on the Space
    showing, and arriving on a Space sets its pending change. So each
    display has at most one per Space. One brief exception: if a new
    change starts on a Space before macOS has announced your arrival
    there `[Q-space-notify-after-swipe]`, and you leave again mid-fade,
    that Space holds two. On the next arrival the newer is set and the
    older dropped. Worst case memory: one buffer per Space per display.
  - *Why not saved across launches:* nothing public names a Space
    (*recalled*), so a saved change couldn't find its Space again.
  - *Untested:* deleting a Space in Mission Control while it holds a
    pending change. macOS moves a deleted Space's windows to another
    Space (*recalled*), so the change would land there when it shows.
    That Space would then show the image its cover was already showing.
  - **Checked by hand before merging** (TESTING.md `[D-cover-checks]`),
    including a 1 s fade that ends during the swipe, before macOS
    announces it. In that case, whether `isOnActiveSpace` and the
    wallpaper set agree on which Space is showing is untested; if they
    disagree, the change could still land on the wrong Space.
  - *Verified* 2026-11-03; the record is under "Record for `[D-change-stays-on-its-space]`"
    at the end of this file.
  - **Fails** 2026-11-03 (cover check 5, 1 s fade, ⌃→ about 0.7 s in):
    in 1 of 6 trials they disagreed. The fade ended 0.25 s into the
    swipe; `isOnActiveSpace` still said the cover's Space was showing,
    so the wallpaper was set, but it landed on Space 2, which hard-cut
    to the new image with no fade, while Space 1 kept its old one. The
    other 5 landed on Space 1. `[Q-set-target-decided-late]`. Answered
    by `[D-reset-on-quick-return]` (approved by the author, 2026-11-03).
    Checks 3–6 rerun on that build the same day: all pass.
- `[D-cover-only-for-crossfade]` **No cover at all unless crossfades will
  actually play:** Transition is Crossfade and Reduce Motion is off.
  - With **Transition: None**, or with Reduce Motion on, Phases just asks
    macOS to change the wallpaper, as drafts before the cover did, and
    holds no cover memory.
  - **Turning crossfades off** (in Settings, or Reduce Motion going on)
    removes every cover at once. Invisible: the real wallpaper behind each
    one is the same image.
  - **Turning crossfades on** puts up no cover by itself. The next change
    brings one.
  - Phases puts up no cover at launch either: until a change, there's no
    motion to hide.
  - *Why:* the cover's only job is to make transitions possible and keep
    them clean; it isn't worth its memory without them (author,
    2026-10-31). Reduce Motion counts as off because it turns every fade
    into an instant switch `[D-no-fade-cases]`.
  - *Verified* 2026-11-03; the record is under "Record for `[D-cover-only-for-crossfade]`"
    at the end of this file.
- `[D-cover-opacity]` **The cover is 99% opaque, not 100%.**
  - *Why:* a fully opaque cover stopped the menu bar restyling for new
    wallpapers: text stayed one color through every change, and with
    "Show menu bar background" on, the background kept an earlier image's
    color through changes, app switches, and 15 s. At 99%, text and
    background restyled promptly for every change, with or without the
    background setting, on one display and three. *Measured* 2026-10-30.
    macOS fights this; see `[Q-opaque-cover-freezes-menubar]`.
  - The 1% that shows through is the real wallpaper, which is the same
    image once set, so it can't be seen. No twitch shows through either:
    frames before and after each fade matched at noise level (43–50 dB).
    *Measured.*
  - *Rejected:* taking an opaque cover off briefly once the wallpaper has
    settled. The background restyled, but the twitch came back at that
    moment, even 4 s after the set (*measured*, `[L-motion-waits-for-reveal]`).
  - Whether the cover could go to 100% once the menu bar has restyled is
    open and untested (`[L-cover-alpha-later]`); not part of this draft.
  - *Verified* 2026-11-03; the record is under "Record for `[D-cover-opacity]`"
    at the end of this file.
- `[D-cover-follows-displays]` **Covers follow display changes.** When a
  display's frame or scale changes, its cover is redrawn at once, without
  a fade, showing the same image at the new size. A disconnected
  display's cover is removed. A newly connected display has no cover
  until Phases changes its image; the normal check
  `[D-screen-change-no-reroll]` may do that right away.
  - Only real geometry changes count. Hiding the Dock or toggling "Show
    menu bar background" also sends the screen-change notification
    `[Q-screen-params-notification]`, but changes no display's full frame,
    so no cover is redrawn.
  - *Why:* a cover that no longer fits its display would show plainly,
    and the experiment didn't handle this (GitHub issue #6).
  - The redraw reads its image with source access open (draft 58,
    `[D-sandboxed]`); before that it worked only outside the sandbox.
  - *Verified* 2026-11-03; the record is under "Record for `[D-cover-follows-displays]`"
    at the end of this file.
  - Accepted by the author, 2026-11-04: a reconnected display having no
    cover until its next change is left as is. Nobody using Phases can
    see the difference.

### A change, step by step

With crossfades on `[D-cover-only-for-crossfade]`:

1. **New cover:** on each display whose image is changing, a new cover
   showing the *incoming* image appears, fully transparent, above the
   display's current cover (if it has one).
2. **Fade in:** the new cover fades to 99% `[D-cover-opacity]` over the
   chosen duration. The real wallpaper hasn't changed yet.
3. **Switch:** the new wallpaper is set behind the covers, and the old
   cover is removed at the same moment. Invisible: the new cover is on
   top, and the old cover and the real wallpaper only show through its 1%.
4. **Stay:** the new cover stays up until the next change on that display,
   or until its Space stops showing `[D-cover-per-space]`. There's no
   settle delay.

- *Why a new window per change,* not a new image inside the same window:
  the 99% results were all measured that way (variant B in the
  experiment). A single window was tested only at 100%, where the menu
  bar failed in both forms `[Q-opaque-cover-freezes-menubar]`.
- The cover draws the image the way macOS will, using that screen's
  scaling (fill, fit, stretch, or center) and fill color.
- *Replaced:* `[D-cover-settle]` (drafts 5–32) removed the cover after a
  settle delay, so macOS's motion `[Q-wallpaper-motion-delay]` would
  finish behind it. The delay had to be raised from 0.5 s to 1.5 s on
  macOS 27.2 (cause unconfirmed; see "The twitch returns" in ERRATA.md),
  and it made the menu bar background lag the fade
  `[Q-menubar-bg-follows-window]`. A cover that stays up while it can be
  seen needs no delay.
- `[D-no-screenshots]` The cover is drawn from the image file. No screenshots and no Screen
  Recording permission.
- `[D-cover-iosurface]` **Each cover holds one copy of its image, and only
  while it's up.**
  - The file is decoded once, at no more than the size the screen needs,
    then drawn into a shared graphics buffer (an IOSurface) that the cover
    shows. The decoded image is dropped as soon as it's drawn: two copies
    for a moment, then only the buffer.
    - ImageIO is told not to cache a full-size decode
      (`kCGImageSourceShouldCache` off). Whether it still makes one
      internally for some formats is measured, not assumed.
    - Not decoded straight into the buffer: macOS has no public way to
      decode a file into memory the caller supplies (*recalled*, not
      verified).
  - 8 bits per channel: macOS shows the wallpaper as SDR, even for an
    HDR photo (LEARNINGS.md `[L-hdr-wallpaper]`).
  - The buffer is tagged with the image's own color space, so colors match
    what macOS draws for the same file on every display, whatever that
    display's color space. An image with no color space, or one that
    isn't RGB (grayscale, CMYK), is drawn in sRGB and tagged sRGB.
  - When the cover is removed, its buffer is released with it.
  - *Why:* up to draft 31, each change left full-screen copies behind (one
    per changing display, about 25–63 MB each at the author's sizes), and
    memory climbed by roughly 20–40 MB per change across three displays,
    to about 300 MB after ten changes. Most of that was a copy the system
    made of every image handed to a cover; a shared buffer is shown as is,
    with no copy. macOS fights this; see `[Q-cover-image-copied]` and
    `[Q-iosurface-color-tag]`.
  - *Cost:* the cover's pixels are drawn by Phases rather than by the
    system's image pipeline, so color matching depends on the tag. Measured
    within 1–5 of 255 of the system's own drawing on all three of the
    author's displays (2026-10-30, test harness, not yet in Phases).
  - *Also:* this sets the floor for the persistent cover
    `[D-persistent-cover]`: at most one buffer per display between
    changes, while crossfades are on, plus one more per changing display
    during a fade. Draft 32 held a buffer only during a fade and the 1.5 s
    after it.
- `[D-no-fade-cases]` **No fade (instant switch) when:**
  - Transition is set to None, or Reduce Motion is on (System Settings ›
    Accessibility › Display). There's no cover in either case
    `[D-cover-only-for-crossfade]`.
  - The incoming image file can't be read, or its cover buffer can't be
    made `[D-cover-iosurface]` (that screen only: its old cover is
    removed and the wallpaper switches without a fade, at the same moment
    as the other screens finish fading). That display stays uncovered
    until a later change there gets a cover; an old cover left up would
    hide the new wallpaper.
  - A screen's image isn't actually changing (that screen only; its cover
    stays as it is, if it has one)
  - Restoring the original wallpaper on quit `[D-restore-on-quit]`
- If another change starts while a fade is running, the running fade finishes
  instantly (its cover jumps to 99%, its wallpaper is set, and the cover it
  replaced is removed) and the new change starts its own fade.
- *Why fade in `[D-fade-in]`:* the real wallpaper changes only at the end,
  behind an identical image, so nothing flashes and the menu bar switches
  once, at the end, just as it does when changing wallpaper in System
  Settings. The old wallpaper is never redrawn, so crossfades also work
  when the outgoing wallpaper is an Aerial. Draft 4 faded the old image
  out instead; macOS fought that; see `[Q-menubar-reads-wallpaper]` and
  ERRATA.md "Why fade in, not fade out". Unchanged by the persistent
  cover: the fade still runs on a new cover and the wallpaper is still set
  at its end.
- `[D-cover-pause-quit]` **Pause, Quit, and crashes:**
  - **Pause** leaves any cover up. It stops scheduled changes, not what's
    on screen. The exception is a pause caused by an outside change, which
    fades out the changed display's cover `[D-outside-change-pauses]`.
  - **Quit** removes every cover at once, after any restore
    `[D-restore-on-quit]` has set the real wallpaper. With restore on,
    that's a hard cut to the original, as in draft 32 (restoring never
    fades, `[D-no-fade-cases]`). With restore off, the real wallpaper
    already matches, so nothing visible happens. Pending changes are
    dropped `[D-change-stays-on-its-space]`.
  - **Logout, restart, shutdown, Force Quit, or a crash** take the covers
    with the process, leaving the real wallpaper, which matches, except
    on a Space with a pending change: that Space keeps its older image. A
    Force Quit showed nothing (*observed* 2026-10-30).
  - *Verified* 2026-11-03; the record is under "Record for `[D-cover-pause-quit]`"
    at the end of this file.
- `[D-no-focus-steal]` **Phases never activates itself to force a menu bar
  restyle.** That would steal focus from the user's app. macOS sometimes
  delays the restyle; see `[Q-menubar-restyle-on-app-switch]`.

## Record: Transitions

*Verified* notes and other evidence moved here, word for word, from the
decisions above when the spec was split into files (2026-11-27), so a
decision reads as its rule and its *Why*. Each decision keeps a dated
pointer to its record here.

### Record for `[D-persistent-cover]`

- *Verified* 2026-11-03, draft 33 Release build, macOS 27.2, three
  displays (cover check 1): no twitch. Five changes per display, each
  display recorded on its own; the frame 0.1 s after each fade's end
  matched the frame 1.5 s later at 44–48 dB. The only later change is
  a one-frame step of about one grey level some 0.65 s after the fade:
  the real wallpaper switching behind the cover's 1%.

### Record for `[D-cover-per-space]`

- *Verified* 2026-11-03, draft 33, three displays, three Spaces on the
  main one (cover check 3): after a change on Space 1, Spaces 2 and 3
  kept their own image and Space 1 kept the new one (read back on
  each); the log showed Space 1's cover removed on leaving; the
  recording shows only the four swipes, no frame change at the removal
  or on returning.

### Record for `[D-reset-on-quick-return]`

- *Verified* 2026-11-03, Release build `3c891b6` (cover check 5, 28
  trials, 24 informative): Space 1 showed the new image on return
  every time and Space 2 kept its own; 23 trials logged "pending
  again" 0.05–0.84 s after the set, then the set on return, with no
  visible change on return (recordings). The misfire itself didn't
  occur in these runs, so the return set after a real misfire is
  unobserved; it's the same ordinary set, made with no swipe under
  way (LEARNINGS.md `[L-misfire-not-seen]`).

### Record for `[D-change-stays-on-its-space]`

- *Verified* 2026-11-03, draft 33 (cover checks 4 and 6): leaving a 3 s
  fade about 0.5 s and 1.2 s in, the log showed the change held
  pending, Space 2 kept its image with no cut, and on return the log
  showed it set and Space 1 read back the new image. Setting
  Transition to None, or quitting, while a change was pending removed
  every cover, and Space 1 kept its old image.

### Record for `[D-cover-only-for-crossfade]`

- *Verified* 2026-11-03, draft 33 (cover checks 6 and 7): with
  Transition: None, and with Crossfade plus Reduce Motion, changes cut
  in one frame and no cover window existed. Turning Reduce Motion on,
  or Transition to None, with covers up logged their removal and left
  none.

### Record for `[D-cover-opacity]`

- *Verified* 2026-11-03, draft 33, three displays, "Show menu bar
  background" on (the author's setting; cover check 2): text and
  background restyled to each new image on every display, 0.4–0.8 s
  after the fade ended, when macOS applied the set, with the one-frame
  blink `[Q-menubar-blank]`. During the fade the bar keeps the old
  image's background `[Q-menubar-bg-follows-window]`.

### Record for `[D-cover-follows-displays]`

- *Verified* 2026-11-03, draft 33 (cover check 8, partly): changing the
  main display from 2580×1080 to 1720×720 points logged every
  display's cover redrawn (the others moved in the arrangement), and
  the main one filled the screen (screenshot). Hiding and showing the
  Dock logged nothing. Disconnecting the Cinema HD (by the author, same
  day, build `3c891b6`) logged its cover removed ("display 3 gone")
  and the other two redrawn, since macOS rearranged the displays and
  changed the main one to 2614×1094. Reconnecting restored both;
  the other covers were redrawn again and the Cinema had no cover
  until its next change.

### Record for `[D-cover-pause-quit]`

- *Verified* 2026-11-03, draft 33 (cover check 9): with restore on,
  Quit was a one-frame cut back to each display's pre-launch image;
  with restore off, nothing moved. No cover windows remained either
  way. Quit was sent as an Apple Event, which skips the "Quit Phases?"
  alert but runs the same termination path.
