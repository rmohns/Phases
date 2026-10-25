import Foundation

/// Calculates civil dawn and dusk locally using the NOAA "Almanac for
/// Computers" sunrise algorithm, with a zenith of 96° (sun 6° below horizon).
enum SolarCalculator {
  struct Coordinate: Codable, Hashable {
    var latitude: Double
    var longitude: Double
  }

  private static let civilZenith = 96.0

  /// The time of `event` on the local calendar day containing `day`, or nil
  /// if the sun never reaches civil twilight that day.
  static func time(
    of event: SolarEvent,
    on day: Date,
    at coordinate: Coordinate,
    calendar: Calendar = .current
  ) -> Date? {
    guard let dayOfYear = calendar.ordinality(of: .day, in: .year, for: day) else { return nil }
    let localMidnight = calendar.startOfDay(for: day)

    let isRising = event == .dawn
    let lngHour = coordinate.longitude / 15
    let t = Double(dayOfYear) + ((isRising ? 6 : 18) - lngHour) / 24

    let meanAnomaly = 0.9856 * t - 3.289
    let center: Double = 1.916 * sin(radians(meanAnomaly)) + 0.020 * sin(radians(2 * meanAnomaly))
    let trueLongitude = normalize(meanAnomaly + center + 282.634, to: 360)

    let rawAscension: Double = degrees(atan(0.91764 * tan(radians(trueLongitude))))
    var rightAscension = normalize(rawAscension, to: 360)
    let quadrantShift: Double = floor(trueLongitude / 90) * 90 - floor(rightAscension / 90) * 90
    rightAscension += quadrantShift
    rightAscension /= 15

    let sinDec = 0.39782 * sin(radians(trueLongitude))
    let cosDec = cos(asin(sinDec))
    let cosH = (cos(radians(civilZenith)) - sinDec * sin(radians(coordinate.latitude)))
      / (cosDec * cos(radians(coordinate.latitude)))
    guard (-1...1).contains(cosH) else { return nil }

    let hourAngle = (isRising ? 360 - degrees(acos(cosH)) : degrees(acos(cosH))) / 15
    let localMeanTime = hourAngle + rightAscension - 0.06571 * t - 6.622
    let utcHours = normalize(localMeanTime - lngHour, to: 24)

    // Anchor to the UTC midnight of the same calendar date, then shift by whole
    // days so the result falls inside the local calendar day.
    var utc = Calendar(identifier: .gregorian)
    utc.timeZone = TimeZone(identifier: "UTC")!
    let components = calendar.dateComponents([.year, .month, .day], from: day)
    guard let utcMidnight = utc.date(from: components) else { return nil }
    var result = utcMidnight.addingTimeInterval(utcHours * 3600)
    let localEnd = localMidnight.addingTimeInterval(86_400)
    while result < localMidnight { result += 86_400 }
    while result >= localEnd { result -= 86_400 }
    return result
  }

  private static func radians(_ degrees: Double) -> Double { degrees * .pi / 180 }
  private static func degrees(_ radians: Double) -> Double { radians * 180 / .pi }

  private static func normalize(_ value: Double, to range: Double) -> Double {
    let remainder = value.truncatingRemainder(dividingBy: range)
    return remainder < 0 ? remainder + range : remainder
  }
}
