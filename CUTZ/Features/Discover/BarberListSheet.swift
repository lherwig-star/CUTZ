import SwiftUI

/// Wie weit die Liste hochgezogen ist.
///
/// Bewusst nur ZWEI Stufen: unten oder ganz oben. Eine mittlere Stufe
/// gab es anfangs, sie fühlte sich aber unentschieden an — man landete
/// beim Ziehen ständig dort, obwohl man entweder die Karte sehen oder
/// die Liste lesen wollte. Zwei klare Zustände sind schneller zu
/// bedienen als drei ungefähre.
enum SheetDetent: CaseIterable {

    case collapsed
    case expanded

    /// Höhe in Punkten, abhängig von der Bildschirmhöhe.
    ///
    /// Unten bleibt genau eine Karte sichtbar. Das ist Absicht: Tippt
    /// man auf der Karte einen Pin an, sieht man den Shop sofort —
    /// ohne dass die Liste die Karte verdeckt.
    func height(in total: CGFloat) -> CGFloat {
        switch self {
        case .collapsed: return 210
        case .expanded:  return total * 0.92
        }
    }

    /// Die jeweils andere Stufe — fürs Antippen des Griffs.
    var toggled: SheetDetent {
        self == .collapsed ? .expanded : .collapsed
    }
}

/// Die von unten hochziehbare Barber-Liste über der Karte.
///
/// Warum selbst gebaut und nicht Apples `.sheet` mit `presentationDetents`?
/// Ein dauerhaft geöffnetes Sheet legt sich in iOS über die GESAMTE App —
/// beim Wechsel in einen anderen Tab bliebe es sichtbar. Als Overlay
/// innerhalb des Screens gehört es dagegen sauber zu Entdecken.
///
/// Bewusste Vereinfachung: Gezogen wird nur am Griff oben, nicht an der
/// Liste selbst. Beides zu koppeln (Apple-Maps-Verhalten) ist berüchtigt
/// fehleranfällig — man scrollt dann versehentlich das Sheet zu, wenn man
/// eigentlich die Liste bewegen wollte. Am Griff ziehen ist eindeutig.
struct BarberListSheet: View {

    let shops: [Barbershop]

    /// Der aktuell auf der Karte ausgewählte Shop.
    @Binding var selectedShopID: UUID?

    @Binding var detent: SheetDetent

    let onSelectShop: (Barbershop) -> Void
    let onOpenFilter: () -> Void

    /// Schaltet "jetzt sofort verfügbar" um.
    let onToggleAvailableNow: () -> Void

    /// Ist der Sofort-Filter gerade an?
    var isAvailableNowActive = false

    /// Wie viele Filter aktiv sind — für das Zahlenabzeichen am Knopf.
    var activeFilterCount: Int = 0

    @Environment(AppModel.self) private var appModel

    /// Verschiebung während des Ziehens. 0, sobald losgelassen wurde.
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let totalHeight = geometry.size.height
            let targetHeight = detent.height(in: totalHeight)

            // Minus, weil Ziehen nach oben eine negative Verschiebung
            // ergibt, die Liste dabei aber größer werden soll.
            let currentHeight = clamp(
                targetHeight - dragOffset,
                min: SheetDetent.collapsed.height(in: totalHeight),
                max: SheetDetent.expanded.height(in: totalHeight)
            )

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                VStack(spacing: 0) {
                    grabber(totalHeight: totalHeight)
                    list
                }
                .frame(height: currentHeight)
                .background(
                    Color(.systemGroupedBackground),
                    in: UnevenRoundedRectangle(
                        topLeadingRadius: 20,
                        topTrailingRadius: 20
                    )
                )
                .shadow(color: .black.opacity(0.15), radius: 12, y: -2)
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Griff und Kopfzeile

