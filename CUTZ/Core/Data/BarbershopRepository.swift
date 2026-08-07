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

    /// Für jeden Shop der nächstmögliche freie Termin.
    ///
    /// Warum alle auf einmal statt einzeln pro Shop? Weil die Angabe
    /// schon in der Liste stehen soll ("Heute 18:30 verfügbar"). Bei
    /// einem Aufruf pro Shop wären das fünf Anfragen fürs Anzeigen einer
    /// einzigen Liste — später über echtes Netzwerk spürbar langsam.
    ///
    /// Das Ergebnis bildet Shop-ID auf Zeitpunkt ab. Shops ohne freien
    /// Termin in den nächsten zwei Wochen fehlen schlicht.
    func nextAvailableSlots() async throws -> [UUID: Date]

    /// Einen Termin verbindlich buchen.
    ///
    /// `employee` darf `nil` sein — dann hat der Nutzer "egal welcher
    /// Barber" gewählt und nimmt den schnellsten Termin.
    func createBooking(
        shop: Barbershop,
        service: BarberService,
        employee: BarberEmployee?,
        startsAt: Date
    ) async throws -> Booking

    /// Die eigenen Termine laden.
    func fetchBookings() async throws -> [Booking]

    /// Einen Termin absagen.
    ///
    /// Der Termin wird NICHT gelöscht, sondern nur auf `cancelled`
    /// gesetzt. Gründe: Der Nutzer soll noch sehen, dass es ihn gab,
    /// und der Friseur später ebenfalls. Löschen wäre nicht rückgängig
    /// zu machen.
    func cancelBooking(_ booking: Booking) async throws
}

/// Fehler, die beim Zugriff auf die Daten auftreten können.
///
/// `LocalizedError` sorgt dafür, dass `error.localizedDescription`
/// unseren Text liefert — sonst stünde dort eine kryptische Meldung.
enum RepositoryError: LocalizedError {

    case bookingNotFound

    var errorDescription: String? {
        switch self {
        case .bookingNotFound:
            return "Dieser Termin existiert nicht mehr."
        }
    }
}
