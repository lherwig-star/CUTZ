import SwiftUI

/// Die vier Kacheln unter dem Kopfbereich.
///
/// Bewusst genau vier und in einer Reihe: Sie sollen mit dem Daumen
/// erreichbar sein, ohne zu scrollen. Was hier nicht hineinpasst,
/// gehört ins Profil — dorthin geht man ohnehin nur selten.
///
/// Die Bewertungskachel zeigt die Zahl direkt an. Das ist der Wert,
/// nach dem Friseure als Erstes schauen, und dafür soll niemand einen
/// Bildschirm weiter tippen müssen.
struct PartnerQuickTiles: View {

    let averageRating: Double
    var onStatistics: () -> Void
    var onReviews: () -> Void
    var onServices: () -> Void
    var onSettings: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            tile(symbol: "chart.bar", title: "Statistiken", action: onStatistics)

            tile(symbol: "star",
                 title: "Bewertungen",
                 detail: averageRating > 0 ? AppText.number(averageRating) : "—",
                 action: onReviews)

            tile(symbol: "scissors", title: "Services", action: onServices)
            tile(symbol: "gearshape", title: "Einstellungen", action: onSettings)
        }
    }

    private func tile(
        symbol: String,
        title: LocalizedStringKey,
        detail: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.title3)

                Text(title)
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                if let detail {
                    Text(detail)
                        .font(.caption.weight(.semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 88)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PartnerQuickTiles(
        averageRating: 4.9,
        onStatistics: {}, onReviews: {}, onServices: {}, onSettings: {}
    )
    .padding()
    .preferredColorScheme(.dark)
}
