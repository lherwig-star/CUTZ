import Foundation

/// Erfundene Beispieldaten für die Entwicklung.
///
/// Alle Shops liegen in Kassel. Die Adressen und Koordinaten sind echt
/// gewählt (Königsstraße, Wilhelmshöher Allee usw.), die Shops selbst
/// aber ausgedacht — es sind keine realen Betriebe gemeint. Auch die
/// Mitarbeiternamen sind frei erfunden.
///
/// Andere Stadt zum Testen? Hier die Koordinaten austauschen und in
/// `DiscoverMap.swift` die Standard-Kartenposition anpassen.
enum MockData {

    // Feste IDs statt `UUID()`.
    //
    // Wichtig: Mit `UUID()` bekäme jeder Shop bei jedem App-Start eine
    // neue ID. Bewertungen und Favoriten könnten dann nicht mehr
    // zugeordnet werden und SwiftUI würde Listen unnötig neu zeichnen.
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

    /// Späte Öffnungszeiten für den Laden mit dem jungen Publikum.
    static let lateHours: [OpeningHour] = [
        OpeningHour(weekday: 3, from: 11, to: 21),
        OpeningHour(weekday: 4, from: 11, to: 21),
        OpeningHour(weekday: 5, from: 11, to: 21),
        OpeningHour(weekday: 6, from: 11, to: 22),
        OpeningHour(weekday: 7, from: 10, to: 20)
    ]

