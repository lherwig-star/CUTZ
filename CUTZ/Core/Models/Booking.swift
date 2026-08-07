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

    /// Wer kommt. Auf der Kundenseite braucht das niemand — man weiß
    /// ja, dass man selbst gemeint ist. Auf der Friseurseite ist es
    /// die wichtigste Angabe im ganzen Termin.
    ///
    /// Leer, solange es keine Nutzerkonten gibt (Phase 3). Bei
    /// Laufkundschaft trägt der Friseur den Namen selbst ein, oft nur
    /// als Vorname — mehr braucht er auch nicht.
    var customerName: String = ""

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
        return AppText.format("booking.withEmployee", employeeName)
    }

    /// z. B. "Freitag, 14.08. · 14:30"
    ///
    /// Früher stand hier `.formatted(date:time:)`. Das richtet sich
    /// aber nach der Region des Geräts, nicht nach der App-Sprache —
    /// wer die App auf Arabisch stellt, hätte trotzdem ein deutsches
    /// Datum gesehen. `AvailabilityText` macht es selbst und folgt
    /// damit der Einstellung im Profil.
    var startsAtFormatted: String {
        AvailabilityText.long(for: startsAt)
    }

    /// Liegt der Termin noch in der Zukunft?
    var isUpcoming: Bool {
        startsAt > .now
    }
}
