import SwiftUI

/// Die Bildergalerie mit vergangenen Arbeiten.
///
/// Warum das so prominent ist: Von den vier Fragen, die ein Profil
/// beantworten muss, ist "kann der schneiden?" die erste — und die
/// beantwortet kein Text, sondern nur ein Bild. Bewertungen sagen, ob
/// andere zufrieden waren; Bilder sagen, ob es DIR gefällt.
///
/// Solange keine echten Fotos da sind, zeichnet `ShopImage` Platzhalter.
/// Die Anordnung stimmt dadurch schon jetzt, und es müssen später nur
/// URLs nachgeliefert werden.
struct PortfolioGallery: View {

    /// Wofür die Bilder stehen — geht in die Platzhalterfarbe ein,
    /// damit zwei Shops nicht identisch aussehen.
    let seed: String

    let imageURLs: [URL]

    /// Wie viele Platzhalter gezeigt werden, solange es keine Fotos gibt.
    var placeholderCount = 6

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(0..<tileCount, id: \.self) { index in
                    ShopImage(
                        seed: "\(seed)-\(index)",
                        url: index < imageURLs.count ? imageURLs[index] : nil,
                        symbolSize: 22
                    )
                    .frame(width: 116, height: 148)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 20)
        }
        // Damit die Bilder am Bildschirmrand "anstoßen" statt in einem
        // eingerückten Kasten zu sitzen — wirkt großzügiger.
        .padding(.horizontal, -20)
    }

    private var tileCount: Int {
        imageURLs.isEmpty ? placeholderCount : imageURLs.count
    }
}

#Preview {
    VStack(alignment: .leading) {
        Text("Arbeiten")
            .font(.title3)
            .fontWeight(.semibold)
        PortfolioGallery(seed: MockData.shopID1.uuidString, imageURLs: [])
    }
    .padding(20)
}
