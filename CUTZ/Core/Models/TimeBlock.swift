import Foundation

/// Eine Zeit, in der nicht gearbeitet wird, obwohl der Laden laut
/// Öffnungszeiten offen hätte: Mittagspause, halber Tag zu, Urlaub.
///
/// ── Warum das nicht über die Öffnungszeiten geht ──────────
///
/// `OpeningHour` beschreibt den Regelfall — "montags 9 bis 19". Ein
/// Urlaub ist aber keine Regel, sondern eine Ausnahme an bestimmten
/// Tagen. Beides in einen Topf zu werfen hieße, jede Woche die
/// Öffnungszeiten umzuschreiben und danach wieder zurück.
///
/// ── Warum das wichtiger ist, als es aussieht ──────────────
///
/// Ohne Ausnahmen lügt der Kalender. Der Friseur macht Mittwoch früher
/// zu, die App verkauft trotzdem einen Termin um 17:00, und der Kunde
/// steht vor verschlossener Tür. Genau einmal — danach ist er weg.
struct TimeBlock: Identifiable, Codable, Hashable {

    /// Wofür die Zeit blockiert ist.
    enum Reason: String, Codable, CaseIterable, Identifiable {
        case pause
        case vacation
        case other

        var id: String { rawValue }

        var label: String {
            switch self {
            case .pause:    return AppText.string("Pause")
            case .vacation: return AppText.string("Urlaub")
            case .other:    return AppText.string("Geschlossen")
            }
        }
    }

    let id: UUID

    var shopID: UUID

    /// Betrifft die Sperre nur eine Person? `nil` heißt: der ganze
    /// Laden. Eine Mittagspause nimmt meist einer allein, in den Urlaub
    /// fährt auch nicht das ganze Team gleichzeitig.
    var employeeID: UUID? = nil

    var startsAt: Date
    var endsAt: Date

    var reason: Reason = .pause

    /// Freitext, falls der Grund nicht in die drei Fälle passt.
    var note: String = ""

    /// Was in der Tagesleiste steht — der Freitext, wenn es einen gibt,
    /// sonst der Grund.
    var title: String {
        note.isEmpty ? reason.label : note
    }

    init(
        id: UUID = UUID(),
        shopID: UUID,
        employeeID: UUID? = nil,
        startsAt: Date,
        endsAt: Date,
        reason: Reason = .pause,
        note: String = ""
    ) {
        self.id = id
        self.shopID = shopID
        self.employeeID = employeeID
        self.startsAt = startsAt
        self.endsAt = endsAt
        self.reason = reason
        self.note = note
    }
}
