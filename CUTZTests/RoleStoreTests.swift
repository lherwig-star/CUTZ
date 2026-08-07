import XCTest
@testable import CUTZ

/// Tests für die Rollenwahl beim ersten Start.
///
/// Der Zustand, auf den es ankommt, ist der dritte: "noch nicht
/// gefragt". Verwechselt man ihn mit "Kunde", bekäme niemand je den
/// Auswahlbildschirm zu sehen und die Friseurseite wäre unerreichbar.
@MainActor
final class RoleStoreTests: XCTestCase {

    func testNothingIsChosenAtFirstLaunch() throws {
        let store = RoleStore(defaults: try makeEmptyDefaults())

        XCTAssertNil(store.current)
        XCTAssertFalse(store.hasChosen, "Beim ersten Start muss gefragt werden.")
    }

    func testChoiceIsRemembered() throws {
        let defaults = try makeEmptyDefaults()

        let store = RoleStore(defaults: defaults)
        store.current = .barber

        XCTAssertTrue(store.hasChosen)

        // Neue Instanz, gleiche Ablage — wie nach einem App-Neustart.
        XCTAssertEqual(RoleStore(defaults: defaults).current, .barber)
    }

    func testRoleCanBeSwitchedBackAndForth() throws {
        // Ohne das käme niemand von der Friseurseite zurück — und man
        // könnte die andere Hälfte der App nicht mehr ausprobieren.
        let defaults = try makeEmptyDefaults()
        let store = RoleStore(defaults: defaults)

        store.current = .barber
        store.current = .customer

        XCTAssertEqual(RoleStore(defaults: defaults).current, .customer)
    }

    func testUnknownStoredValueAsksAgain() throws {
        // Etwa ein Rest aus einer älteren Version. Lieber noch einmal
        // fragen als raten.
        let defaults = try makeEmptyDefaults()
        defaults.set("hausmeister", forKey: "cutz.appRole")

        XCTAssertNil(RoleStore(defaults: defaults).current)
    }

    func testBothRolesExist() {
        XCTAssertEqual(AppRole.allCases.count, 2)
    }

    private func makeEmptyDefaults() throws -> UserDefaults {
        let name = "cutz.tests.role.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        addTeardownBlock { defaults.removePersistentDomain(forName: name) }
        return defaults
    }
}
