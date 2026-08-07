import SwiftUI
// Für `UIApplication.openSettingsURLString` — SwiftUI allein kennt das nicht.
import UIKit

/// Das Nutzerprofil hinter dem Knopf oben rechts.
///
/// Bewusst KEIN Hauptbereich der App und deshalb auch nicht in der
/// Tab-Leiste. Hier liegen nur Dinge, die man selten braucht — die
/// Tab-Leiste ist für das da, was man ständig tut.
///
/// Stand Phase 1: Es gibt noch keine Nutzerkonten (die kommen in
/// Phase 3, siehe PLAN.md). Die Angaben unten sind deshalb Platzhalter
/// und als solche gekennzeichnet — lieber ehrlich "noch nicht
/// eingerichtet" als ein Formular, das ins Leere speichert.
struct AccountScreen: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(AppModel.self) private var appModel

    var body: some View {
        NavigationStack {
            List {
                headerSection
                accountSection
                settingsSection
                partnerSection
                supportSection
                legalSection
            }
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }

    // MARK: - Abschnitte

    private var headerSection: some View {
        Section {
            HStack(spacing: 14) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Noch nicht angemeldet")
                        .font(.headline)
                    Text("Mit einem Konto siehst du deine Termine auf allen Geräten.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 6)

            // Anmelden kommt mit Phase 3. Der Knopf steht trotzdem
            // schon da, damit klar ist, wo es später hingehört.
            Button {
                // Absichtlich noch ohne Funktion.
            } label: {
                Text("Anmelden")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(true)
        }
    }

    private var accountSection: some View {
        Section("Account") {
            placeholderRow("Name", value: "—", symbol: "person")
            placeholderRow("E-Mail", value: "—", symbol: "envelope")
            placeholderRow("Telefon", value: "—", symbol: "phone")
        }
    }

    private var settingsSection: some View {
        // `@Bindable` erzeugt aus dem beobachteten Objekt Bindungen mit
        // `$`. Der Picker unten braucht das, weil er den Wert nicht nur
        // liest, sondern auch zurückschreibt.
        @Bindable var languageStore = appModel.language

        return Section("Einstellungen") {
            Label("Benachrichtigungen", systemImage: "bell")

            LabeledContent {
                Text(locationStatusText)
                    .foregroundStyle(.secondary)
            } label: {
                Label("Standort", systemImage: "location")
            }

            // Der Sprachschalter.
            //
            // `.navigationLink` heißt: Die Zeile zeigt die aktuelle
            // Sprache an und führt beim Antippen auf eine kleine Liste
            // mit allen Möglichkeiten. Das ist der Stil, den iOS in
            // seinen eigenen Einstellungen verwendet — dadurch muss
            // niemand raten, was passiert.
            Picker(selection: $languageStore.current) {
                ForEach(AppLanguage.allCases) { language in
                    // `Text(einString)` übersetzt bewusst NICHT: Die
                    // Sprachnamen sollen in ihrer eigenen Sprache
                    // dastehen, nicht in der gerade eingestellten.
                    Text(language.displayName).tag(language)
                }
            } label: {
                Label("Sprache", systemImage: "globe")
            }
            .pickerStyle(.navigationLink)

            // Führt in die iOS-Einstellungen. Die Standortfreigabe kann
            // eine App nicht selbst umstellen — das macht iOS.
            Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
                Label("Standort in den iOS-Einstellungen ändern", systemImage: "gear")
                    .font(.subheadline)
            }
        }
    }

    private var supportSection: some View {
        Section("Support") {
            Label("Hilfe", systemImage: "questionmark.circle")
            Label("Problem melden", systemImage: "exclamationmark.bubble")
        }
    }

    /// Der Weg auf die Friseurseite.
    ///
    /// Steht bewusst hier im Kundenprofil und nicht versteckt in den
    /// Einstellungen. Wer als Friseur von CUTZ hört, hört es meistens
    /// von einem Kunden — und sucht dann genau hier.
    ///
    /// Das ist der billigste Vertriebsweg, den wir haben: Er kostet
    /// nichts und steht schon da, wenn jemand danach sucht.
    private var partnerSection: some View {
        Section {
            Button {
                appModel.role.current = .barber
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "storefront")
                        .font(.title3)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Bist du Friseur?")
                            .font(.headline)
                        Text("Trag deinen Laden ein und verwalte Termine direkt in CUTZ.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.forward")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .multilineTextAlignment(.leading)
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
        }
    }

    private var legalSection: some View {
        Section {
            Label("Datenschutz", systemImage: "hand.raised")
            Label("Impressum", systemImage: "doc.text")
        } footer: {
            Text("CUTZ · Version 0.1.0")
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)
        }
    }

    // MARK: - Helfer

    private func placeholderRow(_ title: LocalizedStringKey, value: String, symbol: String) -> some View {
        LabeledContent {
            Text(value)
                .foregroundStyle(.secondary)
        } label: {
            Label(title, systemImage: symbol)
        }
    }

    private var locationStatusText: String {
        switch appModel.location.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse: return AppText.string("Erlaubt")
        case .denied, .restricted:                    return AppText.string("Nicht erlaubt")
        default:                                      return AppText.string("Noch nicht gefragt")
        }
    }
}

#Preview {
    AccountScreen()
        .environment(AppModel())
}
