import Foundation

/// Ein Stammkunde, wie ihn die Friseurseite anzeigt.
///
/// ── Warum das nichts ist, was man pflegt ──────────────────
///
/// Es gibt keine Kundenkartei, in die jemand Daten einträgt. Alles
/// hier fällt aus den Buchungen ab: Wer wie oft da war, wann zuletzt,
/// was er üblicherweise machen lässt.
///
/// Das ist genau die Information, die heute im Notizbuch hinter der
/// Kasse steht — nur dass sie sich von selbst aktualisiert. Eine
/// Kartei, die man von Hand pflegen muss, pflegt nach drei Wochen
/// niemand mehr.
struct CustomerSummary: Identifiable, Hashable {

    /// Der Name ist gleichzeitig die Kennung.
    ///
    /// Solange es keine Nutzerkonten gibt (Phase 3), haben wir nichts
    /// Besseres. Zwei verschiedene "Tim" landen damit in einem
    /// Eintrag — unschön, aber besser als zwei Einträge für denselben
    /// Menschen, nur weil er einmal als Laufkundschaft eingetragen
    /// wurde.
    var id: String { name }

    let name: String

    /// Wie oft er da war. Abgesagte Termine zählen nicht.
    var visitCount: Int

    /// Der letzte Besuch, der schon stattgefunden hat.
    var lastVisit: Date?

    /// Der nächste Termin, falls einer ansteht.
    var nextVisit: Date?

    /// Was er am häufigsten machen lässt.
    var usualService: String?

    // MARK: - Ableiten

    /// Fasst eine Liste von Buchungen zu Stammkunden zusammen,
    /// sortiert nach dem letzten Besuch — wer zuletzt da war, steht
    /// oben.
    static func from(bookings: [Booking], now: Date = .now) -> [CustomerSummary] {

        // Buchungen ohne Namen können wir niemandem zuordnen. Die
        // entstehen, solange es keine Nutzerkonten gibt.
        let relevant = bookings.filter { !$0.isCancelled && !$0.customerName.isEmpty }

        let byName = Dictionary(grouping: relevant, by: \.customerName)

        let summaries = byName.map { name, entries -> CustomerSummary in
            let past = entries.filter { $0.startsAt <= now }
            let upcoming = entries.filter { $0.startsAt > now }

            return CustomerSummary(
                name: name,
                visitCount: past.count,
                lastVisit: past.map(\.startsAt).max(),
                nextVisit: upcoming.map(\.startsAt).min(),
                usualService: mostFrequentService(in: entries)
            )
        }

        // Wer noch nie da war, aber einen Termin hat, rutscht ans Ende
        // statt zu verschwinden — `Date.distantPast` als Ersatzwert.
        return summaries.sorted {
            ($0.lastVisit ?? .distantPast) > ($1.lastVisit ?? .distantPast)
        }
    }

    /// Die Leistung, die in diesen Buchungen am häufigsten vorkommt.
    ///
    /// Bei Gleichstand entscheidet der Name, damit dieselbe Eingabe
    /// immer dieselbe Ausgabe ergibt. Sonst stünde dort mal das eine,
    /// mal das andere — und in einem Test wäre es nicht prüfbar.
    private static func mostFrequentService(in bookings: [Booking]) -> String? {
        var counts: [String: Int] = [:]
        for booking in bookings {
            counts[booking.serviceName, default: 0] += 1
        }

        return counts
            .sorted { ($0.value, $1.key) > ($1.value, $0.key) }
            .first?
            .key
    }
}
