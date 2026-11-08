import Foundation
import Testing
@testable import PhasesLogic

/// [D-window-pause-banner] The reason line under "Phases is paused".
struct PauseReasonTests {
  static let locale = Locale(identifier: "en_US")
  static let now = TestCalendar.date(2026, 11, 7, 15, 30)

  static func text(_ date: Date?) -> String {
    // Formatters may put a narrow no-break space before AM/PM.
    PauseReason.text(pausedForOutsideChangeAt: date, now: now, calendar: TestCalendar.newYork, locale: locale)
      .replacingOccurrences(of: "\u{202F}", with: " ")
  }

  @Test func manualPauseSaysMenu() {
    #expect(Self.text(nil) == "Paused from the menu.")
  }

  @Test func outsideChangeTodayGivesTimeOnly() {
    let date = TestCalendar.date(2026, 11, 7, 9, 6)
    #expect(Self.text(date) == "Paused at 9:06 AM because the wallpaper was changed in System Settings.")
  }

  @Test func outsideChangeEarlierDayAddsDate() {
    let date = TestCalendar.date(2026, 11, 6, 21, 15)
    #expect(Self.text(date) == "Paused at Nov 6, 2026 at 9:15 PM because the wallpaper was changed in System Settings.")
  }

  /// Just after midnight is a different day from late the evening before,
  /// in the calendar's time zone, not the Mac's.
  @Test func dayBoundaryUsesCalendarTimeZone() {
    let lateYesterday = TestCalendar.date(2026, 11, 6, 23, 59)
    let earlyToday = TestCalendar.date(2026, 11, 7, 0, 1)
    #expect(Self.text(lateYesterday).contains("Nov 6"))
    #expect(!Self.text(earlyToday).contains("Nov"))
  }
}