    private func grabber(totalHeight: CGFloat) -> some View {
        VStack(spacing: 10) {
            Capsule()
                .fill(.tertiary)
                .frame(width: 40, height: 5)
                .padding(.top, 8)

            HStack(spacing: 8) {
                Text("\(shops.count) Barber")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                Spacer(minLength: 0)

                availableNowButton
                filterButton
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
        // Der gesamte Kopfbereich ist die Ziehfläche — nicht nur der
        // schmale Strich, den träfe man kaum.
        .contentShape(Rectangle())
        .gesture(dragGesture(totalHeight: totalHeight))
        .onTapGesture {
            // Antippen klappt auf oder zu. Praktisch, wenn man nicht
            // ziehen mag.
            withAnimation(.snappy) {
                detent = detent.toggled
            }
        }
    }

    /// "Sofort" — der Knopf für den spontanen Fall.
    ///
    /// Steht bewusst NEBEN dem Filter und nicht darin: Wer jetzt gerade
    /// einen Haarschnitt braucht, soll mit einem Antippen die Liste auf
    /// das eingrenzen, was in den nächsten zwei Stunden geht. Genau
    /// dafür ist die App da.
    private var availableNowButton: some View {
        Button(action: onToggleAvailableNow) {
            HStack(spacing: 5) {
                Image(systemName: "bolt.fill")
                Text("Sofort")
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(availableNowBackground, in: Capsule())
            .foregroundStyle(availableNowForeground)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Nur sofort verfügbare Termine")
        .accessibilityAddTraits(isAvailableNowActive ? .isSelected : [])
    }

    private var availableNowBackground: Color {
        isAvailableNowActive ? .green : Color(.secondarySystemGroupedBackground)
    }

    private var availableNowForeground: Color {
        isAvailableNowActive ? .white : .primary
    }

    private var filterButton: some View {
        Button(action: onOpenFilter) {
            HStack(spacing: 5) {
                Image(systemName: "slider.horizontal.3")
                Text("Filter")
                if activeFilterCount > 0 {
                    Text("\(activeFilterCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(width: 18, height: 18)
                        .background(Color.accentColor, in: Circle())
                }
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color(.secondarySystemGroupedBackground), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func dragGesture(totalHeight: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation.height
            }
            .onEnded { value in
                let released = detent.height(in: totalHeight) - value.translation.height
                withAnimation(.snappy) {
                    detent = Self.nearestDetent(to: released, in: totalHeight)
                    dragOffset = 0
                }
            }
    }

    /// Sucht die Raststufe, die der losgelassenen Höhe am nächsten liegt.
    static func nearestDetent(to height: CGFloat, in total: CGFloat) -> SheetDetent {
        var best = SheetDetent.collapsed
        var smallestGap = CGFloat.greatestFiniteMagnitude

        for candidate in SheetDetent.allCases {
            let gap = abs(candidate.height(in: total) - height)
            if gap < smallestGap {
                smallestGap = gap
                best = candidate
            }
        }
        return best
    }

    // MARK: - Die Liste

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                if shops.isEmpty {
                    emptyState
                } else {
                    ForEach(shops) { shop in
                        BarberListRow(
                            shop: shop,
                            isHighlighted: selectedShopID == shop.id,
                            onTap: { onSelectShop(shop) }
                        )
                        .id(shop.id)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 90)   // Platz für die Tab-Leiste
        }
        .scrollIndicators(.hidden)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: emptyStateSymbol)
                .font(.title)
                .foregroundStyle(.secondary)
            Text(emptyStateText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
    }

    private var emptyStateSymbol: String {
        isAvailableNowActive ? "bolt.slash" : "magnifyingglass"
    }

    /// Beim Sofort-Filter ist die leere Liste der häufige Fall — abends
    /// oder sonntags ist eben nichts mehr frei. Dann muss dastehen,
    /// woran es liegt, sonst wirkt die App kaputt.
    private var emptyStateText: String {
        isAvailableNowActive
            ? "Gerade ist nirgendwo kurzfristig etwas frei. Schalte „Sofort“ aus, um spätere Termine zu sehen."
            : "Kein Barber passt zu deinen Filtern."
    }

    private func clamp(_ value: CGFloat, min lower: CGFloat, max upper: CGFloat) -> CGFloat {
        Swift.min(Swift.max(value, lower), upper)
    }
}

/// Eine Zeile in der Liste.
///
/// Als eigener Baustein und nicht direkt im `ForEach` — verschachtelte
/// Views mit Bedingungen darin treiben Swifts Typprüfung stark hoch,
/// und die Bauzeit war schon einmal von vier auf über zwanzig Minuten
/// gestiegen. Kleine Bausteine halten sie niedrig und sind nebenbei
/// leichter zu lesen.
private struct BarberListRow: View {

    let shop: Barbershop
    /// Ist dieser Shop gerade auf der Karte ausgewählt?
    let isHighlighted: Bool
    let onTap: () -> Void

    @Environment(AppModel.self) private var appModel

    var body: some View {
        Button(action: onTap) {
            BarberCard(
                shop: shop,
                distanceInMeters: appModel.distance(to: shop),
                nextSlot: appModel.nextSlots[shop.id]
            )
            .overlay {
                // Der auf der Karte gewählte Shop wird auch in der Liste
                // hervorgehoben, damit klar ist, dass beides zusammengehört.
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(borderColor, lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
    }

    /// Durchsichtig statt gar kein Rahmen — so ist es ein einziger
    /// Ausdruck ohne Bedingung im View-Aufbau.
    private var borderColor: Color {
        isHighlighted ? Color.accentColor : Color.clear
    }
}
