> *Note 2026-11-22, added later:* from draft 59 Phases is `Phases.xcodeproj` with
> bundle ID `com.robertmohns.phases` (SPEC.md `[D-xcode-project]`, `[D-bundle-id]`).
> Reusing this prompt as a template: settings and entitlements now go in the Xcode
> project (`xcrun xcodeproj`) and `App/Phases.entitlements`, not `Project.json`, and
> `defaults` commands take the new ID. The prompt below is kept as it was run.

You're working overnight and unattended on Phases, a macOS menu-bar app built in Bitrig.
Robert (the author) is asleep. Nobody will answer questions until morning, so when
something needs his call, write it down and move on to work that doesn't depend on it.

## The task

Read GitHub issue #19, "Run Phases in a macOS sandbox", including every comment:
`gh issue view 19 --repo rmohns/Phases --comments` (and without `--comments` for the body).
Then sandbox Phases, as far as can be done and checked without launching it.

## Read first

1. CLAUDE.md (project rules). Follow it, except where this prompt says otherwise below.
2. docs/SPEC.md: the opening, "Design decisions", and every `[D-…]` the work touches,
   especially `[D-aerials-untouched]` and `[D-scoped-bookmarks]`. Note line 4, "Not intended
   for the App Store". Sandboxing doesn't change that. The point is containment, not App Review.
3. docs/LEARNINGS.md and docs/EXPERIMENTS.md `[X-33-sandbox]`: everything already learned
   about running Phases sandboxed. Key entries: `[L-sandbox-x0-paths]`,
   `[L-sandbox-team-needed]`, `[L-sandbox-prefs-move]`, `[L-sandbox-x4-container-wallpaper]`,
   `[L-sandbox-photos-works]`, `[L-sandbox-x1-no-entitlement]`, `[L-photos-ids-stable]`.
4. docs/ERRATA.md for `[Q-…]` entries tagged in files you touch. docs/TESTING.md and
   docs/TEST-TOOLS.md sections on unit tests and diagnostics.
5. The experiment code in tag `archive/experiment/33-photokit` (`App/Experiments/PhotoKitProbe.swift`,
   and the sandbox entitlement in its `Project.json`). Reuse what fits.
6. The `bitrig-project-json` and `bitrig-macos-project` skills. This project is defined by
   `Project.json`, so entitlements and settings go there, never into a hand-edited Xcode project.

## Known facts (from the issue; trust but re-check against the docs)

- Signing: Bitrig signs with Robert's paid team "William Mohns" (Y382W2CA47), which is saved
  on this Mac for the project; `Project.json` doesn't set DEVELOPMENT_TEAM. That clears the
  blocker in `[L-sandbox-team-needed]`. If a build still fails on signing, record exactly
  what happened and stop that line of work. Don't change team or signing settings.
- The real obstacle is SystemWallpaperInspector reading
  `~/Library/Application Support/com.apple.wallpaper/Store/Index.plist`. In the sandbox, home
  points into the container (verified). If the read fails silently, Phases thinks there are no
  system wallpapers and would replace Aerials, which breaks `[D-aerials-untouched]`. Fix it with
  a temporary-exception entitlement for that one path (read-only, as narrow as works), AND make
  a failed read fail safe: Phases must treat "couldn't read the store" differently from "store says
  no Aerials" and must not replace a wallpaper it couldn't check. Put that decision logic in a
  pure file the unit tests can reach.
- Folder bookmarks are already security-scoped (`[D-scoped-bookmarks]`, verified after relaunch).
- Restoring a wallpaper from outside the container works sandboxed (verified).
- Open hypothesis: a crossfade cover remade later (after a Space switch) reads its file without
  open source access (see the comment in `WallpaperScheduler.show`). Sandboxed, that may fail
  or drop to a hard cut. Fix it so access is open for that read too, or explain why not.
