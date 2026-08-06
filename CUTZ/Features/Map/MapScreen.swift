import SwiftUI
import MapKit

/// Die Kartenansicht mit allen Barbershops als Marker.
///
/// ─── Zuständig: Finn ───────────────────────────────────────
///
/// Tippt man einen Marker an, öffnet sich unten eine kleine Vorschau.
/// Von dort geht es weiter ins vollständige Profil.
struct MapScreen: View {

    @Environment(AppModel.self) private var appModel
    @State private var locationManager = LocationManager()

    /// Der sichtbare Kartenausschnitt. Startet über Hamburg.
    /// Falls ihr in einer anderen Stadt testet: Koordinaten hier anpassen.
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 53.5540, longitude: 9.9600),
            span: MKCoordinateSpan(latitudeDelta: 0.09, longitudeDelta: 0.09)
        )
    )

    /// Welcher Shop ist gerade angetippt? `nil` = keiner.
    @State private var selectedShop: Barbershop?

    /// Steuert, ob das große Profil als Vollbild-Sheet offen ist.
    @State private var shopForProfile: Barbershop?

    var body: some View {
        NavigationStack {
            Map(position: $cameraPosition) {

                // Blauer Punkt für den eigenen Standort.
                UserAnnotation()

                ForEach(appModel.shops) { shop in
                    Annotation(shop.name, coordinate: shop.coordinate) {
                        MapMarkerView(
                            shop: shop,
                            isSelected: selectedShop?.id == shop.id
                        )
                        .onTapGesture {
                            withAnimation(.snappy) {
                                selectedShop = shop
                            }
                        }
                    }
                }
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .navigationTitle("Karte")
            .navigationBarTitleDisplayMode(.inline)

            // Vorschaukarte am unteren Rand, wenn ein Marker gewählt ist.
            .safeAreaInset(edge: .bottom) {
                if let selectedShop {
                    MapShopPreview(
                        shop: selectedShop,
                        distanceInMeters: locationManager.distance(to: selectedShop),
                        onOpenProfile: { shopForProfile = selectedShop },
                        onClose: {
                            withAnimation(.snappy) { self.selectedShop = nil }
                        }
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }

            // Das Profil ist Lukas' Teil — hier wird es nur aufgerufen.
            .sheet(item: $shopForProfile) { shop in
                NavigationStack {
                    ShopProfileScreen(shop: shop)
                }
            }

            .task {
                locationManager.requestPermission()
            }
        }
    }
}

/// Der Stecknadel-Ersatz: eine Sprechblase mit Schere und Preisniveau.
private struct MapMarkerView: View {

    let shop: Barbershop
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                Image(systemName: "scissors")
                    .font(.caption2)
                Text(shop.priceLevelText)
                    .font(.caption2)
                    .fontWeight(.bold)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(isSelected ? Color.accentColor : Color(.systemBackground))
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .clipShape(Capsule())
            .shadow(radius: 3, y: 1)

            // Kleines Dreieck, das nach unten auf die Position zeigt.
            Triangle()
                .fill(isSelected ? Color.accentColor : Color(.systemBackground))
                .frame(width: 10, height: 6)
                .shadow(radius: 1, y: 1)
        }
        .scaleEffect(isSelected ? 1.15 : 1.0)
    }
}

/// Ein nach unten zeigendes Dreieck.
private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// Die Vorschaukarte unten auf der Karte.
private struct MapShopPreview: View {

    let shop: Barbershop
    let distanceInMeters: Double?
    let onOpenProfile: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                ShopRow(shop: shop, distanceInMeters: distanceInMeters)

                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Vorschau schließen")
            }

            Button(action: onOpenProfile) {
                Text("Profil & Termin buchen")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 8, y: 2)
    }
}

#Preview {
    MapScreen()
        .environment(AppModel())
}
