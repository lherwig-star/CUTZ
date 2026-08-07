import SwiftUI

/// Zeit sperren: Mittagspause, früherer Feierabend, Urlaub.
///
/// ── Warum es diesen Bildschirm überhaupt gibt ─────────────
///
/// Ohne ihn lügt der Kalender. Der Friseur macht Mittwoch früher zu,
/// die App verkauft trotzdem einen Termin um 17:00, und der Kunde
/// steht vor verschlossener Tür. Das passiert genau einmal — danach
/// ist er weg.
///
/// Die Öffnungszeiten im Profil taugen dafür nicht: Die beschreiben
/// den Regelfall. Für einen einzelnen Tag müsste man sie umschreiben
/// und danach wieder zurück.
struct PartnerTimeBlockEditor: View {

    /// Der Tag, auf dem der Kalender gerade steht.
    let day: Date

    @Environment(PartnerModel.self) private var partnerModel
    @Environment(\.dismiss) private var dismiss

    @State private var reason: TimeBlock.Reason = .pause
    @State private var startsAt = Date()
    @State private var endsAt = Date()

    /// Urlaub geht über ganze Tage, eine Pause über Stunden. Bei
    /// mehreren Tagen wären zwei Uhrzeiten unsinnig.
    @State private var lastsAllDay = false

    @State private var note = ""

    private var isValid: Bool { endsAt > startsAt }

    var body: some View {
        NavigationStack {
            Form {
                Section("Grund") {
                    Picker("Grund", selection: $reason) {
                        ForEach(TimeBlock.Reason.allCases) { item in
                            Text(item.label).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                Section {
                    Toggle("Ganzer Tag", isOn: $lastsAllDay)

                    if lastsAllDay {
                        DatePicker("Von", selection: $startsAt, displayedComponents: .date)
                        DatePicker("Bis", selection: $endsAt, displayedComponents: .date)
                    } else {
                        DatePicker("Beginn", selection: $startsAt,
                                   displayedComponents: [.date, .hourAndMinute])
                        DatePicker("Ende", selection: $endsAt,
                                   displayedComponents: [.date, .hourAndMinute])
                    }
                } footer: {
                    if !isValid {
                        Text("Das Ende muss nach dem Beginn liegen.")
                            .foregroundStyle(.red)
                    } else {
                        Text("In dieser Zeit bietet CUTZ deinen Kunden keine Termine an.")
                    }
                }

                Section("Notiz") {
                    TextField("Optional, z. B. Fortbildung", text: $note)
                }
            }
            .navigationTitle("Zeit sperren")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sperren") {
                        Task { await save() }
                    }
                    .disabled(!isValid)
                }
            }
        }
        .onAppear(perform: setDefaults)
    }

    /// Vorbelegt mit einer Mittagspause an dem Tag, den man gerade
    /// ansieht. Das ist der häufigste Fall — und wer etwas anderes
    /// will, ändert zwei Felder statt vier.
    private func setDefaults() {
        let midnight = Calendar.current.startOfDay(for: day)
        startsAt = midnight.addingTimeInterval(12 * 3600)
        endsAt = midnight.addingTimeInterval(13 * 3600)
    }

    private func save() async {
        guard let shopID = partnerModel.shop?.id else { return }

        // Bei "ganzer Tag" von Mitternacht bis Mitternacht des
        // Folgetages — sonst bliebe der letzte Abend offen.
        let calendar = Calendar.current
        let from = lastsAllDay ? calendar.startOfDay(for: startsAt) : startsAt
        let to: Date = {
            guard lastsAllDay else { return endsAt }
            let endOfDay = calendar.startOfDay(for: endsAt)
            return calendar.date(byAdding: .day, value: 1, to: endOfDay) ?? endsAt
        }()

        await partnerModel.addTimeBlock(
            TimeBlock(
                shopID: shopID,
                startsAt: from,
                endsAt: to,
                reason: reason,
                note: note.trimmingCharacters(in: .whitespaces)
            )
        )

        dismiss()
    }
}
