import Foundation

/// Erfundene Beispieldaten für die Entwicklung.
///
/// Alle Shops liegen in Kassel. Die Adressen und Koordinaten sind echt
/// gewählt (Königsstraße, Wilhelmshöher Allee usw.), die Shops selbst
/// aber ausgedacht — es sind keine realen Betriebe gemeint.
///
/// Andere Stadt zum Testen? Hier die Koordinaten austauschen und in
/// `MapScreen.swift` die Standard-Kartenposition anpassen.
enum MockData {

    // Feste IDs statt `UUID()`.
    //
    // Wichtig: Mit `UUID()` bekäme jeder Shop bei jedem App-Start eine
    // neue ID. Bewertungen könnten dann nicht mehr zugeordnet werden und
    // SwiftUI würde Listen unnötig komplett neu zeichnen.
    static let shopID1 = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    static let shopID2 = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    static let shopID3 = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
    static let shopID4 = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
    static let shopID5 = UUID(uuidString: "55555555-5555-5555-5555-555555555555")!

    /// Standard-Öffnungszeiten: Mo–Fr 9–19 Uhr, Sa 10–16 Uhr, So zu.
    /// (Erinnerung: 1 = Sonntag, 2 = Montag … 7 = Samstag)
    static let standardHours: [OpeningHour] = [
        OpeningHour(weekday: 2, from: 9, to: 19),
        OpeningHour(weekday: 3, from: 9, to: 19),
        OpeningHour(weekday: 4, from: 9, to: 19),
        OpeningHour(weekday: 5, from: 9, to: 19),
        OpeningHour(weekday: 6, from: 9, to: 19),
        OpeningHour(weekday: 7, from: 10, to: 16)
    ]

    static let shops: [Barbershop] = [
        Barbershop(
            id: shopID1,
            name: "Königs Barbershop",
            description: "Klassischer Herrenschnitt mit heißem Handtuch und Nassrasur. Mitten auf der Königsstraße.",
            street: "Königsstraße 42",
            postalCode: "34117",
            city: "Kassel",
            latitude: 51.3155,
            longitude: 9.4930,
            phone: "+49 561 1234567",
            imageURL: nil,
            priceLevel: 2,
            averageRating: 4.7,
            reviewCount: 3,
            services: [
                BarberService(id: UUID(uuidString: "a1000000-0000-0000-0000-000000000001")!,
                              name: "Herrenhaarschnitt", durationMinutes: 30, priceCents: 2600),
                BarberService(id: UUID(uuidString: "a1000000-0000-0000-0000-000000000002")!,
                              name: "Bart trimmen", durationMinutes: 20, priceCents: 1600),
                BarberService(id: UUID(uuidString: "a1000000-0000-0000-0000-000000000003")!,
                              name: "Schnitt & Bart", durationMinutes: 60, priceCents: 3900)
            ],
            openingHours: standardHours
        ),

        Barbershop(
            id: shopID2,
            name: "Fade Lounge Nord",
            description: "Spezialisiert auf Fades, Skin Fades und moderne Styles. Junges Team, laute Musik.",
            street: "Holländische Straße 74",
            postalCode: "34127",
            city: "Kassel",
            latitude: 51.3262,
            longitude: 9.4878,
            phone: "+49 561 2345678",
            imageURL: nil,
            priceLevel: 3,
            averageRating: 4.9,
            reviewCount: 2,
            services: [
                BarberService(id: UUID(uuidString: "a2000000-0000-0000-0000-000000000001")!,
                              name: "Skin Fade", durationMinutes: 45, priceCents: 3300),
                BarberService(id: UUID(uuidString: "a2000000-0000-0000-0000-000000000002")!,
                              name: "Buzz Cut", durationMinutes: 15, priceCents: 1400),
                BarberService(id: UUID(uuidString: "a2000000-0000-0000-0000-000000000003")!,
                              name: "Komplettpaket", durationMinutes: 75, priceCents: 5500)
            ],
            openingHours: standardHours
        ),

        Barbershop(
            id: shopID3,
            name: "Westend Cuts",
            description: "Familienbetrieb in dritter Generation. Auch Kinderhaarschnitte, oft auch ohne Termin.",
            street: "Friedrich-Ebert-Straße 88",
            postalCode: "34119",
            city: "Kassel",
            latitude: 51.3106,
            longitude: 9.4788,
            phone: "+49 561 3456789",
            imageURL: nil,
            priceLevel: 1,
            averageRating: 4.2,
            reviewCount: 2,
            services: [
                BarberService(id: UUID(uuidString: "a3000000-0000-0000-0000-000000000001")!,
                              name: "Herrenhaarschnitt", durationMinutes: 30, priceCents: 1800),
                BarberService(id: UUID(uuidString: "a3000000-0000-0000-0000-000000000002")!,
                              name: "Kinderhaarschnitt", durationMinutes: 20, priceCents: 1200)
            ],
            openingHours: standardHours
        ),

        Barbershop(
            id: shopID4,
            name: "Wilhelmshöhe Grooming",
            description: "Gehobenes Ambiente nahe dem Bergpark, Espresso inklusive. Termin empfohlen.",
            street: "Wilhelmshöher Allee 259",
            postalCode: "34131",
            city: "Kassel",
            latitude: 51.3124,
            longitude: 9.4571,
            phone: "+49 561 4567890",
            imageURL: nil,
            priceLevel: 3,
            averageRating: 4.5,
            reviewCount: 1,
            services: [
                BarberService(id: UUID(uuidString: "a4000000-0000-0000-0000-000000000001")!,
                              name: "Signature Cut", durationMinutes: 60, priceCents: 5900),
                BarberService(id: UUID(uuidString: "a4000000-0000-0000-0000-000000000002")!,
                              name: "Nassrasur", durationMinutes: 45, priceCents: 4200)
            ],
            openingHours: standardHours
        ),

        Barbershop(
            id: shopID5,
            name: "Südstadt Razor",
            description: "Walk-ins willkommen. Barbier-Handwerk ohne Schnickschnack, seit 2011.",
            street: "Frankfurter Straße 55",
            postalCode: "34121",
            city: "Kassel",
            latitude: 51.3052,
            longitude: 9.4906,
            phone: "+49 561 5678901",
            imageURL: nil,
            priceLevel: 2,
            averageRating: 4.0,
            reviewCount: 1,
            services: [
                BarberService(id: UUID(uuidString: "a5000000-0000-0000-0000-000000000001")!,
                              name: "Classic Cut", durationMinutes: 30, priceCents: 2300),
                BarberService(id: UUID(uuidString: "a5000000-0000-0000-0000-000000000002")!,
                              name: "Bart-Styling", durationMinutes: 30, priceCents: 2000)
            ],
            openingHours: standardHours
        )
    ]

