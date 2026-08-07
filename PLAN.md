# CUTZ — Projektplan

Stand: 6. August 2026

Grundidee: **Neotaste für Friseure.** Barbershops entdecken, Bewertungen
lesen, direkt einen Termin buchen — der dann automatisch im eigenen Kalender
landet.

Leitprinzip: **erst einfach, dann komplex.** Jede Phase ergibt eine App, die
man vorzeigen kann. Nichts wird auf Vorrat gebaut.

---

## Die drei Bereiche

1. **Entdecken** — Karte + hochziehbare Barber-Liste, Suche, Filter
2. **Favoriten** — gemerkte Läden, gleiche Karten wie unter Entdecken
3. **Termine** — nächster Termin groß, Vergangenes mit „Erneut buchen"

Alles zielt auf einen Ablauf: **Entdecken → Vertrauen → Termin buchen.**

Der Nutzer soll denken „ich brauche einen Haarschnitt" und nicht „ich
muss jetzt eine Buchungssoftware bedienen". Konkret heißt das: wenige
Entscheidungen, wenige Screens, große Knöpfe, viel Bild, wenig Text —
und die Angabe, wann der nächste Termin frei ist, steht schon in der
Liste. Niemand soll fünf Screens öffnen, um zu merken, dass heute
nichts mehr geht.

---

## Phase 1 — Das Gerüst ✅ *fertig*

Alles läuft mit Testdaten. Kein Server, kein Login, kein Internet.

Warum zuerst so? Weil man dann in wenigen Tagen eine App auf dem eigenen
iPhone hat, die sich echt anfühlt. Erst wenn feststeht, wie sie aussehen und
sich bedienen soll, ist klar, was die Datenbank überhaupt können muss.
Andersherum baut man meistens am Bedarf vorbei.

- [x] Datenmodelle: `Barbershop`, `BarberService`, `BarberEmployee`, `Review`,
      `Booking`, `OpeningHour`, `ServiceCategory`
- [x] `BarbershopRepository` als Protokoll — die Naht zum späteren Backend
- [x] Drei Tabs, Entdecken als Start, Profil hinter dem Knopf oben rechts
- [x] Karte mit Preis-Pins und Standort
- [x] Hochziehbare Barber-Liste mit `BarberCard`
- [x] Filter (Zeit, Entfernung, Preis, Bewertung, Service) und Sortierung
- [x] Suche nach Barber, Salon und Ort
- [x] Barber-Profil: Arbeiten, Team, Leistungen, Bewertungen, Standort
- [x] Buchung in vier Schritten inkl. Barber-Wahl und „egal welcher"
- [x] Kalendereintrag über EventKit
- [x] Favoriten, gespeichert in `UserDefaults`
- [x] Termine: nächster groß, Vergangenes mit „Erneut buchen"
- [x] Account-Bereich (Platzhalter bis Phase 3)
- [x] Tests für alles, was ohne Oberfläche prüfbar ist

### Bewusste Entscheidungen beim Umbau

**Bilder gibt es noch keine.** `ShopImage` zeichnet Farbverläufe, die
aus der Shop-ID abgeleitet werden — derselbe Laden also immer in
derselben Farbe. Sobald echte Fotos vorliegen (Phase 5), lädt dieselbe
View sie ohne weitere Änderung.

**Die Liste über der Karte ist selbst gebaut**, kein Apple-`.sheet`
mit `presentationDetents`. Ein dauerhaft geöffnetes Sheet legt sich in
iOS über die gesamte App und wäre auch in den anderen Tabs sichtbar.

**Gezogen wird nur am Griff der Liste**, nicht an der Liste selbst.
Beides zu koppeln (Apple-Maps-Verhalten) ist berüchtigt fehleranfällig:
Man schließt dann versehentlich das Sheet, wenn man scrollen wollte.

**Kein Monatskalender im Buchungsablauf.** Ein Kalenderblatt zeigt vor
allem Tage, an denen nichts geht. Waagerechte Tagesleiste plus direkt
sichtbare Uhrzeiten zeigen, was geht.

