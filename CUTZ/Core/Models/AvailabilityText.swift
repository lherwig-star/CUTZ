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
/// Das richtet sich aber nach der REGION des Geräts, nicht nach der
/// gewählten App-Sprache. Wer sein iPhone auf Deutschland eingestellt
/// hat, CUTZ aber auf Englisch nutzt, bekäme deutsche Wochentage im
/// englischen Text.
///
/// Deshalb liegen die Namen als übersetzbare Texte vor. Vorteil
/// nebenbei: Dieselbe Eingabe ergibt in derselben Sprache immer
/// dieselbe Ausgabe — das lässt sich testen.
enum AvailabilityText {

    /// Kurzform: "Mo", "Di" …  Index 0 = Sonntag, passend zu Apples
    /// Wochentagszählung (1 = Sonntag), von der wir 1 abziehen.
    ///
    /// Die Schlüssel tragen ein Präfix, weil "Mo" allein mehrdeutig
    /// wäre — im Arabischen und Englischen stehen an derselben Stelle
    /// ganz andere Abkürzungen.
    static var shortWeekdayNames: [String] {
        [
            AppText.string("weekday.short.sunday"),
            AppText.string("weekday.short.monday"),
            AppText.string("weekday.short.tuesday"),
            AppText.string("weekday.short.wednesday"),
            AppText.string("weekday.short.thursday"),
            AppText.string("weekday.short.friday"),
            AppText.string("weekday.short.saturday")
        ]
    }

    static var longWeekdayNames: [String] {
        [
            AppText.string("weekday.long.sunday"),
            AppText.string("weekday.long.monday"),
            AppText.string("weekday.long.tuesday"),
            AppText.string("weekday.long.wednesday"),
            AppText.string("weekday.long.thursday"),
            AppText.string("weekday.long.friday"),
            AppText.string("weekday.long.saturday")
        ]
    }

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
            return format("availability.today", time)
        }

        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
           calendar.isDate(date, inSameDayAs: tomorrow) {
            return format("availability.tomorrow", time)
        }

        // Innerhalb der nächsten Woche reicht der Wochentag — "Do 09:30"
        // liest sich schneller als ein Datum.
        if daysBetween(now, date, calendar: calendar) < 7 {
            return format("availability.weekday", shortWeekday(of: date, calendar: calendar), time)
        }

        return format("availability.date", dayAndMonth(of: date, calendar: calendar), time)
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
            return format("availability.long.today", time)
        }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
           calendar.isDate(date, inSameDayAs: tomorrow) {
            return format("availability.long.tomorrow", time)
        }

        return format(
            "availability.long.date",
            longWeekday(of: date, calendar: calendar),
            dayAndMonth(of: date, calendar: calendar),
            time
        )
    }

    /// Nur die Uhrzeit, immer zweistellig: "09:30".
    ///
    /// Zweistellig, damit in einer Terminliste alle Zeiten gleich breit
    /// untereinander stehen.
    static func timeText(for date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", parts.hour ?? 0, parts.minute ?? 0)
    }

    /// "20.08." auf Deutsch, "08/20" auf Englisch.
    ///
    /// Reihenfolge und Trennzeichen stehen in den Sprachdateien —
    /// Tag und Monat werden als %1$@ und %2$@ eingesetzt.
    static func dayAndMonth(of date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.day, .month], from: date)
        let day = String(format: "%02d", parts.day ?? 0)
        let month = String(format: "%02d", parts.month ?? 0)
        return format("date.dayMonth", day, month)
    }

    /// Kurzschreibweise für `AppText.format`.
    ///
    /// Steht hier, weil in diesem Typ ein Dutzend Mal hintereinander
    /// dasselbe eingesetzt wird und `AppText.format(…)` die Zeilen
    /// unnötig lang machen würde.
    private static func format(_ key: String.LocalizationValue, _ arguments: String...) -> String {
        // Die Umwandlung steht ausdrücklich da: `String(format:arguments:)`
        // erwartet [CVarArg], und darauf sollte man sich nicht stillschweigend
        // verlassen.
        String(format: AppText.string(key), arguments: arguments.map { $0 as CVarArg })
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
