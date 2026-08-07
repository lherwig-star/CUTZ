import SwiftUI

/// Der Tag als maßstäbliche Leiste: links die Stunden, rechts die
/// Termine, Pausen und freien Lücken.
///
/// Die Kacheln liegen absichtlich nicht einfach untereinander, sondern
/// an ihrer Uhrzeit. Nur so sieht man, dass zwischen 11 und 13:30
/// nichts los ist — bei einer gleichmäßigen Liste sähe diese Lücke
/// genauso aus wie eine Viertelstunde.
///
/// Wo die Kacheln sitzen, rechnet `DayTimelineLayout` aus. Hier steht
/// nur, wie es aussieht.
struct PartnerDayTimeline: View {

    let entries: [DayEntry]
    let hourLabels: [Int]
    let windowStart: Date

    var onAddWalkIn: ((DayEntry) -> Void)? = nil
    var onOpenBooking: ((Booking) -> Void)? = nil

    /// Breite der Stundenspalte links.
    private let railWidth: CGFloat = 52

    var body: some View {
        ZStack(alignment: .topLeading) {
            hourRail
            entryColumn
        }
        .frame(height: DayTimelineLayout.totalHeight(hourLabels: hourLabels), alignment: .top)
    }

    /// Die Stundenbeschriftung mit feinen Trennlinien.
    private var hourRail: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(hourLabels, id: \.self) { hour in
                HStack(spacing: 8) {
                    Text(hourText(hour))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .frame(width: railWidth - 8, alignment: .leading)

                    Rectangle()
                        .fill(Color.secondary.opacity(0.12))
                        .frame(height: 1)
                }
                .frame(height: DayTimelineLayout.hourHeight, alignment: .top)
            }
        }
    }

    /// Die Kacheln, jede an ihrer Uhrzeit.
    private var entryColumn: some View {
        ForEach(entries) { entry in
            PartnerEntryCard(
                entry: entry,
                onAddWalkIn: onAddWalkIn,
                onOpenBooking: onOpenBooking
            )
            .frame(height: DayTimelineLayout.height(for: entry))
            .padding(.leading, railWidth)
            .offset(y: DayTimelineLayout.offset(for: entry, windowStart: windowStart))
        }
    }

    /// "09:00" — von Hand und nicht über `.formatted()`, damit die
    /// Schreibweise nicht von der Geräteregion abhängt.
    private func hourText(_ hour: Int) -> String {
        String(format: "%02d:00", hour)
    }
}
