import Foundation

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

    var startsAt: Date
    var durationMinutes: Int

    /// Wann der Termin endet — ergibt sich aus Start + Dauer.
    var endsAt: Date {
        startsAt.addingTimeInterval(TimeInterval(durationMinutes * 60))
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
