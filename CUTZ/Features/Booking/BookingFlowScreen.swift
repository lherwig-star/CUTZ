import SwiftUI

/// Der Buchungsablauf in vier Schritten.
///
/// ─── Zuständig: Lukas ──────────────────────────────────────
///
/// Bewusst kein Assistent mit Zurück/Weiter-Ping-Pong über mehrere
/// Bildschirme, sondern ein Screen, dessen Inhalt wechselt. Unten steht
/// immer genau ein großer Knopf — man muss nie überlegen, was als
/// Nächstes zu tun ist.
///
/// Die Schritte selbst liegen in eigenen Dateien, damit diese hier
/// überschaubar bleibt.
struct BookingFlowScreen: View {

    let shop: Barbershop

    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    /// Das ViewModel wird erst erzeugt, wenn die View erscheint —
    /// deshalb optional. Grund: Es braucht das Repository aus der
    /// Umgebung, das im `init` noch nicht zur Verfügung steht.
    @State private var viewModel: BookingViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    if let booking = viewModel.confirmedBooking {
                        BookingConfirmationView(
                            booking: booking,
                            shop: shop,
                            calendarStatus: viewModel.calendarStatus,
                            onDone: { dismiss() }
                        )
                    } else {
                        flow(viewModel)
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if let viewModel, viewModel.confirmedBooking == nil {
                        toolbarLeading(viewModel)
                    }
                }
            }
        }
        .task {
            if viewModel == nil {
                viewModel = BookingViewModel(shop: shop, repository: appModel.repository)
            }
        }
    }

    // MARK: - Der Ablauf

    /// Rahmen des Ablaufs: Fortschrittspunkte, Überschrift, Inhalt, Knopf.
    ///
    /// Hier wird nur GELESEN — die schreibenden Bindungen (`$`) braucht
    /// allein `stepContent`. Deshalb steht `@Bindable` auch nur dort.
    private func flow(_ viewModel: BookingViewModel) -> some View {
        VStack(spacing: 0) {
            StepIndicator(current: viewModel.step) { target in
                withAnimation(.snappy) { viewModel.jump(to: target) }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 14)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(viewModel.step.title)
                        .font(.title2)
                        .fontWeight(.bold)

                    stepContent(viewModel)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }

            if let error = viewModel.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 6)
            }
        }
        .background(Color(.systemGroupedBackground))
        .safeAreaInset(edge: .bottom) {
            primaryButton(viewModel)
        }
        // Wechselt der Tag, müssen neue Zeiten her.
        .onChange(of: viewModel.selectedDay) {
            Task { await viewModel.loadSlots() }
        }
    }

    /// Der Inhalt des aktuellen Schritts.
    ///
    /// `@Bindable` steht nur HIER einmal, nicht zusätzlich in `flow`.
    /// Zweimal dieselbe Variable so zu überdecken ist zwar erlaubt,
    /// gibt Swifts Typprüfung aber unnötig viel zu tun — und die
    /// Bauzeit war schon einmal aus dem Ruder gelaufen.
    @ViewBuilder
    private func stepContent(_ model: BookingViewModel) -> some View {
        @Bindable var viewModel = model

        switch viewModel.step {
        case .service:
            BookingServiceStep(
                services: shop.services,
                selection: $viewModel.selectedService
            )

        case .employee:
            BookingEmployeeStep(
                employees: shop.employees,
                selection: $viewModel.selectedEmployee
            )

        case .time:
            BookingTimeStep(
                days: viewModel.selectableDays,
                openDays: viewModel.openDays,
                slots: viewModel.availableSlots,
                isLoading: viewModel.isLoadingSlots,
                noSlotsReason: viewModel.noSlotsReason,
                selectedDay: $viewModel.selectedDay,
                selectedSlot: $viewModel.selectedSlot
            )

        case .summary:
            if let service = viewModel.selectedService,
               let slot = viewModel.selectedSlot {
                BookingSummaryStep(
                    shop: shop,
                    service: service,
                    employee: viewModel.selectedEmployee,
                    slot: slot,
                    onEdit: { target in
                        withAnimation(.snappy) { viewModel.jump(to: target) }
                    }
                )
            }
        }
    }

    // MARK: - Bedienelemente

    @ViewBuilder
    private func toolbarLeading(_ viewModel: BookingViewModel) -> some View {
        if viewModel.step == .service {
            Button("Abbrechen") { dismiss() }
        } else {
            Button {
                withAnimation(.snappy) { viewModel.goBack() }
            } label: {
                Label("Zurück", systemImage: "chevron.backward")
            }
        }
    }

    private func primaryButton(_ viewModel: BookingViewModel) -> some View {
        Button {
            Task {
                if viewModel.step == .summary {
                    await viewModel.confirmBooking()
                    // Nach der Buchung sind Zeiten belegt — die Angaben
                    // in der Liste müssen nachgezogen werden.
                    await appModel.refreshNextSlots()
                } else {
                    await viewModel.goForward()
                }
            }
        } label: {
            Group {
                if viewModel.isBooking {
                    ProgressView()
                } else {
                    Text(buttonTitle(viewModel))
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(!viewModel.canGoForward)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.bar)
    }

    /// Der Knopf sagt immer, was als Nächstes passiert — und im letzten
    /// Schritt ausdrücklich, dass jetzt verbindlich gebucht wird.
    private func buttonTitle(_ viewModel: BookingViewModel) -> String {
        switch viewModel.step {
        case .service:
            return viewModel.selectedService == nil
                ? String(localized: "Service wählen")
                : String(localized: "Weiter")
        case .employee:
            return String(localized: "Weiter")
        case .time:
            guard let slot = viewModel.selectedSlot else {
                return String(localized: "Uhrzeit wählen")
            }
            return String(
                format: String(localized: "booking.continueAt"),
                AvailabilityText.timeText(for: slot)
            )
        case .summary:
            guard let price = viewModel.totalPriceText else {
                return String(localized: "Termin buchen")
            }
            return String(format: String(localized: "booking.confirmWithPrice"), price)
        }
    }
}

/// Die vier Punkte oben, die den Fortschritt zeigen.
///
/// Bewusst nur Punkte und keine beschrifteten Reiter: Vier Wörter oben
/// würden mehr Aufmerksamkeit ziehen als der eigentliche Inhalt.
private struct StepIndicator: View {

    let current: BookingViewModel.Step
    let onTapStep: (BookingViewModel.Step) -> Void

    var body: some View {
        HStack(spacing: 6) {
            ForEach(BookingViewModel.Step.allCases, id: \.rawValue) { step in
                Capsule()
                    .fill(color(for: step))
                    .frame(height: 4)
                    .onTapGesture { onTapStep(step) }
            }
        }
        .animation(.snappy, value: current)
    }

    private func color(for step: BookingViewModel.Step) -> Color {
        step.rawValue <= current.rawValue ? .accentColor : Color(.systemGray4)
    }
}

#Preview {
    BookingFlowScreen(shop: MockData.shops[0])
        .environment(AppModel())
}
