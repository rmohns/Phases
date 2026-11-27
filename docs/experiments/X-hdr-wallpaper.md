# `[X-hdr-wallpaper]` HDR photos as wallpaper

Part of "Other investigations" in [EXPERIMENTS.md](../EXPERIMENTS.md), the index of
experiments. Moved here word for word from EXPERIMENTS.md on
2026-11-27, when each record got its own file.
The group's introduction there applies to this record too; copied
here so the record reads on its own:

> Until 2026-11-09 this section was called "Open questions"; most of what
> it held has since been answered. What's still open is under "Still
> open" at its end.


- **Question:** does macOS draw an HDR photo as wallpaper in SDR or with
  HDR headroom?
- **When, on what:** 2026-10-30, macOS 27.2, built-in display, the
  author's iPhone HEIC.
- **Branch:** none.
- **Outcome:** SDR, by the author's eye against a known-HDR control; no
  tool here could measure it. Bears on `[D-cover-iosurface]`.
- **Findings:** `[L-hdr-wallpaper]`.

- `[L-hdr-wallpaper]` **How does macOS draw an HDR photo (an iPhone
  HEIC with a gain map) as wallpaper: SDR, or with HDR headroom?**
  - **Answer: SDR,** by the author's eye against a known-HDR control
    (2026-10-30, below). No tool here could measure it.
  - **Why it matters:** bears on `[D-cover-iosurface]`. An 8-bit SDR
    cover surface is right only if macOS shows the wallpaper as SDR.
  - **Apple's documentation doesn't say.** Read 2026-10-30, macOS 27.0
    SDK:
    - `NSWorkspace` desktop-image pages and `DesktopImageOptionKey`: only
      scaling, clipping, and fill color.
    - "Enhancing high dynamic range image rendering": how an app shows
      HDR, not the wallpaper.
  - **What the SDK offers a cover, if it ever needs to match HDR:**
    - `kCGImageSourceDecodeRequest` = `kCGImageSourceDecodeToHDR`:
      decodes with the gain map applied.
    - `kIOSurfaceContentHeadroom`: tags a surface's headroom.
    - `CALayer.preferredDynamicRange` (macOS 26+): defaults to
      `.standard`, which per the header tone-maps `contents` with
      headroom above 1.0 down to SDR.
  - **The test photo** (author's iPhone HEIC): 4032 × 3024, Display P3,
    8-bit base, ISO gain map. *Measured:*
    - HDR decode: headroom 4.1.
    - ImageIO's default decode: 8-bit, headroom 1.0, so the default is
      SDR. (The headers don't say; first noted as *recalled*, now
      measured.)
  - **What we saw** with it as wallpaper on the built-in display:
    - It "looks pretty SDR" (*observed* by the author).
    - It was set with Finder's Services › Set Desktop Background, not
      by Phases, so this is macOS's own rendering: what a cover has to
      match.
    - A screen capture matched the default SDR decode by eye
      (*observed*). Weak evidence: `screencapture` output is SDR, so it
      can't show HDR either way (*recalled*).
    - The built-in display's
      `maximumExtendedDynamicRangeColorComponentValue` read 1.2
      (potential 16). A wallpaper using the photo's 4.1 headroom would
      likely push that higher (*recalled*, not calibrated).
  - **Known-HDR control, same day:** the same photo open full screen in
    Preview on the built-in display, its bright areas visibly brighter
    than SDR white (*observed* by the author). So the display does show
    this photo as HDR, and the wallpaper doesn't: the author's
    side-by-side is the evidence for "SDR".
    - The EDR reading stayed at 1.2 with Preview showing HDR. It reports
      headroom available, not headroom in use, so it can't tell the two
      apart. *Measured.*
    - ScreenCaptureKit per-window capture with `.hdrLocalDisplay` (16-bit
      half float, extended linear Display P3) also topped out at SDR
      white for Preview's window (max 1.09, under 0.01% of pixels above
      1.05), the same as the wallpaper window. So it didn't see Preview's
      HDR either and can't settle this. *Measured.* Why not: unknown
      (*guess*: Preview's HDR content isn't in the window's captured
      surface, or per-window capture tone-maps). A whole-display capture
      wasn't tried.
    - A ⌘⇧3 screenshot with Preview showing HDR also came out SDR
      (*observed* by the author).
    - No tool here measures HDR on screen yet; only the eye does.
  - **How macOS does HDR, as far as we know:**
    - SDR is the baseline. Pixel value 1.0 is SDR white, shown below the
      panel's peak; values above 1.0 use the leftover headroom
      (extended dynamic range, EDR). *Recalled.*
    - Content gets the headroom only if it carries values above 1.0
      *and* its layer opts in. `CALayer.preferredDynamicRange` defaults
      to `.standard`, which tone-maps it down to SDR. *Read* in the SDK
      header, 2026-10-30.
    - Screenshots and our captures clip at SDR white, so they can't
      show the difference (*observed*; the clipping explanation is
      *recalled*).
    - So the wallpaper showing SDR fits either of two causes: macOS
      decodes it without the gain map, or its layer doesn't opt in.
      Which one doesn't matter to Phases (*inference*).
  - **Still open:**
    - Whether Phases' `setDesktopImageURL` gets the same rendering as
      Finder: *inference* that it does (macOS draws the wallpaper either
      way), not tested. The new cover will show it: an HDR photo should
      look the same before and after the cover comes off.
