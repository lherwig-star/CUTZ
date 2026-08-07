import SwiftUI

/// Das Herz zum Favorisieren.
///
/// Liegt in `Core/UI`, weil es an drei Stellen auftaucht: auf der
/// Barber-Karte, im Shop-Profil und in den Favoriten selbst.
struct FavoriteButton: View {

    let shopID: UUID

    /// Größe des Herzens. Auf der Karte klein, im Profil größer.
    var size: Font = .subheadline

    /// Dunkler Kreis dahinter — nötig, wenn das Herz auf einem Bild
    /// liegt, weil es sonst je nach Bildfarbe verschwindet.
    var hasBackground = false

    @Environment(AppModel.self) private var appModel

    private var isFavorite: Bool {
        appModel.favorites.isFavorite(shopID)
    }

    var body: some View {
        Button {
            // Kurzes Federn beim Antippen. Das ist die eine Animation,
            // die sich lohnt: Sie bestätigt die Aktion sofort, ohne dass
            // irgendwo Text erscheinen muss.
            withAnimation(.snappy(duration: 0.25, extraBounce: 0.3)) {
                appModel.favorites.toggle(shopID)
            }
        } label: {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(size)
                .foregroundStyle(isFavorite ? Color.red : foregroundWhenOff)
                .scaleEffect(isFavorite ? 1.1 : 1.0)
                .padding(hasBackground ? 8 : 0)
                .background {
                    if hasBackground {
                        Circle().fill(.ultraThinMaterial)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isFavorite ? "Aus Favoriten entfernen" : "Zu Favoriten hinzufügen")
    }

    private var foregroundWhenOff: Color {
        hasBackground ? .white : .secondary
    }
}

#Preview {
    HStack(spacing: 20) {
        FavoriteButton(shopID: MockData.shopID1)
        FavoriteButton(shopID: MockData.shopID2, size: .title2)
        ZStack {
            Color.gray
            FavoriteButton(shopID: MockData.shopID3, size: .title3, hasBackground: true)
        }
        .frame(width: 80, height: 80)
    }
    .padding()
    .environment(AppModel())
}
