import Foundation
import Observation

/// Die Logik hinter dem Buchungsablauf.
///
/// ─── Zuständig: Lukas ──────────────────────────────────────
///
/// Warum eine eigene Klasse und nicht alles in der View?
/// Die View soll nur zeigen, wie etwas AUSSIEHT. Was passiert — Schritt
/// weiterschalten, Slots laden, Termin anlegen, Kalendereintrag schreiben,
/// Fehler behandeln — steht hier. So bleibt die View kurz und die Logik
/// ist testbar.
@MainActor
@Observable
final class BookingViewModel {

    /// Die vier Schritte des Ablaufs.
    ///
    /// Bewusst als Aufzählung und nicht als Zahl: `.employee` sagt beim
    /// Lesen, worum es geht, `2` nicht. Und man kann keinen Schritt
    /// erfinden, den es nicht gibt.
    enum Step: Int, CaseIterable {
        case service
        case employee
        case time
        case summary

        var title: String {
            switch self {
            case .service:  return String(localized: "Was möchtest du?")
            case .employee: return String(localized: "Wer soll dich schneiden?")
            case .time:     return String(localized: "Wann passt es dir?")
            case .summary:  return String(localized: "Passt alles?")
            }
        }
    }

    // MARK: - Zustand des Ablaufs

    private(set) var step: Step = .service

    var selectedService: BarberService?

    /// Der gewünschte Barber. `nil` heißt "egal welcher" — dann zählt
    /// nur, wie schnell man drankommt.
    var selectedEmployee: BarberEmployee?

    var selectedDay: Date = .now
    var selectedSlot: Date?

    // MARK: - Ladezustand

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

    let shop: Barbershop
    private let repository: BarbershopRepository

    /// Trägt den Termin in den Kalender ein. Im Betrieb ist das
    /// `CalendarService.addToCalendar`.
    ///
    /// Warum austauschbar? EventKit zeigt beim ersten Zugriff einen
    /// Erlaubnis-Dialog — und im Testlauf sitzt niemand, der ihn
    /// wegklickt. Der Test würde ewig warten (genau das hat die CI
    /// eine halbe Stunde lang aufgehängt). Tests reichen deshalb eine
    /// leere Funktion herein.
    var addToCalendar: (Booking) async throws -> Void = CalendarService.addToCalendar

    init(shop: Barbershop, repository: BarbershopRepository) {
        self.shop = shop
        self.repository = repository
        // Am ersten Tag starten, an dem der Shop überhaupt öffnet.
        // Sonst landet man an einem Ruhetag und sieht erst mal nichts.
        self.selectedDay = Self.firstOpenDay(for: shop) ?? .now
    }

    // MARK: - Schritte

    /// Darf man vom aktuellen Schritt aus weiter?
    var canGoForward: Bool {
        switch step {
        case .service:  return selectedService != nil
        case .employee: return true          // "egal welcher" ist eine gültige Wahl
        case .time:     return selectedSlot != nil
        case .summary:  return !isBooking
        }
    }

    func goForward() async {
        guard canGoForward, let next = Step(rawValue: step.rawValue + 1) else { return }
        step = next

        // Beim Betreten des Zeit-Schritts gleich Termine laden, damit
        // niemand vor einer leeren Liste sitzt und sich fragt, was fehlt.
        if step == .time {
            await loadSlots()
        }
    }

    func goBack() {
        guard let previous = Step(rawValue: step.rawValue - 1) else { return }
        step = previous
    }

    /// Springt direkt zu einem Schritt — für die Punkte in der Kopfzeile.
    /// Nur rückwärts erlaubt, vorwärts fehlen ja die Angaben.
    func jump(to target: Step) {
        guard target.rawValue < step.rawValue else { return }
        step = target
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
                employee: selectedEmployee,
                startsAt: selectedSlot
            )
            confirmedBooking = booking

            // Kalendereintrag ist ein EXTRA, kein Muss.
            // Schlägt er fehl (z. B. Erlaubnis verweigert), bleibt die
            // Buchung trotzdem gültig — wir sagen es nur dazu.
            do {
                try await addToCalendar(booking)
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

    /// Die nächsten 14 Tage zur Auswahl.
    var selectableDays: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        return (0..<14).compactMap {
            calendar.date(byAdding: .day, value: $0, to: today)
        }
    }

    /// Die Tage aus `selectableDays`, an denen der Shop geöffnet hat.
    ///
    /// Die Tagesauswahl graut alles andere aus. Ohne das tippt man sich
    /// durch Ruhetage und liest jedes Mal nur "keine Termine frei" —
    /// ohne zu erfahren, dass schlicht geschlossen ist.
    var openDays: Set<Date> {
        let calendar = Calendar.current
        var result: Set<Date> = []
        for day in selectableDays {
            let weekday = calendar.component(.weekday, from: day)
            if shop.openingHour(forWeekday: weekday) != nil {
                result.insert(day)
            }
        }
        return result
    }

    /// Warum gerade keine Zeiten dastehen.
    ///
    /// "Geschlossen" und "alles ausgebucht" sind zwei verschiedene
    /// Nachrichten — im ersten Fall braucht man einen anderen Tag,
    /// im zweiten eine andere Uhrzeit.
    var noSlotsReason: String {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: selectedDay)

        if shop.openingHour(forWeekday: weekday) == nil {
            return String(localized: "Der Shop hat an diesem Tag geschlossen.")
        }
        return String(localized: "An diesem Tag sind keine Termine mehr frei.")
    }

    /// Gesamtpreis der Auswahl — aktuell genau der Servicepreis.
    var totalPriceText: String? {
        selectedService?.priceShort
    }

    // MARK: - Privat

    /// Sucht den nächsten Tag innerhalb der Auswahl, an dem noch etwas
    /// gehen kann.
    ///
    /// Heute zählt nur mit, solange der Laden nicht schon zu hat. Wer
    /// abends um neun die Buchung öffnet, soll nicht auf einem leeren
    /// heutigen Tag landen und sich fragen, ob die App kaputt ist —
    /// er will ohnehin morgen.
    ///
    /// `static`, weil das schon im `init` gebraucht wird — dort gibt es
    /// das fertige Objekt noch nicht, also kann man keine normale
    /// Methode aufrufen.
    static func firstOpenDay(
        for shop: Barbershop,
        calendar: Calendar = .current,
        now: Date = .now
    ) -> Date? {
        let today = calendar.startOfDay(for: now)
        let minuteNow = calendar.component(.hour, from: now) * 60
                      + calendar.component(.minute, from: now)

        for offset in 0..<14 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else {
                continue
            }
            let weekday = calendar.component(.weekday, from: day)
            guard let hours = shop.openingHour(forWeekday: weekday) else {
                continue
            }
            // Nur heute muss man auf die Uhr schauen.
            if offset == 0 && minuteNow >= hours.closesAtMinute {
                continue
            }
            return day
        }
        return nil
    }
}
