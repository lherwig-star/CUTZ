import XCTest
@testable import CUTZ

/// Tests für das Filtern und Sortieren von Bewertungen.
///
/// Warum hier Tests? Aus demselben Grund wie beim `SlotCalculator`:
/// Man sieht einer Liste nicht an, ob sie richtig sortiert ist. Wenn bei
/// "Beste zuerst" eine 3-Sterne-Bewertung nach oben rutscht, fällt das
/// beim Durchklicken kaum auf — in den Tests dagegen sofort.
///
/// Ausführen in Xcode mit ⌘U.
final class ReviewFilteringTests: XCTestCase {

    // Ein fester Bezugspunkt, damit die Tests morgen noch genauso laufen.
    private let referenceDate = Date(timeIntervalSince1970: 1_777_000_000)

    /// Baut eine Bewertung mit den Sternen und dem Alter, die der Test braucht.
    /// `daysAgo` zählt vom Bezugspunkt aus rückwärts.
    private func makeReview(rating: Int, daysAgo: Int, author: String = "Test") -> Review {
        Review(
            id: UUID(),
            shopID: UUID(),
            authorName: author,
            rating: rating,
            comment: "Kommentar",
            createdAt: referenceDate.addingTimeInterval(TimeInterval(-daysAgo * 86_400))
        )
    }

    /// Fünf Bewertungen mit unterschiedlichen Sternen und Daten.
    private var sampleReviews: [Review] {
        [
            makeReview(rating: 5, daysAgo: 10, author: "Alt und gut"),
            makeReview(rating: 3, daysAgo: 5,  author: "Mittel"),
            makeReview(rating: 5, daysAgo: 1,  author: "Neu und gut"),
            makeReview(rating: 1, daysAgo: 20, author: "Schlecht"),
            makeReview(rating: 4, daysAgo: 3,  author: "Gut"),
        ]
    }

    // MARK: - Filtern

    func testFilterAllKeepsEverything() {
        let result = ReviewFiltering.apply(
            to: sampleReviews, rating: .all, sort: .newest
        )

        XCTAssertEqual(result.count, 5, "Ohne Filter darf nichts wegfallen.")
    }

    func testFilterFourPlusRemovesLowerRatings() {
        let result = ReviewFiltering.apply(
            to: sampleReviews, rating: .fourPlus, sort: .newest
        )

        // Übrig bleiben: 5, 5, 4
        XCTAssertEqual(result.count, 3)
        XCTAssertTrue(
            result.allSatisfy { $0.rating >= 4 },
            "Bei 'Ab 4 Sternen' darf keine Bewertung mit 3 oder weniger durchkommen."
        )
    }

    func testFilterFiveOnlyKeepsOnlyTopRatings() {
        let result = ReviewFiltering.apply(
            to: sampleReviews, rating: .fiveOnly, sort: .newest
        )

        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { $0.rating == 5 })
    }

    func testFilterCanReturnEmptyList() {
        // Nur Bewertungen mit 1 und 2 Sternen — "Nur 5 Sterne" findet nichts.
        let poorReviews = [
            makeReview(rating: 1, daysAgo: 1),
            makeReview(rating: 2, daysAgo: 2),
        ]

        let result = ReviewFiltering.apply(
            to: poorReviews, rating: .fiveOnly, sort: .newest
        )

        XCTAssertTrue(
            result.isEmpty,
            "Passt nichts zum Filter, ist eine leere Liste das richtige Ergebnis."
        )
    }

    // MARK: - Sortieren

    func testNewestFirst() {
        let result = ReviewFiltering.apply(
            to: sampleReviews, rating: .all, sort: .newest
        )

        XCTAssertEqual(result.first?.authorName, "Neu und gut")
        XCTAssertEqual(result.last?.authorName, "Schlecht")
    }

    func testBestFirst() {
        let result = ReviewFiltering.apply(
            to: sampleReviews, rating: .all, sort: .bestFirst
        )

        XCTAssertEqual(result.map(\.rating), [5, 5, 4, 3, 1])
    }

    func testWorstFirst() {
        let result = ReviewFiltering.apply(
            to: sampleReviews, rating: .all, sort: .worstFirst
        )

        XCTAssertEqual(result.map(\.rating), [1, 3, 4, 5, 5])
    }

    func testEqualRatingsAreSortedByDate() {
        // Beide haben 5 Sterne — dann muss die neuere zuerst kommen.
        // Ohne diese Zusatzregel wäre die Reihenfolge zufällig, und die
        // Liste würde bei jedem Neuzeichnen anders aussehen.
        let result = ReviewFiltering.apply(
            to: sampleReviews, rating: .fiveOnly, sort: .bestFirst
        )

        XCTAssertEqual(result.first?.authorName, "Neu und gut")
        XCTAssertEqual(result.last?.authorName, "Alt und gut")
    }

    // MARK: - Randfälle

    func testEmptyInputStaysEmpty() {
        let result = ReviewFiltering.apply(
            to: [], rating: .all, sort: .newest
        )

        XCTAssertTrue(result.isEmpty)
    }

    func testFilteringDoesNotChangeTheOriginalList() {
        let original = sampleReviews

        _ = ReviewFiltering.apply(to: original, rating: .fiveOnly, sort: .worstFirst)

        XCTAssertEqual(
            original.count, 5,
            "Die übergebene Liste darf nicht verändert werden."
        )
    }
}
