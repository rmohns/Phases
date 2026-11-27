import Foundation

/// [D-doc-check] Reads the docs and the source, finds where each `[D-…]`,
/// `[Q-…]`, `[L-…]`, and `[X-…]` tag is defined and where it's cited, and
/// writes the tag index, docs/INDEX.md. DocIndexTests uses it to check that
/// nothing cited has gone missing when docs are moved or split.
struct DocIndex {
  struct SourceFile {
    var path: String  // relative to the project root
    var lines: [String]
  }

  /// One place a tag is defined: a list item, numbered item, heading, or
  /// table row that starts with the tag in backticks.
  struct Definition {
    var tag: String
    var path: String
    var line: Int  // 1-based
    var heading: String  // nearest heading above, without #s
    var summary: String
    var isPointer: Bool  // "Promoted to …" / "Demoted to …"
  }

  struct Reference {
    var path: String
    var line: Int
    var file: String
    var title: String
  }

  var root: URL
  /// Docs that can define tags: docs/**/*.md except INDEX.md and the
  /// handoff and prompt write-ups, which are records that only cite them.
  var docs: [SourceFile] = []
  /// Everything else that cites tags: code, handoffs, CLAUDE.md, README.md.
  var citing: [SourceFile] = []

  static let tagRegex = #/\[(?:D|Q|L|X)-[a-z0-9]+(?:-[a-z0-9]+)*\]/#
  static let indexPath = "docs/INDEX.md"

  init(root: URL) throws {
    self.root = root
    let fm = FileManager.default
    func read(_ relative: String) throws -> SourceFile {
      let text = try String(contentsOf: root.appending(path: relative), encoding: .utf8)
      return SourceFile(path: relative, lines: text.components(separatedBy: "\n"))
    }
    func walk(_ dir: String, extensions: Set<String>) -> [String] {
      guard let e = fm.enumerator(atPath: root.appending(path: dir).path) else { return [] }
      var found: [String] = []
      while let item = e.nextObject() as? String {
        if item.hasPrefix(".build") || item.contains("/.build/") || item.contains(".swiftpm") { continue }
        if extensions.contains((item as NSString).pathExtension) { found.append("\(dir)/\(item)") }
      }
      return found.sorted()
    }
    for path in walk("docs", extensions: ["md"]) where path != Self.indexPath {
      if path.hasPrefix("docs/handoffs/") || path.hasPrefix("docs/prompts/") {
        citing.append(try read(path))
      } else {
        docs.append(try read(path))
      }
    }
    for dir in ["App", "UITests", "UnitTests"] {
      // DocIndexTests' own examples aren't real tags.
      for path in walk(dir, extensions: ["swift", "plist", "entitlements", "md", "xcconfig"])
      where !path.hasSuffix("/DocIndexTests.swift") {
        citing.append(try read(path))
      }
    }
    for path in ["CLAUDE.md", "README.md"] where fm.fileExists(atPath: root.appending(path: path).path) {
      citing.append(try read(path))
    }
  }

  // MARK: Definitions

  /// Whether what follows a tag reads as its statement rather than the
  /// rest of a sentence that cites it ("`[D-…]`, replaced in…").
  static func startsStatement(_ rest: Substring) -> Bool {
    let r = rest.drop { $0 == " " }
    guard let first = r.first else { return true }
    // ERRATA.md opens a *How* section with the decision's and quirk's
    // tags, a colon, and the explanation: that cites them.
    if first == ":" { return r.dropFirst().trimmingCharacters(in: .whitespaces).isEmpty }
    return ![",", ".", ";", ")"].contains(first)
  }

  /// Decisions are defined in the spec and the testing docs. ERRATA.md
  /// and the learnings and experiments open their *How* and history
  /// sections with the decision's tag, but those cite it.
  static func isHome(of tag: String, _ path: String) -> Bool {
    guard tag.hasPrefix("[D-") else { return true }
    return path == "docs/SPEC.md" || path.hasPrefix("docs/spec/") || path == "docs/TESTING.md"
      || path.hasPrefix("docs/testing/") || path == "docs/TEST-TOOLS.md"
  }

