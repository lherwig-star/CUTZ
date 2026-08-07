import Foundation

/// Als was benutzt jemand CUTZ — als Kunde oder als Friseur?
///
/// ── Warum eine Wahl beim ersten Start und kein zweiter Download? ──
///
/// Getrennte Apps (wie Uber und Uber Driver) sind der übliche Weg,
/// kosten aber zwei App-Store-Einträge, zwei Freigaben bei jeder
/// Änderung und zwei Zertifikate. Für den Anfang ist das viel Reibung
/// ohne Gegenwert.
///
/// Wichtiger noch: Ein Friseur, der von einem Kunden von CUTZ hört,
/// lädt dieselbe App und findet die Business-Seite sofort. Genau so
/// soll sich das Produkt verbreiten.
///
/// ── Warum das KEINE Berechtigung ist ─────────────────────
///
/// Diese Wahl steuert nur, welche Oberfläche man sieht. Sie liegt in
/// den Einstellungen des Geräts und lässt sich von jedem umstellen.
///
/// Ob jemand tatsächlich einen Laden verwalten darf, entscheidet
/// später der Server — siehe `PartnerAccountStatus`. Wer hier
/// "Friseur" wählt, sieht die Business-Oberfläche, kann darin aber
/// nichts Echtes tun, solange sein Laden nicht freigegeben ist.
enum AppRole: String, CaseIterable, Identifiable, Codable {

    /// Termine suchen und buchen. Das ist die Seite aus Phase 1.
    case customer

    /// Den eigenen Laden verwalten.
    case barber

    var id: String { rawValue }
}
