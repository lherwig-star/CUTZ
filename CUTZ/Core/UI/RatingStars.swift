import SwiftUI

/// Zeigt eine Bewertung als Sterne an, z. B. ★★★★☆ 4,7
///
/// Wird an mehreren Stellen gebraucht (Liste, Profil, Bewertungen),
/// deshalb liegt die View im gemeinsamen `Core/UI`-Ordner und nicht
/// in einem Feature-Ordner.
struct RatingStars: View {

    let rating: Double
    var reviewCount: Int? = nil
    var showsNumber = true

    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...5, id: \.self) { position in
                Image(systemName: symbolName(for: position))
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            if showsNumber {
                Text(AppText.number(rating))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .padding(.leading, 2)
            }

            if let reviewCount {
                Text("(\(reviewCount))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        // Für VoiceOver: statt 5 einzelner Sterne ein sinnvoller Satz.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    /// Entscheidet pro Stern-Position: voll, halb oder leer?
    private func symbolName(for position: Int) -> String {
        let value = Double(position)
        if rating >= value {
            return "star.fill"
        } else if rating >= value - 0.5 {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }

    /// Was VoiceOver vorliest.
    ///
    /// Wird zusammengesetzt und ist deshalb ein berechneter Text —
    /// also `AppText`, nicht `Text("…")`. Vorher stand hier deutscher
    /// Text fest verdrahtet: Blinde Nutzer hätten die App auf Englisch
    /// gestellt und trotzdem "Bewertung 4,7 von 5" gehört.
    private var accessibilityText: String {
        let base = AppText.format("rating.outOfFive", AppText.number(rating))
        guard let reviewCount else { return base }
        return base + AppText.format("rating.reviewCountSuffix", reviewCount)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        RatingStars(rating: 4.7, reviewCount: 128)
        RatingStars(rating: 3.5)
        RatingStars(rating: 5.0, reviewCount: 12)
        RatingStars(rating: 1.0)
    }
    .padding()
}
