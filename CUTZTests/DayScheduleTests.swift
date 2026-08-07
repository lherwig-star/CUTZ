import XCTest
@testable import CUTZ

/// Tests für die Tagesleiste der Friseurseite.
///
/// Der Teil, auf den es ankommt, sind die LÜCKEN. Termine anzuzeigen
/// ist einfach; herauszufinden, wo noch etwas hineinpasst, ist die
/// eigentliche Rechnung — und dort stecken die Fehler an
/// Tagesgrenzen und bei Überschneidungen.
final class DayScheduleTests: XCTestCase {

    private let calendar = Calendar.current

    // MARK: - Testaufbau

    /// Ein Laden, der an JEDEM Wochentag von 9 bis 18 Uhr offen hat.
    ///
    /// Öffnungszeiten für alle sieben Tage, damit der Test nicht davon
    /// abhängt, welcher Wochentag gerade ist. Genau daran ist in
    /// diesem Projekt schon einmal ein Test auf dem englischen
    /// Rechner bei GitHub gescheitert.
    private func makeShop(services: [BarberService] = []) -> Barbershop {
        Barbershop(
            id: UUID(),
            name: "Testladen",
            description: "",
            street: "Teststraße 1",
            postalCode: "34117",
            city: "Kassel",
            latitude: 51.31,
            longitude: 9.49,
            phone: nil,
            imageURL: nil,
            priceLevel: 2,
            averageRating: 0,
            reviewCount: 0,
            services: services,
            openingHours: (1...7).map { OpeningHour(weekday: $0, from: 9, to: 18) }
        )
    }

    /// Ein fester Tag, damit die Rechnung immer dieselbe ist.
    private var day: Date {
        calendar.startOfDay(for: Date(timeIntervalSince1970: 1_800_000_000))
    }

    private func time(_ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(byAdding: .minute, value: hour * 60 + minute, to: day)!
    }

    private func makeBooking(
        shopID: UUID,
        at start: Date,
        minutes: Int = 30,
        customer: String = "Testkunde",
        status: BookingStatus = .confirmed
    ) -> Booking {
        Booking(
            id: UUID(),
            shopID: shopID,
            shopName: "Testladen",
            shopAddress: "Teststraße 1",
            serviceID: UUID(),
            serviceName: "Herrenhaarschnitt",
            customerName: customer,
            startsAt: start,
            durationMinutes: minutes,
            status: status
        )
    }

    // MARK: - Leerer Tag

