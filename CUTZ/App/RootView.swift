import SwiftUI

/// Die Weiche zwischen Kunden- und Friseurseite.
///
/// Drei mögliche Zustände:
///
///   1. Noch nichts gewählt → der Auswahlbildschirm
///   2. Kunde  → `CustomerRootView` (drei Tabs, wie gehabt)
///   3. Friseur → `PartnerRootView`  (fünf Tabs, dunkel)
///
/// Warum hier und nicht in `CutzApp`? Weil `CutzApp` sich um Umgebung
/// und Sprache kümmert. Was angezeigt wird, ist eine andere Frage —
/// und diese hier lässt sich in der Vorschau durchspielen, ohne die
/// ganze App zu starten.
struct RootView: View {

    @Environment(AppModel.self) private var appModel

    var body: some View {
        // `@Bindable` brauchen wir hier nicht: Wir lesen nur und
        // schreiben über eine Funktion zurück.
        switch appModel.role.current {
        case .none:
            RoleChoiceScreen { chosen in
                appModel.role.current = chosen
            }

        case .customer:
            CustomerRootView()

        case .barber:
            // Die Tab-Leiste gibt es erst nach der Freigabe. Davor
            // steht das Formular oder der Wartezustand — sonst würde
            // ein Kalender angezeigt, den es noch gar nicht gibt.
            if appModel.partner.status == .approved {
                PartnerRootView()
            } else {
                PartnerRegistrationScreen()
            }
        }
    }
}

#Preview("Auswahl") {
    RootView()
        .environment(AppModel())
}
