import Foundation

/// Ein Eintrag in der Tagesleiste des Friseurs.
///
/// Drei Arten, und die dritte ist die interessante: Nicht nur Termine
/// und Sperren stehen dort, sondern auch die LÜCKEN dazwischen. Sonst
/// müsste man aus dem Abstand zweier Kacheln erraten, ob dazwischen
/// noch etwas hineinpasst.
///
/// Genau in diese Lücken trägt der Friseur die Laufkundschaft ein.
struct DayEntry: Identifiable, Hashable {

    enum Kind: Hashable {
        case booking(Booking)
        case blocked(TimeBlock)
        case free
    }

    let kind: Kind
    let startsAt: Date
    let endsAt: Date

    /// Stabil über das Neuzeichnen hinweg.
    ///
    /// Wichtig bei freien Lücken: Mit einer frisch erzeugten `UUID()`
    /// hielte SwiftUI jede Lücke bei jedem Neuzeichnen für eine andere
    /// und würde die Liste unnötig neu aufbauen. Die Startzeit ist
    /// innerhalb eines Tages eindeutig genug.
    var id: String {
        switch kind {
        case .booking(let booking): return "booking-\(booking.id)"
        case .blocked(let block):   return "block-\(block.id)"
        case .free:                 return "free-\(startsAt.timeIntervalSince1970)"
        }
    }

    var durationMinutes: Int {
        Int(endsAt.timeIntervalSince(startsAt) / 60)
    }

    /// "09:00 – 10:00"
    var timeRangeText: String {
        AvailabilityText.timeText(for: startsAt)
            + " – "
            + AvailabilityText.timeText(for: endsAt)
    }
}

/// Baut aus Öffnungszeiten, Terminen und Sperren den Tagesplan.
///
/// Eigener Typ mit statischen Funktionen, kein Code in der View —
/// dieselbe Regel wie beim `SlotCalculator`. Tagesgrenzen und
/// überlappende Einträge sind genau die Sorte Fehler, die man auf dem
/// Bildschirm erst bemerkt, wenn ein Kunde davorsteht.
enum DaySchedule {

    /// Alles, was an diesem Tag ansteht — lückenlos von der Öffnung
    /// bis zum Feierabend.
    ///
    /// Ist der Laden an dem Tag zu, kommt eine leere Liste zurück.
    ///
    /// - Parameter minimumFreeMinutes: Kürzere Lücken werden
    ///   verschluckt. Ohne das stünden zwischen zwei Terminen
    ///   Fünf-Minuten-Reste, in die ohnehin nichts passt.
    static func entries(
        for day: Date,
        shop: Barbershop,
        bookings: [Booking],
        blocks: [TimeBlock] = [],
        calendar: Calendar = .current,
        minimumFreeMinutes: Int = 15
    ) -> [DayEntry] {

        guard let window = openingWindow(for: day, shop: shop, calendar: calendar) else {
            return []
        }

        // Abgesagte Termine belegen nichts mehr — die Zeit ist wieder
        // frei und soll auch so aussehen.
        let occupied: [DayEntry] =
            bookings
                .filter { !$0.isCancelled && calendar.isDate($0.startsAt, inSameDayAs: day) }
                .map { DayEntry(kind: .booking($0), startsAt: $0.startsAt, endsAt: $0.endsAt) }
            + blocks
                .filter { calendar.isDate($0.startsAt, inSameDayAs: day) }
                .map { DayEntry(kind: .blocked($0), startsAt: $0.startsAt, endsAt: $0.endsAt) }

        let sorted = occupied.sorted { $0.startsAt < $1.startsAt }

        var result: [DayEntry] = []
        var cursor = window.opens

        for entry in sorted {
            appendFreeGap(from: cursor, to: entry.startsAt,
                          minimumMinutes: minimumFreeMinutes, into: &result)
            result.append(entry)

            // `max`, weil sich Einträge überlappen können — etwa wenn
            // eine Urlaubssperre über einem älteren Termin liegt.
            cursor = max(cursor, entry.endsAt)
        }

        appendFreeGap(from: cursor, to: window.closes,
                      minimumMinutes: minimumFreeMinutes, into: &result)

        return result
    }

    /// Von wann bis wann die Tagesleiste reicht.
    ///
    /// Richtet sich nach den Öffnungszeiten und nicht nach 0–24 Uhr:
    /// Sonst wäre der halbe Bildschirm Nacht.
    static func openingWindow(
        for day: Date,
        shop: Barbershop,
        calendar: Calendar = .current
    ) -> (opens: Date, closes: Date)? {

        let weekday = calendar.component(.weekday, from: day)
        guard let hours = shop.openingHour(forWeekday: weekday) else { return nil }

        let midnight = calendar.startOfDay(for: day)
        let opens = midnight.addingTimeInterval(TimeInterval(hours.opensAtMinute * 60))
        let closes = midnight.addingTimeInterval(TimeInterval(hours.closesAtMinute * 60))

        return (opens, closes)
    }

    /// Die vollen Stunden, die links neben der Leiste stehen.
    ///
    /// Öffnet der Laden um 9:30, beginnt die Beschriftung trotzdem bei
    /// 9 — sonst stünde dort eine krumme Zahl.
    static func hourLabels(
        for day: Date,
        shop: Barbershop,
        calendar: Calendar = .current
    ) -> [Int] {
        guard let window = openingWindow(for: day, shop: shop, calendar: calendar) else {
            return []
        }

        let first = calendar.component(.hour, from: window.opens)
        let lastMinute = calendar.component(.hour, from: window.closes) * 60
            + calendar.component(.minute, from: window.closes)

        // Aufrunden, damit die Schlussstunde noch mitkommt.
        let last = lastMinute % 60 == 0 ? lastMinute / 60 : lastMinute / 60 + 1

        guard last >= first else { return [] }
        return Array(first...last)
    }

    // MARK: - Intern

    private static func appendFreeGap(
        from start: Date,
        to end: Date,
        minimumMinutes: Int,
        into result: inout [DayEntry]
    ) {
        let minutes = Int(end.timeIntervalSince(start) / 60)
        guard minutes >= minimumMinutes else { return }

        result.append(DayEntry(kind: .free, startsAt: start, endsAt: end))
    }
}
