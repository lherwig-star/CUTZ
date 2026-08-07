import Foundation

/// Formatiert eine Entfernung: unter einem Kilometer in Metern,
/// darüber in Kilometern.
///
/// Eigener Typ, weil dieselbe Formatierung an drei Stellen gebraucht
/// wird — Barber-Karte, Shop-Profil und später die Suche. Dreimal
/// dasselbe hinzuschreiben heißt, es dreimal unterschiedlich falsch
/// machen zu können.
///
/// Die Einheiten stehen in den Sprachdateien: Auf Englisch heißt es
/// "m" und "km" genauso, im Arabischen aber "م" und "كم".
enum DistanceText {

    /// z. B. "800 m" oder "1,2 km".
    static func short(meters: Double) -> String {
        if meters < 1000 {
            return String(format: String(localized: "distance.meters"), Int(meters))
        }

        let kilometers = meters / 1000
        let number = kilometers.formatted(.number.precision(.fractionLength(1)))
        return String(format: String(localized: "distance.kilometers"), number)
    }
}
