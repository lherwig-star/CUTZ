import Foundation

/// Wie weit ein Friseur mit der Anmeldung seines Ladens ist.
///
/// ── Warum es überhaupt eine Hürde gibt ────────────────────
///
/// Anmelden darf sich jeder selbst — nur so verbreitet sich das
/// Produkt von allein: Ein Friseur hört von einem Kunden davon, lädt
/// die App und trägt seinen Laden ein, ohne dass wir etwas tun müssen.
///
/// Freigegeben wird trotzdem von Hand. Ohne das könnte jeder einen
/// fremden Laden für sich beanspruchen und dessen Termine verwalten —
/// und der eigentliche Inhaber merkt es nicht einmal. Bei einer
/// Buchungs-App ist das kein theoretischer Schaden: Wer die Termine
/// kontrolliert, kontrolliert das Geschäft.
///
/// Ein Anruf unter der hinterlegten Nummer reicht als Prüfung völlig.
/// Solange es um Kassel geht, ist das an einem Nachmittag erledigt.
enum PartnerAccountStatus: String, Codable, Hashable {

    /// Rolle "Friseur" gewählt, aber noch keinen Laden eingetragen.
    case notRegistered

    /// Laden eingetragen, Freigabe steht aus.
    case pending

    /// Freigegeben. Erst ab hier lässt sich wirklich etwas verwalten.
    case approved

    /// Abgelehnt, z. B. weil der Laden schon jemand anderem gehört.
    case rejected
}
