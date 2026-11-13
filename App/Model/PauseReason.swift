import Foundation

/// [D-window-pause-banner] Why Phases is paused, in the words the window's
/// pause banner shows. Pure, so the unit tests can reach it
/// [D-tests-unhosted].
enum PauseReason {
  /// "Paused from the menu." for a manual pause; for an outside change
  /// [D-outside-change-pauses], when it happened, with the date added when
  /// it wasn't today.
  static func text(
    pausedForOutsideChangeAt date: Date?,
    now: Date = Date(),
    calendar: Calendar = .current,
    locale: Locale = .autoupdatingCurrent
  ) -> String {
    guard let date else { return "Paused from the menu." }
    var style = Date.FormatStyle(date: .omitted, time: .shortened)
    if !calendar.isDate(date, inSameDayAs: now) {
      style = Date.FormatStyle(date: .abbreviated, time: .shortened)
    }
    style.locale = locale
    style.calendar = calendar
    style.timeZone = calendar.timeZone
    return "Paused at \(date.formatted(style)) because the wallpaper was changed in System Settings."
  }
}
