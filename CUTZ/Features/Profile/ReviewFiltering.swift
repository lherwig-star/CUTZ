import Foundation

/// Filtern und Sortieren von Bewertungen.
///
/// ─── Zuständig: Lukas ──────────────────────────────────────
///
/// Warum eine eigene Datei und nicht direkt in der View?
/// Weil das hier reine Rechnerei ist: Bewertungen rein, gefilterte und
/// sortierte Bewertungen raus. Kein SwiftUI, kein Bildschirm. Dadurch
/// lässt es sich testen, ohne die App zu starten
/// (siehe `CUTZTests/ReviewFilteringTests.swift`).
///
/// Die View daneben bleibt so kurz und beschäftigt sich nur damit,
/// wie das Ergebnis AUSSIEHT.

// MARK: - Filter

/// Ab wie vielen Sternen soll eine Bewertung angezeigt werden?
enum ReviewRatingFilter: CaseIterable, Identifiable {

    case all
    case threePlus
    case fourPlus
    case fiveOnly

    /// `Identifiable` braucht SwiftUI für `ForEach`. Da jeder Fall
    /// nur einmal vorkommt, kann der Fall selbst die id sein.
    var id: Self { self }

    /// Beschriftung im Auswahlmenü.
    var label: String {
        switch self {
        case .all:       "Alle"
        case .threePlus: "Ab 3 Sternen"
        case .fourPlus:  "Ab 4 Sternen"
        case .fiveOnly:  "Nur 5 Sterne"
        }
    }

    /// Wie viele Sterne eine Bewertung mindestens haben muss.
    ///
    /// Praktisch: Weil 5 die Höchstzahl ist, kommt auch "Nur 5 Sterne"
    /// mit einer einfachen Mindestgrenze aus. Wir brauchen keinen
    /// Sonderfall dafür.
    var minimumRating: Int {
        switch self {
        case .all:       1
        case .threePlus: 3
        case .fourPlus:  4
        case .fiveOnly:  5
        }
    }
}

// MARK: - Sortierung

/// In welcher Reihenfolge werden Bewertungen angezeigt?
enum ReviewSort: CaseIterable, Identifiable {

    case newest
    case bestFirst
    case worstFirst

    var id: Self { self }

    var label: String {
        switch self {
        case .newest:     "Neueste zuerst"
        case .bestFirst:  "Beste zuerst"
        case .worstFirst: "Schlechteste zuerst"
        }
    }
}

// MARK: - Die eigentliche Arbeit

/// Sammelstelle für die Filter- und Sortierlogik.
///
/// Aufbau bewusst wie bei `SlotCalculator`: ein Typ ohne Fälle, der nur
/// als Namensschild für statische Funktionen dient. Man legt also nie
/// ein `ReviewFiltering()` an, sondern ruft direkt
/// `ReviewFiltering.apply(...)` auf.
enum ReviewFiltering {

    /// Filtert nach Sternen und sortiert anschließend.
    static func apply(
        to reviews: [Review],
        rating: ReviewRatingFilter,
        sort: ReviewSort
    ) -> [Review] {

        let filtered = reviews.filter { $0.rating >= rating.minimumRating }

        switch sort {
        case .newest:
            return filtered.sorted { $0.createdAt > $1.createdAt }

        case .bestFirst:
            return filtered.sorted { first, second in
                // Bei gleicher Sternzahl entscheidet das Datum.
                //
                // Warum dieser zweite Vergleich nötig ist: Swifts `sorted`
                // gibt bei Gleichstand keine feste Reihenfolge vor. Ohne
                // die Zusatzregel könnten zwei Bewertungen mit je 5 Sternen
                // bei jedem Aufruf anders herum stehen — und die Liste
                // würde beim Blättern scheinbar grundlos herumspringen.
                if first.rating != second.rating {
                    return first.rating > second.rating
                }
                return first.createdAt > second.createdAt
            }

        case .worstFirst:
            return filtered.sorted { first, second in
                if first.rating != second.rating {
                    return first.rating < second.rating
                }
                return first.createdAt > second.createdAt
            }
        }
    }
}
