import SwiftUI

/// Die Barber-Karte — der wichtigste Baustein der App.
///
/// Wird in Entdecken, Favoriten und der Suche benutzt. Deshalb liegt sie
/// in `Core/UI` und nicht in einem Feature-Ordner.
///
/// Bewusst wenige Angaben: Bild, Name, Bewertung, Entfernung, Preis ab,
/// nächster Termin. Mehr würde die Entscheidung verlangsamen statt sie
/// zu erleichtern — man soll in Sekunden sehen, ob der Laden infrage
/// kommt, und nicht erst lesen müssen.
///
/// Die Verfügbarkeit steht bewusst schon HIER und nicht erst im Profil.
/// Sonst klickt man sich durch fünf Läden und merkt am Ende, dass heute
/// überall nichts mehr frei ist.
struct BarberCard: View {

    let shop: Barbershop

    /// Entfernung in Metern — `nil`, solange kein Standort freigegeben ist.
    var distanceInMeters: Double?

    /// Nächster freier Termin — `nil`, wenn keiner bekannt ist.
    var nextSlot: Date?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ShopImage(seed: shop.id.uuidString, url: shop.imageURL, symbolSize: 24)
                .frame(width: 92, height: 92)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 5) {
                header
                ratingLine
                detailLine
                availabilityBadge
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Bestandteile

    private var header: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(shop.name)
                .font(.headline)
                .lineLimit(1)

            Spacer(minLength: 0)

            FavoriteButton(shopID: shop.id)
        }
    }

    private var ratingLine: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.caption2)
                .foregroundStyle(.orange)

            Text(shop.averageRating.formatted(.number.precision(.fractionLength(1))))
                .font(.subheadline)
                .fontWeight(.semibold)

            Text("· \(shop.reviewCount) Bewertungen")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    /// Entfernung und Preis in einer Zeile — beides sind Zahlen, die man
    /// nebeneinander vergleicht.
    private var detailLine: some View {
        HStack(spacing: 6) {
            if let distanceText {
                Text(distanceText)
            }
            if distanceText != nil && shop.priceFromText != nil {
                Text("·")
            }
            if let priceText = shop.priceFromText {
                Text(priceText)
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var availabilityBadge: some View {
        if let nextSlot {
            Text("\(AvailabilityText.short(for: nextSlot)) verfügbar")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.green)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.green.opacity(0.12), in: Capsule())
                .padding(.top, 2)
        } else {
            Text("Zurzeit kein freier Termin")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 2)
        }
    }

    /// Unter 1 km in Metern, darüber in Kilometern.
    private var distanceText: String? {
        guard let distanceInMeters else { return nil }
        if distanceInMeters < 1000 {
            return "\(Int(distanceInMeters)) m"
        }
        let km = distanceInMeters / 1000
        return "\(km.formatted(.number.precision(.fractionLength(1)))) km"
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 10) {
            BarberCard(
                shop: MockData.shops[0],
                distanceInMeters: 800,
                nextSlot: .now.addingTimeInterval(3600 * 5)
            )
            BarberCard(
                shop: MockData.shops[1],
                distanceInMeters: 2350,
                nextSlot: .now.addingTimeInterval(86_400 + 3600)
            )
            BarberCard(shop: MockData.shops[2])
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
    .environment(AppModel())
}