    // Kleiner Helfer, damit die IDs unten lesbar bleiben.
    private static func id(_ text: String) -> UUID {
        UUID(uuidString: text)!
    }

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
            reviewCount: 184,
            services: [
                BarberService(id: id("a1000000-0000-0000-0000-000000000001"),
                              name: "Herrenhaarschnitt", durationMinutes: 30,
                              priceCents: 2600, category: .haircut),
                BarberService(id: id("a1000000-0000-0000-0000-000000000002"),
                              name: "Bart trimmen", durationMinutes: 20,
                              priceCents: 1600, category: .beard),
                BarberService(id: id("a1000000-0000-0000-0000-000000000003"),
                              name: "Schnitt & Bart", durationMinutes: 60,
                              priceCents: 3900, category: .hairAndBeard)
            ],
            openingHours: standardHours,
            employees: [
                BarberEmployee(id: id("b1000000-0000-0000-0000-000000000001"),
                               name: "Samir", rating: 4.9, reviewCount: 96,
                               specialties: [.skinFade, .beard]),
                BarberEmployee(id: id("b1000000-0000-0000-0000-000000000002"),
                               name: "Erol", rating: 4.7, reviewCount: 61,
                               specialties: [.haircut, .hairAndBeard]),
                BarberEmployee(id: id("b1000000-0000-0000-0000-000000000003"),
                               name: "Tobias", rating: 4.5, reviewCount: 27,
                               specialties: [.haircut])
            ]
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
            reviewCount: 231,
            services: [
                BarberService(id: id("a2000000-0000-0000-0000-000000000001"),
                              name: "Skin Fade", durationMinutes: 45,
                              priceCents: 3300, category: .skinFade),
                BarberService(id: id("a2000000-0000-0000-0000-000000000002"),
                              name: "Buzz Cut", durationMinutes: 15,
                              priceCents: 1400, category: .haircut),
                BarberService(id: id("a2000000-0000-0000-0000-000000000003"),
                              name: "Komplettpaket", durationMinutes: 75,
                              priceCents: 5500, category: .hairAndBeard),
                BarberService(id: id("a2000000-0000-0000-0000-000000000004"),
                              name: "Beard Shape", durationMinutes: 20,
                              priceCents: 1800, category: .beard)
            ],
            openingHours: lateHours,
            employees: [
                BarberEmployee(id: id("b2000000-0000-0000-0000-000000000001"),
                               name: "Deniz", rating: 5.0, reviewCount: 142,
                               specialties: [.skinFade, .haircut]),
                BarberEmployee(id: id("b2000000-0000-0000-0000-000000000002"),
                               name: "Luis", rating: 4.8, reviewCount: 74,
                               specialties: [.skinFade, .beard])
            ]
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
            reviewCount: 57,
            services: [
                BarberService(id: id("a3000000-0000-0000-0000-000000000001"),
                              name: "Herrenhaarschnitt", durationMinutes: 30,
                              priceCents: 1800, category: .haircut),
                BarberService(id: id("a3000000-0000-0000-0000-000000000002"),
                              name: "Kinderhaarschnitt", durationMinutes: 20,
                              priceCents: 1200, category: .haircut),
                BarberService(id: id("a3000000-0000-0000-0000-000000000003"),
                              name: "Bart trimmen", durationMinutes: 15,
                              priceCents: 1000, category: .beard)
            ],
            openingHours: standardHours,
            employees: [
                BarberEmployee(id: id("b3000000-0000-0000-0000-000000000001"),
                               name: "Michael", rating: 4.3, reviewCount: 38,
                               specialties: [.haircut]),
                BarberEmployee(id: id("b3000000-0000-0000-0000-000000000002"),
                               name: "Andreas", rating: 4.1, reviewCount: 19,
                               specialties: [.haircut, .beard])
            ]
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
            averageRating: 4.6,
            reviewCount: 93,
            services: [
                BarberService(id: id("a4000000-0000-0000-0000-000000000001"),
                              name: "Signature Cut", durationMinutes: 60,
                              priceCents: 5900, category: .haircut),
                BarberService(id: id("a4000000-0000-0000-0000-000000000002"),
                              name: "Nassrasur", durationMinutes: 45,
                              priceCents: 4200, category: .beard),
                BarberService(id: id("a4000000-0000-0000-0000-000000000003"),
                              name: "Cut & Beard Deluxe", durationMinutes: 90,
                              priceCents: 8900, category: .hairAndBeard)
            ],
            openingHours: standardHours,
            employees: [
                BarberEmployee(id: id("b4000000-0000-0000-0000-000000000001"),
                               name: "Julian", rating: 4.8, reviewCount: 64,
                               specialties: [.haircut, .hairAndBeard]),
                BarberEmployee(id: id("b4000000-0000-0000-0000-000000000002"),
                               name: "Marco", rating: 4.4, reviewCount: 29,
                               specialties: [.beard])
            ]
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
            reviewCount: 41,
            services: [
                BarberService(id: id("a5000000-0000-0000-0000-000000000001"),
                              name: "Classic Cut", durationMinutes: 30,
                              priceCents: 2300, category: .haircut),
                BarberService(id: id("a5000000-0000-0000-0000-000000000002"),
                              name: "Bart-Styling", durationMinutes: 30,
                              priceCents: 2000, category: .beard),
                BarberService(id: id("a5000000-0000-0000-0000-000000000003"),
                              name: "Fade", durationMinutes: 40,
                              priceCents: 2800, category: .skinFade)
            ],
            openingHours: standardHours,
            employees: [
                BarberEmployee(id: id("b5000000-0000-0000-0000-000000000001"),
                               name: "Kai", rating: 4.2, reviewCount: 33,
                               specialties: [.haircut, .skinFade])
            ]
        )
    ]

    static let reviews: [Review] = [
        Review(id: id("c0000000-0000-0000-0000-000000000001"), shopID: shopID1,
               authorName: "Jonas M.", rating: 5,
               comment: "Bester Schnitt seit Jahren. Sehr entspannte Atmosphäre, wird nichts überstürzt.",
               createdAt: .now.addingTimeInterval(-3 * 86_400)),
        Review(id: id("c0000000-0000-0000-0000-000000000002"), shopID: shopID1,
               authorName: "Ali K.", rating: 5,
               comment: "Nassrasur war top. Komme definitiv wieder.",
               createdAt: .now.addingTimeInterval(-12 * 86_400)),
        Review(id: id("c0000000-0000-0000-0000-000000000003"), shopID: shopID1,
               authorName: "Tim R.", rating: 4,
               comment: "Guter Schnitt, aber trotz Termin 15 Minuten Wartezeit.",
               createdAt: .now.addingTimeInterval(-25 * 86_400)),
        Review(id: id("c0000000-0000-0000-0000-000000000004"), shopID: shopID1,
               authorName: "Bene", rating: 3,
               comment: "Handwerklich in Ordnung, mir persönlich zu hektisch.",
               createdAt: .now.addingTimeInterval(-40 * 86_400)),

        Review(id: id("c0000000-0000-0000-0000-000000000005"), shopID: shopID2,
               authorName: "Deniz Y.", rating: 5,
               comment: "Die besten Fades in Kassel, kein Vergleich.",
               createdAt: .now.addingTimeInterval(-2 * 86_400)),
        Review(id: id("c0000000-0000-0000-0000-000000000006"), shopID: shopID2,
               authorName: "Marc B.", rating: 5,
               comment: "Preis ist gehoben, aber das Ergebnis stimmt jedes Mal.",
               createdAt: .now.addingTimeInterval(-9 * 86_400)),
        Review(id: id("c0000000-0000-0000-0000-000000000007"), shopID: shopID2,
               authorName: "Nico", rating: 5,
               comment: "Deniz weiß genau, was er tut. Termin online in 30 Sekunden gebucht.",
               createdAt: .now.addingTimeInterval(-15 * 86_400)),

        Review(id: id("c0000000-0000-0000-0000-000000000008"), shopID: shopID3,
               authorName: "Familie Schulz", rating: 4,
               comment: "Sehr geduldig mit unserem Sohn. Faire Preise.",
               createdAt: .now.addingTimeInterval(-5 * 86_400)),
        Review(id: id("c0000000-0000-0000-0000-000000000009"), shopID: shopID3,
               authorName: "Nina P.", rating: 4,
               comment: "Unkompliziert und schnell, auch spontan.",
               createdAt: .now.addingTimeInterval(-18 * 86_400)),
        Review(id: id("c0000000-0000-0000-0000-00000000000a"), shopID: shopID3,
               authorName: "Hendrik", rating: 3,
               comment: "Solide fürs Geld, optisch etwas altmodisch.",
               createdAt: .now.addingTimeInterval(-30 * 86_400)),

        Review(id: id("c0000000-0000-0000-0000-00000000000b"), shopID: shopID4,
               authorName: "Sebastian L.", rating: 5,
               comment: "Fühlt sich eher nach Spa an als nach Friseur. Top.",
               createdAt: .now.addingTimeInterval(-7 * 86_400)),
        Review(id: id("c0000000-0000-0000-0000-00000000000c"), shopID: shopID4,
               authorName: "Philipp", rating: 4,
               comment: "Sehr gute Arbeit, aber der Preis muss einem das wert sein.",
               createdAt: .now.addingTimeInterval(-21 * 86_400)),

        Review(id: id("c0000000-0000-0000-0000-00000000000d"), shopID: shopID5,
               authorName: "Kevin H.", rating: 4,
               comment: "Ordentlicher Schnitt, sehr sympathisches Team.",
               createdAt: .now.addingTimeInterval(-4 * 86_400)),
        Review(id: id("c0000000-0000-0000-0000-00000000000e"), shopID: shopID5,
               authorName: "Sven", rating: 4,
               comment: "Ohne Termin reingegangen, nach 10 Minuten dran gewesen.",
               createdAt: .now.addingTimeInterval(-11 * 86_400))
    ]
}
