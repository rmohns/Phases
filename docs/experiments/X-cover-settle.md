# `[X-cover-settle]` Crossfade settle timing (drafts 5–32)

Part of "Retired designs" in [EXPERIMENTS.md](../EXPERIMENTS.md), the index of
experiments. Moved here word for word from EXPERIMENTS.md on
2026-11-27, when each record got its own file.
The group's introduction there applies to this record too; copied
here so the record reads on its own:

> Designs that were on `main` and have since been replaced. Moved here
> from ERRATA.md "Design history" when the code they explain was gone.


Moved from ERRATA.md on 2026-11-09, followed by "The twitch returns"
(also from ERRATA.md "Design history", the story of why the delay grew).
Digest: `[L-cover-settle-delay]`, `[L-twitch-returns]`.

`[D-cover-settle]`, replaced in draft 33 by `[D-persistent-cover]`,
removed the cover 1.5 s after the wallpaper was set.

- *Why 1.5 s:* macOS plays its own motion 0.55–0.65 s after the wallpaper
  is set `[Q-wallpaper-motion-delay]`. Draft 5's 0.5 s delay removed the
  cover right as that motion played, bringing the twitch back (see "The
  twitch returns"). 1.5 s leaves about 0.7 s of margin.
- *Cost:* the menu bar's background lags the fade by about 1.5 s instead of
  0.5 s `[Q-menubar-bg-follows-window]`. The menu bar's text and icon color
  lag as before `[Q-menubar-restyle-on-app-switch]`.
- Code was `CrossfadeController.settleDelay`, removed in draft 33.

## The twitch returns

`[L-twitch-returns]` (demoted from ERRATA.md "Design history" on
2026-11-09; text unchanged below).

2026-10-28, draft 22. The twitch came back on macOS 27.2, on one display or
two. A frame-by-frame analysis of a screen recording (seven changes)
showed:

- The fade itself is smooth, and the cover matches the final wallpaper
  exactly (before and after differ only at noise level). So the cover's
  image and geometry aren't the cause.
- The twitch is about 0.13 s of the image shifting and settling back. It
  starts 0.55–0.65 s after the fade ends, in the same frames as the menu
  bar restyle. (Draft 22 read that as when macOS actually shows the new
  wallpaper; see the correction under `[Q-wallpaper-motion-delay]`.)
- The cover was removed 0.5 s after the fade ended `[D-cover-settle]`, just
  before macOS's own motion, so the motion showed through.

The crossfade code's timing hadn't changed since draft 5. The author
believes (not certain) the original fix was tested on macOS 27.1, so macOS
27.2 may have made wallpaper changes slower. That's unconfirmed; the draft
5 timing may also have been marginal from the start. The fix is a longer
settle delay (1.5 s), not a new mechanism (see "Crossfade settle timing
(drafts 5–32)", moved on 2026-11-09 to EXPERIMENTS.md `[X-cover-settle]`).

The same recording showed a second, separate problem: turning System
Settings' "Show menu bar background" on or off started a crossfade to a new
image `[Q-screen-params-notification]`. See `[D-screen-change-no-reroll]`.
