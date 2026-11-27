# Phases spec: Interface

Part of the Phases specification. [SPEC.md](../SPEC.md) is its front
page: the draft number, the "Design decisions" rules, and the list of
spec files.

What's here: the interface-wide rule, icons, the menu bar menu, and the
Dock icon and app menu. The window: [window.md](window.md) and
[phase-editor.md](phase-editor.md).

## Interface

- `[D-content-vs-tools]` **Controls stay clearly separate from content.**
  By default, a control doesn't blend into the wallpaper or images behind
  it; an exception has to be a deliberate, stated choice. Where Liquid
  Glass-style translucency costs legibility or findability, Phases doesn't
  follow it.
  - *Why:* the author's standing design principle, moved here from
    CLAUDE.md (2026-11-01) so it carries a tag like other decisions.

### Icons
- **App icon:** the supplied artwork (landscape in a circle between two lunar
  crescents, blue gradient), as a layered Icon Composer icon
  (`App/AppIcon.icon`), so macOS draws it with Liquid Glass and its
  default, dark, and tinted appearances. It replaces the earlier flat PNG
  (author, 2026-11-14).
- `[D-menubar-icon]` **Menu bar icon:** a simplified version of the app icon, drawn for legibility
  at menu bar size: a bold photo circle (about two-thirds of the width) with a
  filled sun and filled mountains clipped inside, flanked by two solid
  crescents set close to the ring. Rendered as a template image so macOS colors
  it for light and dark menu bars, drawn at 20 pt.
  - *Why:* the first version (draft 7) used thin outlines throughout; at 20 pt
    the inner landscape became a squiggle and the outlined crescents blurred.
    Solid shapes and a larger central circle fixed it, checked by rendering
    both at actual menu bar pixel sizes.
  - `[D-menubar-icon-paused]` **While paused, for any reason, the icon
    shows a small pause badge** (two bars) at its lower right, still a
    template image.
    - *Why:* a pause caused by an outside change `[D-outside-change-pauses]`
      happens without the person choosing Pause, so they need a sign that
      lasts without opening anything. Manual pause gets the same badge so
      one look means one thing.

### Menu bar menu
`[D-menu-status-header]` Kept short. Status is a single section header, not separate dimmed items,
following the pattern of Apple's own menu bar extras (e.g. Time Machine's
"Latest backup" line).

