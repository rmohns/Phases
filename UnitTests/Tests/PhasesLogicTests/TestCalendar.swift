import Foundation

/// A fixed calendar and date helper, so tests don't depend on the Mac's
/// time zone.
enum TestCalendar {
  static let newYork: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "America/New_York")!
    return calendar
  }()

  static func date(
    _ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0,
    in calendar: Calendar = newYork
  ) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
  }
}
