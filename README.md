# CUTZ ✂️

Barbershops finden, bewerten und Termine buchen — wie Neotaste, aber für Friseure.

Native iOS-App in **Swift / SwiftUI**.

---

## Was die App aktuell kann (Phase 1)

| Feature | Status | Wer |
|---|---|---|
| Karte mit allen Shops + Standort | ✅ | Finn |
| Suchliste mit Filter & Sortierung | ✅ | Finn |
| Shop-Profil mit Leistungen & Öffnungszeiten | ✅ | Lukas |
| Bewertungen anzeigen | ✅ | Lukas |
| Terminbuchung + Kalendereintrag | ✅ | Lukas |
| Echte Daten aus der Cloud | ⏳ Phase 2 | zusammen |
| Login / eigene Bewertungen schreiben | ⏳ Phase 3 | zusammen |

> Phase 1 läuft komplett mit **Testdaten** (`CUTZ/Core/Data/MockData.swift`).
> Kein Server, kein Login, kein Internet nötig. Gebuchte Termine sind nach
> einem App-Neustart wieder weg — das ist so gewollt.

Der komplette Fahrplan steht in **[PLAN.md](PLAN.md)**.

---

## Einrichten

### 1. Xcode installieren

Ohne Xcode geht gar nichts — Swift-Apps lassen sich nur damit bauen.

**Wir nutzen Xcode 16.** Das ist die kleinste Änderung, die funktioniert:
Es reicht ein macOS-Update innerhalb von Sonoma (14.5+), kein Sprung auf
eine neue Hauptversion. Für alles, was CUTZ macht — SwiftUI, MapKit,
EventKit, iOS 17 als Ziel — bringt ein neueres Xcode nichts.

1. **macOS aktualisieren** auf 14.5 oder neuer
   → Systemeinstellungen › Allgemein › Softwareupdate
2. **Xcode aus dem App Store laden** (kostenlos, ca. 10 GB, dauert eine Weile).
   Der App Store bietet automatisch die neueste Version an, die zu eurem
   macOS passt.
3. Xcode einmal öffnen und die Zusatzkomponenten installieren lassen.
4. Im Terminal die Entwicklerumgebung umstellen:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

> Falls der App Store Xcode als "nicht kompatibel" meldet: ältere Versionen
> gibt es unter [developer.apple.com/download/all](https://developer.apple.com/download/all/)
> (kostenlose Apple-ID genügt). Gesucht ist dann **Xcode 16.2**.

### 2. Projekt klonen und öffnen

```bash
git clone https://github.com/lherwig-star/CUTZ.git && cd CUTZ && brew install xcodegen && ./scripts/setup.sh && open CUTZ.xcodeproj
```

In Xcode oben links einen Simulator wählen (z. B. *iPhone 16*) und **⌘R** drücken.

### 3. Auf dem eigenen iPhone testen (optional)

1. iPhone per Kabel anschließen und entsperren.
2. In Xcode: *CUTZ* im Projektnavigator → Tab **Signing & Capabilities**
3. Bei **Team** die eigene Apple-ID auswählen (kostenlos, "Personal Team").
4. Gerät oben auswählen und ⌘R.

> Mit einer kostenlosen Apple-ID läuft die App **7 Tage**, danach muss man sie
> neu aufspielen. Für den Anfang völlig ausreichend.

---

## Wichtig zu wissen

### Die `.xcodeproj` liegt bewusst NICHT im Git

Sie wird aus [`project.yml`](project.yml) erzeugt.

**Warum?** Die Datei `project.pbxproj` in einer `.xcodeproj` ist riesig und
unlesbar. Wenn Finn und Lukas gleichzeitig eine neue Swift-Datei anlegen, gibt
es dort garantiert einen Merge-Konflikt, den man kaum auflösen kann. Mit
XcodeGen bearbeiten wir stattdessen eine kleine, gut lesbare YAML-Datei.

**Praktisch heißt das:**

```bash
./scripts/setup.sh
```

… nach jedem `git pull` und nach jeder neu angelegten Datei ausführen.

### Neue Swift-Datei anlegen

Datei irgendwo unter `CUTZ/` anlegen → `./scripts/setup.sh` → fertig.
Sie wird automatisch eingesammelt, `project.yml` muss man dafür nicht anfassen.

---

## Projektaufbau

```
CUTZ/
├── App/                  Einstieg, Tab-Leiste, globaler Zustand
│   ├── CutzApp.swift        @main — hier startet die App
│   ├── RootView.swift       die Tab-Leiste unten
│   └── AppModel.swift       geteilter Zustand (Shop-Liste)
│
├── Core/                 ⚠️ Gemeinsam — Änderungen bitte absprechen
│   ├── Models/              Barbershop, BarberService, Review, Booking …
│   ├── Data/                Repository (Datenquelle) + Testdaten
│   ├── Services/            LocationManager
│   └── UI/                  wiederverwendete Bausteine (RatingStars, ShopRow)
│
└── Features/             ✅ Hier arbeitet jeder für sich
    ├── Map/                 → Finn
    ├── Search/              → Finn
    ├── Profile/             → Lukas
    └── Booking/             → Lukas
```

Die Aufteilung ist bewusst so geschnitten, dass Finn und Lukas fast nie
dieselbe Datei anfassen. Merge-Konflikte entstehen dadurch praktisch nur
noch in `Core/` — und da reden wir vorher kurz.

---

## Zusammen arbeiten (Git)

Nie direkt auf `main` arbeiten. Immer ein eigener Branch:

```bash
git checkout main && git pull && git checkout -b feature/kartenfilter
```

Committen und hochladen:

```bash
git add -A && git commit -m "Filter für Preisniveau auf der Karte" && git push -u origin HEAD
```

Danach auf GitHub einen Pull Request aufmachen, der andere schaut kurz drüber,
dann mergen. So sieht jeder, was der andere gebaut hat.

**Branch-Namen:**
`feature/…` für Neues · `fix/…` für Fehlerbehebungen

---

## Tests

```bash
xcodebuild test -project CUTZ.xcodeproj -scheme CUTZ -destination 'platform=iOS Simulator,name=iPhone 16'
```

Oder in Xcode einfach **⌘U**.

Getestet wird gezielt die Logik, bei der Fehler nicht auffallen —
vor allem `SlotCalculator` (Terminberechnung, Doppelbuchungen).
Views testen wir nicht, die sieht man ja.
