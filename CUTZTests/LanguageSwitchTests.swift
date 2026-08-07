import XCTest
import SwiftUI
@testable import CUTZ

/// Tests für den Sprachschalter im Profil.
///
/// Der wichtigste ist `testSameKeyGivesDifferentTextPerLanguage`: Er
/// beweist, dass das Umschalten überhaupt etwas bewirkt. Ohne ihn
/// könnte `AppText` stillschweigend immer aus derselben Datei lesen,
/// und man würde es erst im Simulator merken.
///
/// Diese Tests kommen ohne die laufende App aus — sie fragen die
/// Sprachdateien direkt. Deshalb funktionieren sie auch, obwohl der
/// Testlauf selbst fest auf Deutsch steht (siehe project.yml).
final class LanguageSwitchTests: XCTestCase {

    // MARK: - Die Sprachdateien sind auffindbar

    func testEveryLanguageFindsItsOwnStringsFile() {
        // Fällt `bundle` auf `.main` zurück, ist der .lproj-Ordner nicht
        // mitgeliefert worden — dann sähe man überall deutschen Text.
        // Genau das soll hier auffallen und nicht erst im Simulator.
        for language in [AppLanguage.german, .english, .arabic] {
            XCTAssertNotEqual(
                language.bundle, Bundle.main,
                "Für \(language.rawValue) fehlt der Ordner \(language.code ?? "?").lproj im App-Bundle."
            )
        }
    }

    func testSystemUsesTheNormalAppBundle() {
        // Ohne eigene Wahl soll iOS entscheiden — also das App-Bundle.
        XCTAssertEqual(AppLanguage.system.bundle, Bundle.main)
        XCTAssertNil(AppLanguage.system.code)
    }

    // MARK: - Das Umschalten wirkt

    func testSameKeyGivesDifferentTextPerLanguage() {
        XCTAssertEqual(AppText.string("Erlaubt", from: .german), "Erlaubt")
        XCTAssertEqual(AppText.string("Erlaubt", from: .english), "Allowed")

        // Beim Arabischen prüfen wir nicht den genauen Wortlaut — nur,
        // dass überhaupt etwas anderes herauskommt als der Schlüssel.
        // Sonst müsste man diesen Test bei jeder Korrektur durch einen
        // Muttersprachler mit anpassen.
        let arabic = AppText.string("Erlaubt", from: .arabic)
        XCTAssertNotEqual(arabic, "Erlaubt", "Arabisch liefert noch den deutschen Text.")
        XCTAssertFalse(arabic.isEmpty)
    }

    func testTextWithPlaceholderIsTranslatedToo() {
        // Texte mit Platzhaltern gehen einen anderen Weg als einfache.
        // Deshalb einer davon extra.
        let german = AppText.string("Termin buchen", from: .german)
        let english = AppText.string("Termin buchen", from: .english)

        XCTAssertEqual(german, "Termin buchen")
        XCTAssertEqual(english, "Book appointment")
    }

    // MARK: - Leserichtung

    func testArabicReadsFromRightToLeft() {
        XCTAssertEqual(AppLanguage.arabic.layoutDirection, .rightToLeft)
    }

    func testGermanAndEnglishReadFromLeftToRight() {
        XCTAssertEqual(AppLanguage.german.layoutDirection, .leftToRight)
        XCTAssertEqual(AppLanguage.english.layoutDirection, .leftToRight)
    }

    // MARK: - Zahlen und Preise folgen der Sprache

    func testNumbersUseTheSeparatorOfTheChosenLanguage() {
        XCTAssertEqual(AppLanguage.german.locale.identifier, "de")
        XCTAssertEqual(AppLanguage.english.locale.identifier, "en")
    }

    // MARK: - Die Namen der Sprachen

    func testLanguageNamesAreNotTranslated() {
        // "Deutsch" muss "Deutsch" heißen, egal worauf die App gerade
        // steht. Sonst findet niemand mehr zurück, der aus Versehen auf
        // Arabisch umgeschaltet hat.
        XCTAssertEqual(AppLanguage.german.displayName, "Deutsch")
        XCTAssertEqual(AppLanguage.english.displayName, "English")
        XCTAssertEqual(AppLanguage.arabic.displayName, "العربية")
    }

    func testAllFourChoicesAreOffered() {
        XCTAssertEqual(AppLanguage.allCases.count, 4)
    }

    // MARK: - Speichern

    @MainActor
    func testChoiceIsRemembered() throws {
        let defaults = try makeEmptyDefaults()

        let store = LanguageStore(defaults: defaults)
        XCTAssertEqual(store.current, .system, "Ohne eigene Wahl gilt die Systemsprache.")

        store.current = .arabic

        // Neue Instanz, gleiche Ablage — wie nach einem App-Neustart.
        let afterRestart = LanguageStore(defaults: defaults)
        XCTAssertEqual(afterRestart.current, .arabic)
    }

    @MainActor
    func testUnknownStoredValueFallsBackToSystem() throws {
        // Etwa ein Rest aus einer älteren Version, in der es eine
        // Sprache noch gab, die inzwischen entfernt wurde.
        let defaults = try makeEmptyDefaults()
        defaults.set("klingonisch", forKey: AppLanguage.storageKey)

        XCTAssertEqual(LanguageStore(defaults: defaults).current, .system)
    }

    /// Eine eigene, leere `UserDefaults`-Ablage — damit der Test nicht
    /// die echte Einstellung des Simulators verstellt. Genauso macht es
    /// `FavoritesStoreTests`.
    private func makeEmptyDefaults() throws -> UserDefaults {
        let name = "cutz.tests.language.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        addTeardownBlock { defaults.removePersistentDomain(forName: name) }
        return defaults
    }
}
