import SwiftUI

/// Eine Zeile in der Shop-Liste: Bild, Name, Bewertung, Adresse, Preis.
///
/// Wird sowohl in der Suche als auch später in "Favoriten" verwendet.
struct ShopRow: View {

    let shop: Barbershop

    /// Entfernung in Metern — optional, weil wir sie nur kennen,
    /// wenn der Nutzer den Standort freigegeben hat.
    var distanceInMeters: Double? = nil

    var body: some View {
        HStack(spacing: 12) {
            thumbnail

            VStack(alignment: .leading, spacing: 4) {
                Text(shop.name)
                    .font(.headline)
                    .lineLimit(1)

                RatingStars(rating: shop.averageRating, reviewCount: shop.reviewCount)

                Text(shop.fullAddress)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(shop.priceLevelText)
                    if let cheapest = shop.cheapestService {
                        Text("· ab \(cheapest.priceFormatted)")
                    }
                    if let distanceText {
                        Text("· \(distanceText)")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }

    /// Platzhalter-Bild, solange wir keine echten Fotos haben.
    private var thumbnail: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(.quaternary)
            .frame(width: 64, height: 64)
            .overlay {
                Image(systemName: "scissors")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
    }

    /// Formatiert die Entfernung: unter 1 km in Metern, darüber in Kilometern.
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
    List {
        ShopRow(shop: MockData.shops[0], distanceInMeters: 420)
        ShopRow(shop: MockData.shops[1], distanceInMeters: 2350)
        ShopRow(shop: MockData.shops[2])
    }
}
