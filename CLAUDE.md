# CUTZ — Hinweise für Claude

Native iOS-App (Swift/SwiftUI): Barbershops finden, bewerten, Termine buchen.
"Neotaste für Friseure."

Zwei Entwickler: **Finn** (Karte, Suche) und **Lukas** (Profil, Buchung).
**Beide sind Programmier-Anfänger** — bitte entsprechend arbeiten:

- Kommentare auf **Deutsch**, und zwar zum *Warum*, nicht zum *Was*
- Dateien klein halten, lieber eine Datei mehr
- Keine fortgeschrittenen Patterns ohne Not (kein Combine, keine
  Property Wrapper von Hand, keine Generics wo ein konkreter Typ reicht)
- Wenn ein Konzept neu ist, kurz im Kommentar erklären
- Antworten auf Deutsch

## Aufbau

```
CUTZ/App/        Einstieg (CutzApp), Tab-Leiste (RootView), AppModel
CUTZ/Core/       Gemeinsam: Models, Data (Repository), Services, UI-Bausteine
CUTZ/Features/   Discover/ · Profile/ · Booking/ · Favorites/ · Account/
CUTZTests/       Tests zu allem, was ohne Oberfläche prüfbar ist
supabase/        schema.sql für Phase 2
```

Drei Tabs: **Favoriten · Entdecken · Termine.** Entdecken ist der Start.
Das Nutzerprofil (`Account/`) hängt am Knopf oben rechts, nicht in der
Tab-Leiste.

**Wiederverwendbare Bausteine liegen in `Core/UI/`** — `BarberCard`,
`RatingStars`, `FavoriteButton`, `ShopImage`. Bevor du eine neue Karte
oder Zeile baust: erst dort nachsehen.

## Wichtige Regeln

**Xcode-Projekt wird generiert.** `CUTZ.xcodeproj` ist gitignored und entsteht
aus `project.yml`. Nach dem Anlegen neuer Dateien `./scripts/setup.sh`
ausführen. Niemals die `.xcodeproj` von Hand bearbeiten oder committen.

**Info.plist wird ebenfalls generiert** — aus dem `info:`-Block in
`project.yml`. Neue Berechtigungen dort eintragen, nicht in der Plist.

**Datenquelle ist ausgetauschbar.** Die App kennt nur das Protokoll
`BarbershopRepository`. Aktuell liefert `MockBarbershopRepository` Testdaten.
In Phase 2 kommt `SupabaseBarbershopRepository` dazu — getauscht wird an
genau einer Zeile in `AppModel`. Diese Trennung bitte nicht aufweichen:
keine Netzwerkaufrufe direkt aus Views.

**Feature-Ordner sind Eigentum.** Beim Arbeiten an einem Feature nach
Möglichkeit nur den eigenen Ordner anfassen. Änderungen in `Core/` oder
`App/` betreffen beide Entwickler und sollten explizit erwähnt werden.

**Logik gehört nicht in Views.** Alles, was man ohne Bildschirm prüfen
kann, liegt in einem eigenen Typ mit statischen Funktionen und hat
Tests: `SlotCalculator`, `ReviewFiltering`, `BarberFiltering`,
`BarberSearch`, `AvailabilityText`, `OpeningStatus`. Views zeigen nur an.

**Keine Formatierung über `.formatted()` bei Datum und Wochentag.** Das
richtet sich nach der Region des Geräts, nicht nach der App-Sprache.
Die Namen stehen als übersetzbare Texte in `AvailabilityText`.

**Die App spricht Deutsch, Englisch und Arabisch.** Texte liegen in
`CUTZ/Resources/<sprache>.lproj/Localizable.strings`. Der Schlüssel ist
der deutsche Satz selbst — `Text("Termin buchen")` funktioniert also
ohne Zutun.

Drei Fallstricke:

1. **`Text(einString)` übersetzt NICHT**, nur `Text("literal")`. Nimmt
   eine Hilfsfunktion Text entgegen, muss der Parameter
   `LocalizedStringKey` heißen, nicht `String`.
2. **Berechnete Texte** (in Aufzählungen, `if`-Zweigen, Rückgabewerten)
   brauchen `String(localized: "…")`.
3. **Ändert man einen deutschen Text**, ändert sich der Schlüssel — dann
   greifen `en` und `ar` nicht mehr und englische Nutzer sehen Deutsch.
   Beide Dateien mitziehen. `LocalizationTests` fängt das ab.

Für Arabisch dreht iOS das Layout automatisch. Deshalb überall
`leading`/`trailing` statt `left`/`right`, und `chevron.forward`
statt `chevron.right` — nur die spiegeln mit.

## Konventionen

- Geldbeträge immer als `Int` in **Cent** (`priceCents`), nie `Double`
- Uhrzeiten in Öffnungszeiten als **Minuten seit Mitternacht** (`Int`)
- Wochentage nach Apples Zählung: **1 = Sonntag … 7 = Samstag**
- Mindest-iOS: **17.0** (`@Observable`, neue MapKit-API sind erlaubt)
- Nutzertexte auf Deutsch, Code-Bezeichner auf Englisch
- Zeitzone/Locale: `de_DE`, Europe/Berlin

## Stand

Phase 1 fertig (Testdaten, kein Backend). Fahrplan: `PLAN.md`.

## Bauen und testen

```bash
./scripts/setup.sh
xcodebuild test -project CUTZ.xcodeproj -scheme CUTZ -destination 'platform=iOS Simulator,name=iPhone 16'
```

Ohne installiertes Xcode lässt sich nur die Syntax prüfen:
`swiftc -parse <datei>.swift`
