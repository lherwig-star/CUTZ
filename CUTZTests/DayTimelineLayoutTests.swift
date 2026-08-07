import XCTest
@testable import CUTZ

/// Tests für die Maße der Tagesleiste.
///
/// Sieht nach Kleinkram aus, ist aber der Grund, warum man den Tag auf
/// einen Blick erfassen kann: Eine Stunde muss doppelt so hoch sein
/// wie eine halbe. Verrutscht das, sieht ein voller Nachmittag aus wie
/// ein leerer.
final class DayTimelineLayoutTests: XCTestCase {

    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    private func entry(fromMinute: Int, minutes: Int) -> DayEntry {
        let begin = start.addingTimeInterval(TimeInterval(fromMinute * 60))
        return DayEntry(
            kind: .free,
            startsAt: begin,
            endsAt: begin.addingTimeInterval(TimeInterval(minutes * 60))
        )
    }

    // MARK: - Position

    func testEntryAtTheStartSitsAtTheTop() {
        XCTAssertEqual(
            DayTimelineLayout.offset(for: entry(fromMinute: 0, minutes: 30), windowStart: start),
            0
        )
    }

    func testOneHourLaterIsOneHourDown() {
        XCTAssertEqual(
            DayTimelineLayout.offset(for: entry(fromMinute: 60, minutes: 30), windowStart: start),
            DayTimelineLayout.hourHeight
        )
    }

    func testHalfHourLaterIsHalfTheHeightDown() {
        XCTAssertEqual(
            DayTimelineLayout.offset(for: entry(fromMinute: 30, minutes: 30), windowStart: start),
            DayTimelineLayout.hourHeight / 2
        )
    }

    func testEntryBeforeTheWindowIsNotPushedAboveTheTop() {
        // Kann vorkommen, wenn ein Termin vor die Öffnungszeit fällt.
        // Ein negativer Versatz würde die Kachel aus der Leiste
        // herausschieben.
        XCTAssertEqual(
            DayTimelineLayout.offset(for: entry(fromMinute: -60, minutes: 30), windowStart: start),
            0
        )
    }

    // MARK: - Höhe

    func testLongEntryIsProportional() {
        // Zwei Stunden, abzüglich des Abstands zur nächsten Kachel.
        XCTAssertEqual(
            DayTimelineLayout.height(for: entry(fromMinute: 0, minutes: 120)),
            2 * DayTimelineLayout.hourHeight - DayTimelineLayout.gap
        )
    }

    func testDoubleDurationIsAboutDoubleHeight() {
        let short = DayTimelineLayout.height(for: entry(fromMinute: 0, minutes: 60))
        let long = DayTimelineLayout.height(for: entry(fromMinute: 0, minutes: 120))

        XCTAssertEqual(long + DayTimelineLayout.gap, 2 * (short + DayTimelineLayout.gap))
    }

    func testVeryShortEntryStaysReadable() {
        // Eine Viertelstunde wäre maßstäblich 16 Punkte hoch. Da passt
        // kein Name mehr hinein.
        XCTAssertEqual(
            DayTimelineLayout.height(for: entry(fromMinute: 0, minutes: 15)),
            DayTimelineLayout.minimumHeight
        )
    }

    func testNoEntryIsEverSmallerThanTheMinimum() {
        for minutes in [1, 5, 10, 15, 20, 30, 45, 60] {
            XCTAssertGreaterThanOrEqual(
                DayTimelineLayout.height(for: entry(fromMinute: 0, minutes: minutes)),
                DayTimelineLayout.minimumHeight,
                "\(minutes) Minuten ergeben eine zu flache Kachel."
            )
        }
    }

    // MARK: - Gedrängte Darstellung

    func testShortEntriesUseTheCompactLayout() {
        XCTAssertTrue(DayTimelineLayout.isCompact(entry(fromMinute: 0, minutes: 20)))
        XCTAssertFalse(DayTimelineLayout.isCompact(entry(fromMinute: 0, minutes: 60)))
    }

    // MARK: - Gesamthöhe

    func testTotalHeightFollowsTheNumberOfHours() {
        XCTAssertEqual(
            DayTimelineLayout.totalHeight(hourLabels: Array(9...18)),
            10 * DayTimelineLayout.hourHeight
        )
    }

    func testTotalHeightIsNeverZero() {
        // Ohne Stunden bliebe die Leiste unsichtbar und die Kacheln
        // darin würden abgeschnitten.
        XCTAssertGreaterThan(DayTimelineLayout.totalHeight(hourLabels: []), 0)
    }
}
