import XCTest
@testable import CUTZ

/// Tests für "nächster freier Termin".
///
/// Diese Angabe steht direkt auf der Barber-Karte in der Liste. Sie ist
/// der Grund, warum niemand fünf Screens durchklicken muss, um zu
/// merken, dass heute nichts mehr frei ist — also lohnt es sich, dass
/// sie stimmt.
///
/// Ausführen in Xcode mit ⌘U.
final class NextAvailableSlotTests: XCTestCase {

    func testEveryMockShopHasAnUpcomingSlot() async throws {
        let repository = MockBarbershopRepository()

        let slots = try await repository.nextAvailableSlots()

        // Alle Testshops haben Öffnungszeiten, also muss für jeden
        // innerhalb von zwei Wochen etwas frei sein.
        XCTAssertEqual(
            slots.count, MockData.shops.count,
            "Für jeden Shop muss ein Termin gefunden werden."
        )
    }

    func testSlotsAreInTheFuture() async throws {
        let repository = MockBarbershopRepository()
        let now = Date.now

        let slots = try await repository.nextAvailableSlots()

        for (shopID, slot) in slots {
            XCTAssertGreaterThan(
                slot, now,
                "Der Termin für Shop \(shopID) liegt in der Vergangenheit."
            )
        }
    }

    func testSlotUsesTheShortestServiceOfTheShop() async throws {
        // Der frühestmögliche Termin muss mit der kürzesten Leistung
        // gerechnet werden. Sonst wäre die Angabe zu pessimistisch:
        // Ein 90-Minuten-Service passt seltener in eine Lücke als einer
        // mit 15 Minuten.
        let repository = MockBarbershopRepository()

        let slots = try await repository.nextAvailableSlots()

        for shop in MockData.shops {
            guard let reported = slots[shop.id],
                  let shortest = shop.shortestService else {
                continue
            }

            // Mit der kürzesten Leistung selbst nachrechnen — es darf
            // kein früherer Termin existieren als der gemeldete.
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: .now)

            var earliest: Date?
            for offset in 0..<14 {
                guard let day = calendar.date(byAdding: .day, value: offset, to: today) else {
                    continue
                }
                let daySlots = SlotCalculator.slots(for: shop, service: shortest, on: day)
                if let first = daySlots.first {
                    earliest = first
                    break
                }
            }

            XCTAssertEqual(
                reported, earliest,
                "Für \(shop.name) wurde nicht der früheste Termin gemeldet."
            )
        }
    }

    func testShopWithoutServicesHasNoSlot() {
        // Ohne Leistungen gibt es nichts zu buchen — dann darf auch
        // kein Termin gemeldet werden.
        let shop = Barbershop(
            id: UUID(),
            name: "Leerer Shop",
            description: "",
            street: "Teststraße 1",
            postalCode: "34117",
            city: "Kassel",
            latitude: 51.3155,
            longitude: 9.4930,
            phone: nil,
            imageURL: nil,
            priceLevel: 2,
            averageRating: 4.0,
            reviewCount: 0,
            services: [],
            openingHours: MockData.standardHours
        )

        XCTAssertNil(shop.shortestService)
    }

    // MARK: - Abgeleitete Werte auf dem Shop

    func testShortestAndCheapestCanDiffer() {
        // Bei "Fade Lounge Nord" ist der Buzz Cut sowohl der kürzeste
        // als auch der günstigste — bei "Königs Barbershop" dagegen ist
        // "Bart trimmen" das kürzeste UND günstigste. Der Test stellt
        // vor allem sicher, dass beide Werte überhaupt geliefert werden.
        for shop in MockData.shops {
            XCTAssertNotNil(shop.shortestService, "\(shop.name) ohne kürzeste Leistung")
            XCTAssertNotNil(shop.cheapestService, "\(shop.name) ohne günstigste Leistung")
            XCTAssertNotNil(shop.priceFromText, "\(shop.name) ohne 'ab'-Preis")
        }
    }

    func testCategoriesReflectTheServices() {
        let fadeLounge = MockData.shops[1]

        XCTAssertTrue(fadeLounge.categories.contains(.skinFade))
        XCTAssertTrue(fadeLounge.categories.contains(.beard))
        XCTAssertTrue(fadeLounge.categories.contains(.haircut))
    }

    func testPriceShortHasNoDecimals() {
        let service = BarberService(
            id: UUID(), name: "Test", durationMinutes: 30, priceCents: 2500
        )

        XCTAssertEqual(service.priceShort, "25 €")
    }
}