---

## Phase 2 — Echte Daten (Supabase)

Ziel: Die Shops kommen aus dem Internet statt aus `MockData.swift`, und
Buchungen überleben den App-Neustart.

**Warum Supabase und nicht CloudKit?**
CloudKit ist an Apple gebunden. Barbershops und Bewertungen sind aber Daten,
die *allen* Nutzern gehören und die später auch eine Android-App oder ein
Web-Dashboard für Friseure lesen können soll. Supabase ist eine normale
PostgreSQL-Datenbank — leichter zu verstehen, überall abrufbar, kostenlos
in der Startgröße.

- [ ] Supabase-Projekt anlegen, **beide** als Mitglieder einladen
- [ ] `supabase/schema.sql` einspielen (liegt fertig im Repo)
- [ ] Die 5 Testshops als echte Datensätze anlegen
- [ ] `supabase-swift` als Paket einbinden
- [ ] `SupabaseBarbershopRepository` schreiben
- [ ] In `AppModel` eine Zeile tauschen → fertig
- [ ] Schlüssel in `Secrets.xcconfig` auslagern (nicht ins Git!)

> Die Umstellung ist deshalb so klein, weil die ganze App nur das Protokoll
> `BarbershopRepository` kennt und nicht, woher die Daten kommen.

---

## Phase 3 — Nutzerkonten

Ziel: Man kann selbst Bewertungen schreiben und sieht seine Termine überall.

- [ ] **Sign in with Apple** über Supabase Auth
- [ ] Profil-Tab mit Name und Bild
- [ ] Bewertung schreiben (nur nach einem tatsächlich wahrgenommenen Termin)
- [ ] Eigene Termine absagen
- [ ] Favoriten

> ⚠️ **Sign in with Apple braucht das kostenpflichtige Apple Developer Program
> (99 €/Jahr).** Mit einer kostenlosen Apple-ID funktioniert es nicht.
> Falls das erst mal zu früh ist: Supabase kann auch E-Mail-Login oder
> "Magic Link" — reicht zum Entwickeln völlig.

---

## Phase 4 — Die Friseur-Seite

Bis hier war die App rein für Kunden. Jetzt kommt die andere Hälfte dazu —
und das ist der Punkt, an dem CUTZ von einem Verzeichnis zu einem echten
Buchungssystem wird.

- [ ] Friseur-Modus: eigene Öffnungszeiten und Leistungen pflegen
- [ ] Terminübersicht für den Shop
- [ ] Push-Nachricht bei neuer Buchung
- [ ] **Google-Kalender des Friseurs anbinden** (siehe unten)

### Zur Kalender-Frage

Das war eine der ursprünglichen Anforderungen, und dahinter stecken
zwei völlig verschiedene Dinge:

**a) Der Kunde will den Termin in seinem Kalender haben** → *schon erledigt.*
Wir schreiben über EventKit in den Standardkalender des iPhones. Welcher das
ist, hat der Nutzer selbst in den iOS-Einstellungen festgelegt — iCloud,
Google, Outlook, egal. iOS synchronisiert von dort automatisch weiter.
Kein Google-Login, keine Zugangsdaten, kein Server.

**b) Freie Zeiten sollen aus dem Google-Kalender des Friseurs kommen**
→ *deutlich aufwendiger, deshalb Phase 4.*
Das braucht echte Google-OAuth-Anmeldung, das Verwalten und Erneuern von
Zugangstokens, einen Server, der diese Tokens sicher aufbewahrt, sowie
Behandlung von Sonderfällen wie Serienterminen und mehreren Kalendern
pro Konto. Machbar — aber nichts, womit man anfängt.

**Unsere Datenbank bleibt in beiden Fällen die maßgebliche Quelle** für das,
was frei ist. Der Google-Kalender wird später nur zusätzlich abgeglichen.
Andersherum — Google als alleinige Wahrheit — würde bedeuten, dass die App
bei jedem Google-Ausfall keine Termine mehr anzeigen kann.

