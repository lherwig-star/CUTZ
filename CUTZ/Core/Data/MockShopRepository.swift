import Foundation

/// Testdaten für die Friseurseite, solange es kein Backend gibt.
///
/// ── Warum ein voller Tag statt eines leeren ───────────────
///
/// Beim ersten Zugriff auf einen Laden legt die Attrappe dort einen
/// realistischen Tag an: Termine über den Tag verteilt, eine
/// Mittagspause, dazwischen Lücken, am Abend noch etwas frei.
///
/// Ein leerer Kalender würde nichts beweisen. Ob die Tagesleiste
/// taugt, sieht man erst, wenn Termine dicht beieinanderliegen und
/// eine Pause dazwischen sitzt.
///
/// Gefüllt wird für den Laden, der gerade gefragt wird — nicht fest
/// für einen bestimmten. Sonst stünde ein Friseur, der seinen eigenen
/// Laden anmeldet, vor einem leeren Bildschirm.
///
/// ── Warum sie NICHT dieselben Buchungen hat wie die Kundenseite ──
///
/// `MockBarbershopRepository` hat einen eigenen Vorrat. In Phase 2
/// sprechen beide mit derselben Datenbank, dann sieht der Friseur
/// natürlich, was ein Kunde gerade gebucht hat.
///
/// Die zwei Vorräte jetzt zusammenzulegen wäre Arbeit an einer
/// Attrappe, die in Phase 2 ohnehin verschwindet. Wichtig ist nur, es
/// zu wissen: Was man als Kunde bucht, taucht hier nicht auf.
actor MockShopRepository: ShopRepository {

    private var bookingsStore: [Booking] = []
    private var blocksStore: [TimeBlock] = []
    private var shopsStore: [Barbershop] = MockData.shops

    /// Für welche Läden schon Testdaten angelegt wurden.
    private var seededShopIDs: Set<UUID> = []

    /// Künstliche Verzögerung, damit sich die App schon jetzt so
    /// anfühlt wie später mit echtem Netzwerk.
    private func simulateNetworkDelay() async {
        try? await Task.sleep(for: .milliseconds(400))
    }

    // MARK: - Anmelden

    func registerShop(
        name: String,
        street: String,
        postalCode: String,
        city: String,
        phone: String
    ) async throws -> Barbershop {
        await simulateNetworkDelay()

        // Ein frisch angemeldeter Laden bekommt Standard-Öffnungszeiten
        // und drei übliche Leistungen. Sonst stünde der Friseur vor
        // einem Kalender, in dem sich nichts buchen lässt, und müsste
        // erst ein Formular ausfüllen, bevor er überhaupt etwas sieht.
        //
        // Ändern kann er alles unter Profil.
        let shop = Barbershop(
            id: UUID(),
            name: name,
            description: "",
            street: street,
            postalCode: postalCode,
            city: city,
            latitude: 51.3127,
            longitude: 9.4797,
            phone: phone.isEmpty ? nil : phone,
            imageURL: nil,
            priceLevel: 2,
            averageRating: 0,
            reviewCount: 0,
            services: Self.defaultServices(),
            openingHours: MockData.standardHours
        )

        shopsStore.append(shop)
        return shop
    }

    func shop(withID id: UUID) async throws -> Barbershop? {
        await simulateNetworkDelay()
        return shopsStore.first { $0.id == id }
    }

    // MARK: - Lesen

    func bookings(forShop shopID: UUID) async throws -> [Booking] {
        await simulateNetworkDelay()
        seedIfNeeded(shopID: shopID)

        return bookingsStore
            .filter { $0.shopID == shopID }
            .sorted { $0.startsAt < $1.startsAt }
    }

    func timeBlocks(forShop shopID: UUID) async throws -> [TimeBlock] {
        await simulateNetworkDelay()
        seedIfNeeded(shopID: shopID)

        return blocksStore
            .filter { $0.shopID == shopID }
            .sorted { $0.startsAt < $1.startsAt }
    }

    // MARK: - Schreiben

    func addTimeBlock(_ block: TimeBlock) async throws {
        await simulateNetworkDelay()
        blocksStore.append(block)
    }

    func removeTimeBlock(id: UUID) async throws {
        await simulateNetworkDelay()

        guard let index = blocksStore.firstIndex(where: { $0.id == id }) else {
            throw ShopRepositoryError.timeBlockNotFound
        }
        blocksStore.remove(at: index)
    }

    func addWalkIn(
        shop: Barbershop,
        service: BarberService,
        employee: BarberEmployee?,
        customerName: String,
        startsAt: Date
    ) async throws -> Booking {
        await simulateNetworkDelay()

        let booking = Booking(
            id: UUID(),
            shopID: shop.id,
            shopName: shop.name,
            shopAddress: shop.fullAddress,
            serviceID: service.id,
            serviceName: service.name,
            employeeID: employee?.id,
            employeeName: employee?.name,
            customerName: customerName,
            startsAt: startsAt,
            durationMinutes: service.durationMinutes
        )

        bookingsStore.append(booking)
        return booking
    }

    func cancelBooking(id: UUID) async throws {
        await simulateNetworkDelay()

        guard let index = bookingsStore.firstIndex(where: { $0.id == id }) else {
            throw ShopRepositoryError.bookingNotFound
        }
        // Absagen heißt Status ändern, nicht löschen — genau wie auf
        // der Kundenseite. Ein gelöschter Termin wäre nicht mehr
        // nachvollziehbar.
        bookingsStore[index].status = .cancelled
    }

    func save(shop: Barbershop) async throws {
        await simulateNetworkDelay()

        guard let index = shopsStore.firstIndex(where: { $0.id == shop.id }) else {
            throw ShopRepositoryError.shopNotFound
        }
        shopsStore[index] = shop
    }

    // MARK: - Testdaten

    /// Absichtlich NICHT übersetzt.
    ///
    /// Leistungsnamen sind Daten des Ladens, kein Text der App — der
    /// Friseur benennt sie um, wie er will. Würde man sie übersetzen,
    /// hieße dieselbe Leistung je nach Spracheinstellung anders,
    /// obwohl in der Datenbank ein fester Text steht.
    private static func defaultServices() -> [BarberService] {
        [
            BarberService(id: UUID(), name: "Herrenhaarschnitt",
                          durationMinutes: 30, priceCents: 2500, category: .haircut),
            BarberService(id: UUID(), name: "Bart trimmen",
                          durationMinutes: 20, priceCents: 1500, category: .beard),
            BarberService(id: UUID(), name: "Schnitt & Bart",
                          durationMinutes: 60, priceCents: 3800, category: .hairAndBeard)
        ]
    }

    /// Legt für einen Laden einmalig einen realistischen Tag an.
    private func seedIfNeeded(shopID: UUID) {
        guard !seededShopIDs.contains(shopID) else { return }
        seededShopIDs.insert(shopID)

        guard let shop = shopsStore.first(where: { $0.id == shopID }),
              !shop.services.isEmpty else { return }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        // Voller Vormittag, Pause, voller Nachmittag, am Ende frei.
        let plan: [(minute: Int, service: Int, customer: String)] = [
            (9 * 60,       min(2, shop.services.count - 1), "Maximilian Weber"),
            (10 * 60 + 30, 0,                               "Lukas Schmitt"),
            (13 * 60 + 30, min(2, shop.services.count - 1), "David Müller"),
            (15 * 60,      0,                               "Julian Hoffmann"),
            (16 * 60 + 30, 0,                               "Tim Becker")
        ]

        for (index, item) in plan.enumerated() {
            guard let startsAt = calendar.date(byAdding: .minute, value: item.minute, to: today)
            else { continue }

            // Reihum durch das Team, damit nicht alles bei einer Person
            // hängt. Hat der Laden noch niemanden, bleibt es leer.
            let employee = shop.employees.isEmpty
                ? nil
                : shop.employees[index % shop.employees.count]

            bookingsStore.append(
                makeBooking(shop: shop, service: shop.services[item.service],
                            employee: employee, customer: item.customer, startsAt: startsAt)
            )
        }

        // Frühere Besuche, damit die Stammkundenliste nicht leer ist.
        for weeksAgo in 1...4 {
            guard let startsAt = calendar.date(
                byAdding: .day, value: -7 * weeksAgo,
                to: today.addingTimeInterval(TimeInterval(11 * 3600))
            ) else { continue }

            bookingsStore.append(
                makeBooking(shop: shop, service: shop.services[0],
                            employee: shop.employees.first,
                            customer: "Maximilian Weber", startsAt: startsAt)
            )
        }

        // Mittagspause.
        if let start = calendar.date(byAdding: .minute, value: 12 * 60, to: today),
           let end = calendar.date(byAdding: .minute, value: 13 * 60, to: today) {
            blocksStore.append(
                TimeBlock(shopID: shop.id, startsAt: start, endsAt: end, reason: .pause)
            )
        }
    }

    private func makeBooking(
        shop: Barbershop,
        service: BarberService,
        employee: BarberEmployee?,
        customer: String,
        startsAt: Date
    ) -> Booking {
        Booking(
            id: UUID(),
            shopID: shop.id,
            shopName: shop.name,
            shopAddress: shop.fullAddress,
            serviceID: service.id,
            serviceName: service.name,
            employeeID: employee?.id,
            employeeName: employee?.name,
            customerName: customer,
            startsAt: startsAt,
            durationMinutes: service.durationMinutes
        )
    }
}
