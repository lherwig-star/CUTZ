import Foundation
import CoreGraphics

/// Rechnet aus, wo ein Eintrag in der Tagesleiste sitzt und wie hoch
/// er ist.
///
/// ── Warum die Leiste maßstäblich ist ──────────────────────
///
/// Man könnte die Termine auch einfach untereinander auflisten. Dann
/// sähen eine Viertelstunde und zwei Stunden aber gleich groß aus —
/// und genau darum geht es hier: Ein Friseur will auf einen Blick
/// sehen, ob der Nachmittag voll ist oder ob noch etwas hineinpasst.
///
/// ── Warum das ein eigener Typ ist ─────────────────────────
///
/// Weil es Rechnung ist, keine Darstellung. So lässt sich prüfen, dass
/// eine Stunde wirklich doppelt so hoch ist wie eine halbe — und dass
/// ein Viertelstundentermin nicht auf 16 Punkte zusammenschrumpft, in
/// denen kein Name mehr lesbar wäre.
enum DayTimelineLayout {

    /// Höhe einer vollen Stunde in Punkten.
    static let hourHeight: CGFloat = 64

    /// Darunter wird kein Eintrag gezeichnet, egal wie kurz er ist.
    ///
    /// Ein 15-Minuten-Termin wäre maßstäblich 16 Punkte hoch. Da passt
    /// keine Zeile Text hinein, und antippen könnte man ihn auch kaum.
    /// Ab hier gewinnt Lesbarkeit gegen Maßstabstreue.
    static let minimumHeight: CGFloat = 54

    /// Abstand zwischen zwei Kacheln, damit sie nicht aneinanderkleben.
    static let gap: CGFloat = 4

    /// Wie weit unterhalb des Leistenanfangs der Eintrag beginnt.
    static func offset(for entry: DayEntry, windowStart: Date) -> CGFloat {
        let minutes = entry.startsAt.timeIntervalSince(windowStart) / 60
        return CGFloat(max(0, minutes)) / 60 * hourHeight
    }

    /// Wie hoch die Kachel wird.
    static func height(for entry: DayEntry) -> CGFloat {
        let exact = CGFloat(entry.durationMinutes) / 60 * hourHeight
        return max(minimumHeight, exact - gap)
    }

    /// Die Gesamthöhe der Leiste.
    ///
    /// Richtet sich nach den Öffnungszeiten. Eine Stunde wird
    /// aufgeschlagen, damit der letzte Eintrag nicht am unteren Rand
    /// klebt.
    static func totalHeight(hourLabels: [Int]) -> CGFloat {
        CGFloat(max(1, hourLabels.count)) * hourHeight
    }

    /// Passt in die Kachel mehr als eine Zeile?
    ///
    /// Kurze Einträge bekommen eine gedrängte Darstellung — sonst
    /// würde der Text abgeschnitten, und abgeschnittener Text ist
    /// schlimmer als weniger Text.
    static func isCompact(_ entry: DayEntry) -> Bool {
        entry.durationMinutes < 45
    }
}
