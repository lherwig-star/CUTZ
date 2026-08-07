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
- [x] Die 5 Testshops als echte Datensätze anlegen → `supabase/seed.sql`
- [ ] `supabase-swift` als Paket einbinden
- [ ] `SupabaseBarbershopRepository` schreiben
- [ ] In `AppModel` eine Zeile tauschen → fertig
- [ ] Schlüssel in `Secrets.xcconfig` auslagern (nicht ins Git!)

> Die Umstellung ist deshalb so klein, weil die ganze App nur das Protokoll
> `BarbershopRepository` kennt und nicht, woher die Daten kommen.

**Beide Dateien sind gegen ein echtes PostgreSQL 16 geprüft**, nicht nur
gelesen: Schema angelegt, Seed zweimal eingespielt (läuft ohne Fehler
und ohne Dubletten durch), Sperre gegen Doppelbuchungen ausgelöst.

Drei Dinge, die man beim Einspielen wissen sollte:

1. **Die Textwerte sind camelCase** — `'skinFade'`, nicht `'skin_fade'`.
   Sie müssen zeichengenau den `rawValue`s der Swift-Enums entsprechen.
   Schreibt man sie in SQL-Schreibweise, schlägt kein Constraint an;
   stattdessen scheitert später der `JSONDecoder` und die Liste in der
   App bleibt einfach leer. Die `check`-Bedingungen fangen das ab.
2. **Die Bewertungen sehen danach anders aus.** In `MockData` steht bei
   Shop 1 „4,7 ★ · 184 Bewertungen" — von Hand gesetzt. Die Datenbank
   rechnet selbst, und zu den 14 eingespielten Bewertungen gibt es auch
   einen Text. Shop 1 steht dann bei 4,25 ★ aus 4 Bewertungen. Kein
   Fehler, sondern der ehrliche Wert.
3. **`reviews.user_id` darf jetzt leer sein.** Vorher `not null` — damit
   ließe sich keine einzige übernommene Bewertung einspielen, denn die
   gehört zu keinem Konto. `author_name` steht jetzt direkt dabei, so
   wie im Swift-Modell auch.

