You're working on Phases, a macOS menu-bar app built in Bitrig. Robert (the author) is
around for this session; checkpoints below wait for his yes.

## The task

Three changes, landing together as one squash-merged change:

1. **Change the bundle ID** from `app.bitrig.new.ecd0db30-b411-4419-8736-9fe3d1c96268`
   (Bitrig's placeholder) to `com.robertmohns.phases`, all lowercase. Robert controls
   `robertmohns.com`. Treat the new ID as permanent.
2. **Convert the project** from `Project.json` to an Xcode project with
   `bitrig convert-to-xcode-project`.
3. **Move Robert's settings once** from the old ID to the new one, with `defaults export`
   and `defaults import`. This is a one-time move done from the shell. Phases itself gets no
   migration code.

Background, from the conversation that planned this (2026-11-22):
- A new bundle ID means a new, empty sandbox container. The old container stays on disk,
  untouched. Setting the old ID back would find it again (*inferred* from how containers
  work, not tested).
- No App Store Connect app is connected: the account has none (**verified** 2026-11-22 with
  `asc_list_apps`). The conversion shouldn't pick a bundle ID of its own, but check.
- Phases' code never hard-codes the bundle ID (**verified** 2026-11-22 by searching the
  code). The UI test preferences suite and the UI test driver read it at run time.
- `origin` and the project folder use Bitrig's project ID, not the bundle ID (*inferred*
  from the names), so neither should change.

## Read first

1. CLAUDE.md (project rules). Follow it, except where this prompt says otherwise.
2. docs/SPEC.md: the opening, "Design decisions", and the "Sandbox" section, especially
   `[D-sandbox-entitlements]` (which says entitlements are set in `Project.json`) and
   `[D-sandbox-settings-move]`.
3. docs/LEARNINGS.md `[L-sandbox-prefs-move]`, `[L-photos-grant-per-build]`, and
   `[L-photos-ids-stable]`. docs/TEST-TOOLS.md "Diagnostics", including the note that
   Terminal can't list containers.
4. docs/TESTING.md "Unit tests" and "Sandbox checks".
5. The `bitrig-project-json` skill ("Converting to an Xcode Project"), the
   `xcode-project-editing` skill, the `bitrig-macos-project` skill, and the `bitrig-cli` skill.
6. GitHub issue #42 (`bitrig test` refuses this project). Context only; see "Not in scope".

## Order of work

### 1. Branch and spec

- Branch `feature/xcode-project` from `main`.
- First commit: the SPEC.md change. Update `[D-sandbox-entitlements]` and anything else that
  names `Project.json` as where settings live, so they name the Xcode project, edited with
  `xcrun xcodeproj`. Record the new bundle ID and why (a domain Robert controls; the
  placeholder was Bitrig's). Add how the one-time settings move works and what doesn't carry
  over (see step 5). Bump the draft number, and keep the build number matching it (step 3).
- Open it in Marked (`/opt/homebrew/bin/mk docs/SPEC.md`) and **wait for Robert's approval**
  before continuing.

### 2. Bundle ID, then conversion

- Back up `Project.json` to a new folder of its own (`mktemp -d`) and note the path.
- Change `PRODUCT_BUNDLE_IDENTIFIER` in `Project.json` to `com.robertmohns.phases`. Build with
  `bitrig build -destination 'platform=macOS'`. Check the signed app with
  `codesign -d --entitlements - <built Phases.app>` and read its Info.plist's
  `CFBundleIdentifier`. Commit.
- Run `bitrig convert-to-xcode-project`. Then, following the skill:
  - Compare the new project with the backed-up `Project.json`. Every setting must carry
    over: the bundle ID, `CURRENT_PROJECT_VERSION`, `MARKETING_VERSION`, the deployment
    target (26.0), `LSUIElement`, the app category, the three usage descriptions,
    `ITSAppUsesNonExemptEncryption`, the app icon and accent color names, `SWIFT_VERSION`,
    and all six entitlements, including the wallpaper store temporary exception.
  - Set anything missing with `xcrun xcodeproj`, never by editing `project.pbxproj` by hand.
- Build again. Verify with `codesign`: the six entitlements exactly as on `main` (plus
  `get-task-allow`), team Y382W2CA47, and bundle ID `com.robertmohns.phases`. If anything
  differs, fix it before going on.
- If the build fails because the new App ID isn't registered with Apple, run
  `bitrig build --provision` once. That registers it under the same team, and it's allowed
  for this task. Don't change the team or any other signing settings.

### 3. What reads `Project.json`

- `UnitTests/Tests/PhasesLogicTests/AppVersionTests.swift` reads `CURRENT_PROJECT_VERSION`
  from `Project.json` (`buildNumberMatchesSpecTitle`). Point it at the Xcode project, keeping
  the check that the build number matches the spec draft. Same for the comment in
  `App/Model/AppVersion.swift`.
- Run unit tests with `swift test` in `UnitTests/` (allowed; CLAUDE.md "Testing"). All must
  pass.

### 4. Docs

- Living docs that name `Project.json` or the old bundle ID get updated: CLAUDE.md,
  README.md, docs/SPEC.md, docs/TESTING.md, docs/TEST-TOOLS.md. This includes the
  `defaults` commands, which would otherwise quietly go to the old ID.
- **Records keep the old ID as written:** docs/EXPERIMENTS.md, docs/handoffs/, and older
  prompts in docs/prompts/. Add a dated note where a reader might be misled; never rewrite.
- Record anything learned about the conversion as it happens: what it carried over, what it
  missed, and what it did to the bundle ID. Use LEARNINGS.md, with a record in EXPERIMENTS.md
  if there's more than a digest's worth. Use evidence labels.

### 5. The one-time settings move (needs Robert at the Mac)

**Ask Robert before this step.** He quits Phases first. Nothing may launch a build with the
new ID before the import. A launch creates an empty container, and the import would then
have to go into it instead.

1. Export the old settings. This doubles as the backup:
   `defaults export app.bitrig.new.ecd0db30-b411-4419-8736-9fe3d1c96268 ~/Desktop/phases-settings-old-id.plist`.
   Exporting reads the old container's copy through the preferences system (*inferred*,
   not tested). Check that the file is non-empty and holds the phases
   (`plutil -p` it and look for the keys `SettingsStore` uses). If the export fails or comes
   back empty, stop and tell Robert. Don't work around it.
