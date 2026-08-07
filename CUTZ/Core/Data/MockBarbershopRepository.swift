import Foundation

/// Testdaten-Version des Repositories.
///
/// Damit läuft die komplette App, ohne dass Datenbank, Internet oder
/// Login existieren müssen. Das ist Absicht: So können wir Karte, Suche,
/// Profil und Buchung fertig bauen und auf dem iPhone ansehen, bevor
/// überhaupt ein Backend steht.
///
/// `actor` statt `class`: Ein Actor stellt sicher, dass immer nur ein
/// Zugriff gleichzeitig auf die gespeicherten Buchungen passiert. Bei
/// gleichzeitigen Netzwerk-Aufrufen kann es sonst zu schwer auffindbaren
/// Fehlern kommen. Swift erzwingt das für uns.
actor MockBarbershopRepository: BarbershopRepository {

    /// Buchungen werden nur im Arbeitsspeicher gehalten — nach dem
    /// Neustart der App sind sie wieder weg. Für Phase 1 völlig ok.
    private var bookings: [Booking] = []

    private let shops: [Barbershop] = MockData.shops

    /// Künstliche Verzögerung, damit sich die App schon jetzt so anfühlt
    /// wie später mit echtem Netzwerk (Ladeanzeige wird sichtbar).
    private func simulateNetworkDelay() async {
        try? await Task.sleep(for: .milliseconds(400))
    }

    func fetchShops() async throws -> [Barbershop] {
        await simulateNetworkDelay()
        return shops
    }

    func fetchReviews(for shopID: UUID) async throws -> [Review] {
        await simulateNetworkDelay()
        return MockData.reviews
            .filter { $0.shopID == shopID }
            .sorted { $0.createdAt > $1.createdAt }   // neueste zuerst
    }

    func availableSlots(
        shop: Barbershop,
        service: BarberService,
        on day: Date
    ) async throws -> [Date] {
        await simulateNetworkDelay()

        // Schon vergebene Termine dieses Shops berücksichtigen.
        //
        // Abgesagte Termine zählen hier bewusst NICHT mit — sonst bliebe
        // die Zeit für immer blockiert, obwohl sie wieder frei ist.
        let booked = bookings
            .filter { $0.shopID == shop.id && $0.status == .confirmed }
            .map { (start: $0.startsAt, durationMinutes: $0.durationMinutes) }

        return SlotCalculator.slots(
            for: shop,
            service: service,
            on: day,
            bookedSlots: booked
        )
    }

    func createBooking(
        shop: Barbershop,
        service: BarberService,
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
            startsAt: startsAt,
            durationMinutes: service.durationMinutes
        )

        bookings.append(booking)
        return booking
    }

    func fetchBookings() async throws -> [Booking] {
        await simulateNetworkDelay()
        return bookings.sorted { $0.startsAt < $1.startsAt }
    }

    func cancelBooking(_ booking: Booking) async throws {
        await simulateNetworkDelay()

        guard let index = bookings.firstIndex(where: { $0.id == booking.id }) else {
            throw RepositoryError.bookingNotFound
        }

        bookings[index].status = .cancelled
    }
}
