import SwiftUI

/// Die Tab-Leiste der Friseurseite.
///
/// Fünf Bereiche statt drei wie bei den Kunden. Das ist Absicht: Ein
/// Kunde macht mit CUTZ genau eine Sache, ein Friseur verwaltet damit
/// seinen Betrieb.
///
/// Die Reihenfolge folgt der Häufigkeit. "Übersicht" steht vorn und
/// ist beim Start ausgewählt, weil das der Bildschirm ist, den man
/// zwanzigmal am Tag kurz aufmacht: Wer kommt als Nächstes?
///
/// ── Warum durchgehend dunkel ──────────────────────────────
///
/// Die Kundenseite folgt dem Gerät, diese hier nicht. Zwei Gründe:
///
/// Der offensichtliche ist, dass ein Tagesplan mit vielen farbigen
/// Zuständen auf dunklem Grund ruhiger wirkt — die Termine sollen
/// auffallen, nicht der Hintergrund.
///
/// Der wichtigere: Das Gerät liegt beim Friseur auf dem Tresen und
/// wird im Vorbeigehen angesehen, oft in einem Laden mit gedämpftem
/// Licht. Ein weißer Bildschirm blendet dabei.
struct PartnerRootView: View {

    @State private var selection: Tab = .overview

    enum Tab {
        case overview
        case calendar
        case bookings
        case customers
        case profile
    }

    var body: some View {
        TabView(selection: $selection) {
            PartnerOverviewScreen()
                .tabItem { Label("Übersicht", systemImage: "house") }
                .tag(Tab.overview)

            PartnerCalendarScreen()
                .tabItem { Label("Kalender", systemImage: "calendar") }
                .tag(Tab.calendar)

            PartnerBookingsScreen()
                .tabItem { Label("Buchungen", systemImage: "checkmark.square") }
                .tag(Tab.bookings)

            PartnerCustomersScreen()
                .tabItem { Label("Kunden", systemImage: "person.2") }
                .tag(Tab.customers)

            PartnerProfileScreen()
                .tabItem { Label("Profil", systemImage: "person") }
                .tag(Tab.profile)
        }
        // Gilt für alles darunter, auch für Blätter, die sich von unten
        // schieben — deshalb hier oben und nicht je Screen einzeln.
        .preferredColorScheme(.dark)
    }
}

#Preview {
    PartnerRootView()
        .environment(AppModel())
}
