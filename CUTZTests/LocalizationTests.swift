import XCTest
@testable import CUTZ

/// Tests für die Mehrsprachigkeit.
///
/// Der wichtigste Test ist `testNoTranslationIsMissing`: Fehlt ein
/// Eintrag in einer Sprachdatei, zeigt iOS stillschweigend den
/// Schlüssel an — also deutschen Text mitten in der englischen App.
/// Auffallen würde das nur, wenn man zufällig genau diesen Bildschirm
/// in genau dieser Sprache öffnet.
///
/// Diese Tests lesen die Sprachdateien direkt und sind deshalb
/// unabhängig davon, in welcher Sprache die App gerade läuft. Alle
/// anderen Tests prüfen deutschen Text — dafür steht die Sprache des
/// Testlaufs in `project.yml` fest auf Deutsch.
///
/// Ausführen in Xcode mit ⌘U.
final class LocalizationTests: XCTestCase {

    private let languages = ["de", "en", "ar"]

    /// Liest eine Sprachdatei als Wörterbuch ein.
    private func strings(for language: String) throws -> [String: String] {
        let bundle = Bundle(for: type(of: self))

        // Im Testlauf liegen die Sprachdateien im App-Bundle, nicht im
        // Test-Bundle. Deshalb beide Orte absuchen.
        let candidates = [Bundle.main, bundle].compactMap {
            $0.path(forResource: language, ofType: "lproj")
        }

        guard let lproj = candidates.first,
              let dict = NSDictionary(
                contentsOfFile: lproj + "/Localizable.strings"
              ) as? [String: String] else {
            throw XCTSkip("Sprachdatei für \(language) im Testlauf nicht auffindbar.")
        }
        return dict
    }

    // MARK: - Vollständigkeit

    func testNoTranslationIsMissing() throws {
        let german = try strings(for: "de")
        XCTAssertFalse(german.isEmpty, "Die deutsche Sprachdatei ist leer.")

        for language in languages where language != "de" {
            let translated = try strings(for: language)

            let missing = Set(german.keys).subtracting(translated.keys).sorted()
            XCTAssertTrue(
                missing.isEmpty,
                "In \(language) fehlen \(missing.count) Übersetzungen: \(missing.prefix(10))"
            )
        }
    }

    func testNoExtraKeys() throws {
        // Übrig gebliebene Schlüssel deuten auf Text hin, den es im Code
        // nicht mehr gibt — harmlos, aber sie sammeln sich an.
        let german = try strings(for: "de")

        for language in languages where language != "de" {
            let translated = try strings(for: language)

            let extra = Set(translated.keys).subtracting(german.keys).sorted()
            XCTAssertTrue(
                extra.isEmpty,
                "In \(language) stehen \(extra.count) Schlüssel zu viel: \(extra.prefix(10))"
            )
        }
    }

    func testNothingIsLeftUntranslated() throws {
        // Ein Wert, der genau dem deutschen entspricht, ist meist
        // vergessen worden. Ausnahmen sind Fachbegriffe und reine
        // Platzhalter-Formate.
        let german = try strings(for: "de")
        let allowed: Set<String> = [
            "Haircut", "Skin Fade", "Hair + Beard", "Beard",     // Fachbegriffe
            "Name", "Service", "Team", "Barber", "Filter",        // in en identisch
            "Account", "Support", "Navigation",
            "CUTZ · Version 0.1.0",
            "availability.weekday", "availability.date",          // nur Platzhalter
            "availability.long.date", "distance.meters",
            "distance.kilometers", "price.short",
            "profile.characterCount"
        ]

        let english = try strings(for: "en")
        var suspicious: [String] = []

        for (key, germanValue) in german {
            guard !allowed.contains(key) else { continue }
            if english[key] == germanValue {
                suspicious.append(key)
            }
        }

        XCTAssertTrue(
            suspicious.isEmpty,
            "Diese englischen Texte sind identisch mit dem deutschen: \(suspicious.sorted())"
        )
    }

    // MARK: - Platzhalter

    func testPlaceholdersMatchAcrossLanguages() throws {
        // Steht im Deutschen ein %@ und in der Übersetzung keines,
        // fehlt dort ein Wert — im schlimmsten Fall stürzt die App ab.
        let german = try strings(for: "de")

        for language in languages where language != "de" {
            let translated = try strings(for: language)

            for (key, germanValue) in german {
                guard let other = translated[key] else { continue }

                XCTAssertEqual(
                    placeholderCount(germanValue), placeholderCount(other),
                    "Unterschiedlich viele Platzhalter bei \"\(key)\" in \(language): "
                    + "\"\(germanValue)\" vs. \"\(other)\""
                )
            }
        }
    }

    /// Zählt %@, %lld und die nummerierten Formen %1$@ / %1$lld.
    private func placeholderCount(_ text: String) -> Int {
        let pattern = "%(?:\\d+\\$)?(?:@|lld|d)"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(text.startIndex..., in: text)
        return regex?.numberOfMatches(in: text, range: range) ?? 0
    }

    // MARK: - Einzelne Werte

    func testGermanKeysMapToThemselves() throws {
        // Für Schlüssel, die selbst der deutsche Satz sind, muss der
        // Wert in de.lproj identisch sein — sonst stimmt etwas nicht.
        let german = try strings(for: "de")

        for (key, value) in german where !key.contains(".") && !key.hasPrefix("%") {
            XCTAssertEqual(
                key, value,
                "In der deutschen Datei weicht \"\(key)\" vom Schlüssel ab."
            )
        }
    }

    func testWeekdayNamesAreComplete() throws {
        for language in languages {
            let dict = try strings(for: language)
            for day in ["sunday", "monday", "tuesday", "wednesday",
                        "thursday", "friday", "saturday"] {
                XCTAssertNotNil(dict["weekday.short.\(day)"], "\(language): kurz \(day) fehlt")
                XCTAssertNotNil(dict["weekday.long.\(day)"], "\(language): lang \(day) fehlt")
            }
        }
    }
}
