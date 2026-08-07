import Foundation
import SwiftUI

/// Die Sprachen, zwischen denen man in der App umschalten kann.
///
/// ── Warum überhaupt ein eigener Schalter? ─────────────────
///
/// iOS kann das eigentlich schon: Seit iOS 13 hat jede App in den
/// Systemeinstellungen einen Eintrag "Sprache". Nur findet den kaum
/// jemand — man muss die App verlassen, in den Einstellungen bis zum
/// App-Namen scrollen und dort nachsehen.
///
/// Für CUTZ ist das der falsche Weg. Ein Teil unserer Zielgruppe
/// spricht zu Hause Arabisch und hat das Telefon trotzdem auf Deutsch
/// stehen. Wer die App zum ersten Mal öffnet, soll die Sprache dort
/// wechseln können, wo er gerade ist.
///
/// ── Warum die Namen NICHT übersetzt werden ────────────────
///
/// "Deutsch", "English", "العربية" stehen jeweils in ihrer eigenen
/// Sprache da, nicht in der gerade eingestellten. Das ist Absicht:
/// Wer aus Versehen auf Arabisch umstellt und kein Wort versteht,
/// findet "Deutsch" trotzdem wieder. Übersetzte Sprachnamen wären
/// genau dann unlesbar, wenn man sie am dringendsten braucht.
enum AppLanguage: String, CaseIterable, Identifiable {

    /// Der Sprache folgen, die iOS für CUTZ ausgewählt hat.
    case system
    case german
    case english
    case arabic

    var id: String { rawValue }

    /// Der Ordnername unter `CUTZ/Resources/` ohne ".lproj".
    /// `nil` heißt: keine eigene Wahl, iOS entscheidet.
    var code: String? {
        switch self {
        case .system:  return nil
        case .german:  return "de"
        case .english: return "en"
        case .arabic:  return "ar"
        }
    }

    /// Was im Profil in der Liste steht.
    ///
    /// Nur "Systemsprache" wird übersetzt — das ist ja keine Sprache,
    /// sondern eine Einstellung.
    var displayName: String {
        switch self {
        case .system:  return AppText.string("Systemsprache")
        case .german:  return "Deutsch"
        case .english: return "English"
        case .arabic:  return "العربية"
        }
    }

    // MARK: - Woher die Texte kommen

    /// Das Bündel mit den Texten dieser Sprache.
    ///
    /// Ein `.lproj`-Ordner ist für iOS ein eigenes kleines Bundle. Wir
    /// suchen es im App-Bundle und lesen die Texte direkt daraus —
    /// dadurch braucht die Sprachumstellung keinen Neustart.
    ///
    /// Findet sich der Ordner nicht (etwa weil jemand eine Sprache
    /// hinzufügt und die Dateien vergisst), fallen wir auf das
    /// normale App-Bundle zurück. Dann sieht man deutschen Text —
    /// unschön, aber besser als ein Absturz.
    var bundle: Bundle {
        guard let code,
              let path = Bundle.main.path(forResource: code, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return .main
        }
        return bundle
    }

    /// Für Zahlen, Währung und Datum.
    ///
    /// Ohne das stünde in der englischen App "4,8 ★" statt "4.8 ★",
    /// weil sich die Zahlenschreibweise sonst nach dem Gerät richtet.
    var locale: Locale {
        guard let code else { return .current }
        return Locale(identifier: code)
    }

    /// Arabisch läuft von rechts nach links.
    ///
    /// Normalerweise nimmt iOS das automatisch aus der Systemsprache.
    /// Wir schalten die Sprache aber selbst um, also müssen wir die
    /// Leserichtung auch selbst mitziehen — sonst stünde arabischer
    /// Text in einem von links nach rechts aufgebauten Layout.
    var layoutDirection: LayoutDirection {
        let identifier = code
            ?? Bundle.main.preferredLocalizations.first
            ?? "de"

        let direction = Locale.Language(identifier: identifier).characterDirection
        return direction == .rightToLeft ? .rightToLeft : .leftToRight
    }

    // MARK: - Gespeicherte Auswahl

    /// Der Schlüssel in `UserDefaults`. Liegt hier und nicht im
    /// `LanguageStore`, weil `AppText` ihn auch braucht — und `AppText`
    /// wird von überall aufgerufen, auch außerhalb der Oberfläche.
    static let storageKey = "cutz.appLanguage"

    /// Die gespeicherte Auswahl.
    ///
    /// Bewusst ohne `@Observable` und ohne Haupt-Thread-Bindung:
    /// `AppText.string(…)` wird auch aus dem Repository heraus
    /// aufgerufen, und das läuft auf einem anderen Thread.
    /// `UserDefaults` darf man von überall lesen.
    static var stored: AppLanguage {
        let raw = UserDefaults.standard.string(forKey: storageKey) ?? ""
        return AppLanguage(rawValue: raw) ?? .system
    }
}
