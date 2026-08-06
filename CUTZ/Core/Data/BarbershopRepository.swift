import Foundation

/// Die Schnittstelle zu unseren Daten.
///
/// Das ist die wichtigste Datei im Projekt für die spätere Erweiterung.
///
/// Ein `protocol` beschreibt nur, WAS möglich ist — nicht, WOHER die Daten
/// kommen. Aktuell liefert `MockBarbershopRepository` erfundene Testdaten.
/// Später schreiben wir ein `SupabaseBarbershopRepository`, das dieselben
/// Funktionen erfüllt, die Daten aber echt aus dem Internet holt.
///
/// Der Rest der App (Karte, Suche, Profil, Buchung) merkt davon nichts.
/// Wir tauschen an genau einer Stelle in `AppModel` die Zeile aus — fertig.
///
/// `async throws` bedeutet:
///   - `async`  = die Funktion darf dauern (Netzwerk!) und blockiert die
///                Oberfläche nicht. Aufruf immer mit `await`.
///   - `throws` = die Funktion kann fehlschlagen (kein Internet, Server weg).
///                Aufruf dann mit `try`.
protocol BarbershopRepository {

    /// Alle Shops laden.
    func fetchShops() async throws -> [Barbershop]

    /// Bewertungen eines bestimmten Shops laden.
    func fetchReviews(for shopID: UUID) async throws -> [Review]

    /// Freie Termin-Startzeiten an einem bestimmten Tag berechnen.
    func availableSlots(
        shop: Barbershop,
        service: BarberService,
        on day: Date
    ) async throws -> [Date]

    /// Einen Termin verbindlich buchen.
    func createBooking(
        shop: Barbershop,
        service: BarberService,
        startsAt: Date
    ) async throws -> Booking

    /// Die eigenen Termine laden.
    func fetchBookings() async throws -> [Booking]
}