    func testEmptyDayIsOneLongFreeBlock() {
        let shop = makeShop()

        let entries = DaySchedule.entries(
            for: day, shop: shop, bookings: [], calendar: calendar
        )

        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.kind, .free)
        XCTAssertEqual(entries.first?.startsAt, time(9))
        XCTAssertEqual(entries.first?.endsAt, time(18))
    }

    func testClosedDayHasNoEntries() {
        // Ein Laden ganz ohne Öffnungszeiten hat nie geöffnet.
        var shop = makeShop()
        shop.openingHours = []

        XCTAssertTrue(
            DaySchedule.entries(for: day, shop: shop, bookings: [], calendar: calendar).isEmpty
        )
    }

    // MARK: - Lücken

    func testGapsAppearBeforeBetweenAndAfter() {
        let shop = makeShop()
        let bookings = [
            makeBooking(shopID: shop.id, at: time(10), minutes: 60),
            makeBooking(shopID: shop.id, at: time(14), minutes: 30)
        ]

        let entries = DaySchedule.entries(
            for: day, shop: shop, bookings: bookings, calendar: calendar
        )

        // frei 9–10, Termin 10–11, frei 11–14, Termin 14–14:30, frei 14:30–18
        XCTAssertEqual(entries.count, 5)
        XCTAssertEqual(entries.map(\.startsAt),
                       [time(9), time(10), time(11), time(14), time(14, 30)])
    }

    func testTinyGapIsSwallowed() {
        // Zwischen 10:00 und 10:05 passt nichts hinein. So eine Lücke
        // anzuzeigen wäre nur Rauschen in der Liste.
        let shop = makeShop()
        let bookings = [
            makeBooking(shopID: shop.id, at: time(9), minutes: 60),
            makeBooking(shopID: shop.id, at: time(10, 5), minutes: 30)
        ]

        let entries = DaySchedule.entries(
            for: day, shop: shop, bookings: bookings, calendar: calendar
        )

        XCTAssertEqual(entries.count, 3, "Die 5-Minuten-Lücke gehört nicht in die Liste.")
        XCTAssertEqual(entries[2].kind, .free, "Nach dem letzten Termin ist noch offen.")
    }

    // MARK: - Was Zeit belegt und was nicht

    func testCancelledBookingFreesItsTime() {
        let shop = makeShop()
        let bookings = [
            makeBooking(shopID: shop.id, at: time(12), minutes: 60, status: .cancelled)
        ]

        let entries = DaySchedule.entries(
            for: day, shop: shop, bookings: bookings, calendar: calendar
        )

        XCTAssertEqual(entries.count, 1, "Der abgesagte Termin darf keine Zeit mehr belegen.")
        XCTAssertEqual(entries.first?.kind, .free)
    }

    func testPauseBlocksTimeLikeABooking() {
        let shop = makeShop()
        let pause = TimeBlock(
            shopID: shop.id, startsAt: time(12), endsAt: time(13), reason: .pause
        )

        let entries = DaySchedule.entries(
            for: day, shop: shop, bookings: [], blocks: [pause], calendar: calendar
        )

        // frei 9–12, Pause 12–13, frei 13–18
        XCTAssertEqual(entries.count, 3)
        XCTAssertEqual(entries[1].kind, .blocked(pause))
    }

    func testEntriesAreSortedByTime() {
        let shop = makeShop()
        // Bewusst in falscher Reihenfolge hineingegeben.
        let bookings = [
            makeBooking(shopID: shop.id, at: time(15)),
            makeBooking(shopID: shop.id, at: time(10))
        ]

        let entries = DaySchedule.entries(
            for: day, shop: shop, bookings: bookings, calendar: calendar
        )

        XCTAssertEqual(entries.map(\.startsAt), entries.map(\.startsAt).sorted())
    }

    func testOverlappingEntriesDoNotCreateNegativeGaps() {
        // Eine Urlaubssperre kann über einem älteren Termin liegen.
        // Ohne Vorsicht käme dabei eine Lücke mit negativer Länge
        // heraus — oder die Liste geriete durcheinander.
        let shop = makeShop()
        let booking = makeBooking(shopID: shop.id, at: time(10), minutes: 120)
        let block = TimeBlock(
            shopID: shop.id, startsAt: time(11), endsAt: time(13), reason: .vacation
        )

        let entries = DaySchedule.entries(
            for: day, shop: shop, bookings: [booking], blocks: [block], calendar: calendar
        )

        for entry in entries where entry.kind == .free {
            XCTAssertGreaterThan(entry.durationMinutes, 0)
        }
        XCTAssertEqual(entries.last?.endsAt, time(18))
    }

    func testBookingsOfOtherDaysAreIgnored() {
        let shop = makeShop()
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: time(10))!

        let entries = DaySchedule.entries(
            for: day,
            shop: shop,
            bookings: [makeBooking(shopID: shop.id, at: tomorrow)],
            calendar: calendar
        )

        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.kind, .free)
    }

    // MARK: - Beschriftung

    func testHourLabelsCoverTheOpeningHours() {
        XCTAssertEqual(
            DaySchedule.hourLabels(for: day, shop: makeShop(), calendar: calendar),
            Array(9...18)
        )
    }

    func testHourLabelsRoundOutwards() {
        // Öffnet der Laden um 9:30 und schließt um 18:30, soll die
        // Beschriftung trotzdem bei vollen Stunden stehen.
        var shop = makeShop()
        shop.openingHours = (1...7).map {
            OpeningHour(weekday: $0, opensAtMinute: 9 * 60 + 30, closesAtMinute: 18 * 60 + 30)
        }

        XCTAssertEqual(
            DaySchedule.hourLabels(for: day, shop: shop, calendar: calendar),
            Array(9...19)
        )
    }

    // MARK: - Anzeigetext

    func testTimeRangeTextIsTwoDigits() {
        let entry = DayEntry(kind: .free, startsAt: time(9, 5), endsAt: time(10))
        XCTAssertEqual(entry.timeRangeText, "09:05 – 10:00")
    }
}
