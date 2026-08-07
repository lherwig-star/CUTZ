import XCTest
@testable import CUTZ

/// Tests für Filter und Sortierung der Barber-Liste.
///
/// Warum hier Tests? Weil eine gefilterte Liste immer plausibel aussieht.
/// Fehlt versehentlich ein Laden, merkt das beim Durchklicken niemand —
/// man sieht ja eine Liste, nur eben die falsche.
///
/// Ausführen in Xcode mit ⌘U.
final class BarberFilteringTests: XCTestCase {

    private let calendar = Calendar.current

    /// Fester Bezugspunkt, damit die Zeitfilter reproduzierbar sind.
    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 8, day: 10, hour: 12))!
    }

    private func day(_ offset: Int, hour: Int = 10) -> Date {
        let base = calendar.date(byAdding: .day, value: offset, to: now)!
        return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: base)!
    }

    private func makeShop(
        name: String,
        rating: Double,
        reviewCount: Int = 50,
        priceCents: Int,
        category: ServiceCategory = .haircut
    ) -> Barbershop {
        Barbershop(
            id: UUID(),
            name: name,
            description: "",
            street: "Teststraße 1",
            postalCode: "34117",
            city: "Kassel",
            latitude: 51.3155,
            longitude: 9.4930,
            phone: nil,
            imageURL: nil,
            priceLevel: 2,
            averageRating: rating,
            reviewCount: reviewCount,
            services: [
                BarberService(id: UUID(), name: "Test", durationMinutes: 30,
                              priceCents: priceCents, category: category)
            ],
            openingHours: MockData.standardHours
        )
    }

    // MARK: - Ohne Filter

    func testEmptyFilterKeepsEverything() {
        let shops = [
            makeShop(name: "A", rating: 4.0, priceCents: 2000),
            makeShop(name: "B", rating: 4.5, priceCents: 3000)
        ]

        let result = BarberFiltering.apply(
            to: shops, filter: .none, nextSlots: [:], distances: [:], now: now, calendar: calendar
        )

        XCTAssertEqual(result.count, 2)
    }

    func testActiveCountIgnoresSorting() {
        var filter = BarberFilter.none
        filter.sort = .price

        XCTAssertEqual(
            filter.activeCount, 0,
            "Sortieren schränkt nichts ein und darf nicht als aktiver Filter zählen."
        )

        filter.minRating = 4.5
        XCTAssertEqual(filter.activeCount, 1)
    }

    // MARK: - Sofort verfügbar

    func testAvailableNowKeepsOnlyShopsWithinTheWindow() {
        let soon = makeShop(name: "Gleich", rating: 4.0, priceCents: 2000)
        let later = makeShop(name: "Spaeter heute", rating: 4.0, priceCents: 2000)

        var filter = BarberFilter.none
        filter.onlyAvailableNow = true

        let result = BarberFiltering.apply(
            to: [soon, later],
            filter: filter,
            nextSlots: [
                // 12:00 ist "jetzt" — in 90 Minuten liegt im Fenster.
                soon.id: now.addingTimeInterval(90 * 60),
                // Sechs Stunden später ist heute, aber nicht sofort.
                later.id: now.addingTimeInterval(6 * 3600)
            ],
            distances: [:],
            now: now, calendar: calendar
        )

        XCTAssertEqual(result.map(\.name), ["Gleich"])
    }

    func testAvailableNowIncludesTheExactBoundary() {
        // Genau am Rand des Fensters muss noch durchkommen — sonst wäre
        // es Zufall, ob ein Termin sichtbar ist oder nicht.
        let shop = makeShop(name: "Genau", rating: 4.0, priceCents: 2000)
        let window = TimeInterval(BarberFilter.instantWindowMinutes * 60)

        var filter = BarberFilter.none
        filter.onlyAvailableNow = true

        let result = BarberFiltering.apply(
            to: [shop], filter: filter,
            nextSlots: [shop.id: now.addingTimeInterval(window)],
            distances: [:], now: now, calendar: calendar
        )

        XCTAssertEqual(result.count, 1)
    }

    func testAvailableNowDropsShopsWithoutKnownSlot() {
        let shop = makeShop(name: "Unbekannt", rating: 4.0, priceCents: 2000)

        var filter = BarberFilter.none
        filter.onlyAvailableNow = true

        let result = BarberFiltering.apply(
            to: [shop], filter: filter, nextSlots: [:], distances: [:],
            now: now, calendar: calendar
        )

        XCTAssertTrue(
            result.isEmpty,
            "Ohne bekannten Termin kann man auch nicht sofort drankommen."
        )
    }

    func testAvailableNowCountsAsActiveFilter() {
        var filter = BarberFilter.none
        XCTAssertEqual(filter.activeCount, 0)

        filter.onlyAvailableNow = true
        XCTAssertEqual(filter.activeCount, 1)
    }

    // MARK: - Zeitpunkt

    func testTimingTodayKeepsOnlyShopsWithASlotToday() {
        let today = makeShop(name: "Heute", rating: 4.0, priceCents: 2000)
        let tomorrow = makeShop(name: "Morgen", rating: 4.0, priceCents: 2000)

        var filter = BarberFilter.none
        filter.timing = .today

        let result = BarberFiltering.apply(
            to: [today, tomorrow],
            filter: filter,
            nextSlots: [today.id: day(0, hour: 18), tomorrow.id: day(1)],
            distances: [:],
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(result.map(\.name), ["Heute"])
    }

    func testTimingTomorrowAlsoIncludesToday() {
        // "Morgen" heißt "bis morgen" — wer morgen einen Termin will,
        // nimmt heute erst recht.
        let today = makeShop(name: "Heute", rating: 4.0, priceCents: 2000)
        let tomorrow = makeShop(name: "Morgen", rating: 4.0, priceCents: 2000)
        let later = makeShop(name: "Spaeter", rating: 4.0, priceCents: 2000)

        var filter = BarberFilter.none
        filter.timing = .tomorrow

        let result = BarberFiltering.apply(
            to: [today, tomorrow, later],
            filter: filter,
            nextSlots: [
                today.id: day(0, hour: 18),
                tomorrow.id: day(1),
                later.id: day(5)
            ],
            distances: [:],
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(Set(result.map(\.name)), ["Heute", "Morgen"])
    }

    func testShopWithoutSlotIsDroppedWhenFilteringByTime() {
        let known = makeShop(name: "Bekannt", rating: 4.0, priceCents: 2000)
        let unknown = makeShop(name: "Unbekannt", rating: 4.0, priceCents: 2000)

        var filter = BarberFilter.none
        filter.timing = .thisWeek

        let result = BarberFiltering.apply(
            to: [known, unknown],
            filter: filter,
            nextSlots: [known.id: day(2)],
            distances: [:],
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(result.map(\.name), ["Bekannt"])
    }

    // MARK: - Entfernung

    func testDistanceFilter() {
        let near = makeShop(name: "Nah", rating: 4.0, priceCents: 2000)
        let far = makeShop(name: "Weit", rating: 4.0, priceCents: 2000)

        var filter = BarberFilter.none
        filter.maxDistanceKm = 3

        let result = BarberFiltering.apply(
            to: [near, far],
            filter: filter,
            nextSlots: [:],
            distances: [near.id: 800, far.id: 9000],
            now: now, calendar: calendar
        )

        XCTAssertEqual(result.map(\.name), ["Nah"])
    }

    func testDistanceFilterKeepsShopsWithUnknownDistance() {
        // Ohne Standortfreigabe kennen wir keine Entfernung. Dann darf
        // die Liste nicht plötzlich leer sein.
        let shop = makeShop(name: "Ohne Standort", rating: 4.0, priceCents: 2000)

        var filter = BarberFilter.none
        filter.maxDistanceKm = 1

        let result = BarberFiltering.apply(
            to: [shop], filter: filter, nextSlots: [:], distances: [:],
            now: now, calendar: calendar
        )

        XCTAssertEqual(
            result.count, 1,
            "Ohne bekannte Entfernung darf nicht ausgesiebt werden."
        )
    }

    // MARK: - Preis, Bewertung, Kategorie

    func testPriceFilterUsesCheapestService() {
        let cheap = makeShop(name: "Guenstig", rating: 4.0, priceCents: 1800)
        let pricey = makeShop(name: "Teuer", rating: 4.0, priceCents: 5900)

        var filter = BarberFilter.none
        filter.maxPriceEuro = 30

        let result = BarberFiltering.apply(
            to: [cheap, pricey], filter: filter, nextSlots: [:], distances: [:],
            now: now, calendar: calendar
        )

        XCTAssertEqual(result.map(\.name), ["Guenstig"])
    }

    func testRatingFilter() {
        let good = makeShop(name: "Gut", rating: 4.8, priceCents: 2000)
        let okay = makeShop(name: "Okay", rating: 4.1, priceCents: 2000)

        var filter = BarberFilter.none
        filter.minRating = 4.5

        let result = BarberFiltering.apply(
            to: [good, okay], filter: filter, nextSlots: [:], distances: [:],
            now: now, calendar: calendar
        )

        XCTAssertEqual(result.map(\.name), ["Gut"])
    }

    func testCategoryFilterMatchesIfAnyCategoryFits() {
        let fade = makeShop(name: "Fade", rating: 4.0, priceCents: 2000, category: .skinFade)
        let beard = makeShop(name: "Beard", rating: 4.0, priceCents: 2000, category: .beard)

        var filter = BarberFilter.none
        filter.categories = [.skinFade]

        let result = BarberFiltering.apply(
            to: [fade, beard], filter: filter, nextSlots: [:], distances: [:],
            now: now, calendar: calendar
        )

        XCTAssertEqual(result.map(\.name), ["Fade"])
    }

    // MARK: - Sortierung

    func testSortByPrice() {
        let a = makeShop(name: "A", rating: 4.0, priceCents: 3000)
        let b = makeShop(name: "B", rating: 4.0, priceCents: 1800)
        let c = makeShop(name: "C", rating: 4.0, priceCents: 2400)

        var filter = BarberFilter.none
        filter.sort = .price

        let result = BarberFiltering.apply(
            to: [a, b, c], filter: filter, nextSlots: [:], distances: [:],
            now: now, calendar: calendar
        )

        XCTAssertEqual(result.map(\.name), ["B", "C", "A"])
    }

    func testSortByRatingUsesReviewCountAsTiebreaker() {
        let few = makeShop(name: "Wenige", rating: 4.8, reviewCount: 3, priceCents: 2000)
        let many = makeShop(name: "Viele", rating: 4.8, reviewCount: 200, priceCents: 2000)

        var filter = BarberFilter.none
        filter.sort = .rating

        let result = BarberFiltering.apply(
            to: [few, many], filter: filter, nextSlots: [:], distances: [:],
            now: now, calendar: calendar
        )

        XCTAssertEqual(
            result.map(\.name), ["Viele", "Wenige"],
            "Bei gleicher Note zählt, wie viele bewertet haben."
        )
    }

    func testSortByDistancePutsUnknownDistancesLast() {
        let near = makeShop(name: "Nah", rating: 4.0, priceCents: 2000)
        let unknown = makeShop(name: "Unbekannt", rating: 4.0, priceCents: 2000)
        let far = makeShop(name: "Weit", rating: 4.0, priceCents: 2000)

        var filter = BarberFilter.none
        filter.sort = .distance

        let result = BarberFiltering.apply(
            to: [unknown, far, near],
            filter: filter,
            nextSlots: [:],
            distances: [near.id: 300, far.id: 4000],
            now: now, calendar: calendar
        )

        XCTAssertEqual(result.map(\.name), ["Nah", "Weit", "Unbekannt"])
    }
}
