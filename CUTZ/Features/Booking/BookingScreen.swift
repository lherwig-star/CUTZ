import SwiftUI

/// Der Buchungsablauf: Leistung wählen → Tag wählen → Uhrzeit wählen → buchen.
///
/// ─── Zuständig: Lukas ──────────────────────────────────────
struct BookingScreen: View {

    let shop: Barbershop

    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    /// Das ViewModel wird erst erzeugt, wenn die View erscheint —
    /// deshalb ist es optional und wird in `.task` gesetzt. Grund:
    /// Es braucht das Repository aus der Umgebung, das im `init`
    /// noch nicht zur Verfügung steht.
    @State private var viewModel: BookingViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    if let booking = viewModel.confirmedBooking {
                        BookingConfirmationView(
                            booking: booking,
                            calendarStatus: viewModel.calendarStatus,
                            onDone: { dismiss() }
                        )
                    } else {
                        bookingForm(viewModel)
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Termin buchen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
        .task {
            // Nur beim ersten Erscheinen erzeugen, nicht bei jedem Neuzeichnen.
            if viewModel == nil {
                let model = BookingViewModel(shop: shop, repository: appModel.repository)
                viewModel = model
                await model.loadSlots()
            }
        }
    }

    // MARK: - Das Formular

    @ViewBuilder
    private func bookingForm(_ viewModel: BookingViewModel) -> some View {
        // `@Bindable` erlaubt es, mit `$` an Werte einer `@Observable`-Klasse
        // zu binden — also z. B. den Picker direkt schreiben zu lassen.
        @Bindable var viewModel = viewModel

        Form {
            Section("Leistung") {
                Picker("Leistung", selection: $viewModel.selectedService) {
                    ForEach(shop.services) { service in
                        VStack(alignment: .leading) {
                            Text(service.name)
                            Text("\(service.durationFormatted) · \(service.priceFormatted)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        // Der Typ muss exakt zur Auswahl passen —
                        // `selectedService` ist optional, also auch der Tag.
                        .tag(Optional(service))
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }

            Section("Tag") {
                DayPicker(
                    days: viewModel.selectableDays,
                    selection: $viewModel.selectedDay
                )
            }

            Section("Uhrzeit") {
                slotGrid(viewModel)
            }

            if let errorMessage = viewModel.errorMessage {
                Section {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
            }
        }
        // Sobald Leistung oder Tag wechseln, neue Zeiten laden.
        .onChange(of: viewModel.selectedService) {
            Task { await viewModel.loadSlots() }
        }
        .onChange(of: viewModel.selectedDay) {
            Task { await viewModel.loadSlots() }
        }
        .safeAreaInset(edge: .bottom) {
            confirmButton(viewModel)
        }
    }

    @ViewBuilder
    private func slotGrid(_ viewModel: BookingViewModel) -> some View {
        if viewModel.isLoadingSlots {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)

        } else if viewModel.availableSlots.isEmpty {
            Text("An diesem Tag sind keine Termine mehr frei.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.vertical, 4)

        } else {
            // Ein Raster, das sich automatisch an die Bildschirmbreite anpasst.
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 76), spacing: 8)],
                spacing: 8
            ) {
                ForEach(viewModel.availableSlots, id: \.self) { slot in
                    let isSelected = viewModel.selectedSlot == slot

                    Button {
                        viewModel.selectedSlot = slot
                    } label: {
                        Text(slot.formatted(date: .omitted, time: .shortened))
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                isSelected ? Color.accentColor : Color(.secondarySystemBackground),
                                in: RoundedRectangle(cornerRadius: 8)
                            )
                            .foregroundStyle(isSelected ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func confirmButton(_ viewModel: BookingViewModel) -> some View {
        Button {
            Task { await viewModel.confirmBooking() }
        } label: {
            if viewModel.isBooking {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                Text(confirmButtonTitle(viewModel))
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(!viewModel.canConfirm)
        .padding()
        .background(.bar)
    }

    private func confirmButtonTitle(_ viewModel: BookingViewModel) -> String {
        guard let slot = viewModel.selectedSlot else {
            return "Zeit auswählen"
        }
        return "Für \(slot.formatted(date: .omitted, time: .shortened)) buchen"
    }
}

/// Waagerechte Leiste zur Tagesauswahl.
private struct DayPicker: View {

    let days: [Date]
    @Binding var selection: Date

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(days, id: \.self) { day in
                    let isSelected = Calendar.current.isDate(day, inSameDayAs: selection)

                    Button {
                        selection = day
                    } label: {
                        VStack(spacing: 2) {
                            Text(day.formatted(.dateTime.weekday(.abbreviated)))
                                .font(.caption2)
                            Text(day.formatted(.dateTime.day()))
                                .font(.headline)
                        }
                        .frame(width: 46, height: 54)
                        .background(
                            isSelected ? Color.accentColor : Color(.secondarySystemBackground),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                        .foregroundStyle(isSelected ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    BookingScreen(shop: MockData.shops[0])
        .environment(AppModel())
}
