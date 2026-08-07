import SwiftUI

/// Die Terminübersicht (Tab "Termine").
///
/// ─── Zuständig: Lukas ──────────────────────────────────────
///
/// Bewusst kein Kalender. Ein Kalenderblatt zeigt vor allem leere Tage;
/// interessant ist aber nur eins: der nächste Termin. Der steht deshalb
/// groß oben, alles Vergangene klein darunter.
///
/// Hinweis für Phase 1: Die Buchungen liegen nur im Arbeitsspeicher
/// (siehe `MockBarbershopRepository`). Nach einem Neustart der App ist
/// die Liste wieder leer. Das ändert sich mit Supabase in Phase 2.
struct BookingsScreen: View {

    @Environment(AppModel.self) private var appModel

    @State private var bookings: [Booking] = []
    @State private var isLoading = false

    /// Welcher Termin soll storniert werden?
    @State private var bookingToCancel: Booking?
    @State private var isCancelConfirmationShown = false

    /// Für "Umbuchen" und "Erneut buchen": beides öffnet den ganz
    /// normalen Buchungsablauf beim passenden Shop.
    @State private var shopToBook: Barbershop?

    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && bookings.isEmpty {
                    ProgressView()
                } else if bookings.isEmpty {
                    emptyState
                } else {
                    content
                }
            }
            .navigationTitle("Termine")
            .background(Color(.systemGroupedBackground))
            .task { await load() }
            .refreshable { await load() }

            // Stornieren ist nicht rückgängig zu machen — deshalb Rückfrage.
            .confirmationDialog(
                "Termin stornieren?",
                isPresented: $isCancelConfirmationShown,
                presenting: bookingToCancel
            ) { booking in
                Button("Termin stornieren", role: .destructive) {
                    Task { await cancel(booking) }
                }
                Button("Behalten", role: .cancel) {}
            } message: { booking in
                Text("\(booking.serviceName) bei \(booking.shopName)\nam \(booking.startsAtFormatted)")
            }
        }
        .sheet(item: $shopToBook) { shop in
            BookingFlowScreen(shop: shop)
        }
        // Nach dem Buchen aus diesem Screen heraus die Liste nachziehen.
        .onChange(of: shopToBook) { _, newValue in
            if newValue == nil {
                Task { await load() }
            }
        }
    }

    // MARK: - Inhalt

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }

                if let next = nextBooking {
                    sectionTitle("Nächster Termin")
                    NextAppointmentCard(
                        booking: next,
                        onNavigate: { navigate(to: next) },
                        onReschedule: { rebook(next) },
                        onCancel: {
                            bookingToCancel = next
                            isCancelConfirmationShown = true
                        }
                    )
                }

                if !laterBookings.isEmpty {
                    sectionTitle("Weitere Termine")
                    ForEach(laterBookings) { booking in
                        PastAppointmentRow(booking: booking) { rebook(booking) }
                    }
                }

                if !pastBookings.isEmpty {
                    sectionTitle("Vergangen")
                    ForEach(pastBookings) { booking in
                        PastAppointmentRow(booking: booking) { rebook(booking) }
                    }
                }
            }
            .padding(16)
        }
    }

    /// `LocalizedStringKey` statt `String` - sonst wuerde SwiftUI den
    /// Text nicht uebersetzen.
    private func sectionTitle(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.headline)
            .padding(.top, 4)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Noch keine Termine", systemImage: "calendar")
        } description: {
            Text("Such dir unter Entdecken einen Barber und buche deinen ersten Termin.")
        }
    }

    // MARK: - Aufteilung der Termine

    /// Termine, die noch anstehen und nicht abgesagt sind.
    private var upcoming: [Booking] {
        bookings
            .filter { $0.isUpcoming && !$0.isCancelled }
            .sorted { $0.startsAt < $1.startsAt }
    }

    private var nextBooking: Booking? { upcoming.first }

    private var laterBookings: [Booking] { Array(upcoming.dropFirst()) }

    /// Vergangenes und Abgesagtes zusammen — beides ist erledigt, und
    /// bei beidem ist "Erneut buchen" die sinnvolle Aktion.
    private var pastBookings: [Booking] {
        bookings
            .filter { !$0.isUpcoming || $0.isCancelled }
            .sorted { $0.startsAt > $1.startsAt }   // zuletzt gewesenes zuerst
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
            await load()
            // Die abgesagte Zeit ist wieder frei — das muss auch in
            // den Barber-Karten stehen.
            await appModel.refreshNextSlots()
        } catch {
            errorMessage = error.localizedDescription
        }
        bookingToCancel = nil
    }

    private func navigate(to booking: Booking) {
        if let shop = appModel.shop(withID: booking.shopID) {
            MapNavigation.open(shop)
        } else {
            MapNavigation.open(address: booking.shopAddress, name: booking.shopName)
        }
    }

    /// Umbuchen und erneut buchen sind derselbe Weg: den Ablauf beim
    /// selben Shop erneut öffnen.
    ///
    /// Beim Umbuchen bleibt der alte Termin bewusst bestehen, bis der
    /// neue steht. Sonst stünde man ohne Termin da, falls der gewünschte
    /// Ersatz schon vergeben ist.
    private func rebook(_ booking: Booking) {
        shopToBook = appModel.shop(withID: booking.shopID)
    }
}

#Preview {
    BookingsScreen()
        .environment(AppModel())
}
