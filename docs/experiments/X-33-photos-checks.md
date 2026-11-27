# `[X-33-photos-checks]` Merge #2 Photos checks

Part of "Photos library (issue #33)" in [EXPERIMENTS.md](../EXPERIMENTS.md), the index of
experiments. Moved here word for word from EXPERIMENTS.md on
2026-11-27, when each record got its own file.


- **Question:** do Photos sources behave as the draft 54 spec says (then
  draft 53 on the branch) with the author's real settings and library?
  Nine hands-on checks, listed in TESTING.md "Photos checks".
- **When, on what:** 2026-11-12, macOS 27.2; builds from 16:44 local on,
  not sandboxed. Run by the author, with
  Claude reading the diagnostics log.
- **Branch:** `feature/33-photos-albums`.
- **Outcome:** all nine checks passed; two fixes landed on the branch
  (the brand panel during a wait, and rereading Photos sources before
  showing).
- **Findings:** `[L-photos-grant-needs-relaunch]`,
  `[L-photos-grant-per-build]`, `[L-photos-offline-check]`,
  `[L-photos-formats-check]`, `[L-photos-deleted-album-race]`.

Draft 53 build of 16:44 local (`feature/33-photos-albums`), not
sandboxed, the author's real settings and library.

- `[L-photos-grant-needs-relaunch]` **Turning Phases on under Privacy &
  Security › Photos didn't reach a running Phases.** After the author
  refused the prompt, then allowed Phases in System Settings, Add Photos
  Album… still showed "no access". A Phases launched at 21:38 logged
  "access asked: 2" (denied); whether that was before or after the
  change in System Settings isn't known. After Claude quit and relaunched
  Phases (21:4x), the albums showed. *Observed* by the author, once;
  diagnostics log for the status. System Settings listed one Phases
  entry (author), so Claude's guess of a grant going to another build's
  entry was wrong. Why (*hypothesis*): PhotoKit keeps a process's
  authorization once it has been decided, so only a relaunch rereads it.
  Not checked: whether a running Phases picks it up after a longer wait.
- `[L-photos-grant-per-build]` **Each Bitrig build loses the Photos
  grant.** Bitrig signs debug builds ad hoc (`codesign -dv`:
  `Signature=adhoc`, no team), so TCC pins the grant to the build's
  cdhash. On 2026-11-12, after a relaunch into the 22:26 build, every
  Photos source read "Can't open". tccd logged at 22:30:27 "Failed to
  match existing code requirement for subject app.bitrig.new.ecd0db30…
  and service kTCCServicePhotos", with the old and new cdhashes, and the
  status read as not yet asked. The 22:05 build had prompted again at
  22:13 for the same reason. *Verified* by Claude from the tccd log. This
  may also explain `[L-photos-grant-needs-relaunch]` (*hypothesis*).
  Builds signed with a team (Developer ID or App Store) keep one
  designated requirement across builds, so users won't see this
  (*recalled*). During checks: after each new build, Add Photos Album…
  prompts again; allow it.
- `[L-photos-offline-check]` **Offline, the fallback worked, but kept
  landing on the same photo.** Phase: Gift Ideas (4, cached) then 3
  Buddhism photos (not cached), In order, 1 minute. Wi-Fi off about
  21:55–22:02. Each Buddhism photo failed ahead in under 0.1 s ("The
  Internet connection appears to be offline"), failed again at its
  change, and fell back. All three fell back to IMG_6045, the first
  Gift Ideas photo: In order's "next on hand after the missing one"
  wraps to the start for every photo at the end of the list. Only the
  first fallback logged a set; the next two were the image already
  showing, so nothing changed on screen. Back online, each Buddhism
  photo was fetched 30 s ahead in 0.62–0.93 s and set on time.
  *Verified* (diagnostics log), and *observed* by the author on screen.
  - The brand panel briefly showed the missing photo's thumbnail at each
    failed change, because the applied record names the planned pick
    before the fetch settles (author's screen recording). Fixed the same
    day: the panel keeps what's showing while a change waits.
- `[L-photos-formats-check]` **An edited (cropped) photo, a Live Photo,
  an iPhone ProRAW+HEIC, and a Canon DSLR RAW all showed the way Photos
  shows them.** *Observed* by the author, 22:13–22:15, build of 22:05.
  Every cache file was a HEIC or JPEG of 0.3–3.6 MB, none a RAW, so
  Photos handed over a rendered version for `.current` (or Phases
  converted it); the log can't tell which. Fetches took 0.52–1.91 s.
  The edited photo's file carries a modification time minutes old,
  consistent with an edit giving a new cache file `[D-photos-version]`.
- `[L-photos-deleted-album-race]` **A photo from an album the author was
  deleting was set as the wallpaper at 22:18:02,** the change after
  Photos reported a library change (22:17:41, which made Phases pick
  again). The phase's selection was only that album, so afterward every
  pick found nothing and Change Now did nothing, as the spec says for a
  phase with no available images. *Verified* (diagnostics log), the set
  *observed* by the author. When the album was deleted isn't known
  (author), so whether this was a race (PhotoKit still listing the album
  for a moment after the delete) or a set just before the delete is a
  *hypothesis*. Treated as a race, the author's call: since the same day
  Phases rereads its Photos sources just before showing, and a photo no
  longer in the library counts as missing even if it's cached. If
  PhotoKit itself lags, that reread can't help.
