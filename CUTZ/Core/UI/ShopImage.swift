import SwiftUI

/// Zeigt ein Bild an — oder einen Platzhalter, solange es keins gibt.
///
/// Hintergrund: Im Projekt liegen noch keine echten Fotos. Die kommen
/// erst mit Supabase Storage (Phase 5, siehe PLAN.md). Bis dahin sähe
/// die App mit lauter grauen Kästen kaputt aus — dabei ist sie es nicht.
///
/// Deshalb zeichnen wir einen Farbverlauf mit Schere darin. Der Verlauf
/// wird aus dem `seed` berechnet: Derselbe Shop bekommt also IMMER
/// dieselbe Farbe, verschiedene Shops verschiedene. Das wirkt gewollt
/// statt zufällig, und die Liste bleibt beim Scrollen ruhig.
///
/// Sobald echte Bilder da sind, ändert sich hier nichts: Ist `url`
/// gesetzt, wird das Foto geladen und der Platzhalter dient nur noch
/// als Zwischenzustand während des Ladens.
struct ShopImage: View {

    /// Beliebiger Text, aus dem die Farbe abgeleitet wird — üblicherweise
    /// die Shop-ID plus laufende Nummer.
    let seed: String

    /// Das echte Bild, falls vorhanden.
    var url: URL? = nil

    /// Größe des Symbols in der Mitte.
    var symbolSize: CGFloat = 28

    var symbolName = "scissors"

    var body: some View {
        ZStack {
            placeholder

            if let url {
                // `AsyncImage` lädt das Bild im Hintergrund. Solange es
                // nicht da ist, bleibt der Platzhalter darunter sichtbar.
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.clear
                }
            }
        }
        .clipped()
    }

    private var placeholder: some View {
        LinearGradient(
            colors: Self.colors(for: seed),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            Image(systemName: symbolName)
                .font(.system(size: symbolSize, weight: .light))
                .foregroundStyle(.white.opacity(0.55))
        }
    }

    // MARK: - Farbe aus Text ableiten

    /// Eine feste Palette. Bewusst gedeckte, dunkle Töne — die App soll
    /// hochwertig wirken, und darauf funktionieren weiße Schrift und
    /// Symbole zuverlässig.
    private static let palette: [[Color]] = [
        [Color(red: 0.16, green: 0.18, blue: 0.24), Color(red: 0.28, green: 0.31, blue: 0.40)],
        [Color(red: 0.24, green: 0.17, blue: 0.15), Color(red: 0.42, green: 0.29, blue: 0.24)],
        [Color(red: 0.13, green: 0.22, blue: 0.22), Color(red: 0.22, green: 0.38, blue: 0.36)],
        [Color(red: 0.21, green: 0.15, blue: 0.24), Color(red: 0.36, green: 0.26, blue: 0.42)],
        [Color(red: 0.22, green: 0.20, blue: 0.14), Color(red: 0.38, green: 0.34, blue: 0.22)],
        [Color(red: 0.14, green: 0.19, blue: 0.28), Color(red: 0.23, green: 0.33, blue: 0.47)]
    ]

    /// Wählt anhand des Textes einen Eintrag aus der Palette.
    ///
    /// `hashValue` von Swift wäre hier falsch: Der ändert sich bei jedem
    /// App-Start (Absicht von Swift, aus Sicherheitsgründen). Dann hätte
    /// derselbe Shop mal diese, mal jene Farbe. Deshalb rechnen wir
    /// selbst — simpel, aber immer gleich.
    static func colors(for seed: String) -> [Color] {
        var sum = 0
        for byte in seed.utf8 {
            sum += Int(byte)
        }
        return palette[sum % palette.count]
    }
}

#Preview {
    VStack(spacing: 12) {
        ShopImage(seed: "shop-1", symbolSize: 44)
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 14))

        HStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { index in
                ShopImage(seed: "shop-2-\(index)", symbolSize: 20)
                    .frame(width: 76, height: 76)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
    .padding()
}
