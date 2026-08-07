import SwiftUI

/// Laufkundschaft eintragen: Jemand steht im Laden und bekommt jetzt
/// einen Platz.
///
/// ── Warum das kein Nebenfeature ist ───────────────────────
///
/// Fast jeder Barbershop nimmt Leute ohne Termin. Weiß die App nicht,
/// dass gerade jemand auf dem Stuhl sitzt, verkauft sie denselben
/// Platz an einen App-Kunden. Der steht dann um 14:00 im Laden und
/// wird weggeschickt — und genau in diesem Moment fliegt die App vom
/// Telefon des Friseurs.
///
/// Deshalb hängt der Knopf dazu direkt in der freien Lücke und nicht
/// in einem Menü: Jemand wartet, das muss mit einem Griff gehen.
struct PartnerWalkInSheet: View {

    /// Die Lücke, in die eingetragen wird.
    let slot: DayEntry

    @Environment(PartnerModel.self) private var partnerModel
    @Environment(\.dismiss) private var dismiss

    @State private var customerName = ""
    @State private var serviceID: UUID?
    @State private var employeeID: UUID?
    @State private var isSaving = false

    /// Nur Leistungen, die in die Lücke passen.
    ///
    /// Eine 45-Minuten-Leistung in eine halbe Stunde zu quetschen
    /// hieße, den nächsten Termin zu überfahren. Lieber gar nicht erst
    /// anbieten, als hinterher zwei Kunden gleichzeitig dasitzen zu
    /// haben.
    private var fittingServices: [BarberService] {
        (partnerModel.shop?.services ?? [])
            .filter { $0.durationMinutes <= slot.durationMinutes }
    }

    private var selectedService: BarberService? {
        fittingServices.first { $0.id == serviceID }
    }

    private var canSave: Bool {
        selectedService != nil
            && !customerName.trimmingCharacters(in: .whitespaces).isEmpty
            && !isSaving
    }

    var body: some View {
        NavigationStack {
            Group {
                if fittingServices.isEmpty {
                    ContentUnavailableView(
                        "Zu wenig Zeit",
                        systemImage: "clock.badge.exclamationmark",
                        description: Text("In diese Lücke passt keine deiner Leistungen.")
                    )
                } else {
                    form
                }
            }
            .navigationTitle("Termin eintragen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Eintragen") {
                        Task { await save() }
                    }
                    .disabled(!canSave)
                }
            }
        }
        .onAppear {
            // Die kürzeste passende Leistung ist die wahrscheinlichste
            // Wahl bei Laufkundschaft — und sie lässt am meisten Rest.
            serviceID = fittingServices.min { $0.durationMinutes < $1.durationMinutes }?.id
        }
    }

    private var form: some View {
        Form {
            Section("Wer kommt?") {
                TextField("Name", text: $customerName)
                    .textContentType(.givenName)
            }

            Section("Leistung") {
                Picker("Leistung", selection: $serviceID) {
                    ForEach(fittingServices) { service in
                        // Zusammengesetzt und NICHT als `Text("...")`
                        // mit Platzhaltern: Beide Teile sind schon
                        // fertig — der Name ist Ladendaten, die Dauer
                        // kommt aus `AppText`. Ein Übersetzungsschlüssel
                        // "%@ · %@" brächte hier nichts.
                        Text(service.name + " · " + service.durationFormatted)
                            .tag(Optional(service.id))
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }

            if let employees = partnerModel.shop?.employees, !employees.isEmpty {
                Section("Wer schneidet?") {
                    Picker("Barber", selection: $employeeID) {
                        Text("Egal").tag(UUID?.none)
                        ForEach(employees) { employee in
                            Text(employee.name).tag(Optional(employee.id))
                        }
                    }
                    .pickerStyle(.menu)
                }
            }

            Section {
                LabeledContent {
                    Text(AvailabilityText.timeText(for: slot.startsAt))
                        .foregroundStyle(.secondary)
                } label: {
                    Text("Beginn")
                }
            } footer: {
                Text("Die freie Lücke geht bis \(AvailabilityText.timeText(for: slot.endsAt)).")
            }
        }
    }

    private func save() async {
        guard let service = selectedService else { return }
        isSaving = true

        let employee = partnerModel.shop?.employees.first { $0.id == employeeID }

        await partnerModel.addWalkIn(
            service: service,
            employee: employee,
            customerName: customerName.trimmingCharacters(in: .whitespaces),
            startsAt: slot.startsAt
        )

        isSaving = false
        dismiss()
    }
}
