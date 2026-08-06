import Foundation

/// Eine Kundenbewertung für einen Shop.
struct Review: Identifiable, Codable, Hashable {

    let id: UUID
    var shopID: UUID

    var authorName: String

    /// Sterne von 1 bis 5.
    var rating: Int

    var comment: String
    var createdAt: Date

    /// z. B. "vor 3 Tagen" — macht iOS für uns, in der Sprache des Nutzers.
    var createdAtRelative: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: createdAt, relativeTo: .now)
    }
}
