import SwiftUI

/// Das Filter-Sheet, das aus der Barber-Liste heraus geöffnet wird.
///
/// Gearbeitet wird auf einer KOPIE der Filter (`draft`). Erst "Anzeigen"
/// übernimmt sie. Sonst würde die Liste im Hintergrund bei jedem Tippen
/// zucken — und ein versehentlich gesetzter Filter ließe sich nur durch
/// erneutes Tippen rückgängig machen.
struct FilterSheet: View {

    /// Die echten Filter. Werden erst beim Bestätigen überschrieben.
    @Binding var filter: BarberFilter

    /// Wie viele Shops mit den aktuellen Einstellungen übrig blieben —
    /// wird von außen berechnet, damit hier keine Datenlogik liegt.
    let resultCount: (BarberFilter) -> Int

    @Environment(\.dismiss) private var dismiss

    @State private var draft: BarberFilter

    init(filter: Binding<BarberFilter>, resultCount: @escaping (BarberFilter) -> Int) {
        self._filter = filter
        self.resultCount = resultCount
        self._draft = State(initialValue: filter.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    timingSection
                    serviceSection
                    distanceSection
                    priceSection
                    ratingSection
                    sortSection
                }
                .padding(20)
                .padding(.bottom, 80)
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Zurücksetzen") {
                        withAnimation(.snappy) { draft = .none }
                    }
                    .disabled(draft.activeCount == 0)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Abbrechen") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                applyButton
            }
        }
    }

    // MARK: - Abschnitte

    private var timingSection: some View {
        section("Wann?") {
            ChipRow(items: TimingFilter.allCases, isSelected: { $0 == draft.timing }) { option in
                draft.timing = option
            } label: { $0.label }
        }
    }

    private var serviceSection: some View {
        section("Service") {
            // Mehrfachauswahl: Wer Fade UND Beard sucht, will beides sehen.
            ChipRow(
                items: ServiceCategory.allCases,
                isSelected: { draft.categories.contains($0) }
            ) { category in
                if draft.categories.contains(category) {
                    draft.categories.remove(category)
                } else {
                    draft.categories.insert(category)
                }
            } label: { $0.label }
        }
    }

    private var distanceSection: some View {
        section("Entfernung") {
            ChipRow(
                items: Self.distanceOptions,
                isSelected: { draft.maxDistanceKm == $0 }
            ) { option in
                // Nochmal antippen hebt die Auswahl auf.
                draft.maxDistanceKm = (draft.maxDistanceKm == option) ? nil : option
            } label: { option in
                option == nil ? "Egal" : "bis \(Self.kmText(option))"
            }
        }
    }

    private var priceSection: some View {
        section("Preis") {
            ChipRow(
                items: Self.priceOptions,
                isSelected: { draft.maxPriceEuro == $0 }
            ) { option in
                draft.maxPriceEuro = (draft.maxPriceEuro == option) ? nil : option
            } label: { option in
                option == nil ? "Egal" : "bis \(option!) €"
            }
        }
    }

    private var ratingSection: some View {
        section("Bewertung") {
            ChipRow(
                items: Self.ratingOptions,
                isSelected: { draft.minRating == $0 }
            ) { option in
                draft.minRating = (draft.minRating == option) ? nil : option
            } label: { option in
                guard let option else { return "Egal" }
                return "ab \(option.formatted(.number.precision(.fractionLength(1)))) ★"
            }
        }
    }

    private var sortSection: some View {
        section("Sortieren nach") {
            ChipRow(items: BarberSort.allCases, isSelected: { $0 == draft.sort }) { option in
                draft.sort = option
            } label: { $0.label }
        }
    }

    // MARK: - Bausteine

    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content()
        }
    }

    private var applyButton: some View {
        let count = resultCount(draft)

        return Button {
            filter = draft
            dismiss()
        } label: {
            // Die Zahl im Knopf ist der eigentliche Trick: Man sieht schon
            // VOR dem Bestätigen, ob die Auswahl noch etwas übrig lässt.
            Text(count == 1 ? "1 Barber anzeigen" : "\(count) Barber anzeigen")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(count == 0)
        .padding()
        .background(.bar)
    }

    // MARK: - Auswahlmöglichkeiten

    // Optional, damit "Egal" als erster Eintrag mit in derselben Reihe steht.
    static let distanceOptions: [Double?] = [nil, 1, 3, 5, 10]
    static let priceOptions: [Int?] = [nil, 20, 30, 40, 60]
    static let ratingOptions: [Double?] = [nil, 4.0, 4.5, 4.8]

    static func kmText(_ km: Double?) -> String {
        guard let km else { return "" }
        return km < 1
            ? "\(Int(km * 1000)) m"
            : "\(km.formatted(.number.precision(.fractionLength(0)))) km"
    }
}

/// Eine Reihe auswählbarer Chips, die bei Bedarf umbricht.
///
/// Eigener Baustein, weil im Filter sechs davon vorkommen. Ohne ihn
/// wäre die Datei dreimal so lang und dreimal so leicht zu verhauen.
private struct ChipRow<Item: Hashable>: View {

    let items: [Item]
    let isSelected: (Item) -> Bool
    let onTap: (Item) -> Void
    let label: (Item) -> String

    var body: some View {
        // `FlowLayout` gibt es in SwiftUI nicht fertig. Statt selbst eins
        // zu bauen, nehmen wir waagerechtes Scrollen — das ist auf dem
        // iPhone ohnehin die gewohntere Geste und kommt ohne eigene
        // Layout-Rechnerei aus.
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items, id: \.self) { item in
                    let selected = isSelected(item)

                    Button {
                        withAnimation(.snappy(duration: 0.2)) { onTap(item) }
                    } label: {
                        Text(label(item))
                            .font(.subheadline)
                            .fontWeight(selected ? .semibold : .regular)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(
                                selected ? Color.accentColor : Color(.secondarySystemBackground),
                                in: Capsule()
                            )
                            .foregroundStyle(selected ? Color.white : Color.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 1)   // damit der Rand nicht abgeschnitten wirkt
        }
    }
}

#Preview {
    FilterSheet(
        filter: .constant(.none),
        resultCount: { _ in 4 }
    )
}
