import Foundation

/// Woher die Friseurseite ihre Daten bekommt und wohin sie schreibt.
///
/// ── Warum ein ZWEITES Protokoll ───────────────────────────
///
/// Naheliegend wäre, die neuen Funktionen an `BarbershopRepository`
/// anzuhängen. Das wäre ein Fehler.
///
/// `BarbershopRepository` ist die Sicht des KUNDEN auf die Welt:
/// Läden suchen, freie Zeiten sehen, buchen. Die Friseurseite tut das
/// Gegenteil — sie sieht fremde Termine, sperrt Zeiten, ändert Preise.
/// Beides in ein Protokoll zu werfen hieße, dass jede Umsetzung
/// Funktionen mitschleppt, die sie nichts angehen.
///
/// Ganz praktisch heißt es in Phase 2 auch: Die Berechtigungen sind
/// völlig verschieden. Ein Kunde darf nur seine eigenen Buchungen
/// sehen, ein Friseur alle seines Ladens. Getrennte Protokolle machen
/// sichtbar, dass das zwei verschiedene Dinge sind.
///
/// ── Was hier bewusst NICHT drinsteht ──────────────────────
///
/// Kein "Stammkunden laden", kein "Tagesplan bauen". Das sind
/// Berechnungen auf den Buchungen und keine Datenquelle — sie stehen
/// in `CustomerSummary` und `DaySchedule` und sind dort ohne Netzwerk
/// prüfbar.
protocol ShopRepository: Sendable {

    /// Einen neuen Laden zur Freigabe anmelden.
    ///
    /// Anmelden darf sich jeder selbst — das ist der Grund, warum sich
    /// das Produkt ohne unser Zutun verbreiten kann. Freigegeben wird
    /// danach von Hand, siehe `PartnerAccountStatus`.
    func registerShop(
        name: String,
        street: String,
        postalCode: String,
        city: String,
        phone: String
    ) async throws -> Barbershop

    /// Der aktuelle Stand eines Ladens.
    ///
    /// Nach dem Speichern also die geänderte Fassung — die Friseurseite
    /// muss sehen, was sie gerade selbst eingetragen hat.
    func shop(withID id: UUID) async throws -> Barbershop?

    /// Alle Buchungen eines Ladens — auch vergangene und abgesagte.
    /// Gefiltert wird in der App, nicht hier.
    func bookings(forShop shopID: UUID) async throws -> [Booking]

    /// Alle Sperrzeiten eines Ladens.
    func timeBlocks(forShop shopID: UUID) async throws -> [TimeBlock]

    func addTimeBlock(_ block: TimeBlock) async throws

    func removeTimeBlock(id: UUID) async throws

    /// Laufkundschaft: jemand steht im Laden und bekommt jetzt einen
    /// Platz. Ohne diese Funktion verkauft die App Zeiten, auf denen
    /// schon jemand sitzt.
    func addWalkIn(
        shop: Barbershop,
        service: BarberService,
        employee: BarberEmployee?,
        customerName: String,
        startsAt: Date
    ) async throws -> Booking

    func cancelBooking(id: UUID) async throws

    /// Geänderte Stammdaten speichern: Name, Beschreibung, Adresse,
    /// Öffnungszeiten, Leistungen.
    func save(shop: Barbershop) async throws
}

/// Fehler, die nur auf der Friseurseite auftreten können.
enum ShopRepositoryError: LocalizedError {
    case bookingNotFound
    case timeBlockNotFound
    case shopNotFound

    var errorDescription: String? {
        switch self {
        case .bookingNotFound:  return AppText.string("Dieser Termin existiert nicht mehr.")
        case .timeBlockNotFound: return AppText.string("Diese Sperrzeit existiert nicht mehr.")
        case .shopNotFound:     return AppText.string("Dieser Laden existiert nicht mehr.")
        }
    }
}
