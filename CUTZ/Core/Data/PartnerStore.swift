import Foundation
import Observation

/// Merkt sich, welchen Laden ein Friseur verwaltet und wie weit die
/// Freigabe ist.
///
/// Aufgebaut wie `FavoritesStore`, `LanguageStore` und `RoleStore`
/// nebenan: eine kleine Klasse für genau eine Sache, die selbst
/// speichert.
///
/// ── Das hier ist eine Attrappe, und zwar bewusst ──────────
///
/// Freigabe und Ladenzugehörigkeit gehören auf den Server. Ein Wert in
/// `UserDefaults` ist keine Berechtigung — man könnte ihn von außen
/// setzen und wäre "freigegeben".
///
/// Solange es kein Backend gibt, ist das trotzdem richtig: So lässt
/// sich der ganze Ablauf bauen und ausprobieren, und in Phase 2 wird
/// aus dem Lesen von `UserDefaults` ein Lesen aus `shop_members`. Die
/// Oberfläche darüber bleibt, wie sie ist.
@MainActor
@Observable
final class PartnerStore {

    private static let statusKey = "cutz.partner.status"
    private static let shopKey = "cutz.partner.shopID"

    /// Wie weit die Anmeldung ist.
    private(set) var status: PartnerAccountStatus

    /// Welchen Laden dieser Friseur verwaltet.
    private(set) var managedShopID: UUID?

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let raw = defaults.string(forKey: Self.statusKey) ?? ""
        self.status = PartnerAccountStatus(rawValue: raw) ?? .notRegistered

        if let text = defaults.string(forKey: Self.shopKey) {
            self.managedShopID = UUID(uuidString: text)
        }
    }

    /// Einen Laden zur Freigabe anmelden.
    func register(shopID: UUID) {
        managedShopID = shopID
        status = .pending
        save()
    }

    /// Die Anmeldung zurücknehmen.
    func reset() {
        managedShopID = nil
        status = .notRegistered
        save()
    }

    /// Freigabe von Hand — der Ersatz für das, was später jemand von
    /// uns nach einem Anruf im Laden tut.
    ///
    /// Steht hier, damit man die Friseurseite überhaupt ansehen kann,
    /// solange es kein Backend gibt. In der Oberfläche ist der Knopf
    /// dazu ausdrücklich als Behelf beschriftet — sonst hält ihn
    /// jemand für ein Feature.
    func approveForDemo() {
        status = .approved
        save()
    }

    private func save() {
        defaults.set(status.rawValue, forKey: Self.statusKey)

        if let managedShopID {
            defaults.set(managedShopID.uuidString, forKey: Self.shopKey)
        } else {
            defaults.removeObject(forKey: Self.shopKey)
        }
    }
}
