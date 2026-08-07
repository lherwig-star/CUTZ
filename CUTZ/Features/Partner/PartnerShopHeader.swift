import SwiftUI

/// Der Kopf der Übersicht: Logo, Name, Adresse, Weg ins Profil.
///
/// Der Haken hinter dem Namen ist nicht Zierde. Er sagt: Dieser Laden
/// wurde von uns geprüft. Für den Friseur ist das die Bestätigung,
/// dass seine Anmeldung durch ist — und später steht derselbe Haken
/// auf der Kundenseite.
struct PartnerShopHeader: View {

    let shop: Barbershop
    let isVerified: Bool
    var onOpenProfile: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            // Der Farbverlauf wird aus der Shop-ID abgeleitet, damit
            // derselbe Laden immer gleich aussieht. Ein echtes Logo
            // ersetzt ihn, sobald eins hochgeladen wurde.
            ShopImage(seed: shop.id.uuidString, url: shop.imageURL, symbolSize: 24)
                .frame(width: 64, height: 64)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Text(shop.name)
                        .font(.title3.bold())
                        .lineLimit(1)

                    if isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.footnote)
                            .foregroundStyle(.tint)
                            .accessibilityLabel("Geprüfter Laden")
                    }
                }

                Text(shop.fullAddress)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Button(action: onOpenProfile) {
                    HStack(spacing: 3) {
                        Text("Profil ansehen")
                        Image(systemName: "chevron.forward")
                    }
                    .font(.caption.weight(.medium))
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }

            Spacer(minLength: 0)
        }
    }
}
