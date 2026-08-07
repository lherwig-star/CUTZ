import SwiftUI

/// Wie weit die Liste hochgezogen ist.
enum SheetDetent: CaseIterable {

    case collapsed
    case medium
    case expanded

    /// Höhe in Punkten, abhängig von der Bildschirmhöhe.
    func height(in total: CGFloat) -> CGFloat {
        switch self {
        case .collapsed: return 210
        case .medium:    return total * 0.52
        case .expanded:  return total * 0.92
        }
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

            HStack {
                Text("\(shops.count) Barber in der Nähe")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

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
            // Antippen wechselt zwischen klein und mittel. Praktisch,
            // wenn man nicht ziehen mag.
            withAnimation(.snappy) {
                detent = detent == .collapsed ? .medium : .collapsed
            }
        }
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
            Image(systemName: "magnifyingglass")
                .font(.title)
                .foregroundStyle(.secondary)
            Text("Kein Barber passt zu deinen Filtern.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
        .frame(maxWidth: .infinity)
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
