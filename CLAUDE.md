# Phases: project rules

- **Read first, scoped to the work.** Before touching code, the spec, or
  tests: read SPEC.md's opening and "Design decisions", then the `[D-…]`
  decisions and `[Q-…]` quirks tagged in the files you'll touch (search
  for the tags in SPEC.md and ERRATA.md) and the entries they cite. Read a
  whole file when the change is broad or the tag search comes up empty.
  Read the TESTING.md and TEST-TOOLS.md sections the work touches (tests,
  test-only launch arguments, diagnostics). Search LEARNINGS.md before
  experimenting, or before blaming or working around platform behavior:
  it may already hold the answer. Open EXPERIMENTS.md only when a
  LEARNINGS.md entry sends you there or you're picking that experiment
  back up. Conversations about rules, git, or general questions can skip
  all of this.
- **Which file.** All six live in `docs/`, along with README images
  (`docs/images/`). SPEC.md is the source of truth for what the app does
  and why; ERRATA.md holds what macOS/SwiftUI/AppKit do to Phases and how
  it routes around them (quirks, workaround mechanics, design history of
  code still on `main`, the regressions list). The sorting tests:
  - If a future macOS fixed the bug, would the line still be true?
    Yes → SPEC.md. No → ERRATA.md.
  - Would someone using Phases ever see or care about it? No → one of
    the two testing docs. **Test process** (what to check, when, how a
    run goes, what to do when a fixed bug comes back) → TESTING.md.
    **Test tools** (the input driver, diagnostics, test-only switches,
    the tools' own quirks, techniques for driving and measuring the Mac)
    → TEST-TOOLS.md.
  - Doesn't shape code on `main`? → the finding goes in LEARNINGS.md, a
    short digest entry with an `[L-…]` tag (experiments, rejected
    approaches, measurements, open questions); the full record behind it
    (question, setup, every run, numbers, wrong guesses) goes in
    EXPERIMENTS.md under the experiment's `[X-…]` tag. A digest entry
    names its `[X-…]`. Record as it happens, not at the end.
  - **Nothing learned is ever dropped.** Digest entries summarize; they
    never replace the record. Records aren't trimmed or reworded later;
    corrections are added next to what they correct.
- **Moving entries.** ERRATA.md holds only quirks the code on `main`
  depends on.
  - *Promotion:* when a learning starts shaping code, it moves to
    ERRATA.md as a `[Q-…]` entry (or to SPEC.md as a decision) in the same
    change, leaving a one-line pointer in LEARNINGS.md: "Promoted to
    `[Q-…]` (date)." The record in EXPERIMENTS.md stays where it is; its
    `[X-…]` header's outcome names the `[Q-…]`.
  - *Demotion:* when the code a `[Q-…]` entry (or a design history entry
    in ERRATA.md) shapes is removed from `main`, the entry moves to
    EXPERIMENTS.md in the same change (under its experiment, or under
    "Retired designs" with a new `[X-…]`), keeping its `[Q-…]` tag
    alongside a new `[L-…]` tag so old comments and commits still find
    it. LEARNINGS.md gets a digest entry with that `[L-…]`, and ERRATA.md
    a one-line pointer: "Demoted to `[L-…]` (date)."
- **Evidence labels.** Every factual claim in the docs, and in what
  Claude tells Robert, says how we know: **verified** (tested or
  measured, with date and by whom), **observed** (seen, not measured or
  repeated), or **recalled** (believed from past knowledge, not tested
  here). Hypotheses are labeled as such. Keep corrections and history;
  don't silently rewrite an entry.
- **Spec first, for design.** Changes to behavior, interface, or user
  experience start with a SPEC.md change the user approves before any code
  is written, landing in the same commit as the code. A bug fix that only
  makes the app do what SPEC.md already says needs no spec change, but it
  still needs Robert's go-ahead before code is edited (global rule:
  diagnose, explain, wait). Spec first is an app design and architecture
  rule, not a debugging rule. The build must meet the spec, not the other
  way around: if the code needs to differ from the spec, change the spec
  first and say so. TESTING.md and TEST-TOOLS.md decisions follow the
  same approval.
  SPEC.md is this project's ISA: don't create a separate one.
- **Tagged decisions.** How `[D-…]` and `[Q-…]` tags work is in SPEC.md
  "Design decisions". Before changing tagged code, re-read its decision;
  if the change contradicts it, say so and update the spec first.
- **One branch per change, squash-merged.** Start each change on its own
  branch: the spec edit, if the change needs one, goes first (open it in
  Marked for review), then code and ERRATA notes follow on the same
  branch. Squash-merge into `main` so each change lands as one commit
  with spec, code, and errata together. **Merging into `main` needs
  Robert's yes.** Notes that change no decision (*Verified* notes in any
  doc, SPEC.md included; test results; LEARNINGS.md and EXPERIMENTS.md
  entries) can be committed straight to `main`.
