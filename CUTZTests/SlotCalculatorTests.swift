import XCTest
@testable import CUTZ

/// Tests für die Terminberechnung.
///
/// Warum ausgerechnet hier Tests? `SlotCalculator` ist die Stelle mit der
/// meisten "unsichtbaren" Logik — Zeiten, Überschneidungen, Ladenschluss.
/// Fehler fallen dort in der Oberfläche kaum auf, führen aber zu
/// Doppelbuchungen. Views testen wir bewusst nicht, die sieht man ja.
///
/// Ausführen in Xcode mit ⌘U.
final class SlotCalculatorTests: XCTestCase {

    // Ein fester Bezugspunkt, damit die Tests morgen noch genauso laufen.
    // Sonst wären sie von der echten Uhrzeit abhängig und würden
    // zufällig mal durchlaufen und mal nicht.
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return cal
    }

    /// Montag, 10. August 2026, 00:00 Uhr
    private func testDay() -> Date {
        var components = DateComponents()
        components.year = 2026
        components.month = 8
        components.day = 10
        return calendar.date(from: components)!
    }

    private func makeShop(openFrom: Int, to closeHour: Int) -> Barbershop {
        Barbershop(
            id: UUID(),
            name: "Testshop",
            description: "",
            street: "Teststraße 1",
            postalCode: "20357",
            city: "Hamburg",
            latitude: 53.55,
            longitude: 9.99,
            phone: nil,
            imageURL: nil,
            priceLevel: 2,
            averageRating: 4.5,
            reviewCount: 10,
            services: [],
            // 2 = Montag
            openingHours: [OpeningHour(weekday: 2, from: openFrom, to: closeHour)]
        )
    }

    private let service = BarberService(
        id: UUID(),
        name: "Haarschnitt",
        durationMinutes: 30,
        priceCents: 2800
    )

    // MARK: - Tests

    func testSlotsAreGeneratedInFifteenMinuteSteps() {
        let shop = makeShop(openFrom: 9, to: 12)

        let slots = SlotCalculator.slots(
            for: shop,
            service: service,
            on: testDay(),
            calendar: calendar,
            // "Jetzt" liegt weit vor dem Testtag, damit nichts wegfällt.
            now: testDay().addingTimeInterval(-86_400)
        )

        // 9:00 bis 12:00, 30-Minuten-Service, 15-Minuten-Raster
        // -> letzter möglicher Start ist 11:30. Also 9:00, 9:15 … 11:30 = 11 Slots.
        XCTAssertEqual(slots.count, 11)

        let first = calendar.dateComponents([.hour, .minute], from: slots.first!)
        XCTAssertEqual(first.hour, 9)
        XCTAssertEqual(first.minute, 0)

        let last = calendar.dateComponents([.hour, .minute], from: slots.last!)
        XCTAssertEqual(last.hour, 11)
        XCTAssertEqual(last.minute, 30)
    }

    func testNoSlotsOnClosedDay() {
        // Shop hat nur montags offen — wir fragen den Dienstag ab.
        let shop = makeShop(openFrom: 9, to: 18)
        let tuesday = calendar.date(byAdding: .day, value: 1, to: testDay())!

        let slots = SlotCalculator.slots(
            for: shop,
            service: service,
            on: tuesday,
            calendar: calendar,
            now: testDay().addingTimeInterval(-86_400)
        )

        XCTAssertTrue(slots.isEmpty, "An einem Ruhetag darf es keine Termine geben.")
    }

    func testServiceMustFitBeforeClosingTime() {
        // Offen 9–10 Uhr, Service dauert 90 Minuten -> passt nie.
        let shop = makeShop(openFrom: 9, to: 10)
        let longService = BarberService(
            id: UUID(), name: "Lang", durationMinutes: 90, priceCents: 5000
        )

        let slots = SlotCalculator.slots(
            for: shop,
            service: longService,
            on: testDay(),
            calendar: calendar,
            now: testDay().addingTimeInterval(-86_400)
        )

        XCTAssertTrue(slots.isEmpty, "Ein Termin darf nicht über den Ladenschluss hinausgehen.")
    }

    func testBookedSlotBlocksOverlappingTimes() {
        let shop = makeShop(openFrom: 9, to: 12)

        // Jemand hat bereits 10:00–10:30 gebucht.
        let bookedStart = calendar.date(
            bySettingHour: 10, minute: 0, second: 0, of: testDay()
        )!

        let slots = SlotCalculator.slots(
            for: shop,
            service: service,
            on: testDay(),
            bookedSlots: [(start: bookedStart, durationMinutes: 30)],
            calendar: calendar,
            now: testDay().addingTimeInterval(-86_400)
        )

        // 9:45, 10:00 und 10:15 überschneiden sich mit 10:00–10:30.
        let blocked = [(9, 45), (10, 0), (10, 15)]
        for (hour, minute) in blocked {
            let exists = slots.contains { slot in
                let c = calendar.dateComponents([.hour, .minute], from: slot)
                return c.hour == hour && c.minute == minute
            }
            XCTAssertFalse(exists, "\(hour):\(minute) überschneidet sich und darf nicht frei sein.")
        }

        // 9:30 endet exakt um 10:00 — das ist erlaubt.
        let nineThirtyExists = slots.contains { slot in
            let c = calendar.dateComponents([.hour, .minute], from: slot)
            return c.hour == 9 && c.minute == 30
        }
        XCTAssertTrue(nineThirtyExists, "Ein Termin, der genau bei Beginn endet, ist erlaubt.")
    }

    func testPastSlotsAreExcluded() {
        let shop = makeShop(openFrom: 9, to: 18)

        // "Jetzt" ist 14:00 am Testtag.
        let now = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: testDay())!

        let slots = SlotCalculator.slots(
            for: shop,
            service: service,
            on: testDay(),
            calendar: calendar,
            now: now
        )

        XCTAssertFalse(slots.isEmpty)
        XCTAssertTrue(
            slots.allSatisfy { $0 > now },
            "Termine in der Vergangenheit dürfen nicht angeboten werden."
        )
    }
}
