import Foundation

/// Öffnungszeiten für genau einen Wochentag.
///
/// Ein Shop hat also bis zu 7 dieser Einträge. Fehlt ein Wochentag
/// komplett, gilt er als Ruhetag.
struct OpeningHour: Identifiable, Codable, Hashable {

    /// Apples Zählung: 1 = Sonntag, 2 = Montag, … 7 = Samstag.
    ///
    /// Das wirkt erst mal unlogisch, aber genau so zählt `Calendar` in iOS.
    /// Wenn wir uns daran halten, können wir Werte direkt vergleichen,
    /// ohne ständig umzurechnen — das ist eine typische Fehlerquelle.
    var weekday: Int

    /// Öffnung in Minuten seit Mitternacht. 9:00 Uhr = 540.
    ///
    /// Auch hier bewusst eine ganze Zahl statt eines Datums: Öffnungszeiten
    /// sind kein konkreter Zeitpunkt, sondern eine Uhrzeit, die für jeden
    /// Montag gilt. Als Minutenzahl lässt sich damit einfach rechnen.
    var opensAtMinute: Int

    /// Schließung in Minuten seit Mitternacht. 18:30 Uhr = 1110.
    var closesAtMinute: Int

    /// `Identifiable` braucht eine id — der Wochentag ist pro Shop eindeutig.
    var id: Int { weekday }

    /// z. B. "Montag"
    ///
    /// Kommt aus `AvailabilityText` und nicht aus
    /// `Calendar.current.weekdaySymbols`. Letzteres richtet sich nach
    /// der REGION des Geräts: Wer sein iPhone auf "Deutschland" hat,
    /// CUTZ aber im Profil auf Englisch gestellt hat, bekäme mitten im
    /// englischen Text "Montag" zu lesen.
    var weekdayName: String {
        // Der Array-Index beginnt bei 0, unser `weekday` bei 1 — daher das -1.
        let names = AvailabilityText.longWeekdayNames
        let index = weekday - 1
        guard names.indices.contains(index) else { return "" }
        return names[index]
    }

    /// z. B. "09:00 – 18:30"
    var rangeFormatted: String {
        "\(Self.timeString(fromMinute: opensAtMinute)) – \(Self.timeString(fromMinute: closesAtMinute))"
    }

    /// Rechnet 540 in "09:00" um.
    static func timeString(fromMinute minute: Int) -> String {
        let hours = minute / 60
        let minutes = minute % 60
        // "%02d" heißt: immer zweistellig, notfalls mit führender Null.
        return String(format: "%02d:%02d", hours, minutes)
    }

    /// Kleiner Helfer zum Anlegen von Testdaten:
    /// `OpeningHour(weekday: 2, from: 9, to: 18)`
    init(weekday: Int, from openHour: Int, to closeHour: Int) {
        self.weekday = weekday
        self.opensAtMinute = openHour * 60
        self.closesAtMinute = closeHour * 60
    }

    init(weekday: Int, opensAtMinute: Int, closesAtMinute: Int) {
        self.weekday = weekday
        self.opensAtMinute = opensAtMinute
        self.closesAtMinute = closesAtMinute
    }
}
