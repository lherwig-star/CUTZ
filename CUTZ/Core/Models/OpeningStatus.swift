import Foundation

/// Ob ein Shop gerade geöffnet hat — und wenn nicht, wann wieder.
///
/// ⚠️ Liegt in `Core/` und gehört damit beiden. Finn kann das in der
/// Suchliste ebenfalls gebrauchen.
///
/// Warum ein eigener Typ und kein simples `Bool`? Weil "geschlossen"
/// allein nichts nützt. Interessant ist "geschlossen, öffnet morgen um
/// 9" — und diese Zusatzangabe lässt sich in einem `Bool` nicht
/// unterbringen.
enum OpeningStatus: Equatable {

    /// Geöffnet. `closesAtMinute` sind Minuten seit Mitternacht.
    case open(closesAtMinute: Int)

    /// Geschlossen, öffnet aber wieder.
    /// `opensInDays` ist 0 für heute, 1 für morgen usw.
    case closed(opensInDays: Int, weekday: Int, opensAtMinute: Int)

    /// Geschlossen und gar keine Öffnungszeiten hinterlegt.
    case closedIndefinitely

    /// Für Einfärbungen in der Oberfläche.
    var isOpen: Bool {
        switch self {
        case .open: true
        default:    false
        }
    }

    /// Fertiger Text, z. B. "Jetzt geöffnet · bis 19:00"
    var text: String {
        switch self {
        case .open(let closesAtMinute):
            return String(
                format: AppText.string("opening.openUntil"),
                OpeningHour.timeString(fromMinute: closesAtMinute)
            )

        case .closed(let opensInDays, let weekday, let opensAtMinute):
            return String(
                format: AppText.string("opening.closedUntil"),
                Self.dayText(opensInDays: opensInDays, weekday: weekday),
                OpeningHour.timeString(fromMinute: opensAtMinute)
            )

        case .closedIndefinitely:
            return AppText.string("opening.closedIndefinitely")
        }
    }

    /// "heute", "morgen" oder der Wochentagsname.
    private static func dayText(opensInDays: Int, weekday: Int) -> String {
        switch opensInDays {
        case 0: return AppText.string("opening.today")
        case 1: return AppText.string("opening.tomorrow")
        default:
            // Die ausgeschriebenen Wochentage kommen aus derselben
            // Quelle wie in der Terminübersicht — sonst hieße es an
            // einer Stelle "Donnerstag" und an der anderen "Thursday".
            let names = AvailabilityText.longWeekdayNames
            let index = weekday - 1
            guard names.indices.contains(index) else { return "" }
            return names[index]
        }
    }
}

extension Barbershop {

    /// Ermittelt den aktuellen Öffnungsstatus.
    ///
    /// `now` und `calendar` sind Parameter mit Vorgabewert — im normalen
    /// Betrieb ruft man einfach `shop.openingStatus()` auf. In Tests kann
    /// man dagegen eine feste Uhrzeit hineinreichen, sonst würden die
    /// Tests je nach Tageszeit mal durchlaufen und mal nicht.
    /// Genauso macht es `SlotCalculator`.
    func openingStatus(now: Date = .now, calendar: Calendar = .current) -> OpeningStatus {

        let weekday = calendar.component(.weekday, from: now)
        let minuteOfDay = calendar.component(.hour, from: now) * 60
                        + calendar.component(.minute, from: now)

        // 1. Haben wir heute offen und ist es gerade innerhalb der Zeit?
        if let today = openingHour(forWeekday: weekday),
           minuteOfDay >= today.opensAtMinute,
           minuteOfDay < today.closesAtMinute {
            return .open(closesAtMinute: today.closesAtMinute)
        }

        // 2. Sonst den nächsten Öffnungstag suchen — höchstens eine Woche
        //    voraus, danach wiederholt sich der Plan ohnehin.
        for offset in 0..<7 {
            // Wochentage laufen von 1 bis 7 und danach wieder bei 1 los.
            // Das -1 und +1 rechnet zwischen "ab 1 zählen" und der
            // Restrechnung (die bei 0 beginnt) hin und her.
            let day = (weekday + offset - 1) % 7 + 1

            guard let hours = openingHour(forWeekday: day) else { continue }

            // Heute zählt nur, wenn die Öffnung noch bevorsteht.
            // Sonst würde abends "öffnet heute 09:00" dastehen.
            if offset == 0 && minuteOfDay >= hours.opensAtMinute { continue }

            return .closed(
                opensInDays: offset,
                weekday: day,
                opensAtMinute: hours.opensAtMinute
            )
        }

        return .closedIndefinitely
    }
}