    static let reviews: [Review] = [
        Review(id: UUID(), shopID: shopID1, authorName: "Jonas M.", rating: 5,
               comment: "Bester Schnitt seit Jahren. Sehr entspannte Atmosphäre, wird nichts überstürzt.",
               createdAt: .now.addingTimeInterval(-3 * 86_400)),
        Review(id: UUID(), shopID: shopID1, authorName: "Ali K.", rating: 5,
               comment: "Nassrasur war top. Komme definitiv wieder.",
               createdAt: .now.addingTimeInterval(-12 * 86_400)),
        Review(id: UUID(), shopID: shopID1, authorName: "Tim R.", rating: 4,
               comment: "Guter Schnitt, aber trotz Termin 15 Minuten Wartezeit.",
               createdAt: .now.addingTimeInterval(-25 * 86_400)),

        Review(id: UUID(), shopID: shopID2, authorName: "Deniz Y.", rating: 5,
               comment: "Die besten Fades in Kassel, kein Vergleich.",
               createdAt: .now.addingTimeInterval(-2 * 86_400)),
        Review(id: UUID(), shopID: shopID2, authorName: "Marc B.", rating: 5,
               comment: "Preis ist gehoben, aber das Ergebnis stimmt jedes Mal.",
               createdAt: .now.addingTimeInterval(-9 * 86_400)),

        Review(id: UUID(), shopID: shopID3, authorName: "Familie Schulz", rating: 4,
               comment: "Sehr geduldig mit unserem Sohn. Faire Preise.",
               createdAt: .now.addingTimeInterval(-5 * 86_400)),
        Review(id: UUID(), shopID: shopID3, authorName: "Nina P.", rating: 4,
               comment: "Unkompliziert und schnell, auch spontan.",
               createdAt: .now.addingTimeInterval(-18 * 86_400)),

        Review(id: UUID(), shopID: shopID4, authorName: "Sebastian L.", rating: 5,
               comment: "Fühlt sich eher nach Spa an als nach Friseur. Top.",
               createdAt: .now.addingTimeInterval(-7 * 86_400)),

        Review(id: UUID(), shopID: shopID5, authorName: "Kevin H.", rating: 4,
               comment: "Ordentlicher Schnitt, sehr sympathisches Team.",
               createdAt: .now.addingTimeInterval(-4 * 86_400))
    ]
}