- Links and aliases whose target is outside the picked folder will fail with "not permitted"
  (issue #17's territory). Detect it and fail safe with a diagnostic log line. Don't build the
  second-bookmark picker flow tonight; write it up as a follow-up.
- Location needs `com.apple.security.personal-information.location`. Photos needs
  `com.apple.security.personal-information.photos-library`. Picking folders needs
  `com.apple.security.files.user-selected.read-only` (or read-write only if the code really
  writes). Login items, setting wallpaper and distributed notifications are recalled as allowed.
  Check each against the code. Add only entitlements Phases actually needs, and justify each one in SPEC.md.
- Preferences move into the container on first sandboxed launch, and going back means moving
  them back by hand. The spec change must say what happens to existing settings and how to
  return to an unsandboxed build.

## How to work tonight (what Robert has allowed for this run)

- Branch: create `feature/19-sandbox` from `main`. Everything goes there.
- Spec first, still: the first commit on the branch is the SPEC.md change (a new or updated
  `[D-…]` decision for sandboxing, its entitlements and why, the Aerials fail-safe, the settings
  migration). For this run only, Robert allows you to write the code on the same branch
  after that commit, without waiting for his approval. He reviews spec and code together
  in the morning. If the code has to differ from your spec draft, update the spec in a
  later commit and say so.
- ERRATA.md: add `[Q-…]` entries for quirks the new code depends on (the container home path,
  the store exception). Promote LEARNINGS entries that now shape code, following the CLAUDE.md
  "Moving entries" rules, with pointers left behind.
- Evidence labels on every claim, in docs and in your report: verified (with date and by whom),
  observed, recalled. Hypotheses labeled as such.
- Build often with `bitrig build` from the project directory, and run unit tests with
  `bitrig test`. Never use xcodebuild or `swift build`. After each build, verify the signed app's
  entitlements with `codesign -d --entitlements - <path to built Phases.app>` and that the
  sandbox key is present.
- Diagnostics: new log lines go through `Diagnostics.logger(…)` only.
- Commits: small, meaningful units. Subject says what changed. Every commit ends with
  `Co-Authored-By: Claude (Bitrig) <noreply@anthropic.com>`. Push the branch to `origin`
  (Bitrig's hosted repo, https://api.bitrig.app/repo/ecd0db30-b411-4419-8736-9fe3d1c96268) as
  you go. Never force-push.
- Delegation: mechanical edits pinned down by your spec can go to a Sonnet subagent with an
  exact brief. Design calls stay with you.

## Hard limits (no exceptions tonight)

- Never launch, preview, or run Phases (`bitrig preview`, `bitrig run`, `open`, double-click).
  The first sandboxed launch moves Robert's real preferences into a container, and launching
  needs his yes anyway.
- No mouse or keyboard driving, no UI tests, nothing that touches the real wallpaper, and
  no `defaults write` against the app's bundle ID. Subagents never start any of these.
- Don't merge into `main`. Don't push to the `github` remote. Don't comment on, edit, or close
  issue #19 or any other issue.
- Don't touch signing or team settings. Don't install launch agents, daemons, or helpers.
- Don't delete or rewrite existing doc entries. Corrections go next to what they correct.
- If you hit the same failure three times, stop that thread, record it, and move on.

## Done looks like

`feature/19-sandbox` on `origin` containing, in order: the SPEC.md change; the code
(entitlements in `Project.json`, the Aerials fail-safe with unit tests, crossfade-cover access,
out-of-folder link detection); ERRATA/LEARNINGS updates. Last of all, a morning report at
`docs/handoffs/2026-11-23-sandbox.md` (also committed) with:

1. What changed, commit by commit, with short hashes.
2. Each entitlement added, why, and how you verified it's in the signed build.
3. Build and unit-test results, pasted, including any failures.
4. Decisions that need Robert's call, each with your recommendation.
5. The hands-on checks only Robert can run, as numbered steps he can approve in one go:
   first sandboxed launch with a prefs backup first
   (`cp ~/Library/Preferences/app.bitrig.new.ecd0db30-b411-4419-8736-9fe3d1c96268.plist ~/Desktop/`),
   Aerials left alone, folder source after relaunch, Photos source, crossfade after a Space switch,
   restore-on-quit, a link pointing outside the folder, location prompt, and how to go back.
6. Follow-ups that should become their own issues (for example, the #17 second-bookmark flow).

If you finish early, re-read your diff against SPEC.md and fix gaps. Don't start unrelated work.
