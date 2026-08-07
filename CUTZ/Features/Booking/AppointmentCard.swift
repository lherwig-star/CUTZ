import SwiftUI

/// Die große Karte für den nächsten anstehenden Termin.
///
/// Alles, was man kurz vorher wissen will, steht darauf: wo, wann, was,
/// bei wem, wie teuer — und die Aktionen direkt darunter. Wer eine
/// Stunde vor dem Termin die App öffnet, soll nichts mehr antippen
/// müssen außer "Navigation".
struct NextAppointmentCard: View {

    let booking: Booking

    let onNavigate: () -> Void
    let onReschedule: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headline
            Divider().padding(.vertical, 14)
            facts
            Divider().padding(.vertical, 14)
            actions
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
    }

    private var headline: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(AvailabilityText.long(for: booking.startsAt))
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(Color.accentColor)

            Text(booking.shopName)
                .font(.title3)
                .fontWeight(.semibold)

            Text(booking.shopAddress)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var facts: some View {
        VStack(alignment: .leading, spacing: 8) {
            factRow(symbol: "scissors", text: booking.serviceName)

            if let employeeText = booking.employeeText {
                factRow(symbol: "person", text: employeeText)
            }

            factRow(symbol: "clock", text: "\(booking.durationMinutes) Minuten")
        }
    }

    private func factRow(symbol: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 18)
            Text(text)
                .font(.subheadline)
            Spacer(minLength: 0)
        }
    }

    private var actions: some View {
        VStack(spacing: 8) {
            Button(action: onNavigate) {
                Label("Navigation", systemImage: "arrow.triangle.turn.up.right.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            HStack(spacing: 8) {
                Button(action: onReschedule) {
                    Text("Umbuchen")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button(role: .destructive, action: onCancel) {
                    Text("Stornieren")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .font(.subheadline)
        }
    }
}

/// Die kleine Zeile für vergangene und abgesagte Termine.
///
/// Der "Erneut buchen"-Knopf ist hier der eigentliche Zweck: Die meisten
/// gehen immer wieder zum selben Barber. Zwei Antippen statt der ganzen
/// Suche zu wiederholen.
struct PastAppointmentRow: View {

    let booking: Booking
    let onRebook: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(booking.shopName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .strikethrough(booking.isCancelled)

                Text(booking.serviceName)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 5) {
                    Text(booking.startsAtFormatted)
                    if booking.isCancelled {
                        Text("· Abgesagt")
                            .fontWeight(.medium)
                            .foregroundStyle(.red)
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Button(action: onRebook) {
                Text("Erneut buchen")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        .opacity(booking.isCancelled ? 0.7 : 1)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 14) {
            NextAppointmentCard(
                booking: Booking(
                    id: UUID(), shopID: MockData.shopID1,
                    shopName: "Königs Barbershop",
                    shopAddress: "Königsstraße 42, 34117 Kassel",
                    serviceID: UUID(), serviceName: "Schnitt & Bart",
                    employeeID: UUID(), employeeName: "Samir",
                    startsAt: .now.addingTimeInterval(86_400),
                    durationMinutes: 60
                ),
                onNavigate: {}, onReschedule: {}, onCancel: {}
            )

            PastAppointmentRow(
                booking: Booking(
                    id: UUID(), shopID: MockData.shopID2,
                    shopName: "Fade Lounge Nord",
                    shopAddress: "Holländische Straße 74",
                    serviceID: UUID(), serviceName: "Skin Fade",
                    startsAt: .now.addingTimeInterval(-86_400 * 14),
                    durationMinutes: 45
                ),
                onRebook: {}
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
