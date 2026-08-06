import Foundation
import CoreLocation
import Observation

/// Kümmert sich um die Standortfreigabe und den aktuellen Standort.
///
/// iOS gibt den Standort nicht einfach heraus — der Nutzer muss zustimmen.
/// Diese Klasse fragt einmal nach und liefert danach die Position.
///
/// Wichtig: In `project.yml` steht `NSLocationWhenInUseUsageDescription`.
/// Ohne diesen Text stürzt die App beim Fragen nach dem Standort ab.
@MainActor
@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {

    private let manager = CLLocationManager()

    /// Der zuletzt bekannte Standort, oder `nil` wenn (noch) unbekannt.
    private(set) var userLocation: CLLocation?

    /// Hat der Nutzer zugestimmt, abgelehnt oder noch gar nicht entschieden?
    private(set) var authorizationStatus: CLAuthorizationStatus

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        // Für eine Shop-Suche reichen ~100 m Genauigkeit. Das schont den Akku
        // deutlich gegenüber der GPS-Höchstgenauigkeit.
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    /// Fragt den Nutzer nach Standortfreigabe.
    /// Zeigt den Dialog nur beim allerersten Mal.
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    /// Fordert eine einzelne Standortmessung an.
    func requestLocation() {
        guard authorizationStatus == .authorizedWhenInUse
                || authorizationStatus == .authorizedAlways else {
            return
        }
        manager.requestLocation()
    }

    /// Entfernung vom Nutzer zu einem Shop, in Metern.
    /// Gibt `nil` zurück, solange kein Standort bekannt ist.
    func distance(to shop: Barbershop) -> Double? {
        guard let userLocation else { return nil }
        let shopLocation = CLLocation(latitude: shop.latitude, longitude: shop.longitude)
        return userLocation.distance(from: shopLocation)
    }

    // MARK: - CLLocationManagerDelegate
    //
    // Diese drei Funktionen ruft iOS von sich aus auf. Wir rufen sie nie
    // selbst. `nonisolated` ist nötig, weil iOS sie nicht garantiert auf
    // dem Haupt-Thread aufruft — deshalb springen wir mit `Task { @MainActor }`
    // zurück, bevor wir unsere Werte ändern.

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            // Direkt nach der Zustimmung gleich einmal messen.
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.requestLocation()
            }
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let latest = locations.last else { return }
        Task { @MainActor in
            self.userLocation = latest
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        // Kein Drama: Ohne Standort funktioniert die App weiter,
        // es fehlen dann nur die Entfernungsangaben.
        print("Standort konnte nicht ermittelt werden: \(error.localizedDescription)")
    }
}
