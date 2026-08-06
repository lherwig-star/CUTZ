import Foundation
import Observation

/// Die Logik hinter dem Buchungs-Bildschirm.
///
/// ─── Zuständig: Lukas ──────────────────────────────────────
///
/// Warum eine eigene Klasse und nicht alles in der View?
/// Die View soll nur zeigen, wie etwas AUSSIEHT. Was passiert, wenn man
/// auf "Buchen" tippt — Slots laden, Termin anlegen, Kalendereintrag
/// schreiben, Fehler behandeln — steht hier. So bleibt die View kurz
/// und die Logik ist testbar.
@MainActor
@Observable
final class BookingViewModel {

    // MARK: - Auswahl des Nutzers

    var selectedService: BarberService?
    var selectedDay: Date = .now
    var selectedSlot: Date?

    // MARK: - Zustand

    private(set) var availableSlots: [Date] = []
    private(set) var isLoadingSlots = false
    private(set) var isBooking = false

    /// Die fertige Buchung — sobald gesetzt, zeigt die View die Bestätigung.
    private(set) var confirmedBooking: Booking?

    /// Konnte der Termin in den Kalender eingetragen werden?
    private(set) var calendarStatus: CalendarStatus = .notAttempted

    var errorMessage: String?

    enum CalendarStatus {
        case notAttempted
        case added
        case failed(String)
    }

    // MARK: - Abhängigkeiten

    private let shop: Barbershop
    private let repository: BarbershopRepository

    init(shop: Barbershop, repository: BarbershopRepository) {
        self.shop = shop
        self.repository = repository
        // Die erste Leistung ist vorausgewählt, damit der Nutzer
        // sofort Zeiten sieht, statt vor einer leeren Liste zu stehen.
        self.selectedService = shop.services.first
    }

    // MARK: - Aktionen

    /// Lädt die freien Zeiten für die aktuelle Auswahl.
    func loadSlots() async {
        guard let selectedService else {
            availableSlots = []
            return
        }

        isLoadingSlots = true
        selectedSlot = nil          // alte Auswahl verwerfen
        errorMessage = nil

        do {
            availableSlots = try await repository.availableSlots(
                shop: shop,
                service: selectedService,
                on: selectedDay
            )
        } catch {
            availableSlots = []
            errorMessage = "Freie Zeiten konnten nicht geladen werden: \(error.localizedDescription)"
        }

        isLoadingSlots = false
    }

    /// Bucht den gewählten Termin und trägt ihn in den Kalender ein.
    func confirmBooking() async {
        guard let selectedService, let selectedSlot else { return }

        isBooking = true
        errorMessage = nil

        do {
            let booking = try await repository.createBooking(
                shop: shop,
                service: selectedService,
                startsAt: selectedSlot
            )
            confirmedBooking = booking

            // Kalendereintrag ist ein EXTRA, kein Muss.
            // Schlägt er fehl (z. B. Erlaubnis verweigert), bleibt die
            // Buchung trotzdem gültig — wir sagen es nur dazu.
            do {
                try await CalendarService.addToCalendar(booking)
                calendarStatus = .added
            } catch {
                calendarStatus = .failed(error.localizedDescription)
            }

        } catch {
            errorMessage = "Die Buchung hat nicht geklappt: \(error.localizedDescription)"
        }

        isBooking = false
    }

    // MARK: - Abgeleitete Werte für die View

    /// Kann der Buchen-Button gedrückt werden?
    var canConfirm: Bool {
        selectedService != nil && selectedSlot != nil && !isBooking
    }

    /// Die nächsten 14 Tage zur Auswahl.
    var selectableDays: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        return (0..<14).compactMap {
            calendar.date(byAdding: .day, value: $0, to: today)
        }
    }
}
