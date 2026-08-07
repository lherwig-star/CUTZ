import SwiftUI

/// Die Woche als waagerechte Leiste: Mo 26 · Di 27 · Mi 28 …
///
/// Kein Monatskalender. Ein Friseur plant selten weiter als ein paar
/// Tage voraus, und ein Kalenderblatt zeigt vor allem Tage, an denen
/// nichts ansteht. Dieselbe Überlegung wie im Buchungsablauf der
/// Kundenseite.
struct PartnerWeekStrip: View {

    @Binding var selectedDay: Date

    /// Ab welchem Tag die Woche gezeigt wird.
    var startingFrom: Date = .now

    private let calendar = Calendar.current

    /// Sieben Tage ab heute — nicht ab Montag.
    ///
    /// Wer am Donnerstag draufschaut, will die nächsten sieben Tage
    /// sehen und nicht drei Tage Vergangenheit.
    private var days: [Date] {
        let start = calendar.startOfDay(for: startingFrom)
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(days, id: \.self) { day in
                    dayButton(day)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func dayButton(_ day: Date) -> some View {
        let isSelected = calendar.isDate(day, inSameDayAs: selectedDay)

        return Button {
            selectedDay = day
        } label: {
            VStack(spacing: 2) {
                // Wochentagsname aus `AvailabilityText`, nicht aus
                // `Calendar.weekdaySymbols` — sonst folgte er der
                // Region des Geräts statt dem Sprachschalter.
                Text(AvailabilityText.shortWeekday(of: day, calendar: calendar))
                    .font(.caption2)

                Text(dayNumber(day))
                    .font(.title3.weight(.semibold))
            }
            .frame(width: 48, height: 56)
            .foregroundStyle(isSelected ? Color.black : Color.primary)
            .background(
                isSelected ? Color.white : Color(.secondarySystemBackground),
                in: RoundedRectangle(cornerRadius: 14)
            )
        }
        .buttonStyle(.plain)
    }

    /// Nur die Tageszahl. Von Hand statt über `.formatted()`, weil dort
    /// je nach Region noch ein Punkt dahinterstünde.
    private func dayNumber(_ day: Date) -> String {
        String(calendar.component(.day, from: day))
    }
}

#Preview {
    // `.constant` statt `@State`: In der Vorschau muss man den Tag
    // nicht wirklich wechseln können, und so bleibt es auf jeder
    // Xcode-Version übersetzbar.
    PartnerWeekStrip(selectedDay: .constant(.now))
        .padding()
        .preferredColorScheme(.dark)
}
