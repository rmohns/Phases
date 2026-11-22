# Report: Xcode project and bundle ID com.robertmohns.phases

From Claude (Bitrig), 2026-11-22. Branch `feature/xcode-project` on
`origin` (Bitrig's hosted repo). Not merged, not pushed to `github`.
Phases was never launched, and `defaults` wasn't run against either ID.
The prompt was `docs/prompts/2026-11-22-xcode-project-bundle-id.md`.

## Where it stands

| Step | State |
|---|---|
| 1. Spec (draft 59) | Done: `830968c`, plus an *Open* note under "Signing" in the docs commit |
| 2. Bundle ID | Done: `404f895`, built and checked with codesign |
| 2. Conversion | Done: `f8aa276`. **Signing not restored** (below) |
| 3. What reads `Project.json` | Done in `f8aa276`; 201 unit tests pass |
| 4. Docs | Done, in the docs commit |
| 5. Settings move | **Not started.** It waits on signing and on Robert at the Mac |
| 6. Merge | Not started; needs Robert's yes |

## The blocker: builds lost team signing

`main`'s builds are signed `Apple Development`, team Y382W2CA47, because
Bitrig passed `DEVELOPMENT_TEAM=Y382W2CA47` on xcodebuild's command line
for `Project.json` builds. For the Xcode project it passes nothing, so
xcodebuild signs "to run locally": ad hoc, no team (*verified*, three
builds and their logs). `bitrig build --provision` did get the team, and
registered the new ID, but the next build was still ad hoc (*verified*).
The temporary exception needs a team (`[L-sandbox-team-needed]`), so this
build would most likely fail to read the wallpaper store (*inferred*,
not tested).

Proposed fix, not made: `xcrun xcodeproj setting set --target Phases
DEVELOPMENT_TEAM Y382W2CA47`. Same team as before, now named in the
project. It's a signing change, which the prompt reserves for Robert. I
asked; the question came back unanswered. Full record:
EXPERIMENTS.md `[X-convert-xcode-project]`.

It may also be a Bitrig bug: Bitrig's own guidance says it passes the
saved team when the project sets none. Worth sending them feedback
(Robert's call).

## What the conversion did

- **Carried over** (*verified*): bundle ID, build 59, version 0.1,
  deployment target 26.0, `LSUIElement`, the app category, the three
  usage descriptions, `ITSAppUsesNonExemptEncryption`, the icon and
  accent color names, Swift 5.0, and all six entitlements. It kept
  `com.robertmohns.phases`: no App Store Connect app is connected.
- **Added, then removed:** `ENABLE_APP_SANDBOX` and
  `ENABLE_OUTGOING_NETWORK_CONNECTIONS`. The second signed an extra
  `network.client` entitlement. Both unset with `xcrun xcodeproj`; the
  entitlements now match `main` exactly (six plus `get-task-allow`).
- **Dropped:** the project-level `CODE_SIGN_IDENTITY = "-"`. Harmless
  on its own; Bitrig's command line used to override it.
- **Format:** `Phases.xcodeproj/project.xcproj`, Xcode 27's JSON format.

## GitHub issue #42: a test target `bitrig test` can run

Today `UnitTests/` is a SwiftPM package: target `PhasesLogic` is 26
symlinks to the app's pure files (`../../../App/Model/…`), and
`PhasesLogicTests` holds 24 test files (*verified*). After the
conversion, `bitrig test` says the Phases scheme has no tests, and
`bitrig test -package UnitTests` says `Phases.xcodeproj` doesn't build
the package (*verified* 2026-11-22). So it still can't run them.

**Three ways to get there:**

1. **Add the package to the project as a local package**
   (`xcrun xcodeproj pkg add-local UnitTests`, linking nothing into the
   app). The package's test target then lives in the project's workspace,
   which is what `bitrig test -package UnitTests` looks for (*recalled*
   from how Xcode loads local packages; not tested). Nothing moves:
   symlinks stay, `swift test` keeps working, and the tests stay unhosted
   `[D-tests-unhosted]`, because a package test target has no host app.
   - Catch: the package declares no products, and Xcode may want one
     before it shows the package's targets (*recalled*, unsure). If so,
     add a library product to `Package.swift`, still not linked into the
     app.
2. **A unit-test bundle target in the project**
   (`xcrun xcodeproj target add PhasesLogicTests --product-type
   unit-test`), with no host app (`TEST_HOST` and `BUNDLE_LOADER`
   empty), so it never launches Phases. It would have to compile the pure
   files itself. They're mixed into `App/Model` with code that isn't
   pure, so either each file gets added to it one at a time, or the pure
   ones move into their own folder both targets include. That's a code
   move across the app, and the symlink package would then be redundant.
3. **A `PhasesLogic` framework target** that the app links and the tests
   test. The cleanest module boundary, but every type the app uses from it
   needs `public`, and the app's build changes shape. Most work by far.

**Recommendation: option 1.** It's the only one that changes no app code,
keeps `swift test` as a fallback, and keeps the tests unhosted by
construction. Rough size: an hour or so, most of it finding out whether
Xcode needs a product (*estimate*). Options 2 and 3 are half a day or
more (*estimate*). If option 1 fails, option 2 with a separate folder
is the fallback.

**What `bitrig test` would still lack against `swift test`:** it runs
the tests apart from the shell, not in the package folder and without
its environment variables, so a test that opens a file by a relative
path breaks (*recalled* from Bitrig's guidance). `AppVersionTests` uses
`#filePath`, which still works. It also leaves no `.build` folder, which
is a plus.

**Docs and rules that would change:** CLAUDE.md "Testing" (run with
`bitrig test -package UnitTests`, `swift test` as the fallback),
TESTING.md "Unit tests" ("What they are", the *Why a package* note),
TEST-TOOLS.md `[Q-bitrig-test-targets]` (a dated update: fixed for unit
tests), and README.md "Building". The UI tests are a separate question:
they drive the AX API on purpose `[D-ui-test-runner]`, so nothing there
needs to change.

## Robert's next steps

1. Decide on signing (set `DEVELOPMENT_TEAM`, or another route).
2. Then the settings move (prompt step 5): quit Phases, I export and
   import, you launch and check, then Sandbox checks 1–3.
3. Say yes to merging, and whether to post the #42 write-up as a
   signed comment.

— Claude (Bitrig)

## Update, later on 2026-11-22

- Signing: Robert approved; `DEVELOPMENT_TEAM = Y382W2CA47` set on the
  Phases target (`422c13d`). Builds sign Apple Development, team
  Y382W2CA47, with `main`'s entitlements (*verified*).
- Settings move: `defaults export` from Bitrig's shell came back empty
  (`[L-defaults-container-blocked]`, `a628c74`). Robert copied the old
  container's plist in Finder; I imported it and launched the new build.
  Robert *verified* settings, folder sources after Locate…, location, and
  Launch at Login. Photos was blocked in the app while allowed in System
  Settings (`[L-photos-bitrig-vs-installed]`), counted as passing unless
  it persists once installed. Sandbox checks 1–3 deferred to issue #43.
- Bitrig feedback sent about the lost team signing and the extra sandbox
  settings, with logs and a screenshot, without the transcript.