> ⚠️ **Offene Produktfrage: Ein Shop gilt als EIN Stuhl.**
>
> Die Sperre gegen Doppelbuchungen greift pro Shop, nicht pro
> Mitarbeiter — ein Laden mit fünf Barbern kann also nur einen Termin
> um 14:00 annehmen. Die App macht denselben Fehler:
> `MockBarbershopRepository` filtert belegte Zeiten ebenfalls nur über
> `shopID`.
>
> Datenbank und App sagen also dasselbe, nur beide dasselbe Falsche.
> Zu ändern ist das nur gemeinsam, und der schwierige Teil ist nicht
> das SQL: Buchungen ohne festen Barber („egal welcher") müssten beim
> Speichern trotzdem einem Stuhl zugewiesen werden, und der
> `SlotCalculator` müsste wissen, wie viele es davon gibt. Details
> stehen im Kommentar bei `bookings_no_overlap`.

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

## Die Friseurseite (CUTZ Partner)

Bis Phase 1 war CUTZ eine reine Kunden-App. Jetzt gibt es die andere
Hälfte — den Bereich, in dem ein Friseur seinen Laden verwaltet.

**Keine zweite App, sondern eine Wahl beim ersten Start.** Getrennte
Apps (wie Uber und Uber Driver) sind der übliche Weg, kosten aber zwei
App-Store-Einträge, zwei Freigaben bei jeder Änderung und zwei
Zertifikate. Wichtiger: Ein Friseur hört von CUTZ meistens durch einen
Kunden — er lädt dieselbe App und findet die Business-Seite sofort.
Genau so soll sich das Produkt verbreiten. Deshalb steht im
Kundenprofil auch ein Hinweis „Bist du Friseur?".

**Anmelden darf sich jeder selbst, freigegeben wird von Hand.** Ohne
diese Hürde könnte jeder einen fremden Laden für sich beanspruchen und
dessen Termine verwalten, ohne dass der Inhaber es merkt. Bei einer
Buchungs-App ist das kein theoretischer Schaden — wer die Termine
kontrolliert, kontrolliert das Geschäft. Ein Anruf unter der
hinterlegten Nummer reicht als Prüfung.

### Was steht

- [x] Rollenwahl beim ersten Start, jederzeit umschaltbar
- [x] Laden anmelden, Wartezustand, Ablehnung
- [x] **Übersicht** mit maßstäblicher Tagesleiste
- [x] **Laufkundschaft** direkt in die freie Lücke eintragen
- [x] **Kalender** mit Sperrzeiten (Pause, Urlaub, früher zu)
- [x] **Buchungen** durchsuchbar, absagen
- [x] **Kunden** — leitet sich aus den Buchungen ab, nichts zu pflegen
- [x] **Profil**: Stammdaten, Öffnungszeiten, Leistungen mit Reihenfolge

### Was fehlt — und warum es fehlt

- [ ] **`shop_members` im Schema.** Es gibt noch kein Konzept „wem
      gehört dieser Laden". Der Freigabestatus liegt vorerst in
      `UserDefaults` und ist damit ausdrücklich **keine** Berechtigung,
      sondern eine Attrappe.
- [ ] **Die Regel für Buchungen umstellen.** Laut `schema.sql` darf
      Buchungen nur lesen, wer sie selbst angelegt hat
      (`auth.uid() = user_id`). Ein Friseur ist nie der Kunde —
      **„Übersicht" wäre nach dem Umstieg auf Supabase leer.** Das
      fällt erst auf, wenn die Oberfläche schon steht.
- [ ] **Sperrzeiten in die Datenbank.** `TimeBlock` gibt es nur im
      Code. Dazu muss der `SlotCalculator` sie abziehen, sonst wirken
      sie nur auf der Friseurseite und die Kunden buchen weiter.
- [ ] **Mehrere Stühle.** Siehe die Warnung bei Phase 2 — für einen
      Laden mit mehreren Barbern ist die Friseurseite sonst sichtbar
      kaputt. Das ist damit keine Fußnote mehr, sondern Voraussetzung.
- [ ] **Bilder hochladen.** Braucht Supabase Storage (Phase 5). Der
      Abschnitt im Profil sagt das auch, statt einen Knopf anzubieten,
      der nichts tut.
- [ ] **Push bei neuer Buchung.** Braucht Server und das
      kostenpflichtige Apple-Programm.
- [ ] **Statistiken.** Die Kachel führt noch nirgendwohin. Bewusst:
      Ohne echte Daten wäre jede Zahl erfunden.

> **Ein Behelf, der wieder verschwinden muss:** Im Wartezustand steht
> ein Knopf „Zum Ausprobieren selbst freigeben". Ohne ihn käme man nie
> auf die Friseurseite, weil niemand freigeben kann. Er ist als Behelf
> beschriftet und fällt mit Phase 2 weg.

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
- [ ] Sieht die App auf **Arabisch** vernünftig aus? Das Layout wird
      gespiegelt, aber ob alles sitzt, sieht man erst im Simulator.
      Umschalten in der App: Profil → Einstellungen → Sprache.
- [ ] Wechselt die Sprache wirklich **sofort**, ohne Neustart? Die
      Tests können nur prüfen, dass die richtigen Texte vorliegen —
      nicht, dass SwiftUI die Oberfläche danach neu zeichnet.
- [ ] Die arabische Übersetzung ist Hocharabisch und stammt nicht von
      einem Muttersprachler. Vor einer Veröffentlichung drüberlesen
      lassen — vor allem die Anrede, das deutsche „du" lässt sich
      nicht eins zu eins übertragen.
- [ ] **Die ganze Friseurseite.** Sie ist gebaut und die Tests laufen,
      aber gesehen hat sie noch niemand. Besonders die Tagesleiste:
      Die Kacheln sitzen dort maßstäblich an ihrer Uhrzeit, und ob
      das bei dicht liegenden Terminen noch lesbar ist, zeigt nur der
      Simulator. Umschalten: Profil → „Bist du Friseur?", dann im
      Wartezustand „Zum Ausprobieren selbst freigeben".

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
