import Foundation
import Observation

/// Der zentrale Zustand der App.
///
/// Hier liegen die Daten, die mehrere Screens gleichzeitig brauchen —
/// vor allem die Liste aller Shops. Karte und Suche greifen beide darauf
/// zu, sollen sie aber nicht zweimal laden.
///
/// `@Observable` ist der moderne Weg in SwiftUI (ab iOS 17). SwiftUI
/// beobachtet automatisch, welche Werte eine View liest, und zeichnet
/// genau diese View neu, sobald sich der Wert ändert. Man muss nichts
/// weiter markieren.
///
/// `@MainActor` heißt: Dieser Code läuft immer auf dem Haupt-Thread.
/// Das ist Pflicht für alles, was die Oberfläche verändert.
@MainActor
@Observable
final class AppModel {

    // ─────────────────────────────────────────────────────────
    //  HIER wird später auf echte Daten umgestellt.
    //
    //  Aus:  private let repository: BarbershopRepository = MockBarbershopRepository()
    //  Wird: private let repository: BarbershopRepository = SupabaseBarbershopRepository()
    //
    //  Sonst ändert sich in der ganzen App keine einzige Zeile.
    // ─────────────────────────────────────────────────────────
    let repository: BarbershopRepository = MockBarbershopRepository()

    /// Alle geladenen Shops.
    private(set) var shops: [Barbershop] = []

    /// Läuft gerade ein Ladevorgang?
    private(set) var isLoading = false

    /// Fehlermeldung, falls das Laden schiefging.
    private(set) var errorMessage: String?

    /// Lädt die Shops. Wird beim Start der App aufgerufen.
    func loadShops() async {
        isLoading = true
        errorMessage = nil

        do {
            shops = try await repository.fetchShops()
        } catch {
            // `error.localizedDescription` ist die von iOS übersetzte Meldung.
            errorMessage = "Shops konnten nicht geladen werden: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Einen Shop anhand seiner ID finden.
    func shop(withID id: UUID) -> Barbershop? {
        shops.first { $0.id == id }
    }
}
