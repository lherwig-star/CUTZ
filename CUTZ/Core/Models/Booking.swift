import Foundation

/// Was mit einem Termin passiert ist.
///
/// Die Werte sind absichtlich genau die, die auch in der Datenbank
/// erlaubt sind (siehe `supabase/schema.sql`, Spalte `status`). Dadurch
/// passt das Modell in Phase 2 ohne Umbau.
///
/// `String` als Grundtyp, damit beim Speichern "cancelled" in der
/// Datenbank landet und nicht eine Zahl, die niemand lesen kann.
enum BookingStatus: String, Codable, Hashable {
    case confirmed
    case cancelled
    case completed
}

/// Ein gebuchter Termin.
///
/// Shop-Name und Service-Name sind hier bewusst als Text mitgespeichert
/// und nicht nur als Verweis (ID). So kann die Terminliste angezeigt
/// werden, ohne erst alle Shops nachladen zu müssen — und der Termin
/// bleibt lesbar, selbst wenn der Shop später umbenannt wird.
struct Booking: Identifiable, Codable, Hashable {

    let id: UUID

    var shopID: UUID
    var shopName: String
    var shopAddress: String

    var serviceID: UUID
    var serviceName: String

    /// Wer schneidet. `nil` bedeutet "egal welcher Barber" — dann hat
    /// der Nutzer bewusst den schnellsten Termin gewählt statt einer
    /// bestimmten Person.
    var employeeID: UUID? = nil
    var employeeName: String? = nil

    var startsAt: Date
    var durationMinutes: Int

    /// Der Vorgabewert sorgt dafür, dass bestehender Code weiterläuft,
    /// der `status` beim Anlegen gar nicht angibt.
    var status: BookingStatus = .confirmed

    /// Wann der Termin endet — ergibt sich aus Start + Dauer.
    var endsAt: Date {
        startsAt.addingTimeInterval(TimeInterval(durationMinutes * 60))
    }

    /// Wurde der Termin abgesagt?
    var isCancelled: Bool {
        status == .cancelled
    }

    /// z. B. "bei Samir" — oder leer, wenn kein Barber festgelegt wurde.
    var employeeText: String? {
        guard let employeeName else { return nil }
        return String(format: String(localized: "booking.withEmployee"), employeeName)
    }

    /// z. B. "Fr., 14. Aug. 2026 um 14:30"
    var startsAtFormatted: String {
        startsAt.formatted(date: .abbreviated, time: .shortened)
    }

    /// Liegt der Termin noch in der Zukunft?
    var isUpcoming: Bool {
        startsAt > .now
    }
}
