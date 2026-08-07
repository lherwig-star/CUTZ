import SwiftUI
import MapKit
// Für `UIApplication.shared.open` in `MapNavigation`.
import UIKit

/// Das Profil eines Barbershops.
///
/// Der Aufbau folgt genau den vier Fragen, die vor einer Buchung im
/// Kopf stehen — und zwar in dieser Reihenfolge:
///
///   1. Kann der schneiden?      → großes Bild + Arbeiten
///   2. Sind andere zufrieden?   → Note und Bewertungen
///   3. Was kostet es?           → Leistungen mit Preis und Dauer
///   4. Wann krieg ich Termin?   → nächster freier Termin, ganz oben
///
/// Der Buchen-Knopf klebt unten fest und ist von jeder Stelle aus
/// erreichbar. Man soll nie erst zurückscrollen müssen, um zu buchen.
struct ShopProfileScreen: View {

    let shop: Barbershop

    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    @State private var reviews: [Review] = []
    @State private var isLoadingReviews = false

    /// Steuert den Buchungsablauf.
    @State private var isBookingShown = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                headerImage
                titleBlock

                if !shop.employees.isEmpty {
                    sectionDivider
                    teamSection
                }

                sectionDivider
                portfolioSection

                sectionDivider
                servicesSection

                sectionDivider
                ReviewsSection(
                    reviews: reviews,
                    isLoading: isLoadingReviews,
                    averageRating: shop.averageRating,
                    totalReviewCount: shop.reviewCount
                )
                .padding(.horizontal, 20)

                sectionDivider
                locationSection

                openingHoursSection
                    .padding(.bottom, 12)
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                FavoriteButton(shopID: shop.id, size: .title3, hasBackground: true)
            }
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .padding(8)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .accessibilityLabel("Schließen")
            }
        }
        .safeAreaInset(edge: .bottom) {
            bookButton
        }
        .sheet(isPresented: $isBookingShown) {
            BookingFlowScreen(shop: shop)
        }
        .task {
            await loadReviews()
        }
    }

    // MARK: - Kopfbereich

    private var headerImage: some View {
        ShopImage(seed: shop.id.uuidString, url: shop.imageURL, symbolSize: 54)
            .frame(height: 260)
            .frame(maxWidth: .infinity)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(shop.name)
                .font(.title)
                .fontWeight(.bold)

            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)

                Text(shop.averageRating.formatted(.number.precision(.fractionLength(1))))
                    .fontWeight(.semibold)

                Text("(\(shop.reviewCount))")
                    .foregroundStyle(.secondary)

                if let distanceText {
                    Text("· \(distanceText)")
                        .foregroundStyle(.secondary)
                }

                Text("· \(shop.priceLevelText)")
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)

            // Verfügbarkeit steht ganz oben, nicht unten bei den
            // Öffnungszeiten. Es ist die Frage, die über Buchen oder
            // Weiterschauen entscheidet.
            availabilityLine

            Text(shop.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 2)
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var availabilityLine: some View {
        if let slot = appModel.nextSlots[shop.id] {
            Label("\(AvailabilityText.short(for: slot)) verfügbar", systemImage: "clock")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.green)
        } else {
            Label("Zurzeit kein freier Termin", systemImage: "clock")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Abschnitte

    private var teamSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Team")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(shop.employees) { employee in
                        EmployeeChip(employee: employee)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, -20)
        }
        .padding(.horizontal, 20)
    }

    private var portfolioSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Arbeiten")
            PortfolioGallery(seed: shop.id.uuidString, imageURLs: shop.portfolioImageURLs)
        }
        .padding(.horizontal, 20)
    }

    private var servicesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Services & Preise")

            ForEach(shop.services) { service in
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(service.name)
                            .fontWeight(.medium)
                        Text("\(service.priceShort) · \(service.durationFormatted)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
        .padding(.horizontal, 20)
    }

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Standort")

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
            .frame(height: 170)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .allowsHitTesting(false)

            HStack(spacing: 10) {
                Button {
                    MapNavigation.open(shop)
                } label: {
                    Label("Navigation", systemImage: "arrow.triangle.turn.up.right.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                if let phone = shop.phone,
                   let url = URL(string: "tel:\(phone.replacingOccurrences(of: " ", with: ""))") {
                    Link(destination: url) {
                        Label("Anrufen", systemImage: "phone.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .font(.subheadline)
        }
        .padding(.horizontal, 20)
    }

    private var openingHoursSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            let status = shop.openingStatus()
            Text(status.text)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(status.isOpen ? Color.green : Color.secondary)

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
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 20)
    }

    // MARK: - Buchen

    private var bookButton: some View {
        Button {
            isBookingShown = true
        } label: {
            Text("Termin buchen")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.bar)
        .disabled(shop.services.isEmpty)
    }

    // MARK: - Helfer

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.title3)
            .fontWeight(.semibold)
    }

    private var sectionDivider: some View {
        Divider().padding(.horizontal, 20)
    }

    private var distanceText: String? {
        guard let meters = appModel.distance(to: shop) else { return nil }
        if meters < 1000 { return "\(Int(meters)) m" }
        return "\((meters / 1000).formatted(.number.precision(.fractionLength(1)))) km"
    }

    private func loadReviews() async {
        isLoadingReviews = true
        // Bewertungen sind nicht kritisch — schlägt das Laden fehl,
        // bleibt die Liste leer, statt das ganze Profil zu blockieren.
        reviews = (try? await appModel.repository.fetchReviews(for: shop.id)) ?? []
        isLoadingReviews = false
    }

    private func weekdayName(_ weekday: Int) -> String {
        let symbols = Calendar.current.weekdaySymbols
        let index = weekday - 1
        guard symbols.indices.contains(index) else { return "" }
        return symbols[index]
    }
}

/// Kleine Karte eines Barbers im Team-Abschnitt.
private struct EmployeeChip: View {

    let employee: BarberEmployee

    var body: some View {
        VStack(spacing: 6) {
            ShopImage(
                seed: employee.id.uuidString,
                url: employee.imageURL,
                symbolSize: 22,
                symbolName: "person.fill"
            )
            .frame(width: 72, height: 72)
            .clipShape(Circle())

            Text(employee.name)
                .font(.subheadline)
                .fontWeight(.medium)

            HStack(spacing: 3) {
                Image(systemName: "star.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.orange)
                Text(employee.rating.formatted(.number.precision(.fractionLength(1))))
                    .font(.caption2)
            }
        }
        .frame(width: 88)
    }
}

/// Öffnet die Apple-Karten-App mit Route zum Shop.
///
/// Eigener Typ, weil das auch aus der Terminübersicht heraus gebraucht
/// wird — und dort liegt kein Shop-Objekt vor, sondern nur eine Adresse.
enum MapNavigation {

    static func open(_ shop: Barbershop) {
        let item = MKMapItem(placemark: MKPlacemark(coordinate: shop.coordinate))
        item.name = shop.name
        item.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
        ])
    }

    /// Fällt auf eine Adresssuche zurück, wenn keine Koordinaten
    /// vorliegen — z. B. bei einem gebuchten Termin, der nur den
    /// Adresstext gespeichert hat.
    static func open(address: String, name: String) {
        let query = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "http://maps.apple.com/?daddr=\(query)") else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    NavigationStack {
        ShopProfileScreen(shop: MockData.shops[0])
            .environment(AppModel())
    }
}
