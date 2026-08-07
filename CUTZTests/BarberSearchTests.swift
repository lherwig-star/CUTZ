import XCTest
@testable import CUTZ

/// Tests für die Suche.
///
/// Ausführen in Xcode mit ⌘U.
final class BarberSearchTests: XCTestCase {

    private let shops = MockData.shops

    func testEmptyQueryFindsNothing() {
        // Bewusst nichts statt alles: Solange man nichts eingegeben hat,
        // soll ein Hinweis stehen, keine Liste aller Läden.
        XCTAssertTrue(BarberSearch.match(query: "", in: shops).isEmpty)
        XCTAssertTrue(BarberSearch.match(query: "   ", in: shops).isEmpty)
    }

    func testFindsByName() {
        let result = BarberSearch.match(query: "Fade Lounge", in: shops)

        XCTAssertEqual(result.map(\.name), ["Fade Lounge Nord"])
    }

    func testIsCaseInsensitive() {
        let lower = BarberSearch.match(query: "fade lounge", in: shops)
        let upper = BarberSearch.match(query: "FADE LOUNGE", in: shops)

        XCTAssertEqual(lower.map(\.id), upper.map(\.id))
        XCTAssertFalse(lower.isEmpty)
    }

    func testIgnoresUmlauts() {
        // "konigs" ohne Umlaut muss "Königs Barbershop" finden.
        let result = BarberSearch.match(query: "konigs", in: shops)

        XCTAssertEqual(result.map(\.name), ["Königs Barbershop"])
    }

    func testFindsByStreet() {
        let result = BarberSearch.match(query: "Holländische", in: shops)

        XCTAssertEqual(result.map(\.name), ["Fade Lounge Nord"])
    }

    func testFindsByPostalCode() {
        let result = BarberSearch.match(query: "34131", in: shops)

        XCTAssertEqual(result.map(\.name), ["Wilhelmshöhe Grooming"])
    }

    func testFindsByCityReturnsAll() {
        let result = BarberSearch.match(query: "Kassel", in: shops)

        XCTAssertEqual(
            result.count, shops.count,
            "Alle Testshops liegen in Kassel."
        )
    }

    func testAllWordsMustMatch() {
        // "kassel fade" trifft nur den Laden, auf den beides zutrifft.
        let both = BarberSearch.match(query: "kassel fade", in: shops)
        XCTAssertEqual(both.map(\.name), ["Fade Lounge Nord"])

        // Ein Wort, das nirgends vorkommt, lässt nichts übrig.
        let none = BarberSearch.match(query: "kassel hamburg", in: shops)
        XCTAssertTrue(none.isEmpty)
    }

    func testKeepsInputOrder() {
        let result = BarberSearch.match(query: "Kassel", in: shops)

        XCTAssertEqual(
            result.map(\.id), shops.map(\.id),
            "Die Reihenfolge der übergebenen Liste muss erhalten bleiben."
        )
    }

    func testUnknownQueryFindsNothing() {
        XCTAssertTrue(BarberSearch.match(query: "Zahnarzt", in: shops).isEmpty)
    }

    // MARK: - Suche in einzelnen Feldern
    //
    // Diese Fassung benutzt die Friseurseite, um Buchungen nach
    // Kundenname und Leistung zu durchsuchen. Sie muss sich genauso
    // verhalten wie die Ladensuche — sonst wundert sich später jemand,
    // warum dieselbe Eingabe an zwei Stellen verschieden wirkt.

    func testMatchesIgnoresCaseAndUmlauts() {
        XCTAssertTrue(BarberSearch.matches("muller", in: ["Tim Müller"]))
        XCTAssertTrue(BarberSearch.matches("MÜLLER", in: ["tim müller"]))
    }

    func testMatchesNeedsAllWords() {
        XCTAssertTrue(BarberSearch.matches("tim fade", in: ["Tim Müller", "Skin Fade"]))
        XCTAssertFalse(BarberSearch.matches("tim beard", in: ["Tim Müller", "Skin Fade"]))
    }

    func testEmptyQueryMatchesEverything() {
        // Anders als bei der Ladensuche: Ein leeres Suchfeld soll die
        // Liste nicht leeren, sondern alles stehen lassen.
        XCTAssertTrue(BarberSearch.matches("", in: ["Irgendwas"]))
    }

    func testMatchesSearchesAcrossAllFields() {
        XCTAssertTrue(BarberSearch.matches("schnitt", in: ["Tim", "Herrenhaarschnitt"]))
    }

    func testUnknownQueryDoesNotMatch() {
        XCTAssertFalse(BarberSearch.matches("hamburg", in: ["Tim", "Herrenhaarschnitt"]))
    }
}
