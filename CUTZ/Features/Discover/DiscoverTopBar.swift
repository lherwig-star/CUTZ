import SwiftUI

/// Die schwebende Leiste oben im Entdecken-Screen:
/// Suchfeld links, Profil-Button rechts.
///
/// Sie liegt ÜBER der Karte statt in einer Navigationsleiste. Grund:
/// Die Karte soll den ganzen Bildschirm füllen. Eine feste Leiste
/// darüber würde oben einen Streifen wegnehmen und die App sofort
/// nach Verwaltungssoftware aussehen lassen.
struct DiscoverTopBar: View {

    /// Wird beim Antippen des Suchfelds aufgerufen. Das Feld selbst ist
    /// nur eine Attrappe — getippt wird in der Suchansicht, die sich
    /// darüberlegt. So bleibt die Karte darunter unangetastet.
    let onSearchTap: () -> Void
    let onProfileTap: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            searchField
            profileButton
        }
        .padding(.horizontal, 16)
    }

    private var searchField: some View {
        Button(action: onSearchTap) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                Text("Barber oder Ort suchen")
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer(minLength: 0)
            }
            .font(.subheadline)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(.regularMaterial, in: Capsule())
            .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Suchen")
    }

    private var profileButton: some View {
        Button(action: onProfileTap) {
            Image(systemName: "person.crop.circle")
                .font(.title2)
                .foregroundStyle(.primary)
                .frame(width: 44, height: 44)
                .background(.regularMaterial, in: Circle())
                .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Profil")
    }
}

#Preview {
    ZStack(alignment: .top) {
        LinearGradient(colors: [.green.opacity(0.3), .blue.opacity(0.3)],
                       startPoint: .top, endPoint: .bottom)
        DiscoverTopBar(onSearchTap: {}, onProfileTap: {})
            .padding(.top, 60)
    }
    .ignoresSafeArea()
}
