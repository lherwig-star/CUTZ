import Foundation

/// Bis wann ein Termin frei sein soll.
///
/// Die Stufen bauen aufeinander auf: Wer "Morgen" wählt, will einen
/// Termin bis morgen — heute ist ihm also auch recht. Das entspricht
/// dem, was man meint, wenn man so filtert.
enum TimingFilter: CaseIterable, Identifiable {

    case any
    case today
    case tomorrow
    case thisWeek

    var id: Self { self }

    var label: String {
        switch self {
        case .any:      return AppText.string("Egal")
        case .today:    return AppText.string("Heute")
        case .tomorrow: return AppText.string("Morgen")
        case .thisWeek: return AppText.string("Diese Woche")
        }
    }

    /// Wie viele Tage ab heute der Termin höchstens entfernt sein darf.
    /// `nil` heißt: keine Grenze.
    var maxDaysAhead: Int? {
        switch self {
        case .any:      return nil
        case .today:    return 0
        case .tomorrow: return 1
        case .thisWeek: return 6
        }
    }
}

/// Wonach die Liste sortiert wird.
enum BarberSort: CaseIterable, Identifiable {

    case recommended
    case distance
    case rating
    case price

    var id: Self { self }

    var label: String {
        switch self {
        case .recommended: return AppText.string("Empfohlen")
        case .distance:    return AppText.string("Entfernung")
        case .rating:      return AppText.string("Bewertung")
        case .price:       return AppText.string("Preis")
        }
    }
}

/// Alle Filtereinstellungen zusammen.
///
/// Bewusst nur diese fünf plus Sortierung. Jeder weitere Filter kostet
/// eine Entscheidung, und Entscheidungen sind genau das, wovon die App
/// möglichst wenige verlangen soll.
struct BarberFilter: Equatable {

    /// Wie weit ein Termin höchstens weg sein darf, damit er als
    /// "sofort" gilt.
    ///
    /// Zwei Stunden, weil das die Spanne ist, in der man tatsächlich
    /// spontan losgeht: "jetzt gleich" heißt nicht in fünf Minuten,
    /// aber auch nicht heute Abend. Wer heute Abend will, nimmt den
    /// Zeitfilter "Heute".
    static let instantWindowMinutes = 120

    /// Nur Barber zeigen, bei denen man praktisch sofort drankommt.
    ///
    /// Eigener Schalter statt einer weiteren Stufe bei `timing`: Das
    /// ist der Fall, für den die App eigentlich gebaut ist — jemand
    /// braucht JETZT einen Haarschnitt. Dafür soll man nicht erst ein
    /// Filtermenü öffnen müssen.
    var onlyAvailableNow = false

    var timing: TimingFilter = .any

    /// Höchstentfernung in Kilometern. `nil` = egal.
    var maxDistanceKm: Double?

    /// Höchstpreis in Euro, bezogen auf die günstigste Leistung. `nil` = egal.
    var maxPriceEuro: Int?

    /// Mindestbewertung. `nil` = egal.
    var minRating: Double?

    /// Gesuchte Leistungsarten. Leer = alle.
    var categories: Set<ServiceCategory> = []

    var sort: BarberSort = .recommended

    /// Wie viele Filter gerade etwas einschränken.
    ///
    /// Die Sortierung zählt NICHT mit — sie schränkt nichts ein, sie
    /// ordnet nur um. Sonst stünde am Knopf dauerhaft eine 1.
    var activeCount: Int {
        var count = 0
        if onlyAvailableNow      { count += 1 }
        if timing != .any        { count += 1 }
        if maxDistanceKm != nil  { count += 1 }
        if maxPriceEuro != nil   { count += 1 }
        if minRating != nil      { count += 1 }
        if !categories.isEmpty   { count += 1 }
        return count
    }

    /// Alles auf Anfang.
    static let none = BarberFilter()
}

/// Wendet Filter und Sortierung an.
///
/// Aufbau wie `SlotCalculator` und `ReviewFiltering`: reine Funktionen,
/// kein SwiftUI. Dadurch ohne laufende App testbar — und gerade beim
/// Filtern schleichen sich Fehler ein, die man in der Oberfläche nicht
/// bemerkt, weil eine kürzere Liste ja plausibel aussieht.
enum BarberFiltering {

