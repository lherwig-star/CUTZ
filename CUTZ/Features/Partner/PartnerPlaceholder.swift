import SwiftUI

/// Platzhalter für Bereiche der Friseurseite, die noch nicht gebaut sind.
///
/// Bewusst ehrlich beschriftet statt mit erfundenen Beispieldaten
/// gefüllt. Ein Bildschirm, der so aussieht, als würde er etwas
/// können, kostet später eine Fehlersuche — dieser hier nicht.
///
/// Verschwindet, sobald der jeweilige Bereich fertig ist.
struct PartnerPlaceholder: View {

    let symbol: String
    let title: LocalizedStringKey

    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label(title, systemImage: symbol)
            } description: {
                Text("Dieser Bereich wird gerade gebaut.")
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    PartnerPlaceholder(symbol: "calendar", title: "Kalender")
        .preferredColorScheme(.dark)
}
