import Foundation

/// Die Vergleichslogik der Suche.
///
/// Bewusst von der View getrennt: So lässt sich das ohne Oberfläche
/// testen — und später erweitern, ohne `SearchScreen` anzufassen.
/// Sollen irgendwann auch Leistungen oder Barbernamen durchsucht
/// werden, kommt genau eine Zeile in `searchableText` dazu.
enum BarberSearch {

    /// Sucht in Name, Beschreibung, Straße, Stadt und Postleitzahl.
    ///
    /// Die Reihenfolge der Ergebnisse folgt der Eingabeliste. Das ist
    /// Absicht: Die Liste kommt bereits sortiert an, und eine zweite,
    /// abweichende Sortierung würde nur verwirren.
    static func match(query: String, in shops: [Barbershop]) -> [Barbershop] {
        let needle = normalize(query)
        guard !needle.isEmpty else { return [] }

        // Mehrere Wörter müssen ALLE vorkommen — "kassel fade" findet
        // dann nur Läden, auf die beides zutrifft.
        let parts = needle.split(separator: " ").map(String.init)

        return shops.filter { shop in
            let haystack = searchableText(for: shop)
            return parts.allSatisfy { haystack.contains($0) }
        }
    }

    /// Passt die Eingabe auf eine Handvoll Textfelder?
    ///
    /// Dieselben Regeln wie oben — alle Wörter müssen vorkommen,
    /// Groß- und Kleinschreibung sowie Umlaute sind egal.
    ///
    /// Herausgezogen, weil die Friseurseite ihre Buchungen nach
    /// Kundenname und Leistung durchsucht. Eine zweite Suche mit
    /// leicht anderen Regeln wäre genau die Sorte Unterschied, über
    /// die sich später jemand wundert.
    static func matches(_ query: String, in fields: [String]) -> Bool {
        let needle = normalize(query)
        guard !needle.isEmpty else { return true }

        let haystack = normalize(fields.joined(separator: " "))
        return needle
            .split(separator: " ")
            .allSatisfy { haystack.contains($0) }
    }

    /// Alles, worin gesucht wird — bereits kleingeschrieben.
    ///
    /// Hier später erweitern:
    ///   + shop.services.map(\.name)
    ///   + shop.employees.map(\.name)
    private static func searchableText(for shop: Barbershop) -> String {
        normalize([
            shop.name,
            shop.description,
            shop.street,
            shop.postalCode,
            shop.city
        ].joined(separator: " "))
    }

    /// Klein schreiben, Umlaute und Akzente ignorieren, Ränder kürzen.
    ///
    /// Warum die Umlautbehandlung? Damit "Königs" auch findet, wer
    /// "konigs" tippt — auf einer Handytastatur eine unnötige Hürde.
    ///
    /// Grenze: "koenigs" findet es NICHT. `folding` macht aus "ö" ein
    /// "o", nicht "oe". Für die Umschreibung mit zwei Buchstaben
    /// bräuchte es eine eigene Ersetzungstabelle — lohnt sich erst,
    /// wenn jemand darüber stolpert.
    private static func normalize(_ text: String) -> String {
        text
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "de_DE"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
