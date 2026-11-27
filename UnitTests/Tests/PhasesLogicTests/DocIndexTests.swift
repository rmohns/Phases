import Foundation
import Testing

/// [D-doc-check] The docs keep everything the code and the other docs cite:
/// moving or splitting a doc can't lose a tag's definition or leave a
/// `FILE.md "Title"` reference pointing nowhere. Also keeps docs/INDEX.md
/// current.
struct DocIndexTests {
  static let root = URL(filePath: #filePath)
    .deletingLastPathComponent()  // PhasesLogicTests
    .deletingLastPathComponent()  // Tests
    .deletingLastPathComponent()  // UnitTests
    .deletingLastPathComponent()  // project root

  @Test func everyCitedTagIsDefined() throws {
    let problems = try DocIndex(root: Self.root).problems()
    for c in problems.undefined {
      Issue.record("\(c.tag) cited at \(c.path):\(c.line) but defined nowhere in docs/ (and not mentioned as replaced or retired)")
    }
  }

  @Test func noTagIsDefinedTwice() throws {
    let problems = try DocIndex(root: Self.root).problems()
    for (tag, list) in problems.duplicates.sorted(by: { $0.key < $1.key }) {
      Issue.record("\(tag) defined \(list.count) times: \(list.map { "\($0.path):\($0.line)" }.joined(separator: ", "))")
    }
  }

  @Test func titleReferencesResolve() throws {
    let problems = try DocIndex(root: Self.root).problems()
    for r in problems.brokenReferences {
      Issue.record("\(r.path):\(r.line) cites \(r.file) \"\(r.title)\", but no heading there starts with that title")
    }
    for l in problems.brokenLinks {
      Issue.record("\(l.path):\(l.line) links to \(l.target), which doesn't exist")
    }
    for h in problems.repeatedHeadings {
      Issue.record("\"\(h.heading)\" is a section title more than once in \(h.family)'s files: \(h.places.joined(separator: ", "))")
    }
  }

  /// Rewrites docs/INDEX.md when it's out of date, and fails once so the
  /// new version gets looked at and committed.
  @Test func indexIsCurrent() throws {
    let index = try DocIndex(root: Self.root)
    let url = Self.root.appending(path: DocIndex.indexPath)
    let current = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    let fresh = index.indexText()
    if current != fresh {
      try fresh.write(to: url, atomically: true, encoding: .utf8)
      Issue.record("docs/INDEX.md was out of date and has been rewritten; run the tests again and commit it")
    }
  }

  // The parser itself.

  @Test func definitionsStartTheLine() {
    #expect(DocIndex.definedTags(in: "- `[D-one]` **Rule.**") == ["[D-one]"])
    #expect(DocIndex.definedTags(in: "  2. `[D-two]` Text") == ["[D-two]"])
    #expect(DocIndex.definedTags(in: "     `[D-wrapped]` (author, 2026-11-25).", opensParagraph: false).isEmpty)
    #expect(DocIndex.definedTags(in: "### `[X-run]` Title") == ["[X-run]"])
    #expect(DocIndex.definedTags(in: "### `[L-new]` `[Q-old]` Title") == ["[L-new]", "[Q-old]"])
    #expect(DocIndex.definedTags(in: "| `[Q-row]` | x |") == ["[Q-row]"])
    #expect(DocIndex.definedTags(in: "- see `[D-other]`").isEmpty)
    #expect(DocIndex.definedTags(in: "`[D-para]`, replaced in draft 33").isEmpty)
    #expect(DocIndex.definedTags(in: "`[D-alone]`") == ["[D-alone]"])
    #expect(DocIndex.definedTags(in: "`[D-short]` Kept short.") == ["[D-short]"])
    #expect(DocIndex.definedTags(in: "  - `[D-arg]` never touch the Photos library") == ["[D-arg]"])
    #expect(DocIndex.inlineDefinedTags(in: "`[D-list]`:") == ["[D-list]"])
    #expect(DocIndex.isHome(of: "[D-x]", "docs/spec/window.md"))
    #expect(!DocIndex.isHome(of: "[D-x]", "docs/ERRATA.md"))
    #expect(DocIndex.inlineDefinedTags(in: "- **Launch at Login** `[D-bold]` (with") == ["[D-bold]"])
    #expect(DocIndex.inlineDefinedTags(in: "beside it. `[D-mid]` The toolbar title") == ["[D-mid]"])
    #expect(DocIndex.inlineDefinedTags(in: "the name row `[D-cite]`, or").isEmpty)
  }

  @Test func summaryIsTheBoldPhrase() {
    let lines = ["- `[D-x]` **A rule that", "  wraps.** More text."]
    #expect(DocIndex.summary(lines: lines, at: 0, tag: "[D-x]") == "A rule that wraps")
  }
}
