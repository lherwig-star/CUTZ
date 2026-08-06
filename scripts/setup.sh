#!/usr/bin/env bash
#
# CUTZ — Projekt einrichten
#
# Erzeugt die CUTZ.xcodeproj aus project.yml.
# Immer ausführen nach:
#   - dem ersten Klonen des Projekts
#   - "git pull", wenn jemand neue Dateien hinzugefügt hat
#   - dem eigenen Anlegen einer neuen Swift-Datei
#
# Aufruf:  ./scripts/setup.sh

set -euo pipefail   # bricht bei Fehlern sofort ab, statt weiterzumachen

cd "$(dirname "$0")/.."   # ins Projekt-Hauptverzeichnis wechseln

echo "▸ Prüfe Voraussetzungen …"

if ! command -v xcodegen >/dev/null 2>&1; then
    echo ""
    echo "  ✗ XcodeGen fehlt."
    echo "    Installieren mit:  brew install xcodegen"
    echo ""
    exit 1
fi

if ! xcode-select -p >/dev/null 2>&1 || [[ "$(xcode-select -p)" == *CommandLineTools* ]]; then
    echo ""
    echo "  ! Xcode ist nicht als aktive Entwicklerumgebung gesetzt."
    echo "    Das Projekt wird trotzdem erzeugt, bauen kannst du es aber erst,"
    echo "    wenn Xcode installiert und ausgewählt ist:"
    echo ""
    echo "      sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
    echo ""
fi

echo "▸ Erzeuge CUTZ.xcodeproj aus project.yml …"
xcodegen generate

echo ""
echo "✓ Fertig. Jetzt öffnen mit:"
echo ""
echo "    open CUTZ.xcodeproj"
echo ""
