import XCTest
@testable import CUTZ

/// Tests für die Tagesauswahl im Buchungsablauf.
///
/// Geprüft wird, dass Ruhetage als solche erkannt werden und der Ablauf
/// nicht an einem geschlossenen Tag startet. Beim Durchklicken fiele das
/// nur auf, wenn man zufällig einen Shop mit Ruhetag erwischt.
///
/// `@MainActor` ist nötig, weil `BookingViewModel` selbst so markiert ist —
/// es verändert Werte, an denen die Oberfläche hängt, und das darf in iOS
/// nur der Haupt-Thread.
///
/// Ausführen in Xcode mit ⌘U.
@MainActor
final class BookingViewModelTests: XCTestCase {

    // Wie in den anderen Tests, die über das Repository gehen: derselbe
    // Kalender wie im Betrieb, sonst verschieben sich die Wochentage
    // je nach Zeitzone des Rechners.
    private let calendar = Calendar.current

    private let service = BarberService(
        id: UUID(),
        name: "Haarschnitt",
        durationMinutes: 30,
        priceCents: 2800
    )

    private func makeShop(openWeekdays: [Int]) -> Barbershop {
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
            openingHours: openWeekdays.map { OpeningHour(weekday: $0, from: 9, to: 18) }
        )
    }

    private func makeViewModel(shop: Barbershop) -> BookingViewModel {
        BookingViewModel(shop: shop, repository: MockBarbershopRepository())
    }

    // MARK: - Öffnungstage

    func testOpenDaysContainsOnlyDaysTheShopIsOpen() {
        // Nur montags (2) und mittwochs (4).
        let viewModel = makeViewModel(shop: makeShop(openWeekdays: [2, 4]))

        for day in viewModel.selectableDays {
            let weekday = calendar.component(.weekday, from: day)
            let shouldBeOpen = (weekday == 2 || weekday == 4)

            XCTAssertEqual(
                viewModel.openDays.contains(day), shouldBeOpen,
                "Wochentag \(weekday) wurde falsch eingeordnet."
            )
        }
    }

    func testShopOpenEveryDayHasAllDaysSelectable() {
        let viewModel = makeViewModel(shop: makeShop(openWeekdays: [1, 2, 3, 4, 5, 6, 7]))

        XCTAssertEqual(
            viewModel.openDays.count, viewModel.selectableDays.count,
            "Ist täglich geöffnet, darf kein Tag ausgegraut sein."
        )
    }

    func testShopWithoutOpeningHoursHasNoOpenDays() {
        let viewModel = makeViewModel(shop: makeShop(openWeekdays: []))

        XCTAssertTrue(viewModel.openDays.isEmpty)
    }

    // MARK: - Startauswahl

    func testStartsOnADayTheShopIsActuallyOpen() {
        // Nur samstags (7) offen — irgendwo in den nächsten 14 Tagen
        // liegt garantiert ein Samstag.
        let viewModel = makeViewModel(shop: makeShop(openWeekdays: [7]))

        let weekday = calendar.component(.weekday, from: viewModel.selectedDay)
        XCTAssertEqual(
            weekday, 7,
            "Der Ablauf darf nicht an einem Ruhetag starten."
        )
    }

    // MARK: - Starttag

    func testStartsTomorrowWhenTodayIsAlreadyOver() {
        // Täglich 9–18 Uhr geöffnet, es ist 21 Uhr.
        // Heute geht nichts mehr, also muss morgen dran sein.
        let shop = makeShop(openWeekdays: [1, 2, 3, 4, 5, 6, 7])
        let evening = calendar.date(
            from: DateComponents(year: 2026, month: 8, day: 10, hour: 21)
        )!

        let day = BookingViewModel.firstOpenDay(
            for: shop, calendar: calendar, now: evening
        )

        let expected = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: evening))
        XCTAssertEqual(
            day, expected,
            "Nach Ladenschluss darf der Ablauf nicht auf einem leeren heutigen Tag starten."
        )
    }

    func testStartsTodayWhileTheShopIsStillOpen() {
        let shop = makeShop(openWeekdays: [1, 2, 3, 4, 5, 6, 7])
        let morning = calendar.date(
            from: DateComponents(year: 2026, month: 8, day: 10, hour: 10)
        )!

        let day = BookingViewModel.firstOpenDay(
            for: shop, calendar: calendar, now: morning
        )

        XCTAssertEqual(day, calendar.startOfDay(for: morning))
    }

    func testNoServiceIsPreselected() {
        // Schritt 1 des Ablaufs IST die Wahl der Leistung. Eine
        // Vorauswahl würde so aussehen, als hätte man schon entschieden.
        let viewModel = makeViewModel(shop: makeShop(openWeekdays: [2]))

        XCTAssertNil(viewModel.selectedService)
    }

    // MARK: - Schrittsteuerung

    func testCannotAdvanceWithoutAService() {
        let viewModel = makeViewModel(shop: makeShop(openWeekdays: [2]))

        XCTAssertEqual(viewModel.step, .service)
        XCTAssertFalse(viewModel.canGoForward)
    }

    func testAnyBarberIsAValidChoice() async {
        let shop = makeShop(openWeekdays: [2])
        let viewModel = makeViewModel(shop: shop)
        viewModel.selectedService = shop.services.first

        await viewModel.goForward()

        XCTAssertEqual(viewModel.step, .employee)
        XCTAssertNil(viewModel.selectedEmployee)
        XCTAssertTrue(
            viewModel.canGoForward,
            "\"Egal welcher Barber\" ist eine gültige Wahl, kein fehlender Wert."
        )
    }

    func testCannotAdvanceFromTimeWithoutASlot() async {
        let shop = makeShop(openWeekdays: [2])
        let viewModel = makeViewModel(shop: shop)
        viewModel.selectedService = shop.services.first

        await viewModel.goForward()   // -> employee
        await viewModel.goForward()   // -> time

        XCTAssertEqual(viewModel.step, .time)
        XCTAssertNil(viewModel.selectedSlot)
        XCTAssertFalse(viewModel.canGoForward)
    }

    func testGoBackReturnsToPreviousStep() async {
        let shop = makeShop(openWeekdays: [2])
        let viewModel = makeViewModel(shop: shop)
        viewModel.selectedService = shop.services.first

        await viewModel.goForward()
        viewModel.goBack()

        XCTAssertEqual(viewModel.step, .service)
    }

    func testGoBackOnFirstStepDoesNothing() {
        let viewModel = makeViewModel(shop: makeShop(openWeekdays: [2]))

        viewModel.goBack()

        XCTAssertEqual(viewModel.step, .service, "Vor dem ersten Schritt gibt es nichts.")
    }

    func testJumpOnlyGoesBackwards() async {
        let shop = makeShop(openWeekdays: [2])
        let viewModel = makeViewModel(shop: shop)
        viewModel.selectedService = shop.services.first

        await viewModel.goForward()   // -> employee

        // Vorwärts springen ist nicht erlaubt: Dort fehlen die Angaben.
        viewModel.jump(to: .summary)
        XCTAssertEqual(viewModel.step, .employee)

        // Zurück schon.
        viewModel.jump(to: .service)
        XCTAssertEqual(viewModel.step, .service)
    }

    // MARK: - Begründung für leere Liste

    func testReasonSaysClosedOnADayOff() {
        // Nur montags offen. Wir stellen bewusst auf einen Dienstag.
        let viewModel = makeViewModel(shop: makeShop(openWeekdays: [2]))

        guard let tuesday = viewModel.selectableDays.first(where: {
            calendar.component(.weekday, from: $0) == 3
        }) else {
            return XCTFail("In 14 Tagen muss ein Dienstag vorkommen.")
        }

        viewModel.selectedDay = tuesday

        XCTAssertEqual(
            viewModel.noSlotsReason,
            "Der Shop hat an diesem Tag geschlossen."
        )
    }

    func testReasonSaysFullyBookedOnAnOpenDay() {
        let viewModel = makeViewModel(shop: makeShop(openWeekdays: [2]))

        guard let monday = viewModel.selectableDays.first(where: {
            calendar.component(.weekday, from: $0) == 2
        }) else {
            return XCTFail("In 14 Tagen muss ein Montag vorkommen.")
        }

        viewModel.selectedDay = monday

        XCTAssertEqual(
            viewModel.noSlotsReason,
            "An diesem Tag sind keine Termine mehr frei."
        )
    }
}
