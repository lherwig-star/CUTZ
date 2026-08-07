import XCTest
@testable import CUTZ

/// Tests für den vollständigen Buchungsablauf.
///
/// Geprüft wird der Weg vom ersten Schritt bis zum gebuchten Termin —
/// also genau das, was die App im Kern leisten muss. Ein Fehler auf
/// diesem Weg macht alles andere wertlos.
///
/// Ausführen in Xcode mit ⌘U.
@MainActor
final class BookingFlowTests: XCTestCase {

    private let calendar = Calendar.current

    /// Ein Shop, der jeden Wochentag geöffnet hat — damit der Ablauf
    /// unabhängig davon läuft, welcher Tag beim Testen gerade ist.
    private func makeShop(withEmployees: Bool = true) -> Barbershop {
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
            services: [
                BarberService(id: UUID(), name: "Haircut", durationMinutes: 30,
                              priceCents: 2500, category: .haircut),
                BarberService(id: UUID(), name: "Beard", durationMinutes: 20,
                              priceCents: 1500, category: .beard)
            ],
            openingHours: (1...7).map { OpeningHour(weekday: $0, from: 9, to: 20) },
            employees: withEmployees ? [
                BarberEmployee(id: UUID(), name: "Samir", rating: 4.9,
                               reviewCount: 90, specialties: [.skinFade, .beard])
            ] : []
        )
    }

    private func makeViewModel(
        shop: Barbershop,
        repository: BarbershopRepository = MockBarbershopRepository()
    ) -> BookingViewModel {
        let viewModel = BookingViewModel(shop: shop, repository: repository)
        // WICHTIG: Den echten Kalendereintrag ersetzen. EventKit zeigt
        // einen Erlaubnis-Dialog, den im Testlauf niemand wegklickt —
        // der Test würde ewig hängen statt fehlzuschlagen.
        viewModel.addToCalendar = { _ in }
        return viewModel
    }

    /// Führt bis zur Zeitauswahl und stellt auf MORGEN.
    ///
    /// Warum morgen? Der `SlotCalculator` bietet keine vergangenen
    /// Zeiten an. Bliebe der Test auf heute, hinge sein Ergebnis an der
    /// Uhrzeit des Testlaufs: Um 19 Uhr war noch etwas frei, um 21 Uhr
    /// nichts mehr — genau daran ist dieser Test schon einmal
    /// gescheitert. Morgen liegt immer vollständig in der Zukunft.
    private func advanceToTimeStep(
        _ viewModel: BookingViewModel,
        service: BarberService
    ) async {
        viewModel.selectedService = service
        await viewModel.goForward()   // -> Barber
        await viewModel.goForward()   // -> Termin

        viewModel.selectedDay = calendar.date(byAdding: .day, value: 1, to: .now)!
        await viewModel.loadSlots()
    }

    // MARK: - Der ganze Weg

    func testFullFlowProducesABooking() async {
        let shop = makeShop()
        let viewModel = makeViewModel(shop: shop)

        // Schritt 1: Service
        XCTAssertEqual(viewModel.step, .service)
        viewModel.selectedService = shop.services[0]
        await viewModel.goForward()

        // Schritt 2: Barber
        XCTAssertEqual(viewModel.step, .employee)
        viewModel.selectedEmployee = shop.employees.first
        await viewModel.goForward()

        // Schritt 3: Termin
        XCTAssertEqual(viewModel.step, .time)
        viewModel.selectedDay = calendar.date(byAdding: .day, value: 1, to: .now)!
        await viewModel.loadSlots()

        XCTAssertFalse(
            viewModel.availableSlots.isEmpty,
            "Für morgen muss es freie Zeiten geben."
        )
        viewModel.selectedSlot = viewModel.availableSlots.first
        await viewModel.goForward()

        // Schritt 4: Bestätigen
        XCTAssertEqual(viewModel.step, .summary)
        await viewModel.confirmBooking()

        let booking = viewModel.confirmedBooking
        XCTAssertNotNil(booking, "Am Ende muss ein Termin herauskommen.")
        XCTAssertEqual(booking?.serviceName, "Haircut")
        XCTAssertEqual(booking?.employeeName, "Samir")
        XCTAssertEqual(booking?.status, .confirmed)
        XCTAssertEqual(booking?.durationMinutes, 30)
    }

    func testFlowWithoutChoosingABarber() async {
        let shop = makeShop()
        let viewModel = makeViewModel(shop: shop)

        // Schritt 2 wird einfach übersprungen — "egal welcher Barber".
        await advanceToTimeStep(viewModel, service: shop.services[0])
        viewModel.selectedSlot = viewModel.availableSlots.first
        await viewModel.goForward()
        await viewModel.confirmBooking()

        let booking = viewModel.confirmedBooking
        XCTAssertNotNil(booking)
        XCTAssertNil(booking?.employeeID, "Ohne Wahl darf kein Barber eingetragen sein.")
        XCTAssertNil(booking?.employeeText)
    }

    func testShopWithoutEmployeesStillWorks() async {
        let shop = makeShop(withEmployees: false)
        let viewModel = makeViewModel(shop: shop)

        await advanceToTimeStep(viewModel, service: shop.services[0])
        viewModel.selectedSlot = viewModel.availableSlots.first
        await viewModel.goForward()
        await viewModel.confirmBooking()

        XCTAssertNotNil(
            viewModel.confirmedBooking,
            "Auch ohne hinterlegtes Team muss man buchen können."
        )
    }

    // MARK: - Der gebuchte Termin blockiert die Zeit

    func testBookedSlotIsGoneAfterwards() async {
        let shop = makeShop()
        let repository = MockBarbershopRepository()
        let viewModel = makeViewModel(shop: shop, repository: repository)

        await advanceToTimeStep(viewModel, service: shop.services[0])

        guard let chosen = viewModel.availableSlots.first else {
            return XCTFail("Für morgen muss es freie Zeiten geben.")
        }
        viewModel.selectedSlot = chosen
        await viewModel.goForward()
        await viewModel.confirmBooking()

        // Dieselbe Anfrage nochmal — die gebuchte Zeit darf nicht mehr
        // angeboten werden.
        let after = try? await repository.availableSlots(
            shop: shop, service: shop.services[0], on: viewModel.selectedDay
        )

        XCTAssertNotNil(after)
        XCTAssertFalse(
            after?.contains(chosen) ?? true,
            "Die gebuchte Zeit muss danach belegt sein."
        )
    }

    // MARK: - Preis

    func testTotalPriceFollowsTheChosenService() {
        let shop = makeShop()
        let viewModel = makeViewModel(shop: shop)

        XCTAssertNil(viewModel.totalPriceText, "Ohne Auswahl gibt es keinen Preis.")

        viewModel.selectedService = shop.services[1]   // Beard, 15 €
        XCTAssertEqual(viewModel.totalPriceText, "15 €")
    }

    // MARK: - Zurückspringen verwirft nichts

    func testGoingBackKeepsTheChosenService() async {
        let shop = makeShop()
        let viewModel = makeViewModel(shop: shop)

        viewModel.selectedService = shop.services[0]
        await viewModel.goForward()
        viewModel.goBack()

        XCTAssertEqual(
            viewModel.selectedService?.id, shop.services[0].id,
            "Ein Schritt zurück darf die Auswahl nicht löschen."
        )
    }
}
