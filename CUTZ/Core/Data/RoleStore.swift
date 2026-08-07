import Foundation
import Observation

/// Merkt sich, ob die App gerade als Kunde oder als Friseur läuft.
///
/// Aufgebaut wie `LanguageStore` und `FavoritesStore` nebenan: eine
/// kleine Klasse, die genau eine Einstellung hält und selbst speichert.
///
/// Der Unterschied zu den beiden: Hier gibt es einen dritten Zustand.
/// Wer die App zum ersten Mal öffnet, hat noch gar nichts gewählt —
/// dann zeigen wir den Auswahlbildschirm. `nil` heißt also nicht
/// "keine Rolle", sondern "noch nicht gefragt".
@MainActor
@Observable
final class RoleStore {

    private static let storageKey = "cutz.appRole"

    /// Die gewählte Rolle, oder `nil` beim allerersten Start.
    var current: AppRole? {
        get { chosen }
        set {
            chosen = newValue
            if let newValue {
                defaults.set(newValue.rawValue, forKey: Self.storageKey)
            } else {
                defaults.removeObject(forKey: Self.storageKey)
            }
        }
    }

    private var chosen: AppRole?

    private let defaults: UserDefaults

    /// Hat der Nutzer die Frage schon beantwortet?
    var hasChosen: Bool { chosen != nil }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let raw = defaults.string(forKey: Self.storageKey) ?? ""
        self.chosen = AppRole(rawValue: raw)
    }
}
