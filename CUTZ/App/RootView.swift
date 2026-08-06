import SwiftUI

/// Die Tab-Leiste unten — das Grundgerüst der App.
///
/// Jeder Tab gehört zu genau einem Feature-Ordner. Wer an einem Feature
/// arbeitet, fasst nur seinen eigenen Ordner an. Diese Datei ändern wir
/// nur gemeinsam, wenn ein Tab dazukommt.
struct RootView: View {

    /// Holt den `AppModel`, den `CutzApp` weiter oben hineingegeben hat.
    @Environment(AppModel.self) private var appModel

    var body: some View {
        TabView {
            // ── Finn ──────────────────────────────────────────
            MapScreen()
                .tabItem {
                    Label("Karte", systemImage: "map")
                }

            SearchScreen()
                .tabItem {
                    Label("Suche", systemImage: "magnifyingglass")
                }

            // ── Lukas ─────────────────────────────────────────
            BookingsScreen()
                .tabItem {
                    Label("Termine", systemImage: "calendar")
                }
        }
        // `.task` startet, sobald die View erscheint, und darf `await`
        // benutzen. Das ist der richtige Ort zum Nachladen von Daten.
        .task {
            await appModel.loadShops()
        }
    }
}

#Preview {
    RootView()
        .environment(AppModel())
}
