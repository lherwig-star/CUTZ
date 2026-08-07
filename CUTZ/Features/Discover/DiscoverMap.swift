import SwiftUI
import MapKit

/// Die Karte im Entdecken-Screen.
///
/// Nur die Karte samt Pins — Suchleiste und Liste liegen darüber und
/// werden in `DiscoverScreen` zusammengesetzt. So bleibt jede Datei
/// überschaubar.
struct DiscoverMap: View {

    let shops: [Barbershop]

    /// Welcher Pin ist gerade ausgewählt? Kommt von außen, weil die
    /// Liste darunter dieselbe Auswahl anzeigt.
    @Binding var selectedShopID: UUID?

    @Binding var cameraPosition: MapCameraPosition

    var body: some View {
        Map(position: $cameraPosition) {

            // Blauer Punkt für den eigenen Standort.
            UserAnnotation()

            ForEach(shops) { shop in
                Annotation(shop.name, coordinate: shop.coordinate) {
                    MapPin(
                        shop: shop,
                        isSelected: selectedShopID == shop.id
                    )
                    .onTapGesture {
                        withAnimation(.snappy) {
                            // Nochmal antippen hebt die Auswahl auf.
                            selectedShopID = selectedShopID == shop.id ? nil : shop.id
                        }
                    }
                }
            }
        }
        .mapControls {
            MapUserLocationButton()
        }
    }
}

/// Der Pin: eine Sprechblase mit dem Startpreis.
///
/// Warum der Preis und nicht nur eine Nadel? Weil man auf der Karte
/// als Erstes vergleicht, und Preis plus Lage die zwei Dinge sind, die
/// man dabei gegeneinander abwägt. Eine reine Nadel zwingt zum Antippen.
private struct MapPin: View {

    let shop: Barbershop
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                Image(systemName: "scissors")
                    .font(.caption2)

                if let cheapest = shop.cheapestService {
                    Text(cheapest.priceShort)
                        .font(.caption2)
                        .fontWeight(.bold)
                }
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor : Color(.systemBackground))
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .clipShape(Capsule())
            .shadow(radius: 3, y: 1)

            // Kleines Dreieck, das nach unten auf die Position zeigt.
            PinTriangle()
                .fill(isSelected ? Color.accentColor : Color(.systemBackground))
                .frame(width: 10, height: 6)
                .shadow(radius: 1, y: 1)
        }
        .scaleEffect(isSelected ? 1.18 : 1.0)
    }
}

/// Ein nach unten zeigendes Dreieck.
private struct PinTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// Der Standard-Kartenausschnitt: Kassel.
///
/// Testet ihr in einer anderen Stadt, hier die Koordinaten anpassen —
/// und in `MockData.swift` die Shops dazu.
extension MapCameraPosition {
    static var kassel: MapCameraPosition {
        .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 51.3150, longitude: 9.4800),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        )
    }
}
