import SwiftUI

/// Schritt 3: Wann passt es dir?
///
/// Bewusst KEIN klassischer Monatskalender. Ein Kalenderblatt zeigt vor
/// allem Tage, an denen nichts geht — man sucht dann die wenigen freien
/// heraus. Hier ist es umgekehrt: waagerechte Tagesleiste, darunter
/// sofort die freien Uhrzeiten. Man sieht, was geht, nicht was nicht geht.
struct BookingTimeStep: View {

    let days: [Date]
    let openDays: Set<Date>
    let slots: [Date]
    let isLoading: Bool
    let noSlotsReason: String

    @Binding var selectedDay: Date
    @Binding var selectedSlot: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            dayStrip
            timeSection
        }
    }

    // MARK: - Tage

    private var dayStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(days, id: \.self) { day in
                    DayChip(
                        day: day,
                        isSelected: Calendar.current.isDate(day, inSameDayAs: selectedDay),
                        isOpen: openDays.contains(day)
                    ) {
                        selectedDay = day
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }

    // MARK: - Uhrzeiten

    @ViewBuilder
    private var timeSection: some View {
        if isLoading {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)

        } else if slots.isEmpty {
            VStack(spacing: 6) {
                Image(systemName: "clock.badge.xmark")
                    .font(.title2)
                    .foregroundStyle(.tertiary)
                Text(noSlotsReason)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)

        } else {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 84), spacing: 10)],
                spacing: 10
            ) {
                ForEach(slots, id: \.self) { slot in
                    let isSelected = selectedSlot == slot

                    Button {
                        withAnimation(.snappy(duration: 0.15)) { selectedSlot = slot }
                    } label: {
                        Text(AvailabilityText.timeText(for: slot))
                            .font(.subheadline)
                            .fontWeight(isSelected ? .semibold : .regular)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                isSelected ? Color.accentColor : Color(.secondarySystemGroupedBackground),
                                in: RoundedRectangle(cornerRadius: 10)
                            )
                            .foregroundStyle(isSelected ? Color.white : Color.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

/// Ein Tag in der waagerechten Leiste.
private struct DayChip: View {

    let day: Date
    let isSelected: Bool
    let isOpen: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 3) {
                Text(weekdayText)
                    .font(.caption2)
                Text(dayNumberText)
                    .font(.headline)
            }
            .frame(width: 52, height: 62)
            .background(
                isSelected ? Color.accentColor : Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .foregroundStyle(foreground)
        }
        .buttonStyle(.plain)
        .disabled(!isOpen)
    }

    /// "Heute" statt des Wochentags, wenn es heute ist — das liest man
    /// schneller, als den Wochentag mit dem eigenen Kalender abzugleichen.
    ///
    /// Beides ging vorher an der Übersetzung vorbei: "Heute" stand als
    /// deutscher Text im Code, und `.formatted(.dateTime.weekday(…))`
    /// richtet sich nach der Region des Geräts statt nach der
    /// App-Sprache. `AvailabilityText` kennt die Wochentagsnamen in
    /// allen drei Sprachen.
    private var weekdayText: String {
        if Calendar.current.isDateInToday(day) {
            return AppText.string("Heute")
        }
        return AvailabilityText.shortWeekday(of: day)
    }

    /// Nur die Tageszahl: "14".
    ///
    /// Von Hand statt über `.formatted()`, weil sonst je nach Region
    /// noch ein Punkt dahinterstünde.
    private var dayNumberText: String {
        String(Calendar.current.component(.day, from: day))
    }

    private var foreground: Color {
        if isSelected { return .white }
        // Ruhetage blass, damit man den Unterschied ohne Antippen sieht.
        return isOpen ? .primary : .secondary.opacity(0.4)
    }
}

#Preview {
    BookingTimeStep(
        days: (0..<10).compactMap {
            Calendar.current.date(byAdding: .day, value: $0, to: .now)
        },
        openDays: Set((0..<10).compactMap {
            Calendar.current.date(byAdding: .day, value: $0, to: .now)
        }),
        slots: (0..<8).compactMap {
            Calendar.current.date(byAdding: .minute, value: $0 * 45, to: .now)
        },
        isLoading: false,
        noSlotsReason: "An diesem Tag sind keine Termine mehr frei.",
        selectedDay: .constant(.now),
        selectedSlot: .constant(nil)
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
