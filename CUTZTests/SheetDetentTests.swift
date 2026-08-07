import XCTest
@testable import CUTZ

/// Tests für die zwei Stufen der Barber-Liste.
///
/// Die Liste soll entweder ganz unten oder ganz oben sein — keine
/// Zwischenstufe. Beim Loslassen muss sie deshalb sicher auf einer der
/// beiden landen, egal wo man sie hinzieht.
///
/// Ausführen in Xcode mit ⌘U.
final class SheetDetentTests: XCTestCase {

    /// Ungefähre nutzbare Höhe eines iPhone-Bildschirms.
    private let screenHeight: CGFloat = 800

    func testThereAreExactlyTwoDetents() {
        XCTAssertEqual(
            SheetDetent.allCases.count, 2,
            "Eine mittlere Stufe fühlte sich unentschieden an und wurde entfernt."
        )
    }

    func testExpandedIsTallerThanCollapsed() {
        XCTAssertGreaterThan(
            SheetDetent.expanded.height(in: screenHeight),
            SheetDetent.collapsed.height(in: screenHeight)
        )
    }

    func testCollapsedShowsAboutOneCard() {
        // Unten soll genau eine Karte sichtbar bleiben, damit ein
        // angetippter Kartenpin sofort etwas anzeigt.
        let height = SheetDetent.collapsed.height(in: screenHeight)

        XCTAssertGreaterThan(height, 150, "Zu niedrig für Griff, Kopfzeile und eine Karte.")
        XCTAssertLessThan(height, 300, "Zu hoch — die Karte würde zu stark verdeckt.")
    }

    func testToggleSwitchesBetweenBoth() {
        XCTAssertEqual(SheetDetent.collapsed.toggled, .expanded)
        XCTAssertEqual(SheetDetent.expanded.toggled, .collapsed)
    }

    // MARK: - Einrasten beim Loslassen

    func testReleasingNearTheBottomSnapsClosed() {
        let result = BarberListSheet.nearestDetent(to: 220, in: screenHeight)

        XCTAssertEqual(result, .collapsed)
    }

    func testReleasingNearTheTopSnapsOpen() {
        let result = BarberListSheet.nearestDetent(to: 700, in: screenHeight)

        XCTAssertEqual(result, .expanded)
    }

    func testReleasingInTheMiddleSnapsToTheNearerOne() {
        let collapsed = SheetDetent.collapsed.height(in: screenHeight)   // 210
        let expanded = SheetDetent.expanded.height(in: screenHeight)     // 736
        let middle = (collapsed + expanded) / 2                          // 473

        // Knapp unter der Mitte -> zu, knapp darüber -> auf.
        XCTAssertEqual(BarberListSheet.nearestDetent(to: middle - 20, in: screenHeight), .collapsed)
        XCTAssertEqual(BarberListSheet.nearestDetent(to: middle + 20, in: screenHeight), .expanded)
    }

    func testExtremeValuesStayWithinTheTwoDetents() {
        // Weit über den Bildschirm hinaus gezogen oder unter null —
        // es darf trotzdem nur eine der beiden Stufen herauskommen.
        XCTAssertEqual(BarberListSheet.nearestDetent(to: -500, in: screenHeight), .collapsed)
        XCTAssertEqual(BarberListSheet.nearestDetent(to: 5000, in: screenHeight), .expanded)
    }
}
