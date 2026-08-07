import SwiftUI

/// Der Kalender-Tab: derselbe Tagesplan wie in der Übersicht, aber
/// über den ganzen Bildschirm — und mit dem, was in der Übersicht
/// fehlt: Zeiten sperren.
///
/// ── Warum das nicht dasselbe wie die Übersicht ist ────────
///
/// In der Übersicht ist der Kalender eine Karte neben anderen. Man
/// schaut kurz drauf und macht das Telefon wieder weg.
///
/// Hierher kommt man mit einer Absicht: "Ich mache Freitag früher zu."
/// Dafür braucht es Platz und den Knopf zum Sperren — in der Übersicht
/// wäre er einer von zu vielen.
struct PartnerCalendarScreen: View {

    @Environment(PartnerModel.self) private var partnerModel

    @State private var isBlockingTime = false

    var body: some View {
        NavigationStack {
            Group {
                if let shop = partnerModel.shop {
                    content(shop: shop)
                } else {
                    ContentUnavailableView(
                        "Kein Laden verknüpft",
                        systemImage: "storefront",
                        description: Text("Trag deinen Laden ein, dann siehst du hier deine Termine.")
                    )
                }
            }
            .navigationTitle("Kalender")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isBlockingTime = true
                    } label: {
                        Label("Zeit sperren", systemImage: "nosign")
                    }
                    .disabled(partnerModel.shop == nil)
                }
            }
        }
        .sheet(isPresented: $isBlockingTime) {
            PartnerTimeBlockEditor(day: partnerModel.selectedDay)
        }
    }

    private func content(shop: Barbershop) -> some View {
        // Die Bindung muss hier stehen, wo `$model` auch benutzt wird.
        @Bindable var model = partnerModel

        return VStack(spacing: 0) {
            PartnerWeekStrip(selectedDay: $model.selectedDay)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    timeline(shop: shop)
                    blocksSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
        }
    }

    @ViewBuilder
    private func timeline(shop: Barbershop) -> some View {
        let entries = partnerModel.entriesForSelectedDay
        let labels = DaySchedule.hourLabels(for: partnerModel.selectedDay, shop: shop)

        if let window = DaySchedule.openingWindow(for: partnerModel.selectedDay, shop: shop),
           !entries.isEmpty {
            PartnerDayTimeline(
                entries: entries,
                hourLabels: labels,
                windowStart: window.opens
            )
        } else {
            ContentUnavailableView(
                "An diesem Tag geschlossen",
                systemImage: "moon.zzz",
                description: Text("Öffnungszeiten änderst du im Profil.")
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 30)
        }
    }

    /// Die Sperren dieses Tages, damit man sie auch wieder loswird.
    ///
    /// In der Leiste darüber sieht man sie zwar, kann sie dort aber
    /// nicht entfernen — eine Kachel zum Wischen wäre bei einer
    /// Viertelstunde zu klein.
    @ViewBuilder
    private var blocksSection: some View {
        let blocks = blocksForSelectedDay

        if !blocks.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Gesperrte Zeiten")
                    .font(.headline)

                ForEach(blocks) { block in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(block.title)
                                .font(.subheadline.weight(.medium))
                            Text(AvailabilityText.timeText(for: block.startsAt)
                                 + " – "
                                 + AvailabilityText.timeText(for: block.endsAt))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button(role: .destructive) {
                            Task { await partnerModel.removeTimeBlock(block) }
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(12)
                    .background(Color(.secondarySystemBackground),
                                in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private var blocksForSelectedDay: [TimeBlock] {
        let calendar = Calendar.current
        return partnerModel.timeBlocks
            .filter { calendar.isDate($0.startsAt, inSameDayAs: partnerModel.selectedDay) }
            .sorted { $0.startsAt < $1.startsAt }
    }
}
