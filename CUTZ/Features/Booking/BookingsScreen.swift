import SwiftUI

/// Die Übersicht der eigenen Termine (Tab "Termine").
///
/// ─── Zuständig: Lukas ──────────────────────────────────────
///
/// Hinweis für Phase 1: Die Buchungen liegen nur im Arbeitsspeicher
/// (siehe `MockBarbershopRepository`). Nach einem Neustart der App ist
/// die Liste wieder leer. Das ändert sich mit Supabase in Phase 2.
struct BookingsScreen: View {

    @Environment(AppModel.self) private var appModel

    @State private var bookings: [Booking] = []
    @State private var isLoading = false

    /// Welcher Termin soll abgesagt werden? Wird gesetzt, sobald man
    /// "Absagen" wischt — die Rückfrage kommt erst danach.
    @State private var bookingToCancel: Booking?
    @State private var isCancelConfirmationShown = false

    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && bookings.isEmpty {
                    ProgressView()

                } else if bookings.isEmpty {
                    ContentUnavailableView(
                        "Noch keine Termine",
                        systemImage: "calendar",
                        description: Text("Such dir über die Karte oder die Suche einen Barbershop und buche deinen ersten Termin.")
                    )

                } else {
                    list
                }
            }
            .navigationTitle("Meine Termine")
            .task { await load() }
            .refreshable { await load() }

            // Absagen ist nicht rückgängig zu machen — deshalb eine Rückfrage.
            .confirmationDialog(
                "Termin absagen?",
                isPresented: $isCancelConfirmationShown,
                presenting: bookingToCancel
            ) { booking in
                Button("Termin absagen", role: .destructive) {
                    Task { await cancel(booking) }
                }
                Button("Behalten", role: .cancel) {}
            } message: { booking in
                Text("\(booking.serviceName) bei \(booking.shopName)\nam \(booking.startsAtFormatted)")
            }
        }
    }

    private var list: some View {
        List {
            // Fehler stehen direkt in der Liste — so macht es der Rest
            // der App auch, statt ein Fenster aufzuklappen.
            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle")
                    .font(.subheadline)
                    .foregroundStyle(.red)
            }

            // Abgesagte Termine stehen unten für sich — sie sind weder
            // "anstehend" noch einfach nur "vergangen".
            let active = bookings.filter { !$0.isCancelled }
            let upcoming = active.filter(\.isUpcoming)
            let past = active.filter { !$0.isUpcoming }
            let cancelled = bookings.filter(\.isCancelled)

            if !upcoming.isEmpty {
                Section("Anstehend") {
                    ForEach(upcoming) { booking in
                        BookingRow(booking: booking)
                            // Nur anstehende Termine lassen sich absagen —
                            // einen vergangenen abzusagen ergibt keinen Sinn.
                            .swipeActions(edge: .trailing) {
                                Button("Absagen", role: .destructive) {
                                    bookingToCancel = booking
                                    isCancelConfirmationShown = true
                                }
                            }
                    }
                }
            }

            if !past.isEmpty {
                Section("Vergangen") {
                    ForEach(past) { BookingRow(booking: $0) }
                }
            }

            if !cancelled.isEmpty {
                Section("Abgesagt") {
                    ForEach(cancelled) { BookingRow(booking: $0) }
                }
            }
        }
    }

    // MARK: - Aktionen

    private func load() async {
        isLoading = true
        bookings = (try? await appModel.repository.fetchBookings()) ?? []
        isLoading = false
    }

    private func cancel(_ booking: Booking) async {
        errorMessage = nil
        do {
            try await appModel.repository.cancelBooking(booking)
            // Frisch laden statt selbst herumzuschieben: So zeigt die
            // Liste garantiert das, was die Datenquelle wirklich hat.
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
        bookingToCancel = nil
    }
}

private struct BookingRow: View {

    let booking: Booking

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(booking.shopName)
                .font(.headline)
                // Durchgestrichen macht auf einen Blick klar, dass der
                // Termin nicht mehr gilt.
                .strikethrough(booking.isCancelled)

            Text(booking.serviceName)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                Label(booking.startsAtFormatted, systemImage: "clock")

                if booking.isCancelled {
                    Text("· Abgesagt")
                        .fontWeight(.medium)
                        .foregroundStyle(.red)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
        // Vergangene und abgesagte Termine leicht ausgrauen.
        .opacity(booking.isUpcoming && !booking.isCancelled ? 1.0 : 0.55)
    }
}

#Preview {
    BookingsScreen()
        .environment(AppModel())
}
