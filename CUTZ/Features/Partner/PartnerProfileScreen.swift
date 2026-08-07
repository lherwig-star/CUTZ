import SwiftUI

/// Der Profil-Tab: alles, was man selten anfasst.
///
/// Bewusst nur eine Liste von Wegen und kein Formular. Was hier steht,
/// ändert ein Friseur ein-, zweimal im Jahr — Öffnungszeiten,
/// Leistungen, Beschreibung. Das gehört nicht auf denselben
/// Bildschirm wie der Tagesplan.
struct PartnerProfileScreen: View {

    @Environment(AppModel.self) private var appModel
    @Environment(PartnerModel.self) private var partnerModel

    var body: some View {
        NavigationStack {
            List {
                if let shop = partnerModel.shop {
                    headerSection(shop)
                    shopSection
                }
                appSection
                accountSection
            }
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Abschnitte

    private func headerSection(_ shop: Barbershop) -> some View {
        Section {
            HStack(spacing: 14) {
                ShopImage(seed: shop.id.uuidString, url: shop.imageURL, symbolSize: 22)
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 5) {
                        Text(shop.name)
                            .font(.headline)
                            .lineLimit(1)

                        if appModel.partner.status == .approved {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundStyle(.tint)
                        }
                    }

                    Text(shop.fullAddress)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var shopSection: some View {
        Section("Dein Laden") {
            NavigationLink {
                PartnerProfileEditScreen()
            } label: {
                Label("Profil bearbeiten", systemImage: "pencil")
            }

            NavigationLink {
                PartnerServicesScreen()
            } label: {
                Label("Services verwalten", systemImage: "scissors")
            }

            NavigationLink {
                PartnerOpeningHoursScreen()
            } label: {
                Label("Öffnungszeiten", systemImage: "clock")
            }
        }
    }

    private var appSection: some View {
        Section("Einstellungen") {
            // Derselbe Schalter wie auf der Kundenseite. Der Laden
            // spricht nicht zwingend die Sprache seiner Kunden — und
            // umgekehrt.
            LanguageRow(store: appModel.language)
        }
    }

    private var accountSection: some View {
        Section {
            Button {
                appModel.role.current = .customer
            } label: {
                Label("Zur Kundenansicht wechseln", systemImage: "arrow.left.arrow.right")
            }

            Button(role: .destructive) {
                appModel.partner.reset()
            } label: {
                Label("Eintrag zurückziehen", systemImage: "trash")
            }
        } footer: {
            Text("CUTZ · Version 0.1.0")
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)
        }
    }
}

/// Die Sprachzeile. Steht als eigener kleiner Typ da, weil sie im
/// Kundenprofil genauso aussieht — nur dass sie dort in einer anderen
/// Liste sitzt.
struct LanguageRow: View {

    let store: LanguageStore

    var body: some View {
        @Bindable var store = store

        return Picker(selection: $store.current) {
            ForEach(AppLanguage.allCases) { language in
                // `Text(einString)` übersetzt bewusst NICHT: Die
                // Sprachnamen stehen in ihrer eigenen Sprache da.
                Text(language.displayName).tag(language)
            }
        } label: {
            Label("Sprache", systemImage: "globe")
        }
        .pickerStyle(.navigationLink)
    }
}
