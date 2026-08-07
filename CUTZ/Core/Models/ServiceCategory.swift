import Foundation

/// Die Art einer Leistung — unabhängig davon, wie ein einzelner Shop
/// sie nennt.
///
/// Warum braucht es das zusätzlich zum Namen? Weil jeder Laden seine
/// Leistungen anders betitelt: "Herrenhaarschnitt", "Classic Cut" und
/// "Signature Cut" sind dasselbe. Zum Filtern brauchen wir eine feste
/// Handvoll Kategorien, sonst könnte man nach nichts sortieren.
///
/// Die Bezeichnungen sind bewusst die Barber-üblichen englischen Begriffe —
/// die benutzt die Zielgruppe selbst, "Hautverblassung" sagt niemand.
enum ServiceCategory: String, Codable, CaseIterable, Identifiable, Hashable {

    case haircut
    case skinFade
    case hairAndBeard
    case beard

    var id: Self { self }

    var label: String {
        switch self {
        case .haircut:      return "Haircut"
        case .skinFade:     return "Skin Fade"
        case .hairAndBeard: return "Hair + Beard"
        case .beard:        return "Beard"
        }
    }

    /// Symbol für Filterchips und Auswahlkarten.
    var symbolName: String {
        switch self {
        case .haircut:      return "scissors"
        case .skinFade:     return "comb"
        case .hairAndBeard: return "person.crop.square"
        case .beard:        return "mustache"
        }
    }
}
