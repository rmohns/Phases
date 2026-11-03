# Phases: project rules

- **Before touching code, the spec, or tests:** read `docs/SPEC.md` and
  `docs/ERRATA.md`. Conversations about rules, git, or general questions
  can skip them; the bullets below carry the doc rules. Both live in `docs/`, along with README images (`docs/images/`).
  SPEC.md is the source of truth for what the app does and why. ERRATA.md
  holds what macOS/SwiftUI/AppKit do to Phases and how it routes around
  them: platform quirks, workaround mechanics, design history, diagnostic
  procedures, and the regressions list. Read `docs/TESTING.md` too when
  the work touches tests, test-only launch arguments, or diagnostics.
  Read `docs/LEARNINGS.md` before experimenting, or before blaming or
  working around platform behavior: it may already hold the answer.
- **Which file:** if a future macOS fixed the bug, would the line still be
  true? Yes → SPEC.md. No → ERRATA.md. Would someone using Phases ever see
  or care about it? No → TESTING.md (tests, test-only switches,
  diagnostics). TESTING.md decisions follow the same spec-first approval.
  Learned something that doesn't shape code on `main`? → LEARNINGS.md,
  with an `[L-…]` tag (experiments, rejected approaches, measurements,
  open questions). Record findings there as they happen, not at the end.
  Entries move between the two as code starts or stops depending on them
  (LEARNINGS.md "Promotion" and "Demotion").
- **Spec first, for design.** Changes to behavior, interface, or user
  experience start with a SPEC.md change the user approves before any code
  is written, landing in the same commit as the code. A bug fix that only
  makes the app do what SPEC.md already says needs no spec change; it
  needs one only if it changes intended behavior. Spec first is an app
  design and architecture rule, not a debugging rule. The build must meet
  the spec, not the other way around: if the code needs to differ from the
  spec, change the spec first and say so. SPEC.md is this project's ISA:
  don't create a separate one.
- **One branch per change, squash-merged.** Start each change on its own
  branch: the spec edit, if the change needs one, goes first (open it in
  Marked for review), then code and ERRATA notes follow on the same
  branch. Squash-merge into `main`
  so each change lands as one commit with spec, code, and errata together.
  Notes that change no decision (*Verified* notes, test results,
  LEARNINGS.md entries) can be committed straight to `main`; spec and
  TESTING.md decisions still go through a branch and approval. A squash
  merge counts as merging
  into `main`: build right after it, unless the merge touched only docs
  (`docs/`, `CLAUDE.md`, README); then skip the build.
- **Two remotes; name the one you push to.** `github` is the author's
  GitHub repo (github.com/rmohns/Phases); `origin` is Bitrig's hosted repo.
  "Push to GitHub" means `git push github …`. Say which remote, by name and
  URL, every time.
- **Mark Claude's commits.** Every commit Claude makes, squash merges
  included, ends with the trailer
  `Co-Authored-By: Claude (Bitrig) <noreply@anthropic.com>`. Commits
  without it are Robert's, except those up to `cf969a9`, all Claude's.
- Never install launch agents, daemons, or helpers without asking the user first.
- Open the specs for review with Marked: `/opt/homebrew/bin/mk docs/SPEC.md`,
  `/opt/homebrew/bin/mk docs/ERRATA.md`, `/opt/homebrew/bin/mk docs/TESTING.md`,
  and `/opt/homebrew/bin/mk docs/LEARNINGS.md`.
- **Tagged decisions:** deliberate choices carry a `[D-…]` tag in SPEC.md (or TESTING.md) and
  in a comment on the code that enforces them (see SPEC.md "Design
  decisions"). Before changing tagged code, re-read the decision; if the
  change contradicts it, say so and update the spec first. Tag new deliberate
  choices when adding them to the spec.
- **Platform quirks:** framework/OS quirks live in ERRATA.md, each with a
  stable `[Q-…]` ID, marked verified (with date) or recalled, and citing
  the `[D-…]` decisions it shapes. Check there before blaming or working
  around SwiftUI/AppKit behavior. Add new quirks there with a new `[Q-…]`
  ID; the affected decision in SPEC.md gets one line: "macOS fights this;
  see `[Q-…]`." Code comments carry both tags where relevant.
- **No section numbers.** Refer to sections by `[D-…]` or `[Q-…]` tag or
  by quoted section title, in both files and in code comments; never "§4"
  or "section 4". Headings are unnumbered on purpose `[D-refs-by-id]`.
- **Spec draft number:** when bumping the draft in SPEC.md's title, bump
  `AppVersion.specDraft` too; a unit test enforces the match
  `[D-version-in-settings]`.
- **Every regression gets a guard.** When a fix for a regression lands,
  its branch also adds (a) a row to ERRATA.md "Regressions found so far"
  and (b) a test that fails without the fix: a UI test, a unit test, or a
  geometry or screenshot check, named in the row's "Guarded by" column.
  Show the test failing against the broken code once (revert the fix
  locally) before trusting it. If no test is practical, "Guarded by" says
  why (for example, frame timing) and names the manual procedure; a bare
  "Nothing yet" isn't allowed. A regression fix doesn't merge without one
  or the other. UI test runs drive the mouse and keyboard, so ask first
  (see TESTING.md "Interface tests").
- **Diagnostics:** logging is built in and off by default
  `[D-diagnostics-switch]` (TESTING.md "Diagnostics"). Add log lines with
  `Diagnostics.logger(…)`; never write new logging infrastructure.
- **Model rungs.** The main conversation handles specs, diagnosis, design,
  and review. Mechanical work goes to a Sonnet subagent (`model: "sonnet"`):
  code edits already pinned down by an approved spec, renames, and doc
  formatting. Run builds and unit tests directly; they're one command. The brief
  names exact files, the relevant `[D-…]`/`[Q-…]` tags, and what done looks
  like; the agent can't see this conversation. Don't delegate when the
  brief would be longer than the edit, or when the work needs a call on a
  tagged decision. Subagents never start UI test runs; those still need
  Robert's yes. If the agent hits a surprise, it stops and reports back.
