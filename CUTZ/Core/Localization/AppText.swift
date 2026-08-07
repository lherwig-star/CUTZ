import Foundation

/// Holt übersetzte Texte in der Sprache, die in der App eingestellt ist.
///
/// ── Warum nicht Apples `String(localized:)` direkt? ───────
///
/// Apples Fassung nimmt immer die Sprache, die iOS für CUTZ ausgewählt
/// hat. Stellt man im Profil auf Englisch um, weiß iOS davon nichts —
/// der Text bliebe deutsch.
///
/// Deshalb sagen wir hier ausdrücklich, aus welcher Sprachdatei
/// gelesen werden soll. Das ist die EINZIGE Stelle im Projekt, an der
/// Apples `String(localized:)` noch vorkommt.
///
/// ── Was NICHT hierüber läuft ──────────────────────────────
///
/// `Text("Termin buchen")` in einer View braucht das nicht. SwiftUI
/// übersetzt solche Texte selbst und richtet sich dabei nach der
/// `locale` aus der Umgebung — die setzen wir in `CutzApp` einmal für
/// die ganze App.
///
/// Faustregel: Steht der Text direkt in Anführungszeichen in einer
/// View, ist nichts zu tun. Wird er ausgerechnet und kommt als
/// fertiger `String` aus einer Funktion, dann `AppText`.
enum AppText {

    /// Die gerade gewählte Sprache.
    static var language: AppLanguage { AppLanguage.stored }

    /// Für Zahlen, Währung und Datum.
    static var locale: Locale { language.locale }

    /// Ein übersetzter Text ohne Platzhalter.
    ///
    ///     AppText.string("Erlaubt")   // "Allowed", wenn Englisch gewählt ist
    static func string(_ key: String.LocalizationValue) -> String {
        string(key, from: language)
    }

    /// Dieselbe Übersetzung, aber aus einer ausdrücklich genannten
    /// Sprache. Braucht man in Tests: Nur so lässt sich prüfen, dass
    /// beim Umschalten wirklich ein anderer Text herauskommt, ohne
    /// dafür die Einstellung des ganzen Testlaufs zu verbiegen.
    static func string(_ key: String.LocalizationValue, from language: AppLanguage) -> String {
        String(localized: key, bundle: language.bundle)
    }

    /// Ein übersetzter Text mit Platzhaltern.
    ///
    ///     AppText.format("booking.withEmployee", "Samir")   // "bei Samir"
    ///
    /// Die Platzhalter heißen %1$@, %2$@ … und nicht schlicht %@,
    /// weil die Reihenfolge je Sprache abweichen darf.
    static func format(_ key: String.LocalizationValue, _ arguments: CVarArg...) -> String {
        String(format: string(key), arguments: arguments)
    }

    /// Eine Zahl mit einer Nachkommastelle: "4,8" auf Deutsch,
    /// "4.8" auf Englisch.
    ///
    /// Steht hier, damit nicht an acht Stellen einzeln daran gedacht
    /// werden muss, die Sprache mitzugeben.
    static func number(_ value: Double, fractionDigits: Int = 1) -> String {
        value.formatted(
            .number.precision(.fractionLength(fractionDigits)).locale(locale)
        )
    }
}
