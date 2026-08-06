import Foundation

/// Berechnet freie Termin-Zeitfenster aus Öffnungszeiten.
///
/// Bewusst als eigener Typ ohne Datenbank und ohne Oberfläche: reine
/// Rechenlogik, die man sehr einfach testen kann (siehe CUTZTests).
/// Genau solche Stellen sind später die häufigste Fehlerquelle — daher
/// liegen sie hier isoliert und nicht mitten in einer View.
enum SlotCalculator {

    /// Im Raster von 15 Minuten werden Termine angeboten:
    /// 09:00, 09:15, 09:30 …
    static let stepMinutes = 15

    /// Ermittelt alle möglichen Startzeiten für einen Service an einem Tag.
    ///
    /// Regeln:
    ///  1. Der Shop muss an dem Wochentag geöffnet haben.
    ///  2. Der Termin muss komplett vor Ladenschluss zu Ende sein.
    ///  3. Bereits vergebene Zeiten fallen raus.
    ///  4. Termine in der Vergangenheit fallen raus.
    ///
    /// - Parameters:
    ///   - day: Irgendein Zeitpunkt an dem gewünschten Tag.
    ///   - bookedSlots: Schon vergebene Startzeiten inklusive ihrer Dauer.
    static func slots(
        for shop: Barbershop,
        service: BarberService,
        on day: Date,
        bookedSlots: [(start: Date, durationMinutes: Int)] = [],
        calendar: Calendar = .current,
        now: Date = .now
    ) -> [Date] {

        // 1. Hat der Shop an diesem Wochentag überhaupt offen?
        let weekday = calendar.component(.weekday, from: day)
        guard let hours = shop.openingHour(forWeekday: weekday) else {
            return []   // Ruhetag
        }

        // Mitternacht des gewählten Tages als Ausgangspunkt.
        let startOfDay = calendar.startOfDay(for: day)

        var result: [Date] = []

        // 2. In 15-Minuten-Schritten durch den Tag laufen.
        var minute = hours.opensAtMinute
        while minute + service.durationMinutes <= hours.closesAtMinute {

            guard let slotStart = calendar.date(
                byAdding: .minute, value: minute, to: startOfDay
            ) else {
                break
            }

            let slotEnd = slotStart.addingTimeInterval(
                TimeInterval(service.durationMinutes * 60)
            )

            // 3. Vergangene Termine überspringen.
            //    Sonst könnte man um 15 Uhr noch 9 Uhr morgens buchen.
            if slotStart <= now {
                minute += stepMinutes
                continue
            }

            // 4. Kollidiert der Slot mit einem schon gebuchten Termin?
            //    Zwei Zeiträume überlappen sich genau dann, wenn der eine
            //    beginnt, bevor der andere endet – und umgekehrt.
            let overlaps = bookedSlots.contains { booked in
                let bookedEnd = booked.start.addingTimeInterval(
                    TimeInterval(booked.durationMinutes * 60)
                )
                return slotStart < bookedEnd && booked.start < slotEnd
            }

            if !overlaps {
                result.append(slotStart)
            }

            minute += stepMinutes
        }

        return result
    }
}
