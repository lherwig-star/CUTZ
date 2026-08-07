import Foundation
import Observation

/// Merkt sich, welche Shops der Nutzer favorisiert hat.
///
/// Warum `UserDefaults` und nicht die Datenbank? Favoriten sind eine
/// reine Gerätesache, solange es keine Nutzerkonten gibt (die kommen
/// in Phase 3). Bis dahin wäre ein Server dafür übertrieben — und
/// `UserDefaults` ist genau für solche kleinen Einstellungen gedacht.
///
/// Anders als die Buchungen überleben Favoriten damit schon jetzt den
/// App-Neustart. Das ist Absicht: Nichts fühlt sich billiger an als
/// eine App, die vergisst, was man ihr gesagt hat.
@MainActor
@Observable
final class FavoritesStore {

    /// Der Schlüssel, unter dem die Liste gespeichert wird.
    private static let storageKey = "cutz.favoriteShopIDs"

    /// Die IDs der favorisierten Shops.
    ///
    /// `Set` statt `Array`: Die Reihenfolge ist egal, und die Frage
    /// "ist das drin?" beantwortet ein Set sofort, statt die ganze
    /// Liste durchzugehen.
    private(set) var favoriteShopIDs: Set<UUID> = []

    private let defaults: UserDefaults

    /// `UserDefaults` wird hineingereicht, damit Tests eine eigene,
    /// leere Ablage benutzen können und nicht die echten Favoriten
    /// des Simulators durcheinanderbringen.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.favoriteShopIDs = Self.load(from: defaults)
    }

    func isFavorite(_ shopID: UUID) -> Bool {
        favoriteShopIDs.contains(shopID)
    }

    /// Fügt hinzu oder entfernt — je nachdem, was gerade gilt.
    func toggle(_ shopID: UUID) {
        if favoriteShopIDs.contains(shopID) {
            favoriteShopIDs.remove(shopID)
        } else {
            favoriteShopIDs.insert(shopID)
        }
        save()
    }

    /// Die favorisierten Shops aus einer Liste herausfiltern.
    ///
    /// Die Reihenfolge der übergebenen Liste bleibt erhalten — sonst
    /// würden die Favoriten bei jedem Öffnen anders sortiert dastehen.
    func favorites(from shops: [Barbershop]) -> [Barbershop] {
        shops.filter { favoriteShopIDs.contains($0.id) }
    }

    // MARK: - Speichern und Laden

    private func save() {
        // UUIDs kann UserDefaults nicht direkt. Als Text geht es.
        let asText = favoriteShopIDs.map(\.uuidString)
        defaults.set(asText, forKey: Self.storageKey)
    }

    private static func load(from defaults: UserDefaults) -> Set<UUID> {
        guard let asText = defaults.stringArray(forKey: Self.storageKey) else {
            return []
        }
        // `compactMap` wirft alles weg, was sich nicht in eine UUID
        // zurückverwandeln lässt — etwa Reste aus einer älteren Version.
        return Set(asText.compactMap { UUID(uuidString: $0) })
    }
}
