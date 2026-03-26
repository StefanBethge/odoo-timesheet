# Umsetzungs-Backlog

## Epic 1: Projektgrundlage

### T1 Flutter-Projekt initialisieren

- Flutter-App fuer Android und spaeter iOS anlegen
- Paketstruktur fuer `core/`, `features/`, `shared/` vorbereiten
- Basis-Build fuer Android lokal startbar machen

Abnahme:

- `flutter run` startet die App auf Android
- Debug- und Release-Build laufen

### T2 Basis-Infrastruktur einrichten

- Routing, Logging, Fehlerbehandlung und Konfigurationssystem aufsetzen
- HTTP-/RPC-Client-Struktur vorbereiten
- Secure Storage anbinden

Abnahme:

- App hat zentrale Fehlerbehandlung
- Secrets koennen lokal sicher gespeichert und gelesen werden

## Epic 2: Setup und Verbindung

### T3 Onboarding- und Settings-Screen bauen

- Felder fuer URL, Datenbank, Username, API-Key, Web-Passwort, TOTP
- Bundesland und Stundenlimits erfassbar machen
- Validierung fuer Pflichtfelder

Abnahme:

- Ungueltige Eingaben werden blockiert
- Konfiguration bleibt nach App-Neustart erhalten

### T4 Verbindungspruefung implementieren

- Test der XML-RPC-Verbindung
- Test der Attendance-Authentifizierung ueber JSON-RPC

Abnahme:

- Nutzer erhaelt klares Feedback bei Erfolg oder Fehler

## Epic 3: Wochenansicht

### T5 Wochen-Daten laden und darstellen

- Aktuelle Woche laden
- Navigation Vorwoche/Folgewoche
- Tages- und Wochensummen darstellen

Abnahme:

- Wochenwechsel laedt korrekt neue Daten
- Heute ist visuell hervorgehoben

### T6 Projekt-/Task-Zeilenmodell umsetzen

- Zeilen fuer Projekt/Task-Kombinationen aufbauen
- Manuell hinzugefuegte Zeilen lokal im State erhalten
- Vorwochen-Hints vorbereiten

Abnahme:

- Bestehende und manuell hinzugefuegte Zeilen werden stabil angezeigt

## Epic 4: Tagesdetails und Bearbeitung

### T7 Tagesdetail-Screen bauen

- Eintraege fuer ausgewaehlten Tag und Zeile anzeigen
- Status, Stunden, Beschreibung und ID anzeigen

Abnahme:

- Leere Tage werden korrekt dargestellt

### T8 Eintrag anlegen und bearbeiten

- Formular fuer Stunden und Beschreibung
- `1.5` und `1:30` unterstuetzen
- Reload nach Speichern

Abnahme:

- Neuer Eintrag erscheint nach Speichern in Woche und Detail
- Bearbeiteter Eintrag zeigt neue Werte

### T9 Eintrag loeschen

- Loeschbestaetigung
- Reload nach Loeschen

Abnahme:

- Eintrag verschwindet aus Detail und Wochenansicht

## Epic 5: Suche

### T10 Projekt-/Task-Suche implementieren

- Gemeinsame Suche fuer Projekte und Tasks
- Anzeige mit Kontext wie Firma oder Projekt
- Auswahl fuegt Zeile hinzu

Abnahme:

- Vorhandene Zeilen werden nicht doppelt angelegt

### T11 Gefiltert/Alle umschaltbar machen

- Odoo-Filter beruecksichtigen
- Toggle fuer ungefilterte Suche

Abnahme:

- Beide Modi liefern sichtbar unterschiedliche Datenmengen

## Epic 6: Attendance

### T12 Attendance-Status anzeigen

- Aktuellen Status und laufende Dauer darstellen
- Heutige Attendance-Perioden anzeigen

Abnahme:

- Clocked-in und clocked-out sind klar unterscheidbar

### T13 Clock-in / Clock-out umsetzen

- Aktionen direkt aus Home
- Fehler und Erfolgsfeedback

Abnahme:

- Status aktualisiert sich ohne App-Neustart

## Epic 7: Polishing

### T14 Feiertage und Stundenwarnungen

- Feiertage nach Bundesland markieren
- Tages- und Wochenlimits farblich bewerten

### T15 Refresh, Loading und Error States

- Pull-to-refresh oder expliziter Refresh
- Leere, ladende und fehlerhafte Zustaende konsistent gestalten

## Empfohlene Reihenfolge

1. T1-T4
2. T5-T7
3. T8-T10
4. T12-T13
5. T11, T14, T15
