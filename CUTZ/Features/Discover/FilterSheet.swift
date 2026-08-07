import SwiftUI

/// Das Filter-Sheet, das aus der Barber-Liste heraus geöffnet wird.
///
/// Gearbeitet wird auf einer KOPIE der Filter (`draft`). Erst "Anzeigen"
/// übernimmt sie. Sonst würde die Liste im Hintergrund bei jedem Tippen
/// zucken — und ein versehentlich gesetzter Filter ließe sich nur durch
/// erneutes Tippen rückgängig machen.
///
/// ── Warum die Bausteine so schlicht getippt sind ───────────
///
/// Ein erster Entwurf hatte einen generischen Chip-Baustein, dem man
/// `[Double?]` oder `[Int?]` samt Beschriftungs-Funktion übergeben
/// konnte. Das war zwar kürzer, brachte Swifts Typprüfung aber ins
/// Schwitzen: Optionale Werte, Generics, Ternäroperatoren und
/// String-Interpolation zusammen sind für den Compiler richtig teuer.
///
/// Jetzt ist `Chip` ein ganz gewöhnlicher Baustein mit `String` und
/// `Bool`, und jeder Abschnitt schreibt seine Möglichkeiten aus. Etwas
/// länger, dafür sofort verständlich und schnell übersetzt.
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

    // Auswahlmöglichkeiten. Bewusst OHNE Optional — "Egal" ist überall
    // ein eigener Chip und steckt nicht als `nil` mit in der Liste.
    private static let distanceOptions: [Double] = [1, 3, 5, 10]
    private static let priceOptions: [Int] = [20, 30, 40, 60]
    private static let ratingOptions: [Double] = [4.0, 4.5, 4.8]

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
            ChipStrip {
                ForEach(TimingFilter.allCases) { option in
                    Chip(title: option.label, isSelected: draft.timing == option) {
                        draft.timing = option
                    }
                }
            }
        }
    }

    private var serviceSection: some View {
        section("Service") {
            ChipStrip {
                // Mehrfachauswahl: Wer Fade UND Beard sucht, will beides sehen.
                ForEach(ServiceCategory.allCases) { category in
                    Chip(
                        title: category.label,
                        isSelected: draft.categories.contains(category)
                    ) {
                        if draft.categories.contains(category) {
                            draft.categories.remove(category)
                        } else {
                            draft.categories.insert(category)
                        }
                    }
                }
            }
        }
    }

    private var distanceSection: some View {
        section("Entfernung") {
            ChipStrip {
                Chip(title: "Egal", isSelected: draft.maxDistanceKm == nil) {
                    draft.maxDistanceKm = nil
                }
                ForEach(Self.distanceOptions, id: \.self) { km in
                    Chip(
                        title: distanceLabel(km),
                        isSelected: draft.maxDistanceKm == km
                    ) {
                        // Nochmal antippen hebt die Auswahl auf.
                        draft.maxDistanceKm = (draft.maxDistanceKm == km) ? nil : km
                    }
                }
            }
        }
    }

    private var priceSection: some View {
        section("Preis") {
            ChipStrip {
                Chip(title: "Egal", isSelected: draft.maxPriceEuro == nil) {
                    draft.maxPriceEuro = nil
                }
                ForEach(Self.priceOptions, id: \.self) { euro in
                    Chip(
                        title: priceLabel(euro),
                        isSelected: draft.maxPriceEuro == euro
                    ) {
                        draft.maxPriceEuro = (draft.maxPriceEuro == euro) ? nil : euro
                    }
                }
            }
        }
    }

    private var ratingSection: some View {
        section("Bewertung") {
            ChipStrip {
                Chip(title: "Egal", isSelected: draft.minRating == nil) {
                    draft.minRating = nil
                }
                ForEach(Self.ratingOptions, id: \.self) { rating in
                    Chip(
                        title: ratingLabel(rating),
                        isSelected: draft.minRating == rating
                    ) {
                        draft.minRating = (draft.minRating == rating) ? nil : rating
                    }
                }
            }
        }
    }

    private var sortSection: some View {
        section("Sortieren nach") {
            ChipStrip {
                ForEach(BarberSort.allCases) { option in
                    Chip(title: option.label, isSelected: draft.sort == option) {
                        draft.sort = option
                    }
                }
            }
        }
    }

    // MARK: - Beschriftungen
    //
    // Als eigene Funktionen mit klarem Rückgabetyp. In der View selbst
    // zusammengebaut wären es verschachtelte Ausdrücke, die der Compiler
    // erst mühsam auflösen muss.

    private func distanceLabel(_ km: Double) -> String {
        "bis \(Int(km)) km"
    }

    private func priceLabel(_ euro: Int) -> String {
        "bis \(euro) €"
    }

    private func ratingLabel(_ rating: Double) -> String {
        let number = rating.formatted(.number.precision(.fractionLength(1)))
        return "ab \(number) ★"
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
            Text(applyLabel(count))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(count == 0)
        .padding()
        .background(.bar)
    }

    private func applyLabel(_ count: Int) -> String {
        count == 1 ? "1 Barber anzeigen" : "\(count) Barber anzeigen"
    }
}

/// Eine waagerecht scrollbare Reihe von Chips.
///
/// `FlowLayout` gibt es in SwiftUI nicht fertig. Statt selbst eins zu
/// bauen, scrollen wir waagerecht — auf dem iPhone ohnehin die
/// gewohntere Geste und ohne eigene Layout-Rechnerei.
private struct ChipStrip<Content: View>: View {

    @ViewBuilder let content: Content

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                content
            }
            .padding(.horizontal, 1)   // damit der Rand nicht abgeschnitten wirkt
        }
    }
}

/// Ein einzelner auswählbarer Chip.
private struct Chip: View {

    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button {
            withAnimation(.snappy(duration: 0.2)) { onTap() }
        } label: {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(background, in: Capsule())
                .foregroundStyle(foreground)
        }
        .buttonStyle(.plain)
    }

    private var background: Color {
        isSelected ? Color.accentColor : Color(.secondarySystemBackground)
    }

    private var foreground: Color {
        isSelected ? Color.white : Color.primary
    }
}

#Preview {
    FilterSheet(
        filter: .constant(.none),
        resultCount: { _ in 4 }
    )
}