---

## Phase 5 — Ausbau

Erst sinnvoll, wenn die App echte Nutzer hat.

- [ ] Fotos der Shops (Supabase Storage)
- [ ] Umkreissuche über PostGIS statt einfacher Koordinatenfilter
- [ ] Marker auf der Karte gruppieren, wenn viele Shops eng beieinander liegen
- [ ] Lokaler Zwischenspeicher mit SwiftData → App startet ohne Ladezeit
- [ ] Push-Erinnerung am Vortag
- [ ] **StoreKit 2** — Abo mit Vorteilen (das Neotaste-Modell)
- [ ] Android

---

## Wer macht was

Aufgeteilt **nach Feature**: Jeder baut sein Stück komplett durch, von der
Oberfläche bis zu den Daten. Vorteil gegenüber einer Trennung in
"Design" und "Datenbank": Niemand wartet auf den anderen, und beide lernen
den ganzen Weg kennen.

| | Finn | Lukas |
|---|---|---|
| **Ordner** | `Features/Discover/` | `Features/Profile/`<br>`Features/Booking/`<br>`Features/Favorites/`<br>`Features/Account/` |
| **Themen** | MapKit, Standort, Filter, Suche | Buchungsablauf, EventKit, Bewertungen, Favoriten |
| **Phase 2** | `SupabaseBarbershopRepository` — Shops laden | Buchungen & Bewertungen speichern |

`Core/` und `App/` gehören beiden. Änderungen dort vorher kurz absprechen —
das sind die einzigen Stellen, an denen ihr euch in die Quere kommen könnt.

> ⚠️ **Der große Umbau hat `Core/` und `App/` deutlich verändert.**
>
> - `RootView` hat jetzt drei Tabs (Favoriten, Entdecken, Termine).
> - `AppModel` hält zusätzlich `favorites`, `location` und `nextSlots`.
> - `BarbershopRepository` kennt `cancelBooking` und `nextAvailableSlots`;
>   `createBooking` nimmt einen Mitarbeiter entgegen. **Alle drei müssen
>   in `SupabaseBarbershopRepository` umgesetzt werden**, sonst
>   kompiliert das Projekt nicht.
> - `Booking` hat `status`, `employeeID` und `employeeName`.
> - `Barbershop` hat `employees` und `portfolioImageURLs`.
> - `MapScreen`, `SearchScreen` und `ShopRow` sind ersatzlos entfallen —
>   sie stecken jetzt in `Features/Discover/` und `Core/UI/BarberCard`.

> ⚠️ **Die App ist jetzt dreisprachig — das betrifft jeden neuen Text.**
>
> - Texte stehen in `CUTZ/Resources/<sprache>.lproj/Localizable.strings`,
>   je einmal für `de`, `en` und `ar`. Der Schlüssel ist der deutsche
>   Satz selbst, `Text("Termin buchen")` funktioniert also unverändert.
> - **Neuer deutscher Text heißt: alle drei Dateien anfassen.** Fehlt
>   ein Eintrag, zeigt iOS stillschweigend den Schlüssel an — also
>   deutschen Text in der englischen App. `LocalizationTests` fängt das ab.
> - `Text(einString)` übersetzt **nicht**, nur `Text("literal")`. Nimmt
>   eine Hilfsfunktion Text entgegen, muss der Parameter
>   `LocalizedStringKey` heißen. Berechnete Texte brauchen
>   `String(localized: "…")`.
> - Der Testlauf steht fest auf Deutsch (`project.yml`, Schema →
>   `test` → `language`). Ohne das richtet sich die App nach dem
>   Rechner, und auf dem englischen Mac bei GitHub wird aus
>   "Heute 18:30" ein "Today 18:30" — 20 Tests waren deswegen rot.
> - Neu: `DistanceText` (Entfernung an einer Stelle formatiert) und
>   `AvailabilityText.shortWeekdayNames` / `longWeekdayNames`.
> - Für Arabisch dreht iOS das Layout. Deshalb überall
>   `leading`/`trailing` statt `left`/`right` und `chevron.forward`
>   statt `chevron.right`.

