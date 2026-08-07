import SwiftUI
import MapKit

/// Das Profil eines Shops: Beschreibung, Leistungen, Öffnungszeiten,
/// Bewertungen — und der Weg zur Terminbuchung.
///
/// ─── Zuständig: Lukas ──────────────────────────────────────
struct ShopProfileScreen: View {

    let shop: Barbershop

    @Environment(AppModel.self) private var appModel

    @State private var reviews: [Review] = []
    @State private var isLoadingReviews = false

    /// Steuert das Buchungs-Sheet.
    @State private var isBookingPresented = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                Divider()
                servicesSection
                Divider()
                openingHoursSection
                Divider()
                locationSection
                Divider()
                ReviewsSection(reviews: reviews, isLoading: isLoadingReviews)
            }
            .padding()
        }
        .navigationTitle(shop.name)
        .navigationBarTitleDisplayMode(.inline)

        // Der Buchen-Button klebt unten fest und scrollt nicht mit weg.
        .safeAreaInset(edge: .bottom) {
            bookButton
        }

        .sheet(isPresented: $isBookingPresented) {
            BookingScreen(shop: shop)
        }

        .task {
            await loadReviews()
        }
    }

    // MARK: - Bereiche

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Platzhalter-Bild. Sobald echte Fotos da sind, kommt hier
            // ein AsyncImage(url: shop.imageURL) hin.
            RoundedRectangle(cornerRadius: 14)
                .fill(.quaternary)
                .frame(height: 160)
                .frame(maxWidth: .infinity)
                .overlay {
                    Image(systemName: "scissors")
                        .font(.system(size: 44))
                        .foregroundStyle(.secondary)
                }

            HStack {
                RatingStars(rating: shop.averageRating, reviewCount: shop.reviewCount)
                Spacer()
                Text(shop.priceLevelText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text(shop.description)
                .font(.body)
                .foregroundStyle(.secondary)

            if let phone = shop.phone {
                // `tel:` öffnet die Telefon-App. Leerzeichen müssen raus,
                // sonst erkennt iOS die Nummer nicht.
                Link(destination: URL(string: "tel:\(phone.replacingOccurrences(of: " ", with: ""))")!) {
                    Label(phone, systemImage: "phone.fill")
                        .font(.subheadline)
                }
            }
        }
    }

    private var servicesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Leistungen")
                .font(.title3)
                .fontWeight(.semibold)

            ForEach(shop.services) { service in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(service.name)
                        Text(service.durationFormatted)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(service.priceFormatted)
                        .fontWeight(.medium)
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var openingHoursSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Öffnungszeiten")
                .font(.title3)
                .fontWeight(.semibold)

            // "Jetzt geöffnet · bis 19:00" bzw. "Geschlossen · öffnet morgen 09:00".
            // Grün nur, wenn wirklich offen — sonst grau.
            //
            // `Color.green` und `Color.secondary` müssen beide ausgeschrieben
            // werden: Ohne den Typnamen sind es zwei verschiedene Typen, und
            // Swift findet dann keinen gemeinsamen Nenner für die Abfrage.
            let status = shop.openingStatus()
            Text(status.text)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(status.isOpen ? Color.green : Color.secondary)
                .padding(.bottom, 4)

            // Wochentage in gewohnter Reihenfolge Mo–So durchgehen.
            // (2 = Montag … 7 = Samstag, dann 1 = Sonntag)
            ForEach([2, 3, 4, 5, 6, 7, 1], id: \.self) { weekday in
                HStack {
                    Text(weekdayName(weekday))
                        .frame(width: 110, alignment: .leading)
                    Spacer()
                    if let hours = shop.openingHour(forWeekday: weekday) {
                        Text(hours.rangeFormatted)
                    } else {
                        Text("geschlossen")
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.subheadline)
                // Heutigen Tag hervorheben.
                .fontWeight(weekday == Calendar.current.component(.weekday, from: .now) ? .semibold : .regular)
            }
        }
    }

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Adresse")
                .font(.title3)
                .fontWeight(.semibold)

            Text(shop.fullAddress)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Kleine, nicht bedienbare Karte als Vorschau.
            Map(initialPosition: .region(
                MKCoordinateRegion(
                    center: shop.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                )
            )) {
                Marker(shop.name, systemImage: "scissors", coordinate: shop.coordinate)
            }
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .allowsHitTesting(false)

            Button {
                openInMaps()
            } label: {
                Label("In Karten öffnen", systemImage: "arrow.triangle.turn.up.right.circle")
            }
            .font(.subheadline)
        }
    }

    private var bookButton: some View {
        Button {
            isBookingPresented = true
        } label: {
            Text("Termin buchen")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .padding()
        .background(.bar)
        .disabled(shop.services.isEmpty)
    }

    // MARK: - Helfer

    private func loadReviews() async {
        isLoadingReviews = true
        // Bewertungen sind nicht kritisch — schlägt das Laden fehl,
        // bleibt die Liste einfach leer, statt das ganze Profil zu blockieren.
        reviews = (try? await appModel.repository.fetchReviews(for: shop.id)) ?? []
        isLoadingReviews = false
    }

    private func weekdayName(_ weekday: Int) -> String {
        let symbols = Calendar.current.weekdaySymbols
        let index = weekday - 1
        guard symbols.indices.contains(index) else { return "" }
        return symbols[index]
    }

    /// Öffnet die Apple-Karten-App mit Route zum Shop.
    private func openInMaps() {
        let placemark = MKPlacemark(coordinate: shop.coordinate)
        let item = MKMapItem(placemark: placemark)
        item.name = shop.name
        item.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
        ])
    }
}

#Preview {
    NavigationStack {
        ShopProfileScreen(shop: MockData.shops[0])
            .environment(AppModel())
    }
}
