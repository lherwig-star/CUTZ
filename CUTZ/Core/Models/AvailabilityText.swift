import Foundation

/// Macht aus einem Zeitpunkt eine kurze Verfügbarkeitsangabe:
/// "Heute 18:30", "Morgen 10:00", "Do 09:30".
///
/// Warum eigener Typ und keine Formatierung direkt in der View?
///
/// Diese Angabe ist die wichtigste Information auf der Barber-Karte —
/// sie entscheidet, ob jemand überhaupt weiterklickt. "Heute" ist etwas
/// völlig anderes als "in zwei Wochen", und man erfasst es nur, wenn es
/// so dasteht, wie man selbst denken würde. Ein reines Datum ("12.08.,
/// 18:30") müsste man erst umrechnen.
///
/// Als eigener Typ lässt sich das ohne Oberfläche testen — und Fehler
/// bei Tagesgrenzen fallen sonst nur zufällig auf.
///
/// ── Warum alles von Hand formatiert wird ──────────────────
///
/// Naheliegend wäre `date.formatted(.dateTime.weekday(.abbreviated))`.
/// Das richtet sich aber nach der Spracheinstellung des GERÄTS: Auf
/// einem englisch eingestellten iPhone stünde dann "Thu" und "08/20"
/// mitten im deutschen Text — und im Testlauf auf GitHub fiel genau
/// das auf.
///
/// CUTZ ist eine deutschsprachige App (siehe CLAUDE.md, Locale de_DE).
/// Deshalb schreiben wir die Wochentage selbst hin. Das ist zugleich
/// vorhersagbar: Dieselbe Eingabe ergibt immer dieselbe Ausgabe,
/// unabhängig davon, wo der Code läuft.
enum AvailabilityText {

    /// Kurzform: "Mo", "Di" …  Index 0 = Sonntag, passend zu Apples
    /// Wochentagszählung (1 = Sonntag), von der wir 1 abziehen.
    static let shortWeekdayNames = ["So", "Mo", "Di", "Mi", "Do", "Fr", "Sa"]

    static let longWeekdayNames = [
        "Sonntag", "Montag", "Dienstag", "Mittwoch",
        "Donnerstag", "Freitag", "Samstag"
    ]

    /// Kurzform für Karten und Listen.
    ///
    /// `now` und `calendar` sind Parameter mit Vorgabewert, damit Tests
    /// eine feste Uhrzeit vorgeben können. Genauso macht es der
    /// `SlotCalculator`.
    static func short(
        for date: Date,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> String {
        let time = timeText(for: date, calendar: calendar)

        if calendar.isDate(date, inSameDayAs: now) {
            return "Heute \(time)"
        }

        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
           calendar.isDate(date, inSameDayAs: tomorrow) {
            return "Morgen \(time)"
        }

        // Innerhalb der nächsten Woche reicht der Wochentag — "Do 09:30"
        // liest sich schneller als ein Datum.
        if daysBetween(now, date, calendar: calendar) < 7 {
            return "\(shortWeekday(of: date, calendar: calendar)) \(time)"
        }

        return "\(dayAndMonth(of: date, calendar: calendar)) \(time)"
    }

    /// Volle Angabe für die Terminübersicht:
    /// "Donnerstag, 20.08. · 14:00".
    static func long(
        for date: Date,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> String {
        let time = timeText(for: date, calendar: calendar)

        if calendar.isDate(date, inSameDayAs: now) {
            return "Heute · \(time)"
        }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
           calendar.isDate(date, inSameDayAs: tomorrow) {
            return "Morgen · \(time)"
        }

        let weekday = longWeekday(of: date, calendar: calendar)
        return "\(weekday), \(dayAndMonth(of: date, calendar: calendar)) · \(time)"
    }

    /// Nur die Uhrzeit, immer zweistellig: "09:30".
    ///
    /// Zweistellig, damit in einer Terminliste alle Zeiten gleich breit
    /// untereinander stehen.
    static func timeText(for date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", parts.hour ?? 0, parts.minute ?? 0)
    }

    /// "20.08."
    static func dayAndMonth(of date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.day, .month], from: date)
        return String(format: "%02d.%02d.", parts.day ?? 0, parts.month ?? 0)
    }

    // MARK: - Wochentage

    static func shortWeekday(of date: Date, calendar: Calendar = .current) -> String {
        name(from: shortWeekdayNames, for: date, calendar: calendar)
    }

    static func longWeekday(of date: Date, calendar: Calendar = .current) -> String {
        name(from: longWeekdayNames, for: date, calendar: calendar)
    }

    private static func name(
        from names: [String],
        for date: Date,
        calendar: Calendar
    ) -> String {
        // Apples Zählung beginnt bei 1 (Sonntag), unser Array bei 0.
        let index = calendar.component(.weekday, from: date) - 1
        guard names.indices.contains(index) else { return "" }
        return names[index]
    }

    /// Volle Tage zwischen zwei Zeitpunkten, jeweils ab Mitternacht
    /// gerechnet. Sonst gälten 23:00 und 01:00 als "0 Tage auseinander",
    /// obwohl ein Tageswechsel dazwischenliegt.
    private static func daysBetween(_ from: Date, _ to: Date, calendar: Calendar) -> Int {
        let start = calendar.startOfDay(for: from)
        let end = calendar.startOfDay(for: to)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }
}
