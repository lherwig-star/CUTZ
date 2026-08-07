import SwiftUI

/// Schritt 4: Passt alles?
///
/// Alles auf einen Blick, bevor verbindlich gebucht wird. Jede Zeile ist
/// antippbar und springt zum passenden Schritt zurück — wer merkt, dass
/// die Uhrzeit falsch ist, soll nicht dreimal "Zurück" drücken müssen.
struct BookingSummaryStep: View {

    let shop: Barbershop
    let service: BarberService
    let employee: BarberEmployee?
    let slot: Date

    /// Springt zum jeweiligen Schritt zurück.
    let onEdit: (BookingViewModel.Step) -> Void

    var body: some View {
        VStack(spacing: 0) {
            shopHeader

            Divider().padding(.leading, 16)

            row(
                title: "Service",
                value: service.name,
                detail: "\(service.priceShort) · \(service.durationFormatted)",
                symbol: service.category.symbolName,
                step: .service
            )

            Divider().padding(.leading, 16)

            row(
                title: "Barber",
                value: employee?.name ?? "Egal welcher Barber",
                detail: employee?.specialtiesText,
                symbol: "person",
                step: .employee
            )

            Divider().padding(.leading, 16)

            row(
                title: "Termin",
                value: AvailabilityText.long(for: slot),
                detail: "\(service.durationMinutes) Minuten",
                symbol: "clock",
                step: .time
            )

            Divider().padding(.leading, 16)

            totalRow
        }
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Bestandteile

    private var shopHeader: some View {
        HStack(spacing: 12) {
            ShopImage(seed: shop.id.uuidString, url: shop.imageURL, symbolSize: 20)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                Text(shop.name)
                    .font(.headline)
                Text(shop.fullAddress)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
    }

    private func row(
        title: String,
        value: String,
        detail: String?,
        symbol: String,
        step: BookingViewModel.Step
    ) -> some View {
        Button {
            onEdit(step)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .foregroundStyle(.secondary)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(value)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    if let detail, !detail.isEmpty {
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Antippen, um \(title) zu ändern")
    }

    private var totalRow: some View {
        HStack {
            Text("Gesamt")
                .font(.headline)
            Spacer()
            Text(service.priceShort)
                .font(.title3)
                .fontWeight(.semibold)
        }
        .padding(16)
    }
}

#Preview {
    BookingSummaryStep(
        shop: MockData.shops[0],
        service: MockData.shops[0].services[0],
        employee: MockData.shops[0].employees.first,
        slot: .now.addingTimeInterval(86_400),
        onEdit: { _ in }
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
