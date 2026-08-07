import SwiftUI
import MapKit

/// Der wichtigste Screen der App: Karte, Suchleiste, hochziehbare Liste.
///
/// Hier startet die App. Alles, was ein Nutzer für die Entscheidung
/// braucht — wo, wie gut, wie teuer, wann frei — ist auf diesem einen
/// Bildschirm erreichbar, ohne vorher irgendetwas anzutippen.
struct DiscoverScreen: View {

    @Environment(AppModel.self) private var appModel

    @State private var selectedShopID: UUID?
    @State private var detent: SheetDetent = .collapsed
    @State private var cameraPosition: MapCameraPosition = .kassel

    @State private var filter: BarberFilter = .none

    @State private var isFilterShown = false
    @State private var isSearchShown = false
    @State private var isAccountShown = false

    /// Der Shop, dessen Profil geöffnet ist.
    @State private var shopForProfile: Barbershop?

    var body: some View {
        ZStack(alignment: .top) {
            DiscoverMap(
                shops: visibleShops,
                selectedShopID: $selectedShopID,
                cameraPosition: $cameraPosition
            )
            .ignoresSafeArea()

            BarberListSheet(
                shops: visibleShops,
                selectedShopID: $selectedShopID,
                detent: $detent,
                onSelectShop: { shopForProfile = $0 },
                onOpenFilter: { isFilterShown = true },
                activeFilterCount: filter.activeCount
            )

            DiscoverTopBar(
                onSearchTap: { isSearchShown = true },
                onProfileTap: { isAccountShown = true }
            )
            .padding(.top, 8)
        }

        // Tippt man auf der Karte einen Pin an, soll die Liste
        // mitgehen — sonst sucht man den Shop dort von Hand.
        .onChange(of: selectedShopID) { _, newValue in
            if newValue != nil, detent == .collapsed {
                withAnimation(.snappy) { detent = .medium }
            }
        }

        .sheet(isPresented: $isFilterShown) {
            FilterSheet(filter: $filter, resultCount: countResults)
        }
        .sheet(isPresented: $isSearchShown) {
            SearchScreen(onSelectShop: { shop in
                isSearchShown = false
                shopForProfile = shop
            })
        }
        .sheet(isPresented: $isAccountShown) {
            AccountScreen()
        }
        .sheet(item: $shopForProfile) { shop in
            NavigationStack {
                ShopProfileScreen(shop: shop)
            }
        }

        .task {
            appModel.location.requestPermission()
        }
    }

    // MARK: - Daten

    /// Entfernungen als Nachschlagetabelle.
    ///
    /// Wird einmal gebaut statt in der Filterfunktion pro Shop neu
    /// berechnet — und hält die Filterlogik frei von `LocationManager`,
    /// sodass sie ohne Standort testbar bleibt.
    private var distances: [UUID: Double] {
        var result: [UUID: Double] = [:]
        for shop in appModel.shops {
            if let meters = appModel.distance(to: shop) {
                result[shop.id] = meters
            }
        }
        return result
    }

    private var visibleShops: [Barbershop] {
        BarberFiltering.apply(
            to: appModel.shops,
            filter: filter,
            nextSlots: appModel.nextSlots,
            distances: distances
        )
    }

    /// Wie viele Shops eine bestimmte Filtereinstellung übrig ließe.
    /// Das Filter-Sheet zeigt die Zahl schon vor dem Bestätigen an.
    private func countResults(_ candidate: BarberFilter) -> Int {
        BarberFiltering.apply(
            to: appModel.shops,
            filter: candidate,
            nextSlots: appModel.nextSlots,
            distances: distances
        ).count
    }
}

#Preview {
    DiscoverScreen()
        .environment(AppModel())
}
