import SwiftUI

/// Die Bestätigung nach erfolgreicher Buchung.
///
/// ─── Zuständig: Lukas ──────────────────────────────────────
struct BookingConfirmationView: View {

    let booking: Booking
    let calendarStatus: BookingViewModel.CalendarStatus
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 68))
                .foregroundStyle(.green)

            VStack(spacing: 8) {
                Text("Termin gebucht")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(booking.shopName)
                    .font(.headline)

                Text(booking.serviceName)
                    .foregroundStyle(.secondary)

                Text(booking.startsAtFormatted)
                    .font(.title3)
                    .fontWeight(.medium)
                    .padding(.top, 4)

                Text(booking.shopAddress)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)

            calendarHint

            Spacer()

            Button(action: onDone) {
                Text("Fertig")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }

    /// Rückmeldung zum Kalendereintrag.
    @ViewBuilder
    private var calendarHint: some View {
        switch calendarStatus {
        case .added:
            Label("In deinen Kalender eingetragen", systemImage: "calendar.badge.checkmark")
                .font(.subheadline)
                .foregroundStyle(.secondary)

        case .failed(let reason):
            // Die Buchung selbst hat geklappt — nur der Kalendereintrag nicht.
            // Das muss klar rüberkommen, damit niemand denkt, der Termin sei weg.
            VStack(spacing: 4) {
                Label("Nicht im Kalender gespeichert", systemImage: "calendar.badge.exclamationmark")
                    .font(.subheadline)
                    .foregroundStyle(.orange)
                Text(reason)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

        case .notAttempted:
            EmptyView()
        }
    }
}

#Preview("Kalender ok") {
    BookingConfirmationView(
        booking: Booking(
            id: UUID(),
            shopID: MockData.shopID1,
            shopName: "Königs Barbershop",
            shopAddress: "Königsstraße 42, 34117 Kassel",
            serviceID: UUID(),
            serviceName: "Herrenhaarschnitt",
            startsAt: .now.addingTimeInterval(86_400),
            durationMinutes: 30
        ),
        calendarStatus: .added,
        onDone: {}
    )
}
