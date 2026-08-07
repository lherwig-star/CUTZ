import SwiftUI

/// Der Startpunkt der App.
///
/// `@main` sagt iOS: Hier geht es los. Es darf genau ein `@main` im
/// gesamten Projekt geben.
@main
struct CutzApp: App {

    /// Der geteilte App-Zustand. Wird einmal erzeugt und lebt so lange
    /// wie die App. `@State` sorgt bei `@Observable`-Klassen dafür, dass
    /// das Objekt nicht bei jedem Neuzeichnen neu angelegt wird.
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                // Damit steht `appModel` in ALLEN untergeordneten Views
                // zur Verfügung, ohne dass wir ihn durch jede Ebene
                // von Hand durchreichen müssen.
                .environment(appModel)

                // ── Die Sprache aus dem Profil ────────────────────
                //
                // Diese beiden Zeilen sind der ganze Trick hinter dem
                // Sprachschalter.
                //
                // `locale` ist das, woran SwiftUI erkennt, in welcher
                // Sprache ein `Text("Termin buchen")` erscheinen soll.
                // Normalerweise kommt der Wert von iOS; wir setzen ihn
                // hier selbst. Ändert sich die Auswahl, zeichnet SwiftUI
                // alles darunter neu — deshalb wirkt das Umschalten
                // sofort und braucht keinen Neustart.
                //
                // `layoutDirection` dreht das Layout für Arabisch.
                // Normalerweise leitet iOS das aus der Systemsprache ab;
                // da wir die Sprache aber selbst bestimmen, müssen wir
                // die Leserichtung auch selbst mitziehen.
                .environment(\.locale, appModel.language.current.locale)
                .environment(\.layoutDirection, appModel.language.current.layoutDirection)
        }
    }
}
