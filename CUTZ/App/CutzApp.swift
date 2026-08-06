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
        }
    }
}
