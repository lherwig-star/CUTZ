import SwiftUI

/// Der Weg vom "Ich bin Friseur" zum freigegebenen Laden.
///
/// Drei Zustände, drei Ansichten:
///
///   noch nichts eingetragen → Formular
///   eingetragen             → "wird geprüft"
///   abgelehnt               → Begründung und Weg zurück
///
/// Freigegebene Läden landen hier gar nicht erst, die sehen die
/// Tab-Leiste.
struct PartnerRegistrationScreen: View {

    @Environment(AppModel.self) private var appModel

    var body: some View {
        NavigationStack {
            Group {
                switch appModel.partner.status {
                case .notRegistered: RegistrationForm()
                case .pending:       PendingView()
                case .rejected:      RejectedView()
                case .approved:      EmptyView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    // Der Weg zurück auf die Kundenseite. Ohne den säße
                    // jemand fest, der sich nur verklickt hat.
                    Button("Als Kunde nutzen") {
                        appModel.role.current = .customer
                    }
                    .font(.subheadline)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Formular

private struct RegistrationForm: View {

    @Environment(AppModel.self) private var appModel

    @State private var name = ""
    @State private var street = ""
    @State private var postalCode = ""
    @State private var city = ""
    @State private var phone = ""
    @State private var isSending = false

    /// Ohne Name, Adresse und Telefonnummer lässt sich der Laden nicht
    /// prüfen — und die Prüfung ist genau der Sinn der Sache.
    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !street.trimmingCharacters(in: .whitespaces).isEmpty
            && !city.trimmingCharacters(in: .whitespaces).isEmpty
            && !phone.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        Form {
            Section {
                TextField("Name des Salons", text: $name)
                    .textContentType(.organizationName)
                TextField("Straße und Hausnummer", text: $street)
                    .textContentType(.streetAddressLine1)
                TextField("PLZ", text: $postalCode)
                    .textContentType(.postalCode)
                    .keyboardType(.numberPad)
                TextField("Stadt", text: $city)
                    .textContentType(.addressCity)
                TextField("Telefon", text: $phone)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
            } header: {
                Text("Dein Laden")
            } footer: {
                Text("Wir rufen unter dieser Nummer an, um zu prüfen, dass der Laden wirklich dir gehört.")
            }

            Section {
                Button {
                    Task { await submit() }
                } label: {
                    if isSending {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Text("Zur Prüfung einreichen")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canSubmit || isSending)
            }
        }
        .navigationTitle("Laden eintragen")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func submit() async {
        isSending = true
        defer { isSending = false }

        do {
            let shop = try await appModel.shopRepository.registerShop(
                name: name.trimmingCharacters(in: .whitespaces),
                street: street.trimmingCharacters(in: .whitespaces),
                postalCode: postalCode.trimmingCharacters(in: .whitespaces),
                city: city.trimmingCharacters(in: .whitespaces),
                phone: phone.trimmingCharacters(in: .whitespaces)
            )
            appModel.partner.register(shopID: shop.id)
        } catch {
            // Mehr als der Versuch ist hier nicht zu tun — der Friseur
            // kann es gleich noch einmal probieren.
        }
    }
}

// MARK: - Warten

private struct PendingView: View {

    @Environment(AppModel.self) private var appModel

    var body: some View {
        VStack(spacing: 18) {
            Spacer()

            Image(systemName: "clock.badge.checkmark")
                .font(.system(size: 46, weight: .light))
                .foregroundStyle(.tint)

            VStack(spacing: 8) {
                Text("Wir prüfen deinen Laden")
                    .font(.title2.bold())

                Text("Das dauert meistens einen Werktag. Wir melden uns telefonisch bei dir.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)

            Spacer()

            // ── Behelf, kein Feature ──────────────────────────
            //
            // Solange es kein Backend gibt, kann niemand freigeben.
            // Ohne diesen Knopf käme man nie auf die Friseurseite und
            // könnte sie auch nicht ausprobieren.
            //
            // Ausdrücklich so beschriftet, damit ihn niemand für einen
            // regulären Teil der App hält. Fällt mit Phase 2 weg.
            VStack(spacing: 10) {
                Text("Noch ohne Server — es kann niemand freigeben.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Zum Ausprobieren selbst freigeben") {
                    appModel.partner.approveForDemo()
                }
                .buttonStyle(.bordered)

                Button("Eintrag zurückziehen", role: .destructive) {
                    appModel.partner.reset()
                }
                .font(.subheadline)
            }
            .multilineTextAlignment(.center)
            .padding(.bottom, 28)
        }
        .navigationTitle("In Prüfung")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Abgelehnt

private struct RejectedView: View {

    @Environment(AppModel.self) private var appModel

    var body: some View {
        ContentUnavailableView {
            Label("Eintrag abgelehnt", systemImage: "xmark.circle")
        } description: {
            Text("Möglicherweise ist der Laden schon eingetragen. Melde dich bei uns, dann klären wir das.")
        } actions: {
            Button("Erneut versuchen") {
                appModel.partner.reset()
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Eintrag abgelehnt")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    PartnerRegistrationScreen()
        .environment(AppModel())
}