  /// The tags a line defines: those in backticks that open the line, after
  /// any list marker, number, heading marks, or table bar, when what
  /// follows starts the statement. A line with no marker counts only when
  /// it opens a paragraph; otherwise it's a citation that wrapped there.
  static func definedTags(in line: String, opensParagraph: Bool = true) -> [String] {
    var s = Substring(line).drop { $0 == " " }
    if s.hasPrefix("#") {
      s = s.drop { $0 == "#" }
    } else if s.hasPrefix("- ") || s.hasPrefix("* ") || s.hasPrefix("+ ") {
      s = s.dropFirst(2)
    } else if let m = s.prefixMatch(of: #/[0-9]+\.\s/#) {
      s = s[m.range.upperBound...]
    } else if s.hasPrefix("|") {
      s = s.dropFirst()
    } else if !opensParagraph {
      return []
    }
    var tags: [String] = []
    while true {
      s = s.drop { $0 == " " }
      guard s.hasPrefix("`"), let m = s.dropFirst().prefixMatch(of: tagRegex),
        s.dropFirst()[m.range.upperBound...].hasPrefix("`")
      else { break }
      tags.append(String(m.output))
      s = s.dropFirst()[m.range.upperBound...].dropFirst()
    }
    return startsStatement(s) ? tags : []
  }

  /// Tags defined mid-line: right after a bold phrase ("**Launch at
  /// Login** `[D-…]`"), or opening a sentence ("`[D-…]` The toolbar…").
  /// They count only for tags with no definition that opens a line.
  static func inlineDefinedTags(in line: String) -> [String] {
    var tags: [String] = []
    for m in line.matches(of: #/`(\[(?:D|Q|L|X)-[a-z0-9-]+\])`/#) {
      let before = line[..<m.range.lowerBound]
      let after = line[m.range.upperBound...]
      let afterBold = before.hasSuffix("** ")
      let lineStart = before.trimmingCharacters(in: .whitespaces).isEmpty
      let opensSentence = (before.hasSuffix(". ") || lineStart)
        && after.hasPrefix(" ") && (after.dropFirst().first?.isUppercase ?? false || after.dropFirst().hasPrefix("**"))
      let introducesList = lineStart && after.trimmingCharacters(in: .whitespaces) == ":"
      if afterBold || opensSentence || introducesList { tags.append(String(m.output.1)) }
    }
    return tags
  }

  static func headingText(_ line: String) -> String? {
    guard line.hasPrefix("#") else { return nil }
    return line.drop { $0 == "#" }.trimmingCharacters(in: .whitespaces)
  }

  /// The bold phrase after the tag, joined across wrapped lines, or else
  /// the rest of the line.
  static func summary(lines: [String], at index: Int, tag: String) -> String {
    var text = lines[index]
    var next = index + 1
    while next < lines.count, next <= index + 4, !lines[next].trimmingCharacters(in: .whitespaces).isEmpty,
      Self.headingText(lines[next]) == nil, definedTags(in: lines[next]).isEmpty
    {
      text += " " + lines[next].trimmingCharacters(in: .whitespaces)
      next += 1
    }
    guard let tagRange = text.range(of: "`\(tag)`") else { return "" }
    var rest = text[tagRange.upperBound...].trimmingCharacters(in: .whitespaces)
    while let m = rest.prefixMatch(of: #/`\[[DQLX]-[a-z0-9-]+\]`\s*/#) {
      rest = String(rest[m.range.upperBound...])
    }
    let before = text[..<tagRange.lowerBound].trimmingCharacters(in: .whitespaces)
    let result: String
    if rest.hasPrefix("**"), let close = rest.dropFirst(2).range(of: "**") {
      result = String(rest.dropFirst(2)[..<close.lowerBound])
    } else if before.hasSuffix("**"), let open = before.dropLast(2).range(of: "**", options: .backwards) {
      result = String(before.dropLast(2)[open.upperBound...])
    } else if let stop = rest.range(of: ". ") {
      result = String(rest[..<stop.lowerBound])
    } else {
      result = rest
    }
    var clean = result.replacingOccurrences(of: "|", with: "\\|")
      .trimmingCharacters(in: CharacterSet(charactersIn: " .:,"))
    if clean.count > 140 { clean = String(clean.prefix(137)) + "…" }
    return clean
  }

