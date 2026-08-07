import SwiftUI

/// Die Stammkunden.
///
/// ── Das Notizbuch hinter der Kasse ────────────────────────
///
/// Genau diese Liste führen viele Friseure heute auf Papier: Wer war
/// wann da, was macht der immer? Nur dass sie sich hier von selbst
/// aktualisiert — es gibt nichts einzutragen.
///
/// Deshalb steht hier auch kein "Kunde anlegen". Eine Kartei, die man
/// von Hand pflegen muss, pflegt nach drei Wochen niemand mehr.
struct PartnerCustomersScreen: View {

    @Environment(PartnerModel.self) private var partnerModel

    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            Group {
                if visibleCustomers.isEmpty {
                    emptyView
                } else {
                    List(visibleCustomers) { customer in
                        NavigationLink {
                            PartnerCustomerDetail(customer: customer)
                        } label: {
                            row(customer)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Kunden")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: Text("Name"))
        }
    }

    private func row(_ customer: CustomerSummary) -> some View {
        HStack(spacing: 12) {
            // Initialen statt eines leeren Kreises. Ein Foto haben wir
            // von Kunden nicht — und werden wir auch nicht bekommen.
            Text(initials(of: customer.name))
                .font(.caption.weight(.semibold))
                .frame(width: 38, height: 38)
                .background(Color(.secondarySystemBackground), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(customer.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                Text(subtitle(for: customer))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            if let next = customer.nextVisit {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Nächster")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Text(AvailabilityText.short(for: next))
                        .font(.caption.weight(.medium))
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var emptyView: some View {
        ContentUnavailableView {
            Label("Noch keine Kunden", systemImage: "person.2")
        } description: {
            Text(searchText.isEmpty
                 ? "Sobald jemand bei dir war, steht er hier."
                 : "Zu dieser Suche gibt es niemanden.")
        }
    }

    // MARK: - Ableiten

    private var visibleCustomers: [CustomerSummary] {
        let all = partnerModel.customers
        guard !searchText.isEmpty else { return all }
        return all.filter { BarberSearch.matches(searchText, in: [$0.name]) }
    }

    /// "3× da · zuletzt 12.08." — oder "Neu", wenn noch nichts war.
    private func subtitle(for customer: CustomerSummary) -> String {
        guard customer.visitCount > 0, let last = customer.lastVisit else {
            return AppText.string("Neuer Kunde")
        }

        return AppText.format(
            "customer.visitsAndLast",
            customer.visitCount,
            AvailabilityText.dayAndMonth(of: last)
        )
    }

    /// Die ersten Buchstaben von bis zu zwei Namensteilen.
    private func initials(of name: String) -> String {
        let parts = name.split(separator: " ").prefix(2)
        return parts.compactMap { $0.first.map(String.init) }.joined().uppercased()
    }
}

// MARK: - Einzelner Kunde

/// Was wir über einen Kunden wissen — und das ist ausschließlich das,
/// was er selbst bei uns gebucht hat.
///
/// Keine Notizfelder, keine Merkmale, keine Vorlieben. Das wäre eine
/// Kartei über Menschen, die dem FRISEUR vertraut haben und nicht uns.
private struct PartnerCustomerDetail: View {

    let customer: CustomerSummary

    @Environment(PartnerModel.self) private var partnerModel

    /// Die Termine dieses Kunden, neueste zuerst.
    private var bookings: [Booking] {
        partnerModel.bookings
            .filter { $0.customerName == customer.name }
            .sorted { $0.startsAt > $1.startsAt }
    }

    var body: some View {
        List {
            Section {
                LabeledContent("Besuche", value: String(customer.visitCount))

                if let last = customer.lastVisit {
                    LabeledContent("Zuletzt", value: AvailabilityText.long(for: last))
                }
                if let next = customer.nextVisit {
                    LabeledContent("Nächster Termin", value: AvailabilityText.long(for: next))
                }
                if let usual = customer.usualService {
                    LabeledContent("Meistens", value: usual)
                }
            }

            Section("Termine") {
                ForEach(bookings) { booking in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(AvailabilityText.long(for: booking.startsAt))
                            .font(.subheadline)

                        HStack(spacing: 4) {
                            Text(booking.serviceName)
                            if booking.isCancelled {
                                Text("· Abgesagt")
                                    .foregroundStyle(.red)
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle(customer.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
