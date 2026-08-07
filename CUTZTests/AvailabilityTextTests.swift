import XCTest
@testable import CUTZ

/// Tests für die Verfügbarkeitsangabe auf der Barber-Karte.
///
/// "Heute 18:30" ist die Angabe, wegen der jemand weiterklickt oder
/// eben nicht. Die Tagesgrenzen sind dabei die typische Fehlerquelle:
/// Ein Termin um 23:50 ist noch heute, einer um 00:10 schon morgen.
///
/// Ausführen in Xcode mit ⌘U.
final class AvailabilityTextTests: XCTestCase {

    private let calendar = Calendar.current

    /// Montag, 10. August 2026, 12:00 Uhr — im Kalender des Rechners,
    /// damit Testdaten und Rechnung dieselbe Zeitzone benutzen.
    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 8, day: 10, hour: 12))!
    }

    private func at(dayOffset: Int, hour: Int, minute: Int = 0) -> Date {
        let day = calendar.date(byAdding: .day, value: dayOffset, to: now)!
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)!
    }

    // MARK: - Kurzform

    func testToday() {
        let text = AvailabilityText.short(for: at(dayOffset: 0, hour: 18, minute: 30),
                                          now: now, calendar: calendar)

        XCTAssertEqual(text, "Heute 18:30")
    }

    func testTomorrow() {
        let text = AvailabilityText.short(for: at(dayOffset: 1, hour: 9),
                                          now: now, calendar: calendar)

        XCTAssertEqual(text, "Morgen 09:00")
    }

    func testLateTonightIsStillToday() {
        let text = AvailabilityText.short(for: at(dayOffset: 0, hour: 23, minute: 50),
                                          now: now, calendar: calendar)

        XCTAssertEqual(text, "Heute 23:50")
    }

    func testJustAfterMidnightIsTomorrow() {
        let text = AvailabilityText.short(for: at(dayOffset: 1, hour: 0, minute: 10),
                                          now: now, calendar: calendar)

        XCTAssertEqual(
            text, "Morgen 00:10",
            "Kurz nach Mitternacht ist der nächste Tag, nicht mehr heute."
        )
    }

    func testWithinTheWeekUsesWeekday() {
        // Drei Tage später: Wochentag statt Datum.
        let text = AvailabilityText.short(for: at(dayOffset: 3, hour: 14),
                                          now: now, calendar: calendar)

        XCTAssertTrue(
            text.hasSuffix(" 14:00"),
            "Die Uhrzeit muss hinten stehen, war: \(text)"
        )
        XCTAssertFalse(text.hasPrefix("Heute"))
        XCTAssertFalse(text.hasPrefix("Morgen"))
        XCTAssertFalse(
            text.contains("."),
            "Innerhalb einer Woche soll der Wochentag stehen, kein Datum. War: \(text)"
        )
    }

    func testBeyondAWeekUsesDate() {
        let text = AvailabilityText.short(for: at(dayOffset: 10, hour: 11),
                                          now: now, calendar: calendar)

        XCTAssertTrue(
            text.contains("."),
            "Ab einer Woche soll ein Datum stehen. War: \(text)"
        )
        XCTAssertTrue(text.hasSuffix(" 11:00"))
    }

    // MARK: - Uhrzeit

    func testTimeIsAlwaysTwoDigits() {
        XCTAssertEqual(
            AvailabilityText.timeText(for: at(dayOffset: 0, hour: 9, minute: 5),
                                      calendar: calendar),
            "09:05",
            "Alle Zeiten sollen gleich breit sein, damit sie untereinander passen."
        )
    }

    // MARK: - Langform

    func testLongFormForToday() {
        let text = AvailabilityText.long(for: at(dayOffset: 0, hour: 14),
                                         now: now, calendar: calendar)

        XCTAssertEqual(text, "Heute · 14:00")
    }

    func testLongFormForLaterDayContainsWeekdayAndTime() {
        let text = AvailabilityText.long(for: at(dayOffset: 4, hour: 16, minute: 30),
                                         now: now, calendar: calendar)

        XCTAssertTrue(text.hasSuffix("· 16:30"), "War: \(text)")
        XCTAssertFalse(text.hasPrefix("Heute"))
    }
}