  /// Each tag's definitions: those that open a line, or, for a tag with
  /// none, its first mid-line definition.
  var definitions: [Definition] {
    var result: [Definition] = []
    var inline: [String: Definition] = [:]
    for file in docs {
      var heading = ""
      for (i, line) in file.lines.enumerated() {
        if let h = Self.headingText(line) { heading = h }
        let opensParagraph = i == 0 || file.lines[i - 1].trimmingCharacters(in: .whitespaces).isEmpty
        let opening = Self.definedTags(in: line, opensParagraph: opensParagraph)
        for tag in opening where Self.isHome(of: tag, file.path) {
          let pointer = line.contains("Promoted to") || line.contains("Demoted to")
          result.append(
            Definition(
              tag: tag, path: file.path, line: i + 1,
              heading: Self.headingText(line) != nil ? "" : heading,
              summary: Self.summary(lines: file.lines, at: i, tag: tag), isPointer: pointer))
        }
        for tag in Self.inlineDefinedTags(in: line)
        where !opening.contains(tag) && inline[tag] == nil && Self.isHome(of: tag, file.path) {
          inline[tag] = Definition(
            tag: tag, path: file.path, line: i + 1, heading: heading,
            summary: Self.summary(lines: file.lines, at: i, tag: tag), isPointer: false)
        }
      }
    }
    let opened = Set(result.map(\.tag))
    result += inline.values.filter { !opened.contains($0.tag) }
    return result
  }

  // MARK: Citations

  struct Citation {
    var tag: String
    var path: String
    var line: Int
    var text: String
  }

  var citations: [Citation] {
    var result: [Citation] = []
    for file in docs + citing {
      for (i, line) in file.lines.enumerated() {
        for m in line.matches(of: Self.tagRegex) {
          result.append(Citation(tag: String(m.output), path: file.path, line: i + 1, text: line))
        }
      }
    }
    return result
  }

  /// Tags with no definition that are mentioned as replaced, retired, or
  /// renamed: decisions kept only as history `[D-refs-by-id]`.
  static func mentionsRetirement(_ line: String) -> Bool {
    let l = line.lowercased()
    return ["replace", "retire", "renamed", "superseded"].contains { l.contains($0) }
  }

  struct Problems {
    var undefined: [Citation] = []
    var duplicates: [String: [Definition]] = [:]
    var brokenReferences: [Reference] = []
    var brokenLinks: [(path: String, line: Int, target: String)] = []
    var isEmpty: Bool {
      undefined.isEmpty && duplicates.isEmpty && brokenReferences.isEmpty && brokenLinks.isEmpty
    }
  }

  /// Which docs a file name in a reference stands for. A family name
  /// (SPEC.md, TESTING.md, EXPERIMENTS.md) means the front page and every
  /// file in its folder, so references written before a split still
  /// resolve `[D-refs-by-id]`.
  func filesNamed(_ name: String) -> [SourceFile] {
    let families = ["SPEC.md": "docs/spec/", "TESTING.md": "docs/testing/", "EXPERIMENTS.md": "docs/experiments/"]
    let all = docs + citing
    if let folder = families[name] {
      return all.filter { $0.path == "docs/\(name)" || $0.path.hasPrefix(folder) }
    }
    return all.filter {
      $0.path == name || $0.path == "docs/\(name)" || $0.path.hasSuffix("/\(name)")
    }
  }

  func problems() -> Problems {
    var problems = Problems()
    let defs = definitions
    let defined = Set(defs.map(\.tag))
    let cites = citations
    var retired = Set<String>()
    for c in cites where !defined.contains(c.tag) && Self.mentionsRetirement(c.text) {
      retired.insert(c.tag)
    }
    problems.undefined = cites.filter { !defined.contains($0.tag) && !retired.contains($0.tag) }

    // A tag is defined once, except that an [L-…] finding has its digest
    // entry in LEARNINGS.md and its full entry in the experiment's record.
    let real = Dictionary(grouping: defs.filter { !$0.isPointer }, by: \.tag)
    for (tag, list) in real where list.count > 1 {
      let inLearnings = list.filter { $0.path == "docs/LEARNINGS.md" }
      let inRecords = list.filter { $0.path == "docs/EXPERIMENTS.md" || $0.path.hasPrefix("docs/experiments/") }
      if tag.hasPrefix("[L-") || tag.hasPrefix("[Q-"), inLearnings.count <= 1, inRecords.count <= 1,
        inLearnings.count + inRecords.count == list.count
      {
        continue
      }
      problems.duplicates[tag] = list
    }

    // FILE.md "Title" references in the docs and CLAUDE.md.
    for file in docs + citing.filter({ $0.path == "CLAUDE.md" }) {
      // A paragraph that names an archive/… tag is describing an old
      // layout; its references point into that tag, not into today's docs.
      var paragraphStart = 0
      for (i, line) in file.lines.enumerated() {
        if line.trimmingCharacters(in: .whitespaces).isEmpty {
          paragraphStart = i + 1
          continue
        }
        var end = i
        while end + 1 < file.lines.count, !file.lines[end + 1].trimmingCharacters(in: .whitespaces).isEmpty { end += 1 }
        let paragraph = file.lines[paragraphStart...end].joined(separator: "\n")
        if paragraph.contains("archive/") { continue }
        for m in line.matches(of: #/([A-Za-z0-9_\/.-]+\.md)"? "([^"]+)"/#) {
          let name = String(m.output.1).replacingOccurrences(of: "docs/", with: "")
          let title = String(m.output.2)
          let targets = filesNamed(name)
          let headings = targets.flatMap { $0.lines.compactMap(Self.headingText) }
            .map { $0.replacingOccurrences(of: "`", with: "") }
          let wanted = title.replacingOccurrences(of: "`", with: "")
          if targets.isEmpty || !headings.contains(where: { $0.hasPrefix(wanted) }) {
            problems.brokenReferences.append(Reference(path: file.path, line: i + 1, file: name, title: title))
          }
        }
        for m in line.matches(of: #/\]\(([^)#\s]+\.(?:md|png|jpg|jpeg|gif))\)/#) {
          let target = String(m.output.1)
          if target.hasPrefix("http") { continue }
          let base = root.appending(path: file.path).deletingLastPathComponent()
          if !FileManager.default.fileExists(atPath: base.appending(path: target).path) {
            problems.brokenLinks.append((file.path, i + 1, target))
          }
        }
      }
    }
    return problems
  }

