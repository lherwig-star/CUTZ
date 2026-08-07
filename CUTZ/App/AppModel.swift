import Foundation
import Observation

/// Der zentrale Zustand der App.
///
/// Hier liegen die Daten, die mehrere Screens gleichzeitig brauchen —
/// vor allem die Liste aller Shops, die Favoriten und der Standort.
/// Entdecken, Favoriten und Termine greifen alle darauf zu, sollen
/// aber nicht jeder für sich laden.
///
/// `@Observable` ist der moderne Weg in SwiftUI (ab iOS 17). SwiftUI
/// beobachtet automatisch, welche Werte eine View liest, und zeichnet
/// genau diese View neu, sobald sich der Wert ändert.
///
/// `@MainActor` heißt: Dieser Code läuft immer auf dem Haupt-Thread.
/// Das ist Pflicht für alles, was die Oberfläche verändert.
@MainActor
@Observable
final class AppModel {

    // ─────────────────────────────────────────────────────────
    //  HIER wird später auf echte Daten umgestellt.
    //
    //  Aus:  let repository: BarbershopRepository = MockBarbershopRepository()
    //  Wird: let repository: BarbershopRepository = SupabaseBarbershopRepository()
    //
    //  Sonst ändert sich in der ganzen App keine einzige Zeile.
    // ─────────────────────────────────────────────────────────
    let repository: BarbershopRepository = MockBarbershopRepository()

    /// Favoriten. Eigene Klasse, weil sie sich selbst um das Speichern
    /// kümmert und nichts mit dem Laden der Shops zu tun hat.
    let favorites = FavoritesStore()

    /// Standort des Nutzers, für Entfernungsangaben.
    let location = LocationManager()

    /// Die im Profil gewählte Sprache. Eigene Klasse, weil sie sich
    /// selbst um das Speichern kümmert — genau wie die Favoriten.
    let language = LanguageStore()

    /// Kunde oder Friseur. Beim allerersten Start noch `nil`, dann
    /// fragt `RootView` nach.
    let role = RoleStore()

    /// Alle geladenen Shops.
    private(set) var shops: [Barbershop] = []

    /// Der nächste freie Termin je Shop-ID.
    ///
    /// Steht schon in der Liste ("Heute 18:30 verfügbar"), damit niemand
    /// erst fünf Screens durchklickt, um zu merken, dass heute nichts
    /// mehr geht. Das ist einer der Kerngedanken der App.
    private(set) var nextSlots: [UUID: Date] = [:]

    /// Läuft gerade ein Ladevorgang?
    private(set) var isLoading = false

    /// Fehlermeldung, falls das Laden schiefging.
    private(set) var errorMessage: String?

    /// Lädt Shops und freie Termine. Wird beim Start der App aufgerufen.
    func loadShops() async {
        isLoading = true
        errorMessage = nil

        do {
            shops = try await repository.fetchShops()
        } catch {
            // `error.localizedDescription` ist die von iOS übersetzte Meldung.
            errorMessage = "Shops konnten nicht geladen werden: \(error.localizedDescription)"
            isLoading = false
            return
        }

        // Die freien Termine sind eine Zusatzinfo. Klappt das nicht,
        // steht in den Karten eben nichts — die Liste selbst funktioniert
        // trotzdem. Deshalb kein `errorMessage` und kein Abbruch.
        nextSlots = (try? await repository.nextAvailableSlots()) ?? [:]

        isLoading = false
    }

    /// Nach einer Buchung neu berechnen, welche Termine noch frei sind.
    func refreshNextSlots() async {
        nextSlots = (try? await repository.nextAvailableSlots()) ?? [:]
    }

    /// Einen Shop anhand seiner ID finden.
    func shop(withID id: UUID) -> Barbershop? {
        shops.first { $0.id == id }
    }

    /// Entfernung zu einem Shop in Metern, falls der Standort bekannt ist.
    func distance(to shop: Barbershop) -> Double? {
        location.distance(to: shop)
    }
}