    /// - Parameters:
    ///   - nextSlots: nächster freier Termin je Shop-ID.
    ///   - distances: Entfernung in Metern je Shop-ID. Leer, solange
    ///     kein Standort freigegeben ist.
    static func apply(
        to shops: [Barbershop],
        filter: BarberFilter,
        nextSlots: [UUID: Date],
        distances: [UUID: Double],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [Barbershop] {

        let filtered = shops.filter { shop in
            matchesAvailableNow(shop, filter: filter, nextSlots: nextSlots, now: now)
                && matchesTiming(shop, filter: filter, nextSlots: nextSlots, now: now, calendar: calendar)
                && matchesDistance(shop, filter: filter, distances: distances)
                && matchesPrice(shop, filter: filter)
                && matchesRating(shop, filter: filter)
                && matchesCategories(shop, filter: filter)
        }

        return sorted(filtered, by: filter.sort, distances: distances)
    }

    // MARK: - Einzelne Bedingungen

    /// Kommt man bei diesem Shop praktisch sofort dran?
    ///
    /// Termine in der Vergangenheit gibt es nicht — `nextSlots` enthält
    /// nur zukünftige Zeiten. Es reicht also die Obergrenze zu prüfen.
    private static func matchesAvailableNow(
        _ shop: Barbershop,
        filter: BarberFilter,
        nextSlots: [UUID: Date],
        now: Date
    ) -> Bool {
        guard filter.onlyAvailableNow else { return true }
        guard let slot = nextSlots[shop.id] else { return false }

        let limit = now.addingTimeInterval(
            TimeInterval(BarberFilter.instantWindowMinutes * 60)
        )
        return slot <= limit
    }

    private static func matchesTiming(
        _ shop: Barbershop,
        filter: BarberFilter,
        nextSlots: [UUID: Date],
        now: Date,
        calendar: Calendar
    ) -> Bool {
        guard let maxDays = filter.timing.maxDaysAhead else { return true }

        // Kein bekannter Termin -> fällt raus, sobald man nach Zeit filtert.
        guard let slot = nextSlots[shop.id] else { return false }

        let today = calendar.startOfDay(for: now)
        let slotDay = calendar.startOfDay(for: slot)
        let days = calendar.dateComponents([.day], from: today, to: slotDay).day ?? Int.max

        return days <= maxDays
    }

    private static func matchesDistance(
        _ shop: Barbershop,
        filter: BarberFilter,
        distances: [UUID: Double]
    ) -> Bool {
        guard let maxKm = filter.maxDistanceKm else { return true }

        // Ohne Standort kennen wir keine Entfernung. Dann NICHT aussieben —
        // sonst wäre die Liste plötzlich leer, nur weil der Nutzer den
        // Standort nicht freigegeben hat.
        guard let meters = distances[shop.id] else { return true }

        return meters <= maxKm * 1000
    }

    private static func matchesPrice(_ shop: Barbershop, filter: BarberFilter) -> Bool {
        guard let maxEuro = filter.maxPriceEuro else { return true }
        guard let cheapest = shop.cheapestService else { return false }
        return cheapest.priceCents <= maxEuro * 100
    }

    private static func matchesRating(_ shop: Barbershop, filter: BarberFilter) -> Bool {
        guard let minRating = filter.minRating else { return true }
        return shop.averageRating >= minRating
    }

    private static func matchesCategories(_ shop: Barbershop, filter: BarberFilter) -> Bool {
        guard !filter.categories.isEmpty else { return true }
        // Es reicht, wenn der Shop EINE der gewählten Arten anbietet.
        return !shop.categories.isDisjoint(with: filter.categories)
    }

    // MARK: - Sortierung

    private static func sorted(
        _ shops: [Barbershop],
        by sort: BarberSort,
        distances: [UUID: Double]
    ) -> [Barbershop] {

        switch sort {
        case .recommended:
            // "Empfohlen" ist bewusst schlicht: beste Bewertung zuerst,
            // bei Gleichstand die näher gelegene. Eine ausgefeilte
            // Gewichtung wäre ohne echte Nutzungsdaten geraten.
            return shops.sorted { first, second in
                if first.averageRating != second.averageRating {
                    return first.averageRating > second.averageRating
                }
                return distance(first, distances) < distance(second, distances)
            }

        case .distance:
            return shops.sorted { distance($0, distances) < distance($1, distances) }

        case .rating:
            return shops.sorted { first, second in
                if first.averageRating != second.averageRating {
                    return first.averageRating > second.averageRating
                }
                // Bei gleicher Note entscheidet, wie viele bewertet haben —
                // 4,8 aus 200 Stimmen ist belastbarer als 4,8 aus dreien.
                return first.reviewCount > second.reviewCount
            }

        case .price:
            return shops.sorted { price($0) < price($1) }
        }
    }

    /// Entfernung oder "unendlich weit", wenn unbekannt.
    ///
    /// Dadurch landen Shops ohne bekannte Entfernung hinten statt vorn.
    private static func distance(_ shop: Barbershop, _ distances: [UUID: Double]) -> Double {
        distances[shop.id] ?? .greatestFiniteMagnitude
    }

    private static func price(_ shop: Barbershop) -> Int {
        shop.cheapestService?.priceCents ?? Int.max
    }
}
