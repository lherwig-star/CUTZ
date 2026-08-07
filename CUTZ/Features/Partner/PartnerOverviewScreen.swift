import SwiftUI

/// Der Startbildschirm der Friseurseite: Was ist heute los?
///
/// ── Warum genau das hier vorn steht ───────────────────────
///
/// Ein Friseur steht, hat die Hände voll und das Telefon in der Hose.
/// Der Bildschirm, den er zwanzigmal am Tag kurz aufmacht, beantwortet
/// genau eine Frage: Wer kommt als Nächstes?
///
/// Deshalb ist der Tagesplan das größte Element und nicht etwa
/// Statistiken oder Einstellungen. Alles, was Eingabe verlangt, liegt
/// eine Ebene tiefer — während der Arbeit pflegt niemand Daten.
struct PartnerOverviewScreen: View {

    @Environment(AppModel.self) private var appModel
    @Environment(PartnerModel.self) private var partnerModel

    @State private var showsProfile = false
    @State private var showsNotifications = false
    @State private var walkInSlot: DayEntry?

    var body: some View {
        NavigationStack {
            Group {
                if let shop = partnerModel.shop {
                    content(shop: shop)
                } else if partnerModel.isLoading {
                    ProgressView()
                } else {
                    ContentUnavailableView(
                        "Kein Laden verknüpft",
                        systemImage: "storefront",
                        description: Text("Trag deinen Laden ein, dann siehst du hier deine Termine.")
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
        // Das Profil kommt als Blatt von unten und nicht als
        // Navigationsschritt. Grund: `PartnerProfileScreen` ist selbst
        // ein Tab und bringt eine eigene Navigation mit — zwei
        // ineinander verschachtelte ergäben zwei Zurück-Pfeile
        // übereinander.
        .sheet(isPresented: $showsProfile) { PartnerProfileScreen() }
        .sheet(isPresented: $showsNotifications) { notificationsSheet }
        .sheet(item: $walkInSlot) { slot in
            PartnerWalkInSheet(slot: slot)
        }
    }

    // MARK: - Inhalt

    private func content(shop: Barbershop) -> some View {
        // `@Bindable` erzeugt aus dem beobachteten Objekt Bindungen mit
        // `$` — der Wochenstreifen schreibt den gewählten Tag zurück.
        @Bindable var model = partnerModel

        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PartnerShopHeader(
                    shop: shop,
                    isVerified: appModel.partner.status == .approved,
                    onOpenProfile: { showsProfile = true }
                )

                PartnerQuickTiles(
                    averageRating: shop.averageRating,
                    onStatistics: {},
                    onReviews: {},
                    onServices: {},
                    onSettings: {}
                )

                calendarCard(shop: shop, model: model)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 24)
        }
    }

    private func calendarCard(shop: Barbershop, model: PartnerModel) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Kalender")
                    .font(.headline)

                Spacer()

                // Springt zurück auf heute. Wer drei Tage weitergeblättert
                // hat, will mit einem Griff zurück.
                Button {
                    model.selectedDay = .now
                } label: {
                    HStack(spacing: 3) {
                        Text("Heute")
                        Image(systemName: "arrow.uturn.backward")
                    }
                    .font(.subheadline)
                }
                .disabled(Calendar.current.isDateInToday(model.selectedDay))
            }

            PartnerWeekStrip(selectedDay: $model.selectedDay)

            timeline(shop: shop, model: model)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground).opacity(0.5),
                    in: RoundedRectangle(cornerRadius: 20))
    }

    @ViewBuilder
    private func timeline(shop: Barbershop, model: PartnerModel) -> some View {
        let entries = model.entriesForSelectedDay
        let labels = DaySchedule.hourLabels(for: model.selectedDay, shop: shop)

        if let window = DaySchedule.openingWindow(for: model.selectedDay, shop: shop),
           !entries.isEmpty {
            PartnerDayTimeline(
                entries: entries,
                hourLabels: labels,
                windowStart: window.opens,
                onAddWalkIn: { walkInSlot = $0 },
                onOpenBooking: { _ in }
            )
        } else {
            // Ruhetag. Ein leeres Raster wäre missverständlich — es
            // sähe aus, als wäre alles frei.
            ContentUnavailableView(
                "An diesem Tag geschlossen",
                systemImage: "moon.zzz",
                description: Text("Öffnungszeiten änderst du im Profil.")
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }

    // MARK: - Leiste oben

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Menu {
                Button {
                    appModel.role.current = .customer
                } label: {
                    Label("Zur Kundenansicht wechseln", systemImage: "arrow.left.arrow.right")
                }

                Button {
                    showsProfile = true
                } label: {
                    Label("Profil bearbeiten", systemImage: "pencil")
                }
            } label: {
                Image(systemName: "line.3.horizontal")
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showsNotifications = true
            } label: {
                Image(systemName: "bell")
            }
        }
    }

    private var notificationsSheet: some View {
        NavigationStack {
            // Ehrlich leer statt mit erfundenen Meldungen gefüllt.
            // Push-Nachrichten brauchen einen Server und das
            // kostenpflichtige Apple-Programm — beides gibt es noch nicht.
            ContentUnavailableView(
                "Keine Benachrichtigungen",
                systemImage: "bell.slash",
                description: Text("Sobald jemand bucht oder absagt, steht es hier.")
            )
            .navigationTitle("Benachrichtigungen")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
}
