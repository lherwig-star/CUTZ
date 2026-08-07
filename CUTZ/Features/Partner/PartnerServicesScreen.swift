import SwiftUI

/// Die Leistungen des Ladens: anlegen, ändern, umsortieren, löschen.
///
/// ── Warum die Reihenfolge zählt ───────────────────────────
///
/// Sie ist keine Spielerei. Im Buchungsablauf der Kundenseite ist die
/// Leistungsauswahl der erste Schritt, und die Liste steht dort in
/// genau dieser Reihenfolge. Was oben steht, wird am häufigsten
/// gebucht — das weiß der Friseur besser als wir.
struct PartnerServicesScreen: View {

    @Environment(PartnerModel.self) private var partnerModel

    @State private var editing: BarberService?
    @State private var isAdding = false

    private var services: [BarberService] {
        partnerModel.shop?.services ?? []
    }

    var body: some View {
        List {
            if services.isEmpty {
                ContentUnavailableView {
                    Label("Noch keine Leistungen", systemImage: "scissors")
                } description: {
                    Text("Ohne mindestens eine Leistung kann niemand bei dir buchen.")
                }
                .listRowBackground(Color.clear)
            } else {
                Section {
                    ForEach(services) { service in
                        Button {
                            editing = service
                        } label: {
                            row(service)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: delete)
                    .onMove(perform: move)
                } footer: {
                    Text("Halte eine Zeile gedrückt, um sie zu verschieben. Ganz oben steht, was am häufigsten gebucht wird.")
                }
            }

            Section {
                Button {
                    isAdding = true
                } label: {
                    Label("Neuen Service hinzufügen", systemImage: "plus")
                }
            }
        }
        .environment(\.editMode, .constant(.active))
        .navigationTitle("Services verwalten")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isAdding = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(item: $editing) { service in
            PartnerServiceEditor(service: service)
        }
        .sheet(isPresented: $isAdding) {
            PartnerServiceEditor(service: nil)
        }
    }

    private func row(_ service: BarberService) -> some View {
        HStack(spacing: 12) {
            Image(systemName: service.category.symbolName)
                .font(.subheadline)
                .frame(width: 38, height: 38)
                .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                Text(service.name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)

                Label {
                    Text(service.durationFormatted)
                } icon: {
                    Image(systemName: "clock")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Text(service.priceShort)
                .font(.subheadline.weight(.semibold))
        }
    }

    // MARK: - Ändern

    private func delete(at offsets: IndexSet) {
        guard var shop = partnerModel.shop else { return }
        shop.services.remove(atOffsets: offsets)
        Task { await partnerModel.save(shop: shop) }
    }

    private func move(from source: IndexSet, to destination: Int) {
        guard var shop = partnerModel.shop else { return }
        shop.services.move(fromOffsets: source, toOffset: destination)
        Task { await partnerModel.save(shop: shop) }
    }
}

// MARK: - Anlegen und ändern

/// Eine Leistung bearbeiten — oder eine neue anlegen, wenn `service`
/// leer ist.
///
/// Ein Bildschirm für beides, weil die Felder identisch sind. Zwei
/// getrennte wären zwei Stellen, an denen dieselbe Prüfung stehen
/// müsste.
private struct PartnerServiceEditor: View {

    /// `nil` heißt: neu anlegen.
    let service: BarberService?

    @Environment(PartnerModel.self) private var partnerModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category: ServiceCategory = .haircut
    @State private var durationMinutes = 30
    @State private var priceEuros = 25

    private var isNew: Bool { service == nil }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && durationMinutes > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("z. B. Herrenhaarschnitt", text: $name)
                }

                Section("Art") {
                    Picker("Art", selection: $category) {
                        ForEach(ServiceCategory.allCases) { item in
                            Label(item.label, systemImage: item.symbolName).tag(item)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section {
                    // In Fünf-Minuten-Schritten. Kein freies Textfeld:
                    // Der `SlotCalculator` rechnet in Viertelstunden,
                    // und "37 Minuten" hilft dabei niemandem.
                    Stepper(value: $durationMinutes, in: 5...240, step: 5) {
                        LabeledContent("Dauer", value: durationFormatted)
                    }

                    Stepper(value: $priceEuros, in: 0...500) {
                        LabeledContent("Preis", value: priceFormatted)
                    }
                } footer: {
                    Text("Die Dauer bestimmt, wie viel Zeit im Kalender blockiert wird.")
                }
            }
            .navigationTitle(isNew ? "Neue Leistung" : "Leistung bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        Task { await save() }
                    }
                    .disabled(!canSave)
                }
            }
        }
        .onAppear(perform: load)
    }

    /// Preis als ganze Euro. Gespeichert wird in Cent — die Umrechnung
    /// passiert erst beim Speichern, damit die Konvention aus
    /// CLAUDE.md gilt: Geld ist immer `Int` in Cent.
    private var priceFormatted: String {
        AppText.format("price.short", priceEuros)
    }

    private var durationFormatted: String {
        AppText.format("duration.minutes", durationMinutes)
    }

    private func load() {
        guard let service else { return }
        name = service.name
        category = service.category
        durationMinutes = service.durationMinutes
        priceEuros = service.priceCents / 100
    }

    private func save() async {
        guard var shop = partnerModel.shop else { return }

        let updated = BarberService(
            id: service?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            durationMinutes: durationMinutes,
            priceCents: priceEuros * 100,
            category: category
        )

        if let index = shop.services.firstIndex(where: { $0.id == updated.id }) {
            shop.services[index] = updated
        } else {
            shop.services.append(updated)
        }

        await partnerModel.save(shop: shop)
        dismiss()
    }
}
