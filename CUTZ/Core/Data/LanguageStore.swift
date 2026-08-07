import Foundation
import Observation

/// Merkt sich, welche Sprache im Profil eingestellt wurde.
///
/// Aufgebaut wie `FavoritesStore` nebenan: eine kleine Klasse, die
/// genau eine Einstellung hält und sich selbst um das Speichern
/// kümmert. `UserDefaults` ist für so etwas gedacht — die Auswahl
/// überlebt damit den App-Neustart.
///
/// Warum eine eigene Klasse und nicht nur `AppLanguage.stored`?
/// Weil SwiftUI mitbekommen muss, wenn sich die Sprache ändert. Ein
/// `@Observable` sorgt dafür, dass die ganze Oberfläche sich neu
/// zeichnet — sonst stünde nach dem Umschalten noch der alte Text da.
@MainActor
@Observable
final class LanguageStore {

    /// Die gewählte Sprache. Schreiben speichert sofort.
    ///
    /// Warum getrennt in `current` und `chosen`? Weil beim Setzen noch
    /// etwas passieren soll — speichern. Ein `didSet` auf `chosen` wäre
    /// naheliegend, verträgt sich aber nicht mit `@Observable`: Das
    /// Makro baut beobachtete Eigenschaften intern um.
    ///
    /// SwiftUI merkt trotzdem, wenn sich etwas ändert: Das Lesen von
    /// `current` liest `chosen` mit, und `chosen` wird beobachtet.
    var current: AppLanguage {
        get { chosen }
        set {
            chosen = newValue
            defaults.set(newValue.rawValue, forKey: AppLanguage.storageKey)
        }
    }

    private var chosen: AppLanguage

    private let defaults: UserDefaults

    /// `UserDefaults` wird hineingereicht, damit Tests eine eigene,
    /// leere Ablage benutzen können — genau wie beim `FavoritesStore`.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let raw = defaults.string(forKey: AppLanguage.storageKey) ?? ""
        self.chosen = AppLanguage(rawValue: raw) ?? .system
    }
}
