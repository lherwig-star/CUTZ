import XCTest
@testable import CUTZ

/// Tests für die Stammkundenliste.
///
/// Sie wird nicht gepflegt, sondern aus den Buchungen abgeleitet.
/// Genau deshalb muss die Ableitung stimmen: Ein Friseur, der hier
/// "war 3× da" liest, verlässt sich darauf.
final class CustomerSummaryTests: XCTestCase {

    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func booking(
        _ customer: String,
        daysFromNow: Int,
        service: String = "Herrenhaarschnitt",
        status: BookingStatus = .confirmed
    ) -> Booking {
        Booking(
            id: UUID(),
            shopID: UUID(),
            shopName: "Testladen",
            shopAddress: "Teststraße 1",
            serviceID: UUID(),
            serviceName: service,
            customerName: customer,
            startsAt: now.addingTimeInterval(TimeInterval(daysFromNow * 86_400)),
            durationMinutes: 30,
            status: status
        )
    }

    // MARK: - Zusammenfassen

    func testVisitsOfOnePersonBecomeOneEntry() {
        let summaries = CustomerSummary.from(
            bookings: [
                booking("Tim", daysFromNow: -30),
                booking("Tim", daysFromNow: -14),
                booking("Tim", daysFromNow: -2)
            ],
            now: now
        )

        XCTAssertEqual(summaries.count, 1)
        XCTAssertEqual(summaries.first?.visitCount, 3)
    }

    func testLastVisitIsTheMostRecentPastOne() {
        let summaries = CustomerSummary.from(
            bookings: [
                booking("Tim", daysFromNow: -30),
                booking("Tim", daysFromNow: -2)
            ],
            now: now
        )

        XCTAssertEqual(
            summaries.first?.lastVisit,
            now.addingTimeInterval(-2 * 86_400)
        )
    }

    func testFutureBookingIsNotCountedAsAVisit() {
        // Wer nächste Woche kommt, war noch nicht da. Sonst stünde bei
        // einem Neukunden "war 1× da", bevor er den Laden gesehen hat.
        let summaries = CustomerSummary.from(
            bookings: [booking("Neu", daysFromNow: 7)],
            now: now
        )

        XCTAssertEqual(summaries.first?.visitCount, 0)
        XCTAssertNil(summaries.first?.lastVisit)
        XCTAssertEqual(summaries.first?.nextVisit, now.addingTimeInterval(7 * 86_400))
    }

    func testNextVisitIsTheSoonestUpcomingOne() {
        let summaries = CustomerSummary.from(
            bookings: [
                booking("Tim", daysFromNow: 20),
                booking("Tim", daysFromNow: 3)
            ],
            now: now
        )

        XCTAssertEqual(summaries.first?.nextVisit, now.addingTimeInterval(3 * 86_400))
    }

    // MARK: - Was nicht zählt

    func testCancelledBookingsAreIgnored() {
        let summaries = CustomerSummary.from(
            bookings: [
                booking("Tim", daysFromNow: -5),
                booking("Tim", daysFromNow: -3, status: .cancelled)
            ],
            now: now
        )

        XCTAssertEqual(summaries.first?.visitCount, 1)
    }

    func testBookingsWithoutANameAreIgnored() {
        // Solange es keine Nutzerkonten gibt, haben Buchungen von der
        // Kundenseite keinen Namen. Ein Eintrag ohne Namen in der Liste
        // wäre für niemanden zu gebrauchen.
        let summaries = CustomerSummary.from(
            bookings: [booking("", daysFromNow: -1)],
            now: now
        )

        XCTAssertTrue(summaries.isEmpty)
    }

    // MARK: - Übliche Leistung

    func testUsualServiceIsTheMostFrequentOne() {
        let summaries = CustomerSummary.from(
            bookings: [
                booking("Tim", daysFromNow: -30, service: "Skin Fade"),
                booking("Tim", daysFromNow: -14, service: "Skin Fade"),
                booking("Tim", daysFromNow: -2, service: "Bart trimmen")
            ],
            now: now
        )

        XCTAssertEqual(summaries.first?.usualService, "Skin Fade")
    }

    func testTieOnServicesIsResolvedTheSameWayEveryTime() {
        // Bei Gleichstand darf nicht mal das eine, mal das andere
        // herauskommen — sonst wechselt der Text bei jedem Öffnen.
        let bookings = [
            booking("Tim", daysFromNow: -10, service: "Fade"),
            booking("Tim", daysFromNow: -5, service: "Bart")
        ]

        let first = CustomerSummary.from(bookings: bookings, now: now).first?.usualService
        let second = CustomerSummary.from(bookings: bookings.reversed(), now: now).first?.usualService

        XCTAssertEqual(first, second)
    }

    // MARK: - Reihenfolge

    func testMostRecentCustomerComesFirst() {
        let summaries = CustomerSummary.from(
            bookings: [
                booking("Lange her", daysFromNow: -60),
                booking("Gestern", daysFromNow: -1),
                booking("Letzte Woche", daysFromNow: -7)
            ],
            now: now
        )

        XCTAssertEqual(summaries.map(\.name), ["Gestern", "Letzte Woche", "Lange her"])
    }

    func testCustomerWithOnlyAFutureBookingIsListedLast() {
        let summaries = CustomerSummary.from(
            bookings: [
                booking("Neu", daysFromNow: 3),
                booking("Stammkunde", daysFromNow: -3)
            ],
            now: now
        )

        XCTAssertEqual(summaries.map(\.name), ["Stammkunde", "Neu"])
    }
}
