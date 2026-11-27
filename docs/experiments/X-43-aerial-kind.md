# `[X-43-aerial-kind]` Why did Quit restore a still over an Aerial?

Part of "Sandbox check 2 on draft 64 (issue #43)" in [EXPERIMENTS.md](../EXPERIMENTS.md), the index of
experiments. Moved here word for word from EXPERIMENTS.md on
2026-11-27, when each record got its own file.


- **Question:** in TESTING.md "Sandbox checks" 2, the Aerial display
  logged "restored: DefaultDesktop.heic" instead of "left alone on quit:
  system wallpaper". Why?
- **When, on what:** 2026-11-27, macOS 27.2, two displays (built-in,
  display 1, UUID `37D8832A…`; a virtual display, 25, `271DBFDB…`). The
  author picked wallpapers and quit; Claude read the diagnostics log and
  the code. The build: `main` at `c163148`, the app from `bitrig build`,
  started with `open`. That build compiled nothing new, and its binary
  carries Nov 26 13:26.
- **Branch:** `fix/aerial-kind-lastset`, archived as tag
  `archive/fix/aerial-kind-lastset` (branch deleted 2026-11-27).
- **Outcome:** cause found; promoted to `[Q-store-kind-lastset]`. The
  fix landed on `main` as `d0391dd` (2026-11-27).
