import SwiftUI

/// Die Öffnungszeiten je Wochentag.
///
/// ── Warum das der wichtigste Bildschirm im Profil ist ─────
///
/// Alles andere hier ist Kosmetik. Diese Zeiten entscheiden, welche
/// Termine die App überhaupt anbietet. Steht hier "bis 19 Uhr",
/// obwohl der Laden um 18 zumacht, verkauft CUTZ eine Stunde, die es
/// nicht gibt.
struct PartnerOpeningHoursScreen: View {

    @Environment(PartnerModel.self) private var partnerModel

    /// Welcher Tag gerade bearbeitet wird.
    @State private var editingWeekday: WeekdaySelection?

    /// Montag zuerst, so wie man eine Woche liest.
    ///
    /// Apple zählt 1 = Sonntag, deshalb steht die Eins am Ende. Wir
    /// rechnen die Zählung NICHT um — sie muss zur Datenbank und zum
    /// `Calendar` passen, sonst verschiebt sich irgendwann alles um
    /// einen Tag.
    private let displayOrder = [2, 3, 4, 5, 6, 7, 1]

    var body: some View {
        List {
            Section {
                ForEach(displayOrder, id: \.self) { weekday in
                    Button {
                        editingWeekday = WeekdaySelection(id: weekday)
                    } label: {
                        row(weekday)
                    }
                    .buttonStyle(.plain)
                }
            } footer: {
                Text("Ausnahmen wie Urlaub oder ein früherer Feierabend trägst du im Kalender ein.")
            }
        }
        .navigationTitle("Öffnungszeiten")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingWeekday) { selection in
            PartnerOpeningHourEditor(weekday: selection.id)
        }
    }

    private func row(_ weekday: Int) -> some View {
        let hours = partnerModel.shop?.openingHour(forWeekday: weekday)

        return HStack {
            Text(weekdayName(weekday))

            Spacer()

            Text(hours?.rangeFormatted ?? AppText.string("Geschlossen"))
                .foregroundStyle(hours == nil ? .tertiary : .secondary)

            Image(systemName: "chevron.forward")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
    }

    /// Aus `AvailabilityText` und nicht aus `Calendar.weekdaySymbols` —
    /// sonst folgten die Namen der Geräteregion statt dem
    /// Sprachschalter.
    private func weekdayName(_ weekday: Int) -> String {
        let names = AvailabilityText.longWeekdayNames
        let index = weekday - 1
        guard names.indices.contains(index) else { return "" }
        return names[index]
    }
}

/// Welcher Wochentag gerade bearbeitet wird.
///
/// Eigener kleiner Typ, weil `.sheet(item:)` etwas `Identifiable`
/// verlangt und ein blanker `Int` das nicht ist. Man könnte `Int` diese
/// Eigenschaft nachträglich beibringen — das gälte dann aber im ganzen
/// Projekt für jede Zahl. Ein Typ mit einem Feld ist harmloser.
private struct WeekdaySelection: Identifiable {
    let id: Int
}

// MARK: - Bearbeiten

/// Ein Wochentag: offen oder zu, und wenn offen, von wann bis wann.
private struct PartnerOpeningHourEditor: View {

    let weekday: Int

    @Environment(PartnerModel.self) private var partnerModel
    @Environment(\.dismiss) private var dismiss

    @State private var isOpen = true
    @State private var opensAt = Date()
    @State private var closesAt = Date()

    /// Zu vor auf — sonst ergäbe die Zeitspanne keinen Sinn und der
    /// `SlotCalculator` fände nie einen freien Termin.
    private var isValid: Bool { closesAt > opensAt }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Geöffnet", isOn: $isOpen)
                }

                if isOpen {
                    Section {
                        DatePicker("Öffnet", selection: $opensAt, displayedComponents: .hourAndMinute)
                        DatePicker("Schließt", selection: $closesAt, displayedComponents: .hourAndMinute)
                    } footer: {
                        if !isValid {
                            Text("Die Schließzeit muss nach der Öffnungszeit liegen.")
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .navigationTitle(weekdayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        Task { await save() }
                    }
                    .disabled(isOpen && !isValid)
                }
            }
        }
        .onAppear(perform: load)
    }

    private var weekdayName: String {
        let names = AvailabilityText.longWeekdayNames
        let index = weekday - 1
        guard names.indices.contains(index) else { return "" }
        return names[index]
    }

    // MARK: - Umrechnen

    /// Die Öffnungszeiten liegen als Minuten seit Mitternacht vor,
    /// `DatePicker` will einen Zeitpunkt. Umgerechnet wird auf einen
    /// beliebigen Tag — nur die Uhrzeit daran zählt.
    private func load() {
        let midnight = Calendar.current.startOfDay(for: .now)

        guard let hours = partnerModel.shop?.openingHour(forWeekday: weekday) else {
            isOpen = false
            opensAt = midnight.addingTimeInterval(9 * 3600)
            closesAt = midnight.addingTimeInterval(18 * 3600)
            return
        }

        isOpen = true
        opensAt = midnight.addingTimeInterval(TimeInterval(hours.opensAtMinute * 60))
        closesAt = midnight.addingTimeInterval(TimeInterval(hours.closesAtMinute * 60))
    }

    private func minutes(from date: Date) -> Int {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
    }

    private func save() async {
        guard var shop = partnerModel.shop else { return }

        shop.openingHours.removeAll { $0.weekday == weekday }

        if isOpen {
            shop.openingHours.append(
                OpeningHour(
                    weekday: weekday,
                    opensAtMinute: minutes(from: opensAt),
                    closesAtMinute: minutes(from: closesAt)
                )
            )
            shop.openingHours.sort { $0.weekday < $1.weekday }
        }

        await partnerModel.save(shop: shop)
        dismiss()
    }
}
