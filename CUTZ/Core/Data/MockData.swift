import Foundation

/// Erfundene Beispieldaten für die Entwicklung.
///
/// Alle Shops liegen in Hamburg. Wenn ihr in einer anderen Stadt testen
/// wollt: einfach Koordinaten und Adressen hier austauschen — und in
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
            name: "Schanzen Barbers",
            description: "Klassischer Herrenschnitt mit heißem Handtuch und Nassrasur. Seit 2014 im Schanzenviertel.",
            street: "Schanzenstraße 41",
            postalCode: "20357",
            city: "Hamburg",
            latitude: 53.5629,
            longitude: 9.9648,
            phone: "+49 40 12345678",
            imageURL: nil,
            priceLevel: 2,
            averageRating: 4.7,
            reviewCount: 3,
            services: [
                BarberService(id: UUID(uuidString: "a1000000-0000-0000-0000-000000000001")!,
                              name: "Herrenhaarschnitt", durationMinutes: 30, priceCents: 2800),
                BarberService(id: UUID(uuidString: "a1000000-0000-0000-0000-000000000002")!,
                              name: "Bart trimmen", durationMinutes: 20, priceCents: 1800),
                BarberService(id: UUID(uuidString: "a1000000-0000-0000-0000-000000000003")!,
                              name: "Schnitt & Bart", durationMinutes: 60, priceCents: 4200)
            ],
            openingHours: standardHours
        ),

        Barbershop(
            id: shopID2,
            name: "Fade & Co.",
            description: "Spezialisiert auf Fades, Skin Fades und moderne Styles. Junges Team, laute Musik.",
            street: "Reeperbahn 112",
            postalCode: "20359",
            city: "Hamburg",
            latitude: 53.5497,
            longitude: 9.9600,
            phone: "+49 40 23456789",
            imageURL: nil,
            priceLevel: 3,
            averageRating: 4.9,
            reviewCount: 2,
            services: [
                BarberService(id: UUID(uuidString: "a2000000-0000-0000-0000-000000000001")!,
                              name: "Skin Fade", durationMinutes: 45, priceCents: 3500),
                BarberService(id: UUID(uuidString: "a2000000-0000-0000-0000-000000000002")!,
                              name: "Buzz Cut", durationMinutes: 15, priceCents: 1500),
                BarberService(id: UUID(uuidString: "a2000000-0000-0000-0000-000000000003")!,
                              name: "Komplettpaket", durationMinutes: 75, priceCents: 5900)
            ],
            openingHours: standardHours
        ),

        Barbershop(
            id: shopID3,
            name: "Altona Cuts",
            description: "Familienbetrieb in dritter Generation. Auch Kinderhaarschnitte, ohne Termin möglich.",
            street: "Ottenser Hauptstraße 8",
            postalCode: "22765",
            city: "Hamburg",
            latitude: 53.5510,
            longitude: 9.9350,
            phone: "+49 40 34567890",
            imageURL: nil,
            priceLevel: 1,
            averageRating: 4.2,
            reviewCount: 2,
            services: [
                BarberService(id: UUID(uuidString: "a3000000-0000-0000-0000-000000000001")!,
                              name: "Herrenhaarschnitt", durationMinutes: 30, priceCents: 1900),
                BarberService(id: UUID(uuidString: "a3000000-0000-0000-0000-000000000002")!,
                              name: "Kinderhaarschnitt", durationMinutes: 20, priceCents: 1200)
            ],
            openingHours: standardHours
        ),

        Barbershop(
            id: shopID4,
            name: "Eppendorf Grooming",
            description: "Gehobenes Ambiente, Espresso inklusive. Termin empfohlen.",
            street: "Eppendorfer Landstraße 77",
            postalCode: "20249",
            city: "Hamburg",
            latitude: 53.5920,
            longitude: 9.9880,
            phone: "+49 40 45678901",
            imageURL: nil,
            priceLevel: 3,
            averageRating: 4.5,
            reviewCount: 1,
            services: [
                BarberService(id: UUID(uuidString: "a4000000-0000-0000-0000-000000000001")!,
                              name: "Signature Cut", durationMinutes: 60, priceCents: 6500),
                BarberService(id: UUID(uuidString: "a4000000-0000-0000-0000-000000000002")!,
                              name: "Nassrasur", durationMinutes: 45, priceCents: 4500)
            ],
            openingHours: standardHours
        ),

        Barbershop(
            id: shopID5,
            name: "St. Pauli Razor",
            description: "Walk-ins willkommen. Tattoos, Barbier-Handwerk und Kiez-Atmosphäre.",
            street: "Talstraße 20",
            postalCode: "20359",
            city: "Hamburg",
            latitude: 53.5505,
            longitude: 9.9640,
            phone: "+49 40 56789012",
            imageURL: nil,
            priceLevel: 2,
            averageRating: 4.0,
            reviewCount: 1,
            services: [
                BarberService(id: UUID(uuidString: "a5000000-0000-0000-0000-000000000001")!,
                              name: "Classic Cut", durationMinutes: 30, priceCents: 2500),
                BarberService(id: UUID(uuidString: "a5000000-0000-0000-0000-000000000002")!,
                              name: "Bart-Styling", durationMinutes: 30, priceCents: 2200)
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
               comment: "Die besten Fades in Hamburg, kein Vergleich.",
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
