# `[X-notice-click]` What a click on the pause notification does

Part of "Notification clicks" in [EXPERIMENTS.md](../EXPERIMENTS.md), the index of
experiments. Moved here word for word from EXPERIMENTS.md on
2026-11-27, when each record got its own file.


- **Question:** why did a click on the pause notification's body
  sometimes do nothing, or open the window behind other apps?
- **When, on what:** 2026-11-08, macOS 27.2, draft 50's hands-on check;
  the log, `ps`, `lsregister -dump`, and `usernoted`'s log.
- **Branch:** draft 50's own branch, merged as `92c376a`; no separate
  experiment branch.
- **Outcome:** every notification click goes through
  `FirstLaunchWindow.open` (draft 50). The second copy is a development
  artifact of stale Launch Services registrations.
- **Findings:** `[L-notice-click-launches-copy]`.

- `[L-notice-click-launches-copy]` **A click on the pause notification
  can launch a second copy of Phases** (draft 50 hands-on check,
  2026-11-08; *verified* from the log and `ps`):
  - Twice, the running build (12:00:59, pid 73297; 12:09:16, pid 75083)
    logged "window requested by notification", and at the same moment
    macOS launched another copy with the same bundle ID: first
    `/Applications/Phases.app` (pid 73346), then, with that deleted, the
    build in Bitrig's `DerivedData/…/Debug/Phases.app` (pid 75681). Both
    copies then sat in the menu bar.
  - The running copy was Bitrig's launch copy in a temporary folder
    (`/var/folders/…/BitrigLaunchApps/…`); the copy macOS launched was a
    different path registered with Launch Services. Launch Services had
    67 registrations for Phases' bundle ID before cleanup, most for
    deleted builds (*verified*, `lsregister -dump`).
  - Before that, at 11:57–12:00, clicks on an older build's notification
    reached the running copy as a relaunch: it logged "relaunched"
    (`applicationShouldHandleReopen`), with no second copy (*observed*,
    log). So a body click does send a reopen when macOS picks the
    running copy.
  - *Hypothesis* (Claude, untested): on a body click macOS delivers the
    response to the running copy and also opens the app by bundle ID
    through Launch Services; when Launch Services prefers a different
    path, that's a fresh launch instead of a reopen. If so, it's a
    development artifact: an installed Phases runs from the one
    registered path. The author's "window opens but doesn't come to the
    front" at 12:00:59 fits the second copy taking the front.
  - **Confirmed from `usernoted`'s log** (*verified*, 12:09:16): it
    sent the response to the running copy ("Notifying UserNotifications
    client …:75083 about response"), then "Bringing app … front for
    response with URL: file:///…/DerivedData/Build/Products/Debug/Phases.app/".
    It brings the app forward by a path, not by the running process, so
    a different registered copy gets launched. The hypothesis above
    holds for that click.
  - **Unregistering every other copy stops notifications altogether**
    (*verified*, 12:12): with only Bitrig's temporary launch copy
    registered, `usernoted` logged "Failed to find or validate client
    of identifier … PID: 76409", and Phases logged "notification failed:
    Notifications are not allowed for this application". `usernoted`
    knows Phases by the DerivedData path; a copy elsewhere isn't a
    valid client. (Claude unregistered the copies; the author saw no
    notifications.)
  - *Next:* run the DerivedData copy itself, the path `usernoted`
    knows, so the running copy and the one it brings forward are the
    same.
  - **Running the DerivedData copy (the only registration) worked**
    (12:14–12:16, pid 77273, launched with `open`): the author saw the
    window come to the front on every click, from closed, minimized and
    another Space (*observed*). No second copy started (*verified*,
    log). Each of the three body clicks logged "window requested by
    notification" and then, 0.06–0.6 s later, "relaunched" and "window
    requested by relaunch" (*verified*, log): `usernoted`'s bring-front
    reaches the running copy as a reopen, so every click asks for the
    window twice. Harmless: the window ended visible and key each time.
  - So a body click opens the window even without the new
    `UNNotificationDefaultActionIdentifier` handling, whenever macOS
    picks the running copy. The 2026-11-07 "only dismisses it"
    (`[L-pause-banner-stack-still-shifts]`) was probably the
    wrong-copy case (*hypothesis*). The handler should still matter for
    the cold launch, where a fresh launch isn't a reopen (*hypothesis*;
    TESTING.md step 8 not yet run).
  - **Cold launch** (TESTING.md step 8, 12:20:09, pid 79254): the click
    launched Phases and the request arrived after the menu bar icon's
    view, so it took the plain path; the window was built but stayed
    behind the frontmost app `[Q-launch-activate-refused]` (*verified*,
    log; the author found it with ⌘Tab). No "relaunched" line followed,
    so the handler is the only thing that opens the window there
    (*verified*, log). Fixed by sending every notification click
    through `FirstLaunchWindow.open`; with that build (12:29, author's
    clicks): step 8 opened the window in front (*observed*), and the
    warm click (step 7, closed window) still did, ending active and key
    (*verified*, log).
  - **Testing notifications under Bitrig:** `bitrig run` launches a
    temporary copy that `usernoted` won't accept once the DerivedData
    copy is unregistered, and that a click won't bring forward while
    it's registered. Run the DerivedData build directly instead, with
    stale registrations for Phases' bundle ID cleared (`lsregister -u`
    each path from `lsregister -dump`, then `lsregister -f` the one
    build).
