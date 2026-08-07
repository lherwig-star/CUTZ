import SwiftUI

/// Schritt 1: Was möchtest du?
///
/// Große antippbare Karten statt einer Auswahlliste. Man soll den Preis
/// sehen, ohne etwas aufzuklappen — das ist mit die wichtigste Angabe
/// überhaupt und darf nicht hinter einer Bedienung versteckt sein.
struct BookingServiceStep: View {

    let services: [BarberService]
    @Binding var selection: BarberService?

    var body: some View {
        VStack(spacing: 10) {
            ForEach(services) { service in
                ServiceCard(
                    service: service,
                    isSelected: selection?.id == service.id
                ) {
                    withAnimation(.snappy(duration: 0.2)) {
                        selection = service
                    }
                }
            }
        }
    }
}

/// Eine auswählbare Leistung.
private struct ServiceCard: View {

    let service: BarberService
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Image(systemName: service.category.symbolName)
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 3) {
                    Text(service.name)
                        .font(.headline)
                    Text(service.durationFormatted)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(service.priceShort)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        isSelected ? Color.accentColor : Color.clear,
                        lineWidth: 2
                    )
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ScrollView {
        BookingServiceStep(
            services: MockData.shops[1].services,
            selection: .constant(MockData.shops[1].services.first)
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
