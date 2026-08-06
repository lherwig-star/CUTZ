import SwiftUI

/// Die Suchliste: alle Shops, durchsuchbar und sortierbar.
///
/// ─── Zuständig: Finn ───────────────────────────────────────
struct SearchScreen: View {

    @Environment(AppModel.self) private var appModel
    @State private var locationManager = LocationManager()

    /// Der eingetippte Suchtext.
    @State private var searchText = ""

    /// Nach welchem Kriterium wird sortiert?
    @State private var sortOption: SortOption = .rating

    var body: some View {
        NavigationStack {
            Group {
                if appModel.isLoading && appModel.shops.isEmpty {
                    ProgressView("Shops werden geladen …")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                } else if let errorMessage = appModel.errorMessage {
                    ContentUnavailableView(
                        "Fehler beim Laden",
                        systemImage: "wifi.exclamationmark",
                        description: Text(errorMessage)
                    )

                } else if filteredShops.isEmpty {
                    ContentUnavailableView.search(text: searchText)

                } else {
                    shopList
                }
            }
            .navigationTitle("Barbershops")
            // Fügt automatisch das Suchfeld oben ein.
            .searchable(
                text: $searchText,
                prompt: "Name, Stadt oder Leistung"
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    sortMenu
                }
            }
            .task {
                locationManager.requestPermission()
            }
        }
    }

    private var shopList: some View {
        List(filteredShops) { shop in
            // NavigationLink schiebt das Profil von rechts herein
            // und erzeugt automatisch den Zurück-Button.
            NavigationLink {
                ShopProfileScreen(shop: shop)
            } label: {
                ShopRow(
                    shop: shop,
                    distanceInMeters: locationManager.distance(to: shop)
                )
            }
        }
        .listStyle(.plain)
    }

    private var sortMenu: some View {
        Menu {
            Picker("Sortieren", selection: $sortOption) {
                ForEach(SortOption.allCases) { option in
                    Label(option.title, systemImage: option.icon).tag(option)
                }
            }
        } label: {
            Label("Sortieren", systemImage: "arrow.up.arrow.down")
        }
    }

    // MARK: - Filtern & Sortieren

    /// Die Shops, die tatsächlich angezeigt werden.
    ///
    /// Erst filtern (Suchtext), dann sortieren. Als `computed property`
    /// wird das bei jeder Änderung von `searchText` oder `sortOption`
    /// automatisch neu berechnet — wir müssen nichts von Hand aktualisieren.
    private var filteredShops: [Barbershop] {
        let matches: [Barbershop]

        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            matches = appModel.shops
        } else {
            let query = searchText.lowercased()
            matches = appModel.shops.filter { shop in
                shop.name.lowercased().contains(query)
                || shop.city.lowercased().contains(query)
                || shop.postalCode.contains(query)
                || shop.services.contains { $0.name.lowercased().contains(query) }
            }
        }

        return sorted(matches)
    }

    private func sorted(_ shops: [Barbershop]) -> [Barbershop] {
        switch sortOption {
        case .rating:
            return shops.sorted { $0.averageRating > $1.averageRating }

        case .priceAscending:
            // Shops ohne Leistungen ans Ende sortieren.
            return shops.sorted { lhs, rhs in
                let l = lhs.cheapestService?.priceCents ?? Int.max
                let r = rhs.cheapestService?.priceCents ?? Int.max
                return l < r
            }

        case .distance:
            // Ohne Standortfreigabe kennen wir keine Entfernung —
            // dann bleibt die Reihenfolge einfach unverändert.
            return shops.sorted { lhs, rhs in
                let l = locationManager.distance(to: lhs) ?? .greatestFiniteMagnitude
                let r = locationManager.distance(to: rhs) ?? .greatestFiniteMagnitude
                return l < r
            }
        }
    }
}

/// Die Sortier-Möglichkeiten.
///
/// `CaseIterable` gibt uns `allCases` — damit lässt sich das Menü
/// automatisch aus dieser Liste bauen. Kommt eine Option dazu,
/// erscheint sie ohne weitere Änderung im Menü.
enum SortOption: String, CaseIterable, Identifiable {
    case rating
    case distance
    case priceAscending

    var id: String { rawValue }

    var title: String {
        switch self {
        case .rating:         "Beste Bewertung"
        case .distance:       "Nächste zuerst"
        case .priceAscending: "Günstigste zuerst"
        }
    }

    var icon: String {
        switch self {
        case .rating:         "star"
        case .distance:       "location"
        case .priceAscending: "eurosign"
        }
    }
}

#Preview {
    SearchScreen()
        .environment(AppModel())
}
