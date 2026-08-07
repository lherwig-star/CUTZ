import SwiftUI

/// Die Bestätigung nach erfolgreicher Buchung.
///
/// ─── Zuständig: Lukas ──────────────────────────────────────
///
/// Zwei Dinge stehen hier im Vordergrund: dass es geklappt hat, und was
/// man jetzt tun kann. Alles andere — Preis, Adresse, Barber — steht
/// schon in der Terminübersicht und muss hier nicht wiederholt werden.
struct BookingConfirmationView: View {

    let booking: Booking

    /// Für die Navigation. Optional, weil ein Termin auch ohne
    /// vorliegenden Shop bestätigt werden könnte — dann wird über die
    /// gespeicherte Adresse navigiert.
    var shop: Barbershop?

    let calendarStatus: BookingViewModel.CalendarStatus
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            successMark
            details
            calendarHint
                .padding(.top, 18)

            Spacer()

            actions
        }
        .padding(20)
    }

    // MARK: - Bestandteile

    private var successMark: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 72))
            .foregroundStyle(.green)
            .padding(.bottom, 20)
    }

    private var details: some View {
        VStack(spacing: 8) {
            Text("Termin gebucht")
                .font(.title2)
                .fontWeight(.bold)

            Text(booking.shopName)
                .font(.headline)

            Text(booking.serviceName)
                .foregroundStyle(.secondary)

            if let employeeText = booking.employeeText {
                Text(employeeText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text(AvailabilityText.long(for: booking.startsAt))
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.top, 6)
        }
        .multilineTextAlignment(.center)
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

    private var actions: some View {
        VStack(spacing: 10) {
            Button {
                openNavigation()
            } label: {
                Label("Navigation starten", systemImage: "arrow.triangle.turn.up.right.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            Button(action: onDone) {
                Text("Fertig")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    private func openNavigation() {
        if let shop {
            MapNavigation.open(shop)
        } else {
            MapNavigation.open(address: booking.shopAddress, name: booking.shopName)
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
            serviceName: "Schnitt & Bart",
            employeeID: UUID(),
            employeeName: "Samir",
            startsAt: .now.addingTimeInterval(86_400),
            durationMinutes: 60
        ),
        shop: MockData.shops[0],
        calendarStatus: .added,
        onDone: {}
    )
}

#Preview("Kalender fehlgeschlagen") {
    BookingConfirmationView(
        booking: Booking(
            id: UUID(),
            shopID: MockData.shopID1,
            shopName: "Fade Lounge Nord",
            shopAddress: "Holländische Straße 74, 34127 Kassel",
            serviceID: UUID(),
            serviceName: "Skin Fade",
            startsAt: .now.addingTimeInterval(3600 * 5),
            durationMinutes: 45
        ),
        calendarStatus: .failed("CUTZ darf nicht auf deinen Kalender zugreifen."),
        onDone: {}
    )
}
