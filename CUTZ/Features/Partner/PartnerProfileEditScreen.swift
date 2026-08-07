import SwiftUI

/// Die Stammdaten des Ladens ändern: Name, Adresse, Beschreibung.
///
/// ── Warum an einem Entwurf gearbeitet wird ────────────────
///
/// Die Eingaben landen erst beim Tippen auf "Speichern" im Laden, nicht
/// bei jedem Buchstaben. Wer mitten im Umbenennen die Meinung ändert
/// und zurückgeht, hat nichts kaputtgemacht.
///
/// Dasselbe Vorgehen wie im Filterblatt der Kundenseite.
struct PartnerProfileEditScreen: View {

    @Environment(PartnerModel.self) private var partnerModel
    @Environment(\.dismiss) private var dismiss

    /// Der Entwurf. Wird beim Erscheinen aus dem Laden gefüllt.
    @State private var draft: Barbershop?
    @State private var isSaving = false

    /// So lang darf die Beschreibung werden.
    ///
    /// Nicht willkürlich: Auf der Kundenseite steht sie unter dem
    /// Ladennamen und wird bei drei Zeilen abgeschnitten. Wer mehr
    /// schreibt, schreibt für den Papierkorb — also lieber vorher
    /// sagen.
    private let descriptionLimit = 200

    var body: some View {
        Group {
            if let draft {
                form(draft)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Profil bearbeiten")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Speichern") {
                    Task { await save() }
                }
                .disabled(!canSave || isSaving)
                .fontWeight(.semibold)
            }
        }
        .onAppear { draft = partnerModel.shop }
    }

    private var canSave: Bool {
        guard let draft else { return false }
        return !draft.name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Formular

    private func form(_ shop: Barbershop) -> some View {
        // `@Bindable` geht hier nicht: `draft` ist ein einfacher Wert,
        // keine beobachtete Klasse. Deshalb von Hand eine Bindung
        // bauen — `$draft` liefert `Binding<Barbershop?>`, und mit
        // `Binding(get:set:)` machen wir daraus eine auf die einzelne
        // Eigenschaft.
        let binding = Binding(
            get: { draft ?? shop },
            set: { draft = $0 }
        )

        return Form {
            logoSection(shop)

            Section("Name des Salons") {
                TextField("Name des Salons", text: binding.name)
                    .labelsHidden()
            }

            Section("Adresse") {
                TextField("Straße und Hausnummer", text: binding.street)
                TextField("PLZ", text: binding.postalCode)
                    .keyboardType(.numberPad)
                TextField("Stadt", text: binding.city)
            }

            descriptionSection(binding)

            Section("Kontakt") {
                TextField("Telefon", text: Binding(
                    get: { binding.wrappedValue.phone ?? "" },
                    set: { binding.wrappedValue.phone = $0.isEmpty ? nil : $0 }
                ))
                .keyboardType(.phonePad)
            }

            imagesSection
        }
    }

    private func logoSection(_ shop: Barbershop) -> some View {
        Section {
            HStack {
                Spacer()
                ShopImage(seed: shop.id.uuidString, url: shop.imageURL, symbolSize: 28)
                    .frame(width: 88, height: 88)
                    .clipShape(Circle())
                Spacer()
            }
            .padding(.vertical, 6)
            .listRowBackground(Color.clear)
        }
    }

    private func descriptionSection(_ binding: Binding<Barbershop>) -> some View {
        Section {
            TextField(
                "Was macht deinen Laden aus?",
                text: binding.description,
                axis: .vertical
            )
            .lineLimit(3...6)
            .onChange(of: binding.wrappedValue.description) { _, new in
                // Abschneiden statt die Eingabe zu blockieren: Wer aus
                // Versehen einen langen Text einfügt, soll sehen, was
                // davon ankommt.
                if new.count > descriptionLimit {
                    binding.wrappedValue.description = String(new.prefix(descriptionLimit))
                }
            }
        } header: {
            Text("Beschreibung")
        } footer: {
            HStack {
                Text("Steht auf der Kundenseite unter deinem Namen.")
                Spacer()
                Text(AppText.format(
                    "profile.characterCount",
                    binding.wrappedValue.description.count,
                    descriptionLimit
                ))
                .monospacedDigit()
            }
        }
    }

    private var imagesSection: some View {
        Section {
            // Ehrlich statt eines Knopfs, der nichts tut: Ein Bild
            // hochzuladen braucht einen Speicherort, und den gibt es
            // erst mit Supabase Storage (Phase 5, siehe PLAN.md).
            ContentUnavailableView {
                Label("Noch keine Bilder", systemImage: "photo.on.rectangle")
            } description: {
                Text("Fotos hochladen geht, sobald der Bildspeicher steht.")
            }
            .frame(height: 150)
            .listRowBackground(Color.clear)
        } header: {
            Text("Bilder")
        }
    }

    // MARK: - Speichern

    private func save() async {
        guard var updated = draft else { return }
        isSaving = true

        updated.name = updated.name.trimmingCharacters(in: .whitespaces)
        await partnerModel.save(shop: updated)

        isSaving = false
        dismiss()
    }
}
