import SwiftUI

/// Der Bewertungsteil im Shop-Profil.
///
/// ─── Zuständig: Lukas ──────────────────────────────────────
struct ReviewsSection: View {

    let reviews: [Review]
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Bewertungen")
                .font(.title3)
                .fontWeight(.semibold)

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)

            } else if reviews.isEmpty {
                Text("Noch keine Bewertungen.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

            } else {
                ForEach(reviews) { review in
                    ReviewCard(review: review)
                }
            }
        }
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
