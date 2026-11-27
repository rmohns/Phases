# `[X-convert-xcode-project]` What `bitrig convert-to-xcode-project` did to Phases

Part of "Project conversion (draft 59)" in [EXPERIMENTS.md](../EXPERIMENTS.md), the index of
experiments. Moved here word for word from EXPERIMENTS.md on
2026-11-27, when each record got its own file.


- **Question:** does converting from `Project.json` to an Xcode project
  keep every setting, entitlement, and the signing of `main`'s builds?
- **When and on what:** 2026-11-22, Claude, macOS 27.2 with the macOS
  27.3 SDK (Xcode-beta, `DTXcode` 2730), branch `feature/xcode-project`
  (commits `404f895` before, `f8aa276` after). Bundle ID already changed
  to `com.robertmohns.phases` in `Project.json` before converting.
- **Outcome:** settings carried over; two unwanted settings added and
  removed; team signing lost and not yet restored (needs the author's
  call). Finding: `[L-convert-xcode-project]`.

**Before (Project.json, build at `404f895`):** `codesign -dvvv` showed
`Authority=Apple Development: William Mohns (X87V3JVLDN)`,
`TeamIdentifier=Y382W2CA47`, bundle ID `com.robertmohns.phases`; the
entitlements were the six of `[D-sandbox-entitlements]` plus
`get-task-allow`. The build log's "Build settings from command line"
listed `CODE_SIGN_IDENTITY = Apple Development`, `CODE_SIGN_STYLE =
Automatic`, `DEVELOPMENT_TEAM = Y382W2CA47` (*verified*).

**The conversion:** it printed "Converted this project to
Phases.xcodeproj and removed Project.json. No App Store Connect app is
connected, so its apps keep the bundle IDs Project.json gave them." It
wrote `Phases.xcodeproj/project.xcproj` (Xcode 27's JSON format, with
trailing commas), `App/Info.plist`, and `App/Phases.entitlements`, and
excluded `Info.plist` from the `App` synced folder. No shared scheme
was written; `bitrig test -list` shows the `Phases` scheme anyway
(*observed*).

