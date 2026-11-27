# `[X-stale-app-icon]` Old app icon in the brand panel after an icon change

Part of "Other investigations" in [EXPERIMENTS.md](../EXPERIMENTS.md), the index of
experiments. Moved here word for word from EXPERIMENTS.md on
2026-11-27, when each record got its own file.
The group's introduction there applies to this record too; copied
here so the record reads on its own:

> Until 2026-11-09 this section was called "Open questions"; most of what
> it held has since been answered. What's still open is under "Still
> open" at its end.


- **Question:** after the switch to the Icon Composer icon (`70390c6`),
  why did the sidebar brand panel show the old PNG icon while the About
  panel showed the new one?
- **When, on what:** 2026-11-14, macOS 27.2, Debug build launched by
  `bitrig preview` from Bitrig's DerivedData.
- **Branch:** `feature/icon-composer-icon` (archived as tag
  `archive/feature/icon-composer-icon`).
- **Outcome:** a stale icon cache outside Phases (hypothesis); fixed by
  refreshing the bundle's date and registration. No code change.
- **Findings:** `[L-stale-app-icon]`.

- **What was seen:** the brand panel (`PhasesWindow.swift`,
  `Image(nsImage: NSApp.applicationIconImage)`) showed the old PNG
  (white crescents, filled mountains); About showed the new Liquid
  Glass icon. Observed by the author, who picked the old PNG out of a
  side-by-side with the new icon's flat fallback.
- **Ruled out:** the running bundle held only the new icon:
  `AppIcon.icns` (its 256 px image is the new artwork, flattened) and
  `Assets.car` built 21:13, with `CFBundleIconFile` and
  `CFBundleIconName` both `AppIcon`. No old PNG anywhere in it.
  Verified by Claude (2026-11-14), by extracting the `.icns` with
  `iconutil` and listing `Assets.car` with `assetutil`.
- **Clue:** the `Phases.app` folder's own modification date was
  Oct 25, though its contents were rebuilt that day. Bitrig rebuilds
  into the same folder, so the folder never looks new. Verified by
  Claude (`ls -la`, 2026-11-14).
- **Hypothesis:** macOS caches an app's icon by bundle path and folder
  date (recalled, not tested here), so `applicationIconImage` returned
  the cached old icon. About reads the compiled assets directly.
- **What fixed it:** `touch Phases.app`, then
  `lsregister -f Phases.app`, then a relaunch from Bitrig. The author
  confirmed the brand panel then showed the new icon (2026-11-14).
  Only one run, so which of the two steps mattered isn't known.