### Nächste konkrete Schritte

**Beide zuerst:** Xcode installieren, Projekt zum Laufen bringen, App einmal
im Simulator ansehen. Erst danach aufteilen.

**Finn**
1. Auf der Karte nach Preisniveau filtern
2. Karten-Marker gruppieren, wenn sie sich überlappen
3. Suche und Karte verbinden: Tippt man in der Liste auf einen Shop,
   springt die Karte dorthin

**Lukas** — ✅ erledigt
1. [x] Bewertungen nach Sternen filtern und sortieren
2. [x] Im Profil anzeigen, ob gerade geöffnet ist ("Jetzt geöffnet · bis 19:00")
3. [x] Termin absagen
4. [x] Ruhetage in der Tagesauswahl ausgrauen

**Offen für beide — das kann nur am Mac beurteilt werden:**

Der komplette Umbau ist gebaut und die Tests laufen durch, aber **noch
nie hat jemand die App danach im Simulator gesehen.** Grün heißt hier
„kompiliert und rechnet richtig", nicht „sieht gut aus". Zu prüfen:

- [ ] Lässt sich die Liste angenehm hochziehen, rasten die Stufen gut?
- [ ] Ist die Karte unter der Liste noch bedienbar?
- [ ] Sind die Farbverläufe als Bildersatz akzeptabel oder störend?
- [ ] Ist der Buchungsablauf wirklich in wenigen Sekunden durch?
- [ ] Stimmen die Abstände auf kleinen Geräten (iPhone SE)?
- [ ] Sieht die App auf **Arabisch** vernünftig aus? iOS spiegelt das
      Layout, aber ob alles sitzt, sieht man erst im Simulator.
      (Einstellungen → CUTZ → Sprache)
- [ ] Die arabische Übersetzung ist Hocharabisch und stammt nicht von
      einem Muttersprachler. Vor einer Veröffentlichung drüberlesen
      lassen — vor allem die Anrede, das deutsche „du" lässt sich
      nicht eins zu eins übertragen.

---

## Festgelegte Entscheidungen

| Thema | Entscheidung | Begründung |
|---|---|---|
| Sprache | Swift / SwiftUI | Native App, beste Integration von Karte und Kalender |
| Mindest-iOS | 17.0 | `@Observable` und die neue Map-API; deckt fast alle iPhones ab |
| Xcode | 16 | Kleinstes nötiges macOS-Update (14.5). Neuer bringt uns nichts |
| Testdaten | Kassel | 5 erfundene Shops an echten Adressen |
| Architektur | Feature-Ordner + MVVM | Klare Trennung → wenig Merge-Konflikte zu zweit |
| Projektdatei | XcodeGen (`project.yml`) | `.xcodeproj` im Git bedeutet ständige Merge-Konflikte |
| Backend | Supabase (ab Phase 2) | Normales PostgreSQL, später auch von Android/Web nutzbar |
| Kalender (Kunde) | EventKit | Erreicht Google *und* Apple ohne jede Anmeldung |
| Geld in Cent | `Int` statt `Double` | Bei Kommazahlen sind Rundungsfehler vorprogrammiert |
| Wochentage | 1 = Sonntag … 7 = Samstag | Apples eigene Zählung — Umrechnen ist eine Fehlerquelle |

---

## Bewusst (noch) nicht gemacht

Damit später nachvollziehbar ist, warum etwas fehlt:

- **SwiftData** — erst sinnvoll, wenn es echte Daten zum Zwischenspeichern gibt (Phase 5)
- **CloudKit** — würde uns an Apple binden; Supabase kann dasselbe plattformübergreifend
- **StoreKit 2 / Abos** — ohne Nutzer gibt es nichts zu verkaufen (Phase 5)
- **Keychain** — Supabase Auth verwaltet seine Tokens selbst sicher
- **Echte Bezahlung im Laden** — Bezahlt wird vor Ort beim Friseur
