# CUTZ — Projektplan

Stand: 6. August 2026

Grundidee: **Neotaste für Friseure.** Barbershops entdecken, Bewertungen
lesen, direkt einen Termin buchen — der dann automatisch im eigenen Kalender
landet.

Leitprinzip: **erst einfach, dann komplex.** Jede Phase ergibt eine App, die
man vorzeigen kann. Nichts wird auf Vorrat gebaut.

---

## Die drei Kernfunktionen

1. **Karte** — Shops mit Standort, antippbar
2. **Suche** — dieselben Shops als durchsuchbare Liste
3. **Profil + Buchung** — Bewertungen sehen, Termin buchen, Kalendereintrag

---

## Phase 1 — Das Gerüst ✅ *fertig*

Alles läuft mit Testdaten. Kein Server, kein Login, kein Internet.

Warum zuerst so? Weil man dann in wenigen Tagen eine App auf dem eigenen
iPhone hat, die sich echt anfühlt. Erst wenn feststeht, wie sie aussehen und
sich bedienen soll, ist klar, was die Datenbank überhaupt können muss.
Andersherum baut man meistens am Bedarf vorbei.

- [x] Datenmodelle: `Barbershop`, `BarberService`, `Review`, `Booking`, `OpeningHour`
- [x] `BarbershopRepository` als Protokoll — die Naht zum späteren Backend
- [x] Karte mit Markern, Standortfreigabe, Vorschaukarte
- [x] Suchliste mit Textsuche und Sortierung (Bewertung / Entfernung / Preis)
- [x] Shop-Profil: Leistungen, Öffnungszeiten, Adresse, Route
- [x] Bewertungen anzeigen
- [x] Buchung: Leistung → Tag → Uhrzeit → bestätigen
- [x] Kalendereintrag über EventKit
- [x] Tests für die Terminberechnung

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
| **Ordner** | `Features/Map/`<br>`Features/Search/` | `Features/Profile/`<br>`Features/Booking/` |
| **Themen** | MapKit, Standort, Filter, Sortierung | Formulare, EventKit, Bewertungen |
| **Phase 2** | `SupabaseBarbershopRepository` — Shops laden | Buchungen & Bewertungen speichern |

`Core/` und `App/` gehören beiden. Änderungen dort vorher kurz absprechen —
das sind die einzigen Stellen, an denen ihr euch in die Quere kommen könnt.

### Nächste konkrete Schritte

**Beide zuerst:** Xcode installieren, Projekt zum Laufen bringen, App einmal
im Simulator ansehen. Erst danach aufteilen.

**Finn**
1. Auf der Karte nach Preisniveau filtern
2. Karten-Marker gruppieren, wenn sie sich überlappen
3. Suche und Karte verbinden: Tippt man in der Liste auf einen Shop,
   springt die Karte dorthin

**Lukas**
1. Bewertungen nach Sternen filtern und sortieren
2. Im Profil anzeigen, ob gerade geöffnet ist ("Jetzt geöffnet · bis 19:00")
3. Termin absagen

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
