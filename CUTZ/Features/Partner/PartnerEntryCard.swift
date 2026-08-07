import SwiftUI

/// Eine Kachel in der Tagesleiste — Termin, Pause oder freie Lücke.
///
/// Alle drei sehen absichtlich verschieden aus, nicht nur verschieden
/// beschriftet: Ein Termin ist gefüllt, eine Pause gedämpft, eine
/// freie Lücke nur gestrichelt umrandet. So erfasst man den Tag, ohne
/// zu lesen.
struct PartnerEntryCard: View {

    let entry: DayEntry

    /// Wird beim Antippen einer freien Lücke aufgerufen — dort trägt
    /// der Friseur die Laufkundschaft ein.
    var onAddWalkIn: ((DayEntry) -> Void)? = nil

    /// Wird beim Antippen eines Termins aufgerufen.
    var onOpenBooking: ((Booking) -> Void)? = nil

    var body: some View {
        switch entry.kind {
        case .booking(let booking): bookingCard(booking)
        case .blocked(let block):   blockedCard(block)
        case .free:                 freeCard
        }
    }

    // MARK: - Termin

    private func bookingCard(_ booking: Booking) -> some View {
        Button {
            onOpenBooking?(booking)
        } label: {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.timeRangeText)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(booking.serviceName)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)

                    if !DayTimelineLayout.isCompact(entry) {
                        Label {
                            Text(booking.customerName)
                                .lineLimit(1)
                        } icon: {
                            Image(systemName: "person.crop.circle.fill")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 0)

                // Der Status steht rechts oben, damit er beim
                // Überfliegen an derselben Stelle sitzt.
                Text("Bestätigt")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.green)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(.green.opacity(0.15), in: Capsule())
            }
            .padding(10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Pause und Sperre

    private func blockedCard(_ block: TimeBlock) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(entry.timeRangeText)
                .font(.caption)
                .foregroundStyle(.tertiary)

            Text(block.title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Freie Lücke

    private var freeCard: some View {
        Button {
            onAddWalkIn?(entry)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.timeRangeText)
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    Text("Verfügbar")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                // Der Knopf für Laufkundschaft. Direkt in der Lücke und
                // nicht in einem Menü versteckt: Jemand steht im Laden
                // und wartet — das muss mit einem Griff gehen.
                Image(systemName: "plus")
                    .font(.footnote.weight(.semibold))
                    .frame(width: 26, height: 26)
                    .background(Color(.secondarySystemBackground), in: Circle())
            }
            .padding(10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        Color.secondary.opacity(0.35),
                        style: StrokeStyle(lineWidth: 1, dash: [5, 4])
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Termin von Hand eintragen")
    }
}

#Preview {
    let now = Calendar.current.startOfDay(for: .now).addingTimeInterval(9 * 3600)

    return VStack(spacing: 8) {
        PartnerEntryCard(entry: DayEntry(
            kind: .free, startsAt: now, endsAt: now.addingTimeInterval(3600)
        ))
        .frame(height: 60)

        PartnerEntryCard(entry: DayEntry(
            kind: .blocked(TimeBlock(
                shopID: UUID(), startsAt: now, endsAt: now.addingTimeInterval(3600)
            )),
            startsAt: now, endsAt: now.addingTimeInterval(3600)
        ))
        .frame(height: 60)
    }
    .padding()
    .preferredColorScheme(.dark)
}
