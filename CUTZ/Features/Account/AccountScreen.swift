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
        Section("Einstellungen") {
            Label("Benachrichtigungen", systemImage: "bell")

            LabeledContent {
                Text(locationStatusText)
                    .foregroundStyle(.secondary)
            } label: {
                Label("Standort", systemImage: "location")
            }

            LabeledContent {
                Text(currentLanguageName)
                    .foregroundStyle(.secondary)
            } label: {
                Label("Sprache", systemImage: "globe")
            }

            // Führt in die iOS-Einstellungen. Sprache und Standortfreigabe
            // kann eine App nicht selbst umstellen — das macht iOS.
            //
            // Seit iOS 13 hat jede App dort einen eigenen Eintrag
            // "Sprache", in dem man Deutsch, Englisch oder Arabisch
            // wählen kann, unabhängig von der Systemsprache. Genau
            // dorthin führt dieser Verweis.
            Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
                Label("In den iOS-Einstellungen ändern", systemImage: "gear")
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

    /// Die Sprache, in der die App gerade läuft — in dieser Sprache
    /// benannt ("Deutsch", "English", "العربية").
    ///
    /// `preferredLocalizations.first` liefert die Sprache, die iOS für
    /// CUTZ tatsächlich ausgewählt hat. Das ist nicht dasselbe wie die
    /// Systemsprache: Wer sein iPhone auf Türkisch hat, sieht CUTZ
    /// trotzdem auf Deutsch, weil wir kein Türkisch anbieten.
    private var currentLanguageName: String {
        let code = Bundle.main.preferredLocalizations.first ?? "de"
        let locale = Locale(identifier: code)
        return locale.localizedString(forLanguageCode: code)?.capitalized ?? code
    }

    private var locationStatusText: String {
        switch appModel.location.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse: return String(localized: "Erlaubt")
        case .denied, .restricted:                    return String(localized: "Nicht erlaubt")
        default:                                      return String(localized: "Noch nicht gefragt")
        }
    }
}

#Preview {
    AccountScreen()
        .environment(AppModel())
}
