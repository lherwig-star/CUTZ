import Foundation

/// Ein einzelner Barber, der in einem Shop arbeitet.
///
/// Warum eigene Bewertung und eigenes Portfolio? Weil man sich beim
/// Friseur nicht den Laden aussucht, sondern die Person. Wer einmal
/// einen guten Fade bei Samir hatte, will wieder zu Samir — nicht
/// irgendwohin in denselben Laden.
///
/// Deshalb steht der Mitarbeiter als eigenes Modell da und nicht nur
/// als Text im Shop. Später kann man so auch Cuts einzelner Barber
/// anzeigen, ohne dass etwas umgebaut werden muss.
struct BarberEmployee: Identifiable, Codable, Hashable {

    let id: UUID
    var name: String

    var rating: Double
    var reviewCount: Int

    /// Worauf diese Person spezialisiert ist, z. B. Fade und Beard.
    /// Wird auf der Auswahlkarte im Buchungsablauf angezeigt.
    var specialties: [ServiceCategory]

    /// Profilbild. Noch leer — echte Fotos kommen mit Supabase Storage
    /// (Phase 5). Bis dahin zeichnet die App einen Platzhalter.
    var imageURL: URL?

    /// Beispielarbeiten dieser Person. Ebenfalls noch leer.
    var portfolioImageURLs: [URL]

    /// z. B. "Fade · Beard" für die Auswahlkarte.
    var specialtiesText: String {
        specialties.map(\.label).joined(separator: " · ")
    }

    init(
        id: UUID,
        name: String,
        rating: Double,
        reviewCount: Int,
        specialties: [ServiceCategory],
        imageURL: URL? = nil,
        portfolioImageURLs: [URL] = []
    ) {
        self.id = id
        self.name = name
        self.rating = rating
        self.reviewCount = reviewCount
        self.specialties = specialties
        self.imageURL = imageURL
        self.portfolioImageURLs = portfolioImageURLs
    }
}
