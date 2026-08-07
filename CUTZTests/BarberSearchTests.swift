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
}
