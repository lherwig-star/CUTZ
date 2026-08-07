import SwiftUI

/// Alle Buchungen des Ladens — nicht nur die von heute.
///
/// ── Wozu, wenn es die Übersicht gibt? ─────────────────────
///
/// Die Übersicht beantwortet "was ist heute los". Hierher kommt man
/// mit anderen Fragen: "Wann war der noch mal da?", "Wer hat für
/// nächsten Samstag gebucht?", "Wer hat abgesagt?"
///
/// Deshalb steht hier eine durchsuchbare Liste und keine Tagesleiste.
struct PartnerBookingsScreen: View {

    @Environment(PartnerModel.self) private var partnerModel

    @State private var scope: Scope = .upcoming
    @State private var searchText = ""
    @State private var bookingToCancel: Booking?

    enum Scope: String, CaseIterable, Identifiable {
        case upcoming
        case past
        case cancelled

        var id: String { rawValue }

        var label: String {
            switch self {
            case .upcoming:  return AppText.string("Kommende")
            case .past:      return AppText.string("Vergangen")
            case .cancelled: return AppText.string("Abgesagt")
            }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if visibleBookings.isEmpty {
                    emptyView
                } else {
                    list
                }
            }
            .navigationTitle("Buchungen")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: Text("Name oder Leistung"))
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("Zeitraum", selection: $scope) {
                        ForEach(Scope.allCases) { item in
                            Text(item.label).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
        .confirmationDialog(
            "Termin absagen?",
            // Eine echte Bindung und kein `.constant`: Wischt jemand
            // den Dialog weg, statt zu tippen, will SwiftUI ihn selbst
            // schließen. Mit einem festen Wert ginge das nicht — der
            // Termin bliebe vorgemerkt und der Dialog käme sofort
            // wieder.
            isPresented: Binding(
                get: { bookingToCancel != nil },
                set: { if !$0 { bookingToCancel = nil } }
            ),
            titleVisibility: .visible,
            presenting: bookingToCancel
        ) { booking in
            Button("Termin absagen", role: .destructive) {
                Task {
                    await partnerModel.cancel(booking)
                    bookingToCancel = nil
                }
            }
            Button("Behalten", role: .cancel) { bookingToCancel = nil }
        } message: { booking in
            // Der Name steht ausdrücklich in der Rückfrage. "Wirklich
            // absagen?" allein sagt nicht, WEN man gerade wegschickt.
            Text(booking.customerName)
        }
    }

    private var list: some View {
        List {
            ForEach(visibleBookings) { booking in
                PartnerBookingRow(booking: booking)
                    .swipeActions(edge: .trailing) {
                        if !booking.isCancelled && booking.isUpcoming {
                            Button(role: .destructive) {
                                bookingToCancel = booking
                            } label: {
                                Label("Absagen", systemImage: "xmark")
                            }
                        }
                    }
            }
        }
        .listStyle(.plain)
    }

    private var emptyView: some View {
        ContentUnavailableView {
            Label("Keine Buchungen", systemImage: "calendar.badge.exclamationmark")
        } description: {
            Text(searchText.isEmpty
                 ? "Hier stehen alle Termine deines Ladens."
                 : "Zu dieser Suche gibt es nichts.")
        }
    }

    // MARK: - Filtern

    private var visibleBookings: [Booking] {
        let now = Date.now

        let byScope = partnerModel.bookings.filter { booking in
            switch scope {
            case .cancelled: return booking.isCancelled
            case .upcoming:  return !booking.isCancelled && booking.startsAt >= now
            case .past:      return !booking.isCancelled && booking.startsAt < now
            }
        }

        let sorted = scope == .past
            ? byScope.sorted { $0.startsAt > $1.startsAt }   // zuletzt zuerst
            : byScope.sorted { $0.startsAt < $1.startsAt }

        guard !searchText.isEmpty else { return sorted }

        // Dieselbe Suche wie auf der Kundenseite: ohne Rücksicht auf
        // Groß- und Kleinschreibung und auf Umlaute. "muller" findet
        // also auch "Müller".
        return sorted.filter {
            BarberSearch.matches(searchText, in: [$0.customerName, $0.serviceName])
        }
    }
}

// MARK: - Eine Zeile

private struct PartnerBookingRow: View {

    let booking: Booking

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(booking.customerName.isEmpty
                     ? AppText.string("Ohne Namen")
                     : booking.customerName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                Text(booking.serviceName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if let employeeText = booking.employeeText {
                    Text(employeeText)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 3) {
                Text(AvailabilityText.short(for: booking.startsAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if booking.isCancelled {
                    Text("· Abgesagt")
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(.vertical, 4)
        .opacity(booking.isCancelled ? 0.55 : 1)
    }
}