- **Status header**, one line:
  - "Dusk · until 7:13 PM": active phase and when the next phase starts
    (weekday added if it's not today)
  - "All Day": an active phase with no upcoming phase change
  - "Dusk · Paused" while paused; "No active phase" if none applies
  - "Paused · wallpaper changed in System Settings" while Phases has
    paused itself for an outside change `[D-outside-change-notice]`, in
    place of the phase line. **Resume Wallpaper Changes** resumes.
    - *Why:* it's status, so it stays in the header, the way Apple's own
      menu bar extras show status. Draft 37 first added it as a second,
      dimmed line, which made two hard-to-read lines (author,
      2026-11-06). The HIG has no guidance on status lines in menus; it
      reserves dimming for unavailable items (*verified* 2026-11-06,
      HIG "Menus").
- **Change Now**: advances to the next image in the active phase
- `[D-menu-pause-verb]` **Pause Wallpaper Changes**, which reads **Resume
  Wallpaper Changes** while paused (for any reason). The pause is saved
  across launches.
  - *Why:* a command names what it will do. A checked "Pause Schedule"
    reads as a state and leaves people working out what unchecking means
    (author, 2026-11-06). The HIG allows either; it suggests a verb when
    a changeable label could be read as a state (*verified* 2026-11-06,
    HIG "Menus"). Draft 36 and earlier used a checkmark.
  - *Why "Wallpaper Changes":* it names what the person wants to stop.
    "Pause Schedule" was accurate but not what someone reaching for it
    means (author, 2026-11-24, GitHub issue #2). It doesn't say "all",
    because Change Now still works while paused (see "Change Now while
    paused"). The Settings switch `[D-settings-pause-switch]` and the
    pause banner's button `[D-window-pause-banner]` use the same words.
    Drafts 36–59 said Pause Schedule / Resume Schedule.
- **Open Phases…**: opens the Phases window
- If location access is denied and a phase needs it, one extra dimmed line
  says so (see "Location").

`[D-menu-no-shortcuts]` The current image's filename is not shown in the
menu. There is no Quit item
in the menu; Quit lives in the app menu, which shows while the Phases
window is open `[D-app-menu]`.

No keyboard shortcuts in the menu. Shortcuts in a menu bar extra's menu work
only while that menu is open, so they'd be decoration; Apple's own menu bar
extras don't show them. No global hotkey.

## Dock icon and app menu

- `[D-dock-while-open]` **Phases shows a Dock icon, and appears in the ⌘Tab
  switcher, only while its window is open.** It launches as a menu bar
  accessory with no Dock icon. Opening the window makes it a regular app;
  closing the window makes it an accessory again, and the Dock icon goes
  away. Minimizing the window does not count as closing: the icon stays, so
  the minimized window can be found.
  - *Why:* a window on screen that ⌘Tab can't reach is un-Mac-like
    (author, 2026-10-29). Removing the icon when the window closes follows
    single-window apps such as Contacts, Calculator, and System Settings,
    which quit (and leave the Dock) when their window closes. Phases keeps
    running in the menu bar instead, but the Dock looks the same.
  - *How:* the window helper `[D-window-helper-order]` makes Phases a
    regular app when it attaches to the window and watches for the window
    closing. "Open Phases…" also switches before activating, so the switch
    happens before the window comes forward.
  - Replaces draft 24's "No Dock icon" rule.
  - macOS may fight this; see `[Q-regular-activation-menubar]` and
    `[Q-accessory-focus-handoff]` (seen 2026-10-29; handled by
    `[D-close-stays-here]`).
- `[D-close-stays-here]` **Closing the window keeps you on the current
  Space.** When the window closes, Phases hands focus to the frontmost
  app with a window on the current Space, or to Finder if there is none,
  before dropping its Dock icon `[D-dock-while-open]`. Only when Phases
  is the active app; otherwise focus is already elsewhere.
  - *Why:* without this, macOS activated the most recently used app,
    wherever its window was, and switched Spaces to it. Contacts, which
    quits when its window closes, hands off to the current Space or
    Finder instead; Phases should feel the same (author, 2026-10-29).
  - *How:* the choice of app is a pure function over the on-screen
    window list (front to back): the first ordinary window (layer 0,
    visible, at least 50 × 50 pt) not owned by Phases; else Finder.
    Unit-tested.
  - macOS fights this; see `[Q-accessory-focus-handoff]`.
- `[D-open-here]` **"Open Phases…" brings the window to the Space you're
  on; the Dock and ⌘Tab take you to the window.** Choosing "Open Phases…"
  from the menu bar shows the window on the current Space, whether it's
  open on another Space or was closed there, instead of switching Spaces. Clicking the Dock icon
  or picking Phases in ⌘Tab behaves like any other app: macOS follows the
  user's Mission Control setting ("When switching to an application,
  switch to a Space with open windows for the application"). Phases never
  changes that setting. A minimized window is left to macOS: "Open
  Phases…" restores it as usual.
  - *Why:* the menu bar is on every Space, so choosing from it means "show
    it here"; being pulled to another Space is disorienting. It matters
    more in Phases than most apps, because wallpaper changes apply to the
    current Space. The Dock and ⌘Tab are about the app, and on the Mac
    switching to an app goes to its windows; keeping that respects the
    user's own setting (author, 2026-10-29).
  - *How:* if the window (open or closed) belongs to another Space, "Open
    Phases…" turns on
    `.moveToActiveSpace` before activating and turns it off once the
    window has arrived on the current Space (or if Phases loses focus
    first). Nothing persistent changes on the window. Details and the
    approaches that failed: ERRATA.md "Open here".
  - macOS fights this; see `[Q-activate-switches-space]`.
- `[D-reopen-shows-window]` **Launching Phases while it's already running
  shows the window** (from Finder, Spotlight, Launchpad, the Dock, or
  `open`). It behaves exactly like "Open Phases…": Dock icon first
  `[D-dock-while-open]`, window brought to the current Space
  `[D-open-here]`, focus on the sidebar `[D-initial-focus-sidebar]`. An
  open window comes to the front; a minimized one is restored.
  - *Why:* a menu bar app has no other sign that it's running, so
    launching it again is how people look for it. Before draft 34, a
    relaunch made Phases the active app and showed nothing: focus left
    the user's app for no visible reason (GitHub issue #13; seen
    2026-11-03, `[L-reopen-event]`).
  - *Scope:* only a relaunch while running. A fresh launch shows nothing
    (Launch at Login must stay silent), except the very first launch
    `[D-first-launch-shows-window]`.
  - *How:* "Open Phases…", Settings…, the relaunch, the first launch,
    and a click on the pause notification `[D-notice-opens-window]`
    share one window-opening routine, so they can't drift apart. macOS
    delivers the relaunch to Phases, but SwiftUI ignores it when the
    window is closed or was never opened; see
    `[Q-reopen-ignores-closed-window]`.
- `[D-first-launch-shows-window]` **The first launch opens the window,**
  exactly as "Open Phases…" does `[D-reopen-shows-window]`. Every later
  launch starts in the menu bar only.
  - **First launch** means this user account has no saved Phases settings
    at all. Phases records that it has launched, and a launch with that
    record, or with any settings saved by an earlier version, is not a
    first launch. So updating Phases never pops the window open for
    someone who already uses it. Erasing Phases' settings on purpose
    makes the next launch a first launch again, which is fine.
  - Launch at Login can't trigger it: it can only be turned on from
    inside Phases `[D-login-consent]`, by which time the launch is
    recorded.
  - *Why:* someone opening Phases for the first time should find its
    settings straight away instead of a menu bar icon they may not
    notice (GitHub issue #14, author). An onboarding screen may come
    later.
  - The window comes to the front, like any app the user just opened.
    macOS fights this; see `[Q-launch-activate-refused]` (*How* in
    ERRATA.md "First launch comes to the front").
- `[D-app-menu]` **While the window is open, Phases has a standard menu
  bar,** trimmed to what applies:
  - **Phases** (app menu): About Phases, **Settings… ⌘,** (opens the window
    with Settings selected in the sidebar `[D-one-window]`), Hide, Hide
    Others, Show All, **Quit Phases ⌘Q**.
  - **File:** none. Phases has no documents, so nothing to put in it.
    Close ⌘W is in the Window menu, where SwiftUI puts it for a
    single-window app (verified 2026-10-29). System Settings has no File
    menu either (recalled).
  - **Edit:** kept. Text fields (phase names) get Undo, Cut, Copy, Paste,
    and Select All from the Edit menu's shortcuts; removing it would break
    ⌘C and ⌘V in them (recalled AppKit behavior, to be checked in testing).
  - **View:** no Show/Hide Sidebar (ruled out by
    `[D-sidebar-always-visible]`) and no toolbar items. What's left is a
    View menu holding only a disabled Enter Full Screen, which macOS
    insists on `[Q-view-menu-fullscreen]`. It stays: removing it with AppKit
    made it show up when the menus opened and then vanish when they were
    clicked, which is worse than an extra menu (author, 2026-10-29; tried in
    draft 26).
  - **Window:** kept as macOS provides it (Minimize, Zoom, the window list,
    and so on). The app must behave like a well-mannered Mac app (author,
    2026-10-29).
  - **Help:** no "Phases Help" item; there's no help book. The menu stays
    for its search field.
  - *Why:* Quit belongs in the app menu, like every Mac app (author,
    2026-10-29). Replaces `[D-quit-in-window]` (draft 24 and earlier: a
    hidden ⌘Q button in the window plus a Quit Phases button in Settings,
    because an accessory app has no app menu).
  - With the window closed there's no menu bar of Phases' own, so quitting
    means opening the window first, as before.
- `[D-quit-confirm]` **Quit Phases (⌘Q) asks first,** because with a Dock
  icon, ⌘Q looks like "close this app", and it's easy to forget that
  Phases keeps working from the menu bar. An alert:
  - **Title:** "Quit Phases?"
  - **Text:** "Your wallpaper will stop changing on schedule." plus what
    happens to it, from `[D-restore-on-quit]`: "The wallpaper you had before
    Phases started will be put back." or "The current wallpaper will stay."
    Then: "To keep Phases running in the menu bar, close its window
    instead."
  - **Buttons:** **Quit** (default, Return), **Keep in Menu Bar** (closes the
    window; Phases keeps running), **Cancel** (Esc; nothing happens).
  - **"Don't ask again"** checkbox. Checked plus Quit turns the question off.
    Settings' Launch & Quit section has an **Ask before quitting** toggle (on by
    default, saved across launches) to turn it back on.
  - Only the Quit menu item asks. Logging out, restarting, or shutting down
    quits without asking, so it never blocks them.
  - *Why:* the author pressed ⌘Q meaning "close" and quit Phases instead
    (2026-10-29). "Keep in Menu Bar" names where Phases goes, rather than the
    mechanism ("Close Window") or a vaguer "Keep Running".
