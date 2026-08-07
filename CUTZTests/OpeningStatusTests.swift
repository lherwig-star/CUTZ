import XCTest
@testable import CUTZ

/// Tests für den Öffnungsstatus eines Shops.
///
/// Warum hier Tests? Der Status hängt von der aktuellen Uhrzeit ab —
/// genau die Sorte Logik, die man beim Ausprobieren nur zufällig richtig
/// oder falsch sieht, je nachdem wann man gerade hinschaut. Ein Fehler
/// beim Wochentagsrechnen fällt sonst erst am Sonntag auf.
///
/// Ausführen in Xcode mit ⌘U.
final class OpeningStatusTests: XCTestCase {

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return cal
    }

    /// Montag, 10. August 2026 — zur gewünschten Uhrzeit.
    private func monday(hour: Int, minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = 2026
        components.month = 8
        components.day = 10
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)!
    }

    /// Shop mit frei wählbaren Öffnungstagen.
    /// Wochentage nach Apples Zählung: 1 = Sonntag … 7 = Samstag.
    private func makeShop(openingHours: [OpeningHour]) -> Barbershop {
        Barbershop(
            id: UUID(),
            name: "Testshop",
            description: "",
            street: "Teststraße 1",
            postalCode: "34117",
            city: "Kassel",
            latitude: 51.3155,
            longitude: 9.4930,
            phone: nil,
            imageURL: nil,
            priceLevel: 2,
            averageRating: 4.5,
            reviewCount: 10,
            services: [],
            openingHours: openingHours
        )
    }

    // MARK: - Geöffnet

    func testOpenDuringBusinessHours() {
        // Montags 9–18 Uhr, wir fragen um 14 Uhr.
        let shop = makeShop(openingHours: [OpeningHour(weekday: 2, from: 9, to: 18)])

        let status = shop.openingStatus(now: monday(hour: 14), calendar: calendar)

        XCTAssertEqual(status, .open(closesAtMinute: 18 * 60))
        XCTAssertTrue(status.isOpen)
    }

    func testOpenExactlyAtOpeningTime() {
        let shop = makeShop(openingHours: [OpeningHour(weekday: 2, from: 9, to: 18)])

        let status = shop.openingStatus(now: monday(hour: 9), calendar: calendar)

        XCTAssertTrue(status.isOpen, "Punkt 9 Uhr ist bereits geöffnet.")
    }

    func testClosedExactlyAtClosingTime() {
        let shop = makeShop(openingHours: [OpeningHour(weekday: 2, from: 9, to: 18)])

        let status = shop.openingStatus(now: monday(hour: 18), calendar: calendar)

        XCTAssertFalse(status.isOpen, "Punkt 18 Uhr ist Ladenschluss, also zu.")
    }

    // MARK: - Geschlossen

    func testBeforeOpeningSaysOpensToday() {
        // Um 7 Uhr morgens — der Shop öffnet noch heute um 9.
        let shop = makeShop(openingHours: [OpeningHour(weekday: 2, from: 9, to: 18)])

        let status = shop.openingStatus(now: monday(hour: 7), calendar: calendar)

        XCTAssertEqual(
            status,
            .closed(opensInDays: 0, weekday: 2, opensAtMinute: 9 * 60)
        )
    }

    func testAfterClosingSkipsToNextOpenDay() {
        // Offen nur montags und dienstags. Montag 20 Uhr -> morgen wieder.
        let shop = makeShop(openingHours: [
            OpeningHour(weekday: 2, from: 9, to: 18),
            OpeningHour(weekday: 3, from: 10, to: 17),
        ])

        let status = shop.openingStatus(now: monday(hour: 20), calendar: calendar)

        XCTAssertEqual(
            status,
            .closed(opensInDays: 1, weekday: 3, opensAtMinute: 10 * 60),
            "Nach Ladenschluss darf nicht 'öffnet heute' dastehen."
        )
    }

    func testWeekdayWrapsAroundToSunday() {
        // Offen nur sonntags (1). Von Montag aus sind das 6 Tage.
        // Hier zeigt sich, ob die Wochentagsrechnung über das
        // Wochenende hinweg richtig zählt.
        let shop = makeShop(openingHours: [OpeningHour(weekday: 1, from: 11, to: 15)])

        let status = shop.openingStatus(now: monday(hour: 12), calendar: calendar)

        XCTAssertEqual(
            status,
            .closed(opensInDays: 6, weekday: 1, opensAtMinute: 11 * 60)
        )
    }

    func testShopWithoutOpeningHoursIsClosedIndefinitely() {
        let shop = makeShop(openingHours: [])

        let status = shop.openingStatus(now: monday(hour: 12), calendar: calendar)

        XCTAssertEqual(status, .closedIndefinitely)
        XCTAssertFalse(status.isOpen)
    }

    // MARK: - Text

    func testTextWhenOpen() {
        let shop = makeShop(openingHours: [
            OpeningHour(weekday: 2, opensAtMinute: 9 * 60, closesAtMinute: 19 * 60 + 30),
        ])

        let status = shop.openingStatus(now: monday(hour: 14), calendar: calendar)

        XCTAssertEqual(status.text, "Jetzt geöffnet · bis 19:30")
    }

    func testTextSaysTodayAndTomorrow() {
        let shop = makeShop(openingHours: [
            OpeningHour(weekday: 2, from: 9, to: 18),
            OpeningHour(weekday: 3, from: 10, to: 17),
        ])

        let beforeOpening = shop.openingStatus(now: monday(hour: 7), calendar: calendar)
        XCTAssertEqual(beforeOpening.text, "Geschlossen · öffnet heute 09:00")

        let afterClosing = shop.openingStatus(now: monday(hour: 20), calendar: calendar)
        XCTAssertEqual(afterClosing.text, "Geschlossen · öffnet morgen 10:00")
    }
}
