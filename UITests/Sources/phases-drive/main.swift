import CoreGraphics
import Foundation
import PhasesUIDriver

// [D-input-driver] Mouse and keyboard driving from the shell, through the
// same SyntheticInput the UI tests use. Hands-on: ask first, with spoken
// warnings [D-hands-on-checks], and prove each action landed
// [D-input-lands].
//
//   swift run phases-drive where            pointer position
//   swift run phases-drive move <x> <y>     global points, top-left origin
//   swift run phases-drive click <x> <y>
//   swift run phases-drive scroll <x> <y> <lines>   positive brings what's below into view
//   swift run phases-drive key tab|down|x [shift] [cmd] [opt] [ctrl]
//   swift run phases-drive flags            modifiers the system reads as held
//                                           (sends no input)

func pointer() -> CGPoint { CGEvent(source: nil)?.location ?? .zero }

func point(_ args: ArraySlice<String>) -> CGPoint? {
  guard args.count >= 2, let x = Double(args[args.startIndex]), let y = Double(args[args.startIndex + 1]) else { return nil }
  return CGPoint(x: x, y: y)
}

func fail(_ message: String) -> Never {
  FileHandle.standardError.write(Data((message + "\n").utf8))
  exit(2)
}

func describe(_ modifiers: [SyntheticInput.Modifier]) -> String {
  modifiers.isEmpty ? "none" : modifiers.map(\.description).joined(separator: ", ")
}

let usage = "usage: phases-drive where | move <x> <y> | click <x> <y> | scroll <x> <y> <lines> | key tab|down|x [shift] [cmd] [opt] [ctrl] | flags"
let modifierNames: [String: SyntheticInput.Modifier] = ["shift": .shift, "cmd": .command, "opt": .option, "ctrl": .control]

let args = CommandLine.arguments.dropFirst()
let before = pointer()
switch args.first {
case "where":
  print("pointer \(Int(before.x)),\(Int(before.y))")
case "move":
  guard let target = point(args.dropFirst()) else { fail("usage: move <x> <y>") }
  try await SyntheticInput.move(to: target)
  print("move from \(Int(before.x)),\(Int(before.y)) to \(Int(target.x)),\(Int(target.y)); reads back \(Int(pointer().x)),\(Int(pointer().y))")
case "click":
  guard let target = point(args.dropFirst()) else { fail("usage: click <x> <y>") }
  try await SyntheticInput.click(at: target)
  print("click at \(Int(target.x)),\(Int(target.y))")
case "scroll":
  guard let target = point(args.dropFirst()), let lines = args.dropFirst(3).first.flatMap(Int.init) else {
    fail("usage: scroll <x> <y> <lines> (positive brings what's below into view)")
  }
  try await SyntheticInput.scroll(at: target, lines: lines)
  print("scroll \(lines) lines at \(Int(target.x)),\(Int(target.y))")
case "key":
  let keys: [String: SyntheticInput.Key] = ["tab": .tab, "down": .downArrow, "x": .x]
  guard let name = args.dropFirst().first, let key = keys[name] else { fail(usage) }
  var modifiers = Set<SyntheticInput.Modifier>()
  for word in args.dropFirst(2) {
    guard let modifier = modifierNames[word] else { fail("unknown modifier \(word); \(usage)") }
    modifiers.insert(modifier)
  }
  let ordered = SyntheticInput.Modifier.allCases.filter(modifiers.contains)
  try await SyntheticInput.press(key, modifiers: modifiers)
  print("key \(name) with \(describe(ordered)); held afterward: \(describe(SyntheticInput.heldModifiers()))")
case "flags":
  print("held: \(describe(SyntheticInput.heldModifiers()))")
default:
  fail(usage)
}
