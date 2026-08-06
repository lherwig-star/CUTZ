import Foundation
import CoreLocation

/// Ein Barbershop / Friseursalon.
///
/// Das ist das zentrale Datenmodell der App. Karte, Suchliste und Profil
/// arbeiten alle mit genau diesem Typ.
///
/// - `Identifiable` braucht SwiftUI, um Listen und Karten-Marker
///   auseinanderhalten zu können (dafür ist die `id` da).
/// - `Codable` erlaubt es, den Typ automatisch aus JSON zu lesen —
///   das brauchen wir später, wenn die Daten von Supabase kommen.
struct Barbershop: Identifiable, Codable, Hashable {

    let id: UUID
    var name: String

    /// Kurzer Beschreibungstext, der oben im Profil steht.
    var description: String

    // MARK: - Adresse & Position

    var street: String
    var postalCode: String
    var city: String

    /// Breitengrad (Nord/Süd). In Deutschland ca. 47–55.
    var latitude: Double
    /// Längengrad (Ost/West). In Deutschland ca. 6–15.
    var longitude: Double

    // MARK: - Kontakt & Darstellung

    var phone: String?
    var imageURL: URL?

    /// Preisniveau von 1 bis 3 — wird als €, €€ oder €€€ angezeigt.
    var priceLevel: Int

    // MARK: - Bewertungen
    //
    // Diese beiden Werte rechnen wir NICHT jedes Mal in der App aus.
    // Die Datenbank liefert sie fertig mit (siehe supabase/schema.sql),
    // sonst müssten wir für jede Karte alle Bewertungen laden.

    /// Durchschnitt aller Bewertungen, z. B. 4.6
    var averageRating: Double
    /// Anzahl der abgegebenen Bewertungen
    var reviewCount: Int

    // MARK: - Angebot

    var services: [BarberService]
    var openingHours: [OpeningHour]

    // MARK: - Abgeleitete Werte
    //
    // "computed properties" — sie werden bei jedem Zugriff neu berechnet
    // und nicht gespeichert. Praktisch, um Anzeige-Logik aus den Views
    // herauszuhalten.

    /// Position für MapKit.
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// z. B. "Schanzenstraße 12, 20357 Hamburg"
    var fullAddress: String {
        "\(street), \(postalCode) \(city)"
    }

    /// z. B. "€€"
    var priceLevelText: String {
        String(repeating: "€", count: max(1, min(priceLevel, 3)))
    }

    /// Der günstigste Service — praktisch für "ab 25 €" in der Liste.
    var cheapestService: BarberService? {
        services.min { $0.priceCents < $1.priceCents }
    }

    /// Öffnungszeit für einen bestimmten Wochentag, falls vorhanden.
    /// `weekday` folgt Apples Zählung: 1 = Sonntag, 2 = Montag, … 7 = Samstag.
    func openingHour(forWeekday weekday: Int) -> OpeningHour? {
        openingHours.first { $0.weekday == weekday }
    }
}