- **Experiment branches.** On a branch that won't be merged, Claude may
  instrument, edit, try fixes, build, and run unit tests without a
  go-ahead for each edit. Each experiment gets an `[X-…]` section in
  EXPERIMENTS.md when it starts (its header: question, when and on what,
  branch, outcome, findings). Run notes go there as they happen, and
  each finding gets its LEARNINGS.md digest entry as soon as it settles.
  A fix headed for `main` gets the usual go-ahead (and spec first, if
  it's design) on its own branch.
- **Cleaning up branches.** Every finished branch is archived first,
  then deleted locally and on every remote: an annotated tag
  `archive/<branch name>` with the message "Archive of branch <branch
  name> (deleted <date>; cited in docs)", pushed to `origin` and
  `github`. That covers merged branches (`fix/…`, `feature/…`, `doc/…`,
  after the squash merge, once their files match what landed on `main`)
  and finished experiments (`experiment/…`, `spike/…`,
  `investigate/…`). *Why:* the tag list is where the author looks for
  old work, rather than digging through git history (author,
  2026-11-13; until then merged branches were deleted without a tag).
  `tools/…` branches stay; they hold tools we come back to. Docs cite
  the tag, not the branch: an experiment's `[X-…]` header names the tag
  and gets its outcome filled in.
- **Testing.** Unit tests need no permission. Prefer pulling decision
  logic into pure files the unit tests can reach, as `WallpaperCheck`
  was; unit tests never launch Phases or exercise the UI
  `[D-tests-unhosted]`. Anything that drives the mouse and keyboard or
  touches the real wallpaper is a hands-on check `[D-hands-on-checks]`:
  ask per the global "Mouse and keyboard driving" rule, hands-off windows
  included. Subagents never start one. Drive the mouse and keyboard
  only through `UITests/Sources/PhasesUIDriver` (from the shell:
  `swift run phases-drive` in `UITests/`) `[D-input-driver]`. Never
  write a new input helper; if the driver lacks something, add it there.
- **Every regression gets a guard.** When a fix for a regression lands,
  its branch also adds (a) a row to ERRATA.md "Regressions found so far"
  and (b) a test that fails without the fix: a UI test, a unit test, or a
  geometry or screenshot check, named in the row's "Guarded by" column.
  Show the test failing against the broken code once (revert the fix
  locally) before trusting it. If no test is practical, "Guarded by" says
  why (for example, frame timing) and names the manual procedure; a bare
  "Nothing yet" isn't allowed. A regression fix doesn't merge without one
  or the other.
- **Diagnostics:** logging is built in and off by default
  `[D-diagnostics-switch]` (TEST-TOOLS.md "Diagnostics"). Add log lines with
  `Diagnostics.logger(…)`; never write new logging infrastructure.
- **Two remotes; name the one you push to.** `github` is the author's
  GitHub repo (github.com/rmohns/Phases); `origin` is Bitrig's hosted repo.
  "Push to GitHub" means `git push github …`. Say which remote, by name and
  URL, every time.
- **Mark Claude's commits.** Every commit Claude makes, squash merges
  included, ends with the trailer
  `Co-Authored-By: Claude (Bitrig) <noreply@anthropic.com>`. Commits
  without it are Robert's, except those up to `cf969a9`, all Claude's.
- **Commit messages say what changed.** The subject line describes the
  change itself; an issue number can follow it, never replace it. A fix
  says what it fixes, in the subject, and its body ends `Fixes #N` so
  GitHub closes the issue when it reaches `github`.
- **Closing an issue takes a summary comment too.** When a fix for a
  GitHub issue reaches `github`, post a signed comment on the issue
  saying what caused the bug, what the fix does, and how it was checked
  (tests, hands-on checks, who verified them), naming the commit. Close
  the issue if GitHub didn't. Both happen every time: the commit
  message and the issue each tell the story on their own.
- **Sign Claude's GitHub writing.** `gh` posts as Robert's account, so
  every issue, comment, PR description, or review Claude writes on
  GitHub says it's from Claude: open with `**Claude (Bitrig):**` (or end
  with `— Claude (Bitrig)` when a lead-in would read badly, as in an
  issue body). Never write as if Robert said it.
- Never install launch agents, daemons, or helpers without asking the user first.
- Open the docs for review with Marked: `/opt/homebrew/bin/mk docs/SPEC.md`,
  `/opt/homebrew/bin/mk docs/ERRATA.md`, `/opt/homebrew/bin/mk docs/TESTING.md`,
  `/opt/homebrew/bin/mk docs/TEST-TOOLS.md`,
  `/opt/homebrew/bin/mk docs/LEARNINGS.md`, and
  `/opt/homebrew/bin/mk docs/EXPERIMENTS.md`.
- **Model rungs.** The main conversation handles specs, diagnosis, design,
  and review. Mechanical work goes to a Sonnet subagent (`model: "sonnet"`):
  code edits already pinned down by an approved spec, renames, and doc
  formatting. Run builds and unit tests directly; they're one command. The brief
  names exact files, the relevant `[D-…]`/`[Q-…]` tags, and what done looks
  like; the agent can't see this conversation. Don't delegate when the
  brief would be longer than the edit, or when the work needs a call on a
  tagged decision. If the agent hits a surprise, it stops and reports back.
