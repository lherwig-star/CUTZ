import Foundation

/// Macht aus einem Zeitpunkt eine kurze Verfügbarkeitsangabe:
/// "Heute 18:30", "Morgen 10:00", "Sa 09:30".
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
enum AvailabilityText {

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

        // Innerhalb der nächsten Woche reicht der Wochentag — "Sa 09:30"
        // liest sich schneller als ein Datum.
        let startOfToday = calendar.startOfDay(for: now)
        let startOfSlot = calendar.startOfDay(for: date)
        let days = calendar.dateComponents([.day], from: startOfToday, to: startOfSlot).day ?? 0

        if days < 7 {
            let weekday = date.formatted(.dateTime.weekday(.abbreviated))
            return "\(weekday) \(time)"
        }

        let day = date.formatted(.dateTime.day().month(.twoDigits))
        return "\(day) \(time)"
    }

    /// Volle Angabe für die Terminübersicht: "Samstag, 8. Aug · 14:00".
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

        let day = date.formatted(.dateTime.weekday(.wide).day().month(.abbreviated))
        return "\(day) · \(time)"
    }

    /// Nur die Uhrzeit, immer zweistellig: "09:30".
    ///
    /// Bewusst nicht `date.formatted(date:.omitted, time:.shortened)` —
    /// das hängt von den Systemeinstellungen ab und liefert je nach
    /// Region auch mal "9:30 AM". In einer Terminliste sollen alle
    /// Zeiten gleich breit untereinander stehen.
    static func timeText(for date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        let hour = parts.hour ?? 0
        let minute = parts.minute ?? 0
        return String(format: "%02d:%02d", hour, minute)
    }
}
