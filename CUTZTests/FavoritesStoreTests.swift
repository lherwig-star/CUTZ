import XCTest
@testable import CUTZ

/// Tests für die Favoriten.
///
/// Wichtig ist vor allem das Speichern: Eine App, die vergisst, was man
/// ihr gerade gesagt hat, wirkt kaputt. Ob das Speichern klappt, sieht
/// man beim Ausprobieren aber erst nach einem Neustart — hier sofort.
///
/// Ausführen in Xcode mit ⌘U.
@MainActor
final class FavoritesStoreTests: XCTestCase {

    /// Eine eigene, leere Ablage pro Test.
    ///
    /// Ohne das würden die Tests in die echten Einstellungen des
    /// Simulators schreiben — und sich gegenseitig beeinflussen,
    /// je nachdem in welcher Reihenfolge sie laufen.
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "cutz.tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    private let shopA = UUID()
    private let shopB = UUID()

    // MARK: - Grundverhalten

    func testStartsEmpty() {
        let store = FavoritesStore(defaults: defaults)

        XCTAssertTrue(store.favoriteShopIDs.isEmpty)
        XCTAssertFalse(store.isFavorite(shopA))
    }

    func testToggleAddsAndRemoves() {
        let store = FavoritesStore(defaults: defaults)

        store.toggle(shopA)
        XCTAssertTrue(store.isFavorite(shopA))

        store.toggle(shopA)
        XCTAssertFalse(store.isFavorite(shopA), "Zweites Antippen muss wieder entfernen.")
    }

    func testTogglingOneShopDoesNotAffectAnother() {
        let store = FavoritesStore(defaults: defaults)

        store.toggle(shopA)
        store.toggle(shopB)
        store.toggle(shopA)

        XCTAssertFalse(store.isFavorite(shopA))
        XCTAssertTrue(store.isFavorite(shopB))
    }

    // MARK: - Speichern

    func testFavoritesSurviveANewStore() {
        let first = FavoritesStore(defaults: defaults)
        first.toggle(shopA)
        first.toggle(shopB)

        // Ein zweiter Store auf derselben Ablage entspricht dem,
        // was nach einem App-Neustart passiert.
        let second = FavoritesStore(defaults: defaults)

        XCTAssertTrue(second.isFavorite(shopA))
        XCTAssertTrue(second.isFavorite(shopB))
    }

    func testRemovalIsAlsoSaved() {
        let first = FavoritesStore(defaults: defaults)
        first.toggle(shopA)
        first.toggle(shopA)

        let second = FavoritesStore(defaults: defaults)

        XCTAssertFalse(
            second.isFavorite(shopA),
            "Auch das Entfernen muss gespeichert werden, nicht nur das Hinzufügen."
        )
    }

    // MARK: - Filtern

    func testFavoritesFromListKeepsOriginalOrder() {
        let store = FavoritesStore(defaults: defaults)
        let shops = MockData.shops

        // Bewusst in umgekehrter Reihenfolge markieren.
        store.toggle(shops[3].id)
        store.toggle(shops[1].id)

        let result = store.favorites(from: shops)

        XCTAssertEqual(
            result.map(\.id), [shops[1].id, shops[3].id],
            "Die Reihenfolge der übergebenen Liste muss erhalten bleiben."
        )
    }

    func testFavoritesFromListIsEmptyWithoutFavorites() {
        let store = FavoritesStore(defaults: defaults)

        XCTAssertTrue(store.favorites(from: MockData.shops).isEmpty)
    }
}
