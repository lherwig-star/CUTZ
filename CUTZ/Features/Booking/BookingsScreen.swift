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
        }
    }

    private var list: some View {
        List {
            let upcoming = bookings.filter(\.isUpcoming)
            let past = bookings.filter { !$0.isUpcoming }

            if !upcoming.isEmpty {
                Section("Anstehend") {
                    ForEach(upcoming) { BookingRow(booking: $0) }
                }
            }

            if !past.isEmpty {
                Section("Vergangen") {
                    ForEach(past) { BookingRow(booking: $0) }
                }
            }
        }
    }

    private func load() async {
        isLoading = true
        bookings = (try? await appModel.repository.fetchBookings()) ?? []
        isLoading = false
    }
}

private struct BookingRow: View {

    let booking: Booking

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(booking.shopName)
                .font(.headline)
            Text(booking.serviceName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Label(booking.startsAtFormatted, systemImage: "clock")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
        // Vergangene Termine leicht ausgrauen.
        .opacity(booking.isUpcoming ? 1.0 : 0.55)
    }
}

#Preview {
    BookingsScreen()
        .environment(AppModel())
}