2. Import under the new ID:
   `defaults import com.robertmohns.phases ~/Desktop/phases-settings-old-id.plist`.
   With no container yet, this writes `~/Library/Preferences/com.robertmohns.phases.plist`.
   macOS moves that file into the new container on first launch, the same way the
   sandboxed build's first launch did (`[L-sandbox-prefs-move]`, *verified* 2026-11-12).
3. Robert launches the new build, or you do once he says yes. Confirm his phases, sources,
   and options are there. If they aren't, quit Phases, run the same `defaults import` again
   (it then writes the container's copy), and relaunch.
4. What doesn't carry over, and what Robert does about it:
   - **Folder sources:** bookmarks belong to the app that made them, so each probably shows
     "Can't open" (*recalled*). One Locate… per source. It keeps the source's ID, so phases'
     selections come back.
   - **Photos and location:** macOS asks again.
   - **Launch at Login:** turn it on again in Phases. Check System Settings › General ›
     Login Items for a leftover entry from the old ID.
   - **Photo cache:** starts empty in the new container and fills as needed.
   - **The old container stays.** Don't delete it. Robert can remove it later.
5. Then Robert runs TESTING.md "Sandbox checks" 1 to 3 (settings, Aerials left alone,
   folder sources after a relaunch). Record the results with date and build, as usual.

### 6. Finish

- Report to Robert: commits with short hashes, the `codesign` output before and after,
  unit test results, what the conversion missed and how you fixed it, and the hands-on
  results.
- Merging into `main` needs Robert's yes. After it: build `main`, archive the branch as
  `archive/feature/xcode-project`, and push `main` and the tag to `origin` and, with his
  yes, to `github`. Then delete the branch locally and on every remote.

## Limits

- No UI tests or mouse and keyboard driving in this session. Launching happens only in
  step 5, with Robert's yes.
- `defaults` writes only in step 5, only `import` against `com.robertmohns.phases`, and only
  once Robert has said go. Nothing writes to the old ID.
- Don't delete the old container, the backup `Project.json`, or the exported plist.
- Don't change the team or signing beyond the `--provision` case above. Don't install
  launch agents, daemons, or helpers.
- A permission block (auto mode classifier, tool denial) is never something to route
  around. Redo a blocked shell edit with Edit; for anything else, stop and ask.
- If the same failure happens three times, stop that thread and tell Robert.

## Not in scope

- Adding a unit test target so `bitrig test` works (#42). Once the project is an Xcode
  project, write up in the report what adding the target would take, but don't do it.
- Any change to what Phases does.