**Carried over** (*verified* against the backup, `xcrun xcodeproj
setting list`, and the built app's Info.plist): bundle ID,
`CURRENT_PROJECT_VERSION` 59, `MARKETING_VERSION` 0.1,
`MACOSX_DEPLOYMENT_TARGET` 26.0 (`LSMinimumSystemVersion` 26.0 in the
built app), `LSUIElement`, `LSApplicationCategoryType`, the three usage
descriptions, `ITSAppUsesNonExemptEncryption`, `CFBundleDisplayName`,
`AppIcon` and `AccentColor`, `SWIFT_VERSION` 5.0, `CODE_SIGN_ENTITLEMENTS`
pointing at a file with all six entitlements, including the wallpaper
store exception.

**Not carried over:** the project-level `CODE_SIGN_IDENTITY = "-"` from
`Project.json`. It made no difference before, since Bitrig's command line
overrode it with `Apple Development` (*inferred* from the log above).

**Added:** on the Phases target, `ENABLE_APP_SANDBOX = YES` and
`ENABLE_OUTGOING_NETWORK_CONNECTIONS = YES`, plus `COMBINE_HIDPI_IMAGES`
and `LD_RUNPATH_SEARCH_PATHS`; on the project, Xcode's usual warning
and optimization defaults and `CODE_SIGN_STYLE = Automatic`. The first
build after converting signed **`com.apple.security.network.client`**,
which Phases doesn't need (`[D-sandbox-entitlements]`), and was signed
`Signature=adhoc`, `TeamIdentifier=not set` (*verified*, codesign).

**Run 2:** unset `ENABLE_OUTGOING_NETWORK_CONNECTIONS` and
`ENABLE_APP_SANDBOX` with `xcrun xcodeproj setting unset`, rebuilt. The
entitlements matched `main` exactly (six plus `get-task-allow`), but the
signature was still ad hoc, no team. The log's "Build settings from
command line" had only `CONFIGURATION_BUILD_DIR` and `SYMROOT`: no team,
no identity; xcodebuild chose "Sign to Run Locally" (*verified*).
`get_project_team` said the project sets no team and the saved team is
Y382W2CA47.

**Run 3:** `bitrig build --provision` (the plan allowed it once). Its
xcodebuild got `DEVELOPMENT_TEAM=Y382W2CA47 -allowProvisioningUpdates`
and succeeded. The next ordinary build was still ad hoc, no team, and
its command line still had no team (*verified*). Three builds, same
result; stopped there.

- *Hypothesis:* Bitrig passes the saved team to `Project.json` builds and
  to `--provision`, but leaves an Xcode project's Mac Debug builds to the
  project's own signing settings. Bitrig's guidance says it passes the
  saved team whenever the project sets none, so this may be a Bitrig bug.
- Not yet tested: whether an ad-hoc build with these entitlements launches
  at all, or reads the wallpaper store (`[L-sandbox-team-needed]` says the
  exception needs a team).

**Run 4 (signing fixed):** with the author's approval, `xcrun xcodeproj
setting set --target Phases DEVELOPMENT_TEAM Y382W2CA47`, then a build:
`Apple Development: William Mohns`, `TeamIdentifier=Y382W2CA47`, the six
entitlements plus `get-task-allow` (*verified*, codesign; commit
`422c13d`). No container for `com.robertmohns.phases` existed afterward
(`ls`: "No such file or directory").

**Settings export, 2026-11-22 16:24 (`[L-defaults-container-blocked]`):**
the old Phases quit by the author (`pgrep` found none). From Bitrig's
shell, `defaults export app.bitrig.new.ecd0db30-b411-4419-8736-9fe3d1c96268
~/Desktop/phases-settings-old-id.plist` exited 0 and wrote 42 bytes, an
empty binary plist (*verified*). Read-only checks after:
`~/Library/Preferences/<old ID>.plist` doesn't exist; the container
folder exists (`drwx------`, dated 2026-11-22 11:29); `ls` of its
`Data/Library/Preferences/` gave "Operation not permitted"; `defaults read
<old ID>` gave "Domain '…/Containers/<old ID>/Data/Library/Preferences/<old
ID>' not found" (*verified*). So `defaults` did aim at the container's
copy, as inferred, but couldn't read it from this process. Stopped there,
per the plan; nothing imported, nothing launched. The empty file was left
on the Desktop.

**Settings move, 2026-11-22 16:22–16:29:** the author copied the old
container's preferences plist to `~/Desktop/phases-settings-old-container.plist`
in Finder (7,515 bytes, `plutil -lint` OK, keys including `phases`,
`imageSources`, `appliedState`, `PhasesDiagnostics`). No container or
preferences file existed yet for `com.robertmohns.phases`. `defaults
import com.robertmohns.phases` that copy exited 0 and wrote
`~/Library/Preferences/com.robertmohns.phases.plist`, identical by
`plutil -p` diff (*verified*). `bitrig preview -platform macOS` built but
didn't launch (Bitrig's Mac preview waits for Run), so `bitrig run … -destination
id=mac` launched it (signed team Y382W2CA47). Seconds later the
preferences file was gone from `~/Library/Preferences` (*verified*;
moved into the container, *inferred*). Diagnostics at launch: "watching
the store: 988 entries" (the exception works), and both folder sources
"found by its location, but not permitted to read it" (*verified*, log).

**Author's checks, same session:** settings came over, folder sources
reopened after Locate…, location allowed again, Launch at Login back on
(all *verified* by the author). Photos: blocked in the app while System
Settings shows it allowed; the author has seen this before with the
Bitrig build and the installed copy (`[L-photos-bitrig-vs-installed]`,
*observed*), and counts it passing unless it persists once installed.
Sandbox checks 1–3 deferred: GitHub issue #43.
