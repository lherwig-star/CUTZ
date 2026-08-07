import Foundation

/// Eine buchbare Leistung, z. B. "Herrenhaarschnitt, 30 Min, 28 €".
///
/// Heißt bewusst `BarberService` und nicht nur `Service` — "Service" ist
/// ein sehr allgemeines Wort, das in Apples Frameworks und in unserem
/// eigenen Code (z. B. `CalendarService`) schon anders belegt ist.
struct BarberService: Identifiable, Codable, Hashable {

    let id: UUID
    var name: String

    /// Dauer in Minuten. Bestimmt, wie lang der Termin im Kalender wird
    /// und wie die freien Zeitfenster berechnet werden.
    var durationMinutes: Int

    /// Preis in Cent.
    ///
    /// Warum Cent und nicht `Double`? Kommazahlen sind für Geld gefährlich:
    /// 0.1 + 0.2 ergibt im Computer nicht exakt 0.3. Mit ganzen Cent-Beträgen
    /// kann beim Rechnen nichts verrutschen. Erst bei der Anzeige teilen wir.
    var priceCents: Int

    /// Zu welcher Art Leistung das gehört.
    ///
    /// Der Vorgabewert sorgt dafür, dass bestehender Code weiterläuft,
    /// der die Kategorie gar nicht angibt.
    var category: ServiceCategory = .haircut

    /// z. B. "28,00 €" — mit korrektem deutschen Komma.
    var priceFormatted: String {
        let euros = Double(priceCents) / 100
        // Waehrung bleibt Euro, die Schreibweise folgt der App-Sprache.
        return euros.formatted(.currency(code: "EUR"))
    }

    /// z. B. "30 Min."
    var durationFormatted: String {
        String(format: String(localized: "service.duration"), durationMinutes)
    }

    /// Kurzform ohne Nachkommastellen für Karten: "25 €".
    ///
    /// In der Liste zählt schnelle Erfassbarkeit — "25 €" liest sich
    /// nebenbei, "25,00 €" muss man lesen.
    var priceShort: String {
        String(format: String(localized: "price.short"), priceCents / 100)
    }
}
