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
CUTZ/Features/   Map/ + Search/ (Finn) · Profile/ + Booking/ (Lukas)
CUTZTests/       Tests, aktuell nur SlotCalculator
supabase/        schema.sql für Phase 2
```

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
