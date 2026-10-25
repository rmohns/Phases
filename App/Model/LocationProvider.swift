import CoreLocation
import Observation

/// Low-accuracy location for dawn/dusk. Remembers the last known location so
/// solar phases still work offline or right after launch.
@MainActor
@Observable
final class LocationProvider: NSObject, CLLocationManagerDelegate {
  private(set) var coordinate: SolarCalculator.Coordinate?
  private(set) var authorizationStatus: CLAuthorizationStatus
  /// Called on the main actor whenever the coordinate changes.
  @ObservationIgnored var onChange: (() -> Void)?

  @ObservationIgnored private let manager = CLLocationManager()
  private static let coordinateKey = "lastCoordinate"

  override init() {
    authorizationStatus = manager.authorizationStatus
    if let data = UserDefaults.standard.data(forKey: Self.coordinateKey) {
      coordinate = try? JSONDecoder().decode(SolarCalculator.Coordinate.self, from: data)
    }
    super.init()
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyKilometer
  }

  var isAuthorized: Bool {
    authorizationStatus == .authorizedAlways || authorizationStatus == .authorized
  }

  var isDenied: Bool {
    authorizationStatus == .denied || authorizationStatus == .restricted
  }

  /// Asks for permission if needed, then fetches a fresh location.
  func refresh() {
    switch authorizationStatus {
    case .notDetermined:
      manager.requestWhenInUseAuthorization()
    case .denied, .restricted:
      break
    default:
      manager.requestLocation()
    }
  }

  nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    let status = manager.authorizationStatus
    MainActor.assumeIsolated {
      authorizationStatus = status
      if isAuthorized { manager.requestLocation() }
    }
  }

  nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.last else { return }
    let newCoordinate = SolarCalculator.Coordinate(
      latitude: location.coordinate.latitude,
      longitude: location.coordinate.longitude
    )
    MainActor.assumeIsolated {
      // Ignore jitter under ~1 km; it moves dawn/dusk by seconds.
      if let coordinate,
        abs(coordinate.latitude - newCoordinate.latitude) < 0.01,
        abs(coordinate.longitude - newCoordinate.longitude) < 0.01
      { return }
      coordinate = newCoordinate
      if let data = try? JSONEncoder().encode(newCoordinate) {
        UserDefaults.standard.set(data, forKey: Self.coordinateKey)
      }
      onChange?()
    }
  }

  nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    NSLog("Wallpaper Scheduler: location error: \(error)")
  }
}
