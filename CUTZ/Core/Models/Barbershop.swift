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

    /// Die Barber, die hier arbeiten.
    ///
    /// Vorgabewert leer, damit bestehender Code und Tests weiterlaufen,
    /// die noch keine Mitarbeiter angeben.
    var employees: [BarberEmployee] = []

    /// Beispielarbeiten des Shops. Noch leer — echte Fotos kommen mit
    /// Supabase Storage (Phase 5). Bis dahin zeichnet die App
    /// Platzhalter, siehe `ShopImage`.
    var portfolioImageURLs: [URL] = []

    // MARK: - Abgeleitete Werte
    //
    // "computed properties" — sie werden bei jedem Zugriff neu berechnet
    // und nicht gespeichert. Praktisch, um Anzeige-Logik aus den Views
    // herauszuhalten.

    /// Position für MapKit.
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// z. B. "Königsstraße 42, 34117 Kassel"
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

    /// "ab 25 €" für die Barber-Karte. `nil`, wenn es nichts zu buchen gibt.
    var priceFromText: String? {
        guard let cheapestService else { return nil }
        return "ab \(cheapestService.priceShort)"
    }

    /// Der kürzeste Service.
    ///
    /// Wird gebraucht, um den nächsten freien Termin zu suchen: Je kürzer
    /// die Leistung, desto eher passt sie noch in eine Lücke. Damit ist
    /// die Angabe "frühester Termin" auch wirklich die früheste.
    var shortestService: BarberService? {
        services.min { $0.durationMinutes < $1.durationMinutes }
    }

    /// Welche Arten von Leistungen hier angeboten werden — fürs Filtern.
    var categories: Set<ServiceCategory> {
        Set(services.map(\.category))
    }

    /// Öffnungszeit für einen bestimmten Wochentag, falls vorhanden.
    /// `weekday` folgt Apples Zählung: 1 = Sonntag, 2 = Montag, … 7 = Samstag.
    func openingHour(forWeekday weekday: Int) -> OpeningHour? {
        openingHours.first { $0.weekday == weekday }
    }
}