  // MARK: Index

  func indexText() -> String {
    let defs = definitions
    let byTag = Dictionary(grouping: defs, by: \.tag)
    let cites = citations
    let codeFiles = Dictionary(grouping: cites.filter { !$0.path.hasPrefix("docs/") && $0.path.hasSuffix(".swift") }, by: \.tag)
      .mapValues { Array(Set($0.map { ($0.path as NSString).lastPathComponent })).sorted() }
    let defined = Set(byTag.keys)
    var retired: [String: [Citation]] = [:]
    for c in cites where !defined.contains(c.tag) && Self.mentionsRetirement(c.text) {
      retired[c.tag, default: []].append(c)
    }

    func place(_ d: Definition) -> String {
      let file = d.path.replacingOccurrences(of: "docs/", with: "")
      return d.heading.isEmpty ? "\(file):\(d.line)" : "\(file):\(d.line) \"\(d.heading.replacingOccurrences(of: "|", with: "\\|"))\""
    }

    var out = """
      # Phases — Tag index

      Every `[D-…]`, `[Q-…]`, `[L-…]`, and `[X-…]` tag: where it's defined,
      what it says, and which Swift files cite it. **Generated; don't edit by
      hand.** The unit tests rewrite this file when it's out of date and fail
      once, so commit the new version (`[D-doc-check]`, TESTING.md "Unit
      tests"). Line numbers are as of the last run.

      """
    let kinds: [(String, String)] = [
      ("[D-", "Decisions `[D-…]`"), ("[Q-", "Quirks `[Q-…]`"),
      ("[L-", "Learnings `[L-…]`"), ("[X-", "Experiments `[X-…]`"),
    ]
    for (prefix, title) in kinds {
      out += "\n## \(title)\n\n| Tag | Where | Says | Cited in code |\n|---|---|---|---|\n"
      for tag in byTag.keys.filter({ $0.hasPrefix(prefix) }).sorted() {
        let list = byTag[tag]!.sorted { ($0.isPointer ? 1 : 0, $0.path) < ($1.isPointer ? 1 : 0, $1.path) }
        let main = list.first { !$0.isPointer } ?? list[0]
        let wheres = list.map { place($0) + ($0.isPointer ? " (pointer)" : "") }.joined(separator: "<br>")
        let says = main.isPointer ? "*Pointer:* \(main.summary)" : main.summary
        let code = codeFiles[tag]?.joined(separator: ", ") ?? ""
        out += "| `\(tag)` | \(wheres) | \(says) | \(code) |\n"
      }
    }
    out += "\n## Retired tags\n\nNo longer defined; mentioned as replaced or retired. The mention says what replaced each.\n\n| Tag | Mentioned in |\n|---|---|\n"
    for tag in retired.keys.sorted() {
      let places = Set(retired[tag]!.map { "\($0.path.replacingOccurrences(of: "docs/", with: "")):\($0.line)" }).sorted()
      out += "| `\(tag)` | \(places.joined(separator: ", ")) |\n"
    }
    return out
  }
}
