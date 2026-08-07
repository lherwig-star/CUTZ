import XCTest
@testable import CUTZ

/// Tests fürs Absagen von Terminen.
///
/// Der wichtigste Test hier ist `testCancelledBookingFreesUpTheSlot`:
/// Bliebe die Zeit nach einer Absage blockiert, könnte niemand sie neu
/// buchen — und man würde es der App nicht ansehen, weil einfach nur
/// ein Termin weniger in der Liste steht.
///
/// Ausführen in Xcode mit ⌘U.
final class BookingCancellationTests: XCTestCase {

    // Hier bewusst `Calendar.current` statt eines festen Berlin-Kalenders.
    //
    // Grund: `MockBarbershopRepository` reicht keinen Kalender an den
    // `SlotCalculator` durch, benutzt also ebenfalls `Calendar.current`.
    // Rechnete der Test mit einer anderen Zeitzone, lägen Testtag und
    // Berechnung auf verschiedenen Kalendertagen — auf dem GitHub-Rechner
    // (UTC) wäre unser "Montag" plötzlich ein Sonntag, und der Shop hätte
    // geschlossen.
    private let calendar = Calendar.current

    /// Ein Tag weit in der Zukunft, damit die Termine nicht als
    /// "vergangen" herausgefiltert werden.
    private func futureDay() -> Date {
        var components = DateComponents()
        components.year = 2027
        components.month = 8
        components.day = 9
        return calendar.date(from: components)!
    }

    /// Der Wochentag unseres Testtages — im selben Kalender gerechnet,
    /// den auch das Repository verwendet.
    private var testWeekday: Int {
        calendar.component(.weekday, from: futureDay())
    }

    private func makeShop() -> Barbershop {
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
            services: [service],
            // Der Shop hat genau an dem Wochentag offen, auf den unser
            // Testtag fällt — egal in welcher Zeitzone der Rechner steht.
            openingHours: [OpeningHour(weekday: testWeekday, from: 9, to: 18)]
        )
    }

    private let service = BarberService(
        id: UUID(),
        name: "Haarschnitt",
        durationMinutes: 30,
        priceCents: 2800
    )

    // MARK: - Modell

    func testNewBookingIsConfirmedByDefault() {
        let booking = Booking(
            id: UUID(),
            shopID: UUID(),
            shopName: "Shop",
            shopAddress: "Adresse",
            serviceID: UUID(),
            serviceName: "Haarschnitt",
            startsAt: futureDay(),
            durationMinutes: 30
        )

        XCTAssertEqual(booking.status, .confirmed)
        XCTAssertFalse(booking.isCancelled)
    }

    // MARK: - Repository

    func testCancelSetsStatusInsteadOfDeleting() async throws {
        let repository = MockBarbershopRepository()
        let shop = makeShop()
        let start = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: futureDay())!

        let booking = try await repository.createBooking(
            shop: shop, service: service, startsAt: start
        )

        try await repository.cancelBooking(booking)

        let all = try await repository.fetchBookings()
        XCTAssertEqual(all.count, 1, "Der Termin darf nicht verschwinden.")
        XCTAssertEqual(all.first?.status, .cancelled)
    }

    func testCancellingUnknownBookingThrows() async throws {
        let repository = MockBarbershopRepository()

        let stranger = Booking(
            id: UUID(),
            shopID: UUID(),
            shopName: "Shop",
            shopAddress: "Adresse",
            serviceID: UUID(),
            serviceName: "Haarschnitt",
            startsAt: futureDay(),
            durationMinutes: 30
        )

        do {
            try await repository.cancelBooking(stranger)
            XCTFail("Einen Termin abzusagen, den es nicht gibt, muss fehlschlagen.")
        } catch {
            // Erwartet.
        }
    }

    func testCancelledBookingFreesUpTheSlot() async throws {
        let repository = MockBarbershopRepository()
        let shop = makeShop()
        let start = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: futureDay())!

        // Erst nachsehen, dass es an dem Tag überhaupt Termine gibt.
        // Ohne diese Prüfung wäre eine leere Liste stillschweigend ein
        // bestandener Test — beide Prüfungen unten fragen ja nur, ob eine
        // bestimmte Zeit NICHT enthalten ist.
        let beforeBooking = try await repository.availableSlots(
            shop: shop, service: service, on: futureDay()
        )
        XCTAssertTrue(
            beforeBooking.contains(start),
            "Vorbedingung: 10:00 muss zunächst frei sein."
        )

        let booking = try await repository.createBooking(
            shop: shop, service: service, startsAt: start
        )

        // Solange der Termin steht, ist 10:00 vergeben.
        let whileBooked = try await repository.availableSlots(
            shop: shop, service: service, on: futureDay()
        )
        XCTAssertFalse(
            whileBooked.contains(start),
            "Ein gebuchter Termin muss die Zeit blockieren."
        )

        try await repository.cancelBooking(booking)

        // Nach der Absage muss die Zeit wieder buchbar sein.
        let afterCancel = try await repository.availableSlots(
            shop: shop, service: service, on: futureDay()
        )
        XCTAssertTrue(
            afterCancel.contains(start),
            "Nach einer Absage muss die Zeit wieder frei sein."
        )
    }
}
