import Foundation
import Observation

/// Der Zustand der Friseurseite: der eigene Laden, seine Termine und
/// seine Sperrzeiten.
///
/// ── Warum nicht einfach in `AppModel`? ────────────────────
///
/// `AppModel` gehört beiden Entwicklern und wird von jedem Bildschirm
/// der Kundenseite gelesen. Diese Daten hier braucht nur die
/// Friseurseite, und ein Kunde soll sie gar nicht erst laden.
///
/// Aufgebaut ist die Klasse trotzdem genau wie `AppModel` — dieselben
/// Bausteine, dasselbe Vorgehen. Wer das eine versteht, versteht auch
/// das andere.
@MainActor
@Observable
final class PartnerModel {

    private let repository: ShopRepository
    private let partner: PartnerStore

    /// Der Laden, den dieser Friseur verwaltet.
    private(set) var shop: Barbershop?

    /// Alle Buchungen des Ladens — auch vergangene und abgesagte.
    /// Gefiltert wird dort, wo es gebraucht wird.
    private(set) var bookings: [Booking] = []

    private(set) var timeBlocks: [TimeBlock] = []

    private(set) var isLoading = false
    private(set) var errorMessage: String?

    /// Welcher Tag in der Übersicht und im Kalender gezeigt wird.
    var selectedDay: Date = .now

    init(repository: ShopRepository, partner: PartnerStore) {
        self.repository = repository
        self.partner = partner
    }

    // MARK: - Laden

    func load() async {
        guard let shopID = partner.managedShopID else {
            shop = nil
            bookings = []
            timeBlocks = []
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            shop = try await repository.shop(withID: shopID)
            bookings = try await repository.bookings(forShop: shopID)
            timeBlocks = try await repository.timeBlocks(forShop: shopID)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Abgeleitet

    /// Der Tagesplan für den gerade gewählten Tag.
    ///
    /// Die Rechnung steckt in `DaySchedule` und nicht hier — dort ist
    /// sie ohne Oberfläche prüfbar.
    var entriesForSelectedDay: [DayEntry] {
        guard let shop else { return [] }
        return DaySchedule.entries(
            for: selectedDay,
            shop: shop,
            bookings: bookings,
            blocks: timeBlocks
        )
    }

    /// Die Termine des gewählten Tages, ohne Pausen und freie Lücken.
    var bookingsForSelectedDay: [Booking] {
        let calendar = Calendar.current
        return bookings
            .filter { !$0.isCancelled && calendar.isDate($0.startsAt, inSameDayAs: selectedDay) }
            .sorted { $0.startsAt < $1.startsAt }
    }

    /// Der nächste Termin ab jetzt — die Frage, die ein Friseur am
    /// häufigsten hat.
    func nextBooking(now: Date = .now) -> Booking? {
        bookings
            .filter { !$0.isCancelled && $0.startsAt >= now }
            .min { $0.startsAt < $1.startsAt }
    }

    var customers: [CustomerSummary] {
        CustomerSummary.from(bookings: bookings)
    }

    // MARK: - Ändern

    func cancel(_ booking: Booking) async {
        do {
            try await repository.cancelBooking(id: booking.id)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addTimeBlock(_ block: TimeBlock) async {
        do {
            try await repository.addTimeBlock(block)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeTimeBlock(_ block: TimeBlock) async {
        do {
            try await repository.removeTimeBlock(id: block.id)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Laufkundschaft eintragen.
    func addWalkIn(
        service: BarberService,
        employee: BarberEmployee?,
        customerName: String,
        startsAt: Date
    ) async {
        guard let shop else { return }

        do {
            _ = try await repository.addWalkIn(
                shop: shop,
                service: service,
                employee: employee,
                customerName: customerName,
                startsAt: startsAt
            )
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func save(shop updated: Barbershop) async {
        do {
            try await repository.save(shop: updated)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
