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
//   swift run phases-drive key tab|down|x [shift]

func pointer() -> CGPoint { CGEvent(source: nil)?.location ?? .zero }

func point(_ args: ArraySlice<String>) -> CGPoint? {
  guard args.count >= 2, let x = Double(args[args.startIndex]), let y = Double(args[args.startIndex + 1]) else { return nil }
  return CGPoint(x: x, y: y)
}

func fail(_ message: String) -> Never {
  FileHandle.standardError.write(Data((message + "\n").utf8))
  exit(2)
}

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
case "key":
  let keys: [String: SyntheticInput.Key] = ["tab": .tab, "down": .downArrow, "x": .x]
  guard let name = args.dropFirst().first, let key = keys[name] else { fail("usage: key tab|down|x [shift]") }
  try await SyntheticInput.press(key, shift: args.contains("shift"))
  print("key \(name)\(args.contains("shift") ? " with shift" : "")")
default:
  fail("usage: phases-drive where | move <x> <y> | click <x> <y> | key tab|down|x [shift]")
}
