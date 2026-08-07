import SwiftUI

/// Die erste Frage beim allerersten Start: Kunde oder Friseur?
///
/// Bewusst der einzige Bildschirm vor der App. Kein mehrseitiges
/// Onboarding mit Erklärbildern — die überspringt ohnehin jeder, und
/// wer noch nichts gesehen hat, kann mit Erklärungen nichts anfangen.
///
/// Die Wahl ist nicht endgültig und der Hinweis unten sagt das auch.
/// Sonst zögert man an dieser Stelle, obwohl es nichts zu verlieren
/// gibt.
struct RoleChoiceScreen: View {

    /// Wird aufgerufen, sobald jemand sich entschieden hat.
    let onChoose: (AppRole) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 10) {
                Image(systemName: "scissors")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(.tint)

                Text("Willkommen bei CUTZ")
                    .font(.largeTitle.bold())

                Text("Wie möchtest du CUTZ nutzen?")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 14) {
                RoleCard(
                    symbol: "magnifyingglass",
                    title: "Ich suche einen Termin",
                    subtitle: "Barbershops in deiner Nähe finden, vergleichen und direkt buchen.",
                    action: { onChoose(.customer) }
                )

                RoleCard(
                    symbol: "storefront",
                    title: "Ich bin Friseur",
                    subtitle: "Meinen Laden eintragen, Termine verwalten und neue Kunden gewinnen.",
                    action: { onChoose(.barber) }
                )
            }
            .padding(.horizontal, 20)

            Text("Das lässt sich später jederzeit im Profil ändern.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 22)
                .padding(.bottom, 28)
        }
    }
}

/// Eine der beiden großen Auswahlkarten.
///
/// Groß und mit Beschreibung statt zwei knapper Knöpfe: Diese Wahl
/// bestimmt, was jemand von der App überhaupt zu sehen bekommt. Wer
/// hier falsch tippt, landet in einer App, die nicht zu ihm passt.
private struct RoleCard: View {

    let symbol: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: symbol)
                    .font(.title2)
                    .foregroundStyle(.tint)
                    .frame(width: 34, height: 34)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                // `.forward` statt `.right`, damit der Pfeil im
                // Arabischen mitdreht.
                Image(systemName: "chevron.forward")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4)
            }
            .multilineTextAlignment(.leading)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 16)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RoleChoiceScreen { _ in }
}
