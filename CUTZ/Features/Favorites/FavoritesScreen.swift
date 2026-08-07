import SwiftUI

/// Die gespeicherten Barber.
///
/// Bewusst schlicht: dieselbe `BarberCard` wie unter Entdecken, sonst
/// nichts. Wer hier landet, hat sich schon entschieden — er will nur
/// noch schnell buchen, nicht erneut vergleichen.
struct FavoritesScreen: View {

    @Environment(AppModel.self) private var appModel

    @State private var shopForProfile: Barbershop?

    var body: some View {
        NavigationStack {
            Group {
                if favorites.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("Favoriten")
            .background(Color(.systemGroupedBackground))
        }
        .sheet(item: $shopForProfile) { shop in
            NavigationStack {
                ShopProfileScreen(shop: shop)
            }
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(favorites) { shop in
                    Button {
                        shopForProfile = shop
                    } label: {
                        BarberCard(
                            shop: shop,
                            distanceInMeters: appModel.distance(to: shop),
                            nextSlot: appModel.nextSlots[shop.id]
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Noch keine Favoriten", systemImage: "heart")
        } description: {
            Text("Tippe bei einem Barber auf das Herz, dann findest du ihn hier wieder.")
        }
    }

    /// Das Herz auf der Karte entfernt den Shop sofort aus dieser Liste —
    /// das ergibt sich von selbst, weil `favorites` bei jeder Änderung
    /// neu berechnet wird.
    private var favorites: [Barbershop] {
        appModel.favorites.favorites(from: appModel.shops)
    }
}

#Preview {
    FavoritesScreen()
        .environment(AppModel())
}
