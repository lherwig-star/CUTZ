import SwiftUI

/// Der Bewertungsteil im Shop-Profil.
///
/// ─── Zuständig: Lukas ──────────────────────────────────────
struct ReviewsSection: View {

    let reviews: [Review]
    let isLoading: Bool

    // Filter und Sortierung stehen bewusst HIER und nicht im
    // `ShopProfileScreen` darüber.
    //
    // Warum? Es sind reine Anzeige-Einstellungen: Sie interessieren
    // niemanden sonst, niemand muss sie speichern, und sie dürfen ruhig
    // vergessen werden, sobald man den Bildschirm verlässt. Genau dafür
    // ist `@State` da. Läge der Zustand oben, müsste er über Bindings
    // hierher durchgereicht werden — mehr Code, kein Gewinn.
    //
    // Nebeneffekt: `ShopProfileScreen` bleibt unverändert. Das ist die
    // längste Datei im Projekt, die soll nicht weiter wachsen.
    @State private var ratingFilter: ReviewRatingFilter = .all
    @State private var sort: ReviewSort = .newest

    /// Was nach Filter und Sortierung übrig bleibt.
    private var visibleReviews: [Review] {
        ReviewFiltering.apply(to: reviews, rating: ratingFilter, sort: sort)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)

            } else if reviews.isEmpty {
                hint("Noch keine Bewertungen.")

            } else if visibleReviews.isEmpty {
                // Wichtig, dass sich diese Meldung von der obigen
                // unterscheidet: "gibt es keine" und "der Filter lässt
                // gerade nichts durch" sind zwei verschiedene Dinge.
                hint("Keine Bewertung passt zu diesem Filter.")

            } else {
                if ratingFilter != .all {
                    Text("\(visibleReviews.count) von \(reviews.count) Bewertungen")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                ForEach(visibleReviews) { review in
                    ReviewCard(review: review)
                }
            }
        }
    }

    // MARK: - Bereiche

    private var header: some View {
        HStack {
            Text("Bewertungen")
                .font(.title3)
                .fontWeight(.semibold)

            Spacer()

            // Solange es gar keine Bewertungen gibt, wäre ein Filter sinnlos.
            if !reviews.isEmpty {
                filterMenu
            }
        }
    }

    private var filterMenu: some View {
        Menu {
            // Ein `Picker` innerhalb eines `Menu` wird von iOS automatisch
            // als Untermenü mit Häkchen dargestellt — man muss sich um die
            // Darstellung nicht kümmern.
            Picker("Sortieren", selection: $sort) {
                ForEach(ReviewSort.allCases) { option in
                    Text(option.label).tag(option)
                }
            }

            Picker("Filtern", selection: $ratingFilter) {
                ForEach(ReviewRatingFilter.allCases) { option in
                    Text(option.label).tag(option)
                }
            }
        } label: {
            Label("Sortieren und filtern", systemImage: filterSymbol)
                .labelStyle(.iconOnly)
                .font(.title3)
        }
        // Ohne Beschriftung wüsste VoiceOver nicht, was der Knopf tut.
        .accessibilityLabel("Bewertungen sortieren und filtern")
    }

    /// Das Symbol wird gefüllt dargestellt, sobald ein Filter aktiv ist —
    /// so sieht man auf einen Blick, dass nicht alles angezeigt wird.
    private var filterSymbol: String {
        ratingFilter == .all
            ? "line.3.horizontal.decrease.circle"
            : "line.3.horizontal.decrease.circle.fill"
    }

    /// Kurzer grauer Hinweistext.
    private func hint(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }
}

/// Eine einzelne Bewertung.
private struct ReviewCard: View {

    let review: Review

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(review.authorName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(review.createdAtRelative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            RatingStars(rating: Double(review.rating), showsNumber: false)

            Text(review.comment)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    ScrollView {
        ReviewsSection(
            reviews: MockData.reviews.filter { $0.shopID == MockData.shopID1 },
            isLoading: false
        )
        .padding()
    }
}
