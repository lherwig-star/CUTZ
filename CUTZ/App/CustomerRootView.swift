import SwiftUI

/// Die Tab-Leiste der Kundenseite.
///
/// Nur drei Bereiche, und zwar genau die drei, die der Nutzungsablauf
/// braucht: entdecken, gemerkte Läden wiederfinden, Termine ansehen.
/// Entdecken steht in der Mitte und ist beim Start ausgewählt, weil
/// dort praktisch alles passiert.
///
/// Das Profil gehört bewusst NICHT hierher, sondern hinter den Knopf
/// oben rechts im Entdecken-Screen. In der Tab-Leiste steht, was man
/// ständig tut — Einstellungen gehören nicht dazu.
///
/// Hieß früher `RootView`. Den Namen trägt jetzt die Weiche, die
/// zwischen Kunden- und Friseurseite entscheidet.
struct CustomerRootView: View {

    @Environment(AppModel.self) private var appModel

    /// Welcher Tab ist gewählt. Entdecken ist die Vorgabe.
    @State private var selection: Tab = .discover

    enum Tab {
        case favorites
        case discover
        case appointments
    }

    var body: some View {
        TabView(selection: $selection) {
            FavoritesScreen()
                .tabItem {
                    Label("Favoriten", systemImage: "heart")
                }
                .tag(Tab.favorites)

            DiscoverScreen()
                .tabItem {
                    Label("Entdecken", systemImage: "mappin.and.ellipse")
                }
                .tag(Tab.discover)

            BookingsScreen()
                .tabItem {
                    Label("Termine", systemImage: "calendar")
                }
                .tag(Tab.appointments)
        }
        // `.task` startet, sobald die View erscheint, und darf `await`
        // benutzen. Das ist der richtige Ort zum Nachladen von Daten.
        .task {
            await appModel.loadShops()
        }
    }
}

#Preview {
    CustomerRootView()
        .environment(AppModel())
}
