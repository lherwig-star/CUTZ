import SwiftUI

/// Die Suche, die sich über den Entdecken-Screen legt.
///
/// Gesucht wird derzeit in Name, Beschreibung, Straße, Stadt und
/// Postleitzahl. Die eigentliche Vergleichslogik liegt in `BarberSearch`
/// — dadurch lässt sie sich später um Leistungen oder Barbernamen
/// erweitern, ohne diese View anzufassen.
struct SearchScreen: View {

    /// Wird aufgerufen, wenn ein Ergebnis angetippt wurde.
    let onSelectShop: (Barbershop) -> Void

    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""

    /// Sorgt dafür, dass die Tastatur beim Öffnen sofort da ist.
    /// Wer die Suche antippt, will tippen — nicht erst nochmal zielen.
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchField

                if query.isEmpty {
                    hint
                } else if results.isEmpty {
                    noResults
                } else {
                    resultList
                }
            }
            .navigationTitle("Suche")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
        .onAppear { isFieldFocused = true }
    }

    // MARK: - Bestandteile

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Barber oder Ort suchen", text: $query)
                .focused($isFieldFocused)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.search)

            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Eingabe löschen")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Color(.secondarySystemBackground), in: Capsule())
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var resultList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(results) { shop in
                    Button {
                        onSelectShop(shop)
                    } label: {
                        BarberCard(
                            shop: shop,
                            distanceInMeters: appModel.distance(to: shop),
                            nextSlot: appModel.nextSlots[shop.id]
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.immediately)
    }

    private var hint: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text("Suche nach einem Barber, Salon oder Ort.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 80)
    }

    private var noResults: some View {
        ContentUnavailableView.search(text: query)
    }

    private var results: [Barbershop] {
        BarberSearch.match(query: query, in: appModel.shops)
    }
}

#Preview {
    SearchScreen(onSelectShop: { _ in })
        .environment(AppModel())
}
