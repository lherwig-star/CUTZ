import Foundation
import EventKit

/// Trägt gebuchte Termine in den Kalender des iPhones ein.
///
/// ─── Zuständig: Lukas ──────────────────────────────────────
///
/// WICHTIG — so lösen wir "Google Kalender ODER Apple Kalender":
///
/// Wir sprechen NICHT direkt mit Google. Stattdessen schreiben wir in den
/// Standardkalender des iPhones. Welcher das ist, hat der Nutzer in den
/// iOS-Einstellungen festgelegt: Das kann iCloud sein, ein Google-Konto,
/// Outlook oder ein lokaler Kalender. iOS synchronisiert von dort aus
/// automatisch weiter.
///
/// Vorteil: kein Google-Login, keine OAuth-Anmeldung, keine Zugangsdaten,
/// kein Server — und es funktioniert für alle Kalender-Anbieter gleichzeitig.
/// Genau deshalb machen wir es in Phase 1 so.
///
/// (Der andere Weg — die Google Calendar API — wird erst interessant,
/// wenn der FRISEUR seine Verfügbarkeiten aus seinem eigenen Kalender
/// ziehen soll. Das ist Phase 4, siehe PLAN.md.)
enum CalendarService {

    /// Was beim Kalendereintrag schiefgehen kann.
    enum CalendarError: LocalizedError {
        case accessDenied
        case noCalendarAvailable
        case saveFailed(String)

        var errorDescription: String? {
            switch self {
            case .accessDenied:
                "CUTZ darf nicht auf deinen Kalender zugreifen. Du kannst das in den Einstellungen unter Datenschutz › Kalender ändern."
            case .noCalendarAvailable:
                "Auf diesem Gerät wurde kein Kalender gefunden, in den geschrieben werden kann."
            case .saveFailed(let reason):
                "Der Termin konnte nicht gespeichert werden: \(reason)"
            }
        }
    }

    /// Trägt eine Buchung als Kalendereintrag ein.
    ///
    /// Beim ersten Aufruf zeigt iOS automatisch den Erlaubnis-Dialog.
    /// Wir fragen nur um SCHREIB-Rechte (`writeOnly`) — CUTZ kann die
    /// bestehenden Termine des Nutzers also gar nicht lesen. Das ist
    /// sparsamer, vertrauenswürdiger und iOS zeigt einen freundlicheren
    /// Dialog.
    static func addToCalendar(_ booking: Booking) async throws {

        let store = EKEventStore()

        // 1. Erlaubnis einholen (ab iOS 17 diese Methode).
        let granted = try await store.requestWriteOnlyAccessToEvents()
        guard granted else {
            throw CalendarError.accessDenied
        }

        // 2. Den Standardkalender des Nutzers ermitteln.
        guard let calendar = store.defaultCalendarForNewEvents else {
            throw CalendarError.noCalendarAvailable
        }

        // 3. Den Termin zusammenbauen.
        let event = EKEvent(eventStore: store)
        event.title = "\(booking.serviceName) · \(booking.shopName)"
        event.startDate = booking.startsAt
        event.endDate = booking.endsAt
        event.location = booking.shopAddress
        event.notes = "Gebucht über CUTZ"
        event.calendar = calendar

        // Erinnerung eine Stunde vorher.
        // Negativer Wert = vor dem Termin.
        event.addAlarm(EKAlarm(relativeOffset: -60 * 60))

        // 4. Speichern.
        do {
            try store.save(event, span: .thisEvent, commit: true)
        } catch {
            throw CalendarError.saveFailed(error.localizedDescription)
        }
    }
}