- **Run 1** (10:51–10:56 local). Launch log: both folder sources "found
  by its bookmark", "watching the store: 1046 entries". The author picked
  an Aerial on the built-in display (10:55:15, logged "outside change on
  37D8832A…: system wallpaper" plus "on all displays: system wallpaper")
  and a JPEG on the virtual one (10:55:44, "outside change on 271DBFDB…:
  Ergo Proxy Re-L wallhaven-dp6733.jpg" plus "on all displays: …"). Quit
  at 10:56:03: "display 1 restored: DefaultDesktop.heic" (wrong),
  "display 25 restored: Ergo Proxy…jpg" (right).
  - First hypothesis (Claude), wrong: the "all displays" entry
    (`AllSpacesAndDisplays`) stamped with the JPEG outranked display 1's
    Aerial. The store dump in run 3 showed `AllSpacesAndDisplays` is
    `$null`.
  - Claude's read-only dump of the store from Bitrig's shell was refused
    by Claude Code's permission check, so the author dumped it instead.
- **Run 2** (11:00–11:02). The author started Phases with Bitrig's Run
  menu, which launched an older build (Nov 26 13:26, from
  `DerivedData`). Not a test of the fix: its quit restored display 1 to
  `DefaultDesktop.heic` correctly, because run 1's quit had already put
  that still there. This launch logged although no launch argument was
  given, so the `PhasesDiagnostics` switch was already saved in Phases'
  container (*observed*); Claude had wrongly said it was off.
- **Run 3** (11:03–11:10), the same build as run 1, started with `open`.
  Aerial picked on the built-in (11:06:04; the first in the Aerial row,
  San Francisco sunset), a still on the virtual one (11:06:18, "Angelie's
  Cloudgame is Strong - Dusk - Oct 2026.jpg"). Before quitting, the
  author ran `plutil -p` on the store (38,504 lines). Quit at 11:10:29:
  "display 1 restored: DefaultDesktop.heic" (wrong again), display 25
  restored to the Dusk still (right). Failure reproduced.
- **The store, as dumped** (UTC; local is −5 h), entries that could
  apply to display 1:
  - `Displays/37D8832A`: provider `default`, LastSet 16:06:04, LastUse
    16:06:20
  - Space `D37B581D` Default and its `37D8832A` entry: `default`,
    LastSet 16:06:04, LastUse 16:06:20
  - Space `""` Default and its `37D8832A` entry: image, LastSet Nov 13
    03:37:02, LastUse 16:06:20
  - Space `7BDB3B2B` Default and its `37D8832A` entry: image, LastSet
    Nov 23 17:36:39, LastUse 16:06:20
  - `SystemDefault`: `default`, LastSet 16:06:04, LastUse 16:06:20
  - Many more Spaces hold entries for `37D8832A` with older dates.
- **Reading:** one write at 16:06:20 moved `LastUse` on every entry
  shown above, still images included. `LastUse` can't tell which is
  showing, and `LastSet` marks the pick, as `[Q-wallpaper-store]`
  already said. Which entry actually won at Phases' captures (11:06:04
  and 11:06:18) isn't known, because the store had been rewritten by the
  time of the dump. That a still-image Space entry had the latest
  `LastUse` at one of them is a hypothesis, but either way the ranking
  rested on a field that doesn't identify the pick. The fix logs the
  deciding entry from now on.
- **Fix test:** `SystemWallpaperCheckTests/anAerialPickOutranksOlderStillsUsedSince`
  failed with the ranking line set back to `LastUse` (kind came out
  `.image`, deciding entry not `Displays`) and passed with the fix; all
  276 unit tests passed (Claude, 2026-11-27).
- **Run 4** (11:20–11:27), the fix (`fix/aerial-kind-lastset` at
  `0499087`), started with `open`. Picks the other way round from runs
  1 and 3: a still on the built-in (11:26:27, "Festival of Lights
  (ultrawide) wallhaven-jelv1w.png"), the same Aerial on the virtual
  display (11:26:38). The new lines:
  - after the still: display 1 `kind image: Displays`, set 16:26:27;
    display 25 `kind image: Space D37B581D Default`
  - after the Aerial: display 25 `kind system: Displays, default`, set
    16:26:38 (right); display 1 `kind system: Space ACE71C78 Default,
    default`, set 16:26:38 (**wrong**: display 1 shows the still)
  - Quit 11:26:57: both displays "left alone on quit: system
    wallpaper". Display 25 is the check passing. Display 1 looks right
    on screen (its recorded original was the user's own still, already
    showing) but was left alone for the wrong reason.
  - Relaunch 11:27:53: the same readings (display 1 still `system` from
    `Space ACE71C78 Default`).
  - **Reading:** a pick on one display also stamps the showing Space's
    `Default` entry with that pick's `LastSet`, so the Space default
    outranks the *other* display's own, older per-display pick. Ranking
    by `LastSet` across defaults and per-display entries alike is still
    wrong whenever displays differ. A hypothesis for the next step:
    prefer per-display entries (`Displays`, and each Space's `Displays`)
    and use defaults only when the display has none. Runs 3 and 4 both
    read right that way, as far as the logged entries show. Asked the
    author before changing the fix.
- **Refinement** (approved by the author, 2026-11-27): rank only the
  display's own entries, defaults only when it has none.
  `anotherDisplaysPickInTheSpaceDefaultDoesNotDecide` (run 4's shape)
  failed with the candidates set back to every entry (display 1 read
  `.system`, decided by the Space default) and passed with the
  refinement; all 278 unit tests passed (Claude). Hands-on rerun below.
- **Run 5 setup** (11:31–11:45). Claude stopped the run-4 Phases with
  `pkill` (no Quit, so no restore; the saved restore point from 11:27:53
  was reloaded) and started the refined build at 11:31:45 with `open`.
  At 11:45:14 Phases set `eclipse_2024_robert_mohns-09.jpg` on display 1
  and `Peter Lik - Eternal Beauty.jpg` on display 25, both from folder
  sources. Opening System Settings › Wallpaper, the author saw a dashed
  box with "?" as the built-in display's thumbnail; the virtual
  display's thumbnail was normal, and the eclipse image was on screen
  (all *observed* by the author). Not explained; see
  `[L-settings-thumbnail-placeholder]`.
  - The eclipse folder is `~/Pictures/Desktop Pictures/Eclipse 2024 web
    share photos`, a copy put there to test subfolders. `~/Pictures`
    itself is also a source (added about 2026-11-26), so everything in
    `Desktop Pictures` appears twice in the source list (author). The
    author thinks timing (the pane opened seconds after Phases' set) the
    likeliest cause; untested.
- **Run 5** (refined build, 11:49–11:56), Aerial on the built-in, a
  still on the virtual display, verified by Claude from the log:
  - 11:55:50, Aerial picked: display 1 `kind system: Displays, default`
    (set 16:55:50), display 25 `kind image: Displays` (right).
  - 11:55:59, still picked (`Ergo Proxy Re-L wallhaven-0ww93p.jpg`):
    display 1 still `kind system: Displays` (no Space default took
    over), display 25 `kind image: Displays` (right).
  - Quit 11:56:33: display 1 "left alone on quit: system wallpaper",
    display 25 "restored: Ergo Proxy Re-L wallhaven-0ww93p.jpg".
    **Passes.**
- **Run 6** (refined build, 11:57–11:58), swapped: a still on the
  built-in, the Aerial on the virtual display (run 4's order), verified
  by Claude from the log:
  - 11:58:25, still picked (`Tokyo wallhaven-pomle9.jpg`): display 1
    `kind image: Displays` (set 16:58:25).
  - 11:58:32, Aerial picked: display 1 still `kind image: Displays` (the
    Space default no longer decides), display 25 `kind system:
    Displays, default` (set 16:58:32).
  - Quit 11:58:51: display 1 "restored: Tokyo wallhaven-pomle9.jpg",
    display 25 "left alone on quit: system wallpaper". **Passes.**
- **Outcome confirmed:** check 2 passes both ways round on the refined
  fix.
- **Not explained:** why check 2 passed on 2026-11-22 (draft 58). Perhaps
  which entries had the newest `LastUse` then; not recorded.
