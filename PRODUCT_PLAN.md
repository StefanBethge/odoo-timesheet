# Produktplan Android MVP

## Zielbild

Die App ersetzt die bestehende TUI durch eine mobile Oberfläche. Fachlich bleibt der vorhandene Odoo-Zugriff aus der CLI maßgeblich. Android ist die erste Zielplattform. iOS folgt später mit derselben Struktur.

## MVP-Priorisierung

### P0: zwingend für das erste nutzbare Release

- Onboarding und Einstellungen für Odoo-URL, Datenbank, Username, API-Key, Web-Passwort und optional TOTP
- Sichere Speicherung der Zugangsdaten auf dem Gerät
- Laden der aktuellen Woche mit Navigation zu Vor- und Folgewoche
- Anzeige von Tages- und Wochensummen
- Anzeige bestehender Projekt-/Task-Zeilen der Woche
- Detailansicht pro Tag mit allen Einträgen
- Eintrag anlegen, bearbeiten und löschen
- Suche nach Projekten und Tasks
- Attendance-Status anzeigen
- Clock-in und Clock-out auslösen
- Robuste Fehleranzeigen für Auth, Netzwerk und Odoo-Fehler

### P1: wichtig kurz nach MVP

- Vorschlagszeilen aus der Vorwoche übernehmen
- Gefilterte und ungefilterte Suche umschaltbar
- Feiertagsmarkierung nach Bundesland
- Farbige Stundenwarnungen für Unter- und Überstunden
- Pull-to-refresh oder explizite Aktualisierung
- Leichte Validierungshilfen in Formularen

### P2: später

- iOS-Release
- UI für erweiterte Modellfilter und `extra_fields`
- Zusätzliche Screens für `whoami`, reine Projektlisten oder Tasklisten
- Offline-Erfassung mit späterem Sync
- Tablet-spezifische Layouts

## User Stories mit Akzeptanzkriterien

### 1. App einrichten

Als Nutzer möchte ich meine Odoo-Zugangsdaten in der App hinterlegen, damit ich ohne CLI arbeiten kann.

Akzeptanzkriterien:

- Ich kann URL, Datenbank, Username, API-Key, Web-Passwort und optional TOTP eingeben.
- Die App prüft, ob Pflichtfelder fehlen.
- Geheimnisse werden sicher gespeichert.
- Nach erfolgreicher Konfiguration kann die App Daten laden.

### 2. Aktuelle Woche sehen

Als Nutzer möchte ich meine aktuelle Arbeitswoche sehen, damit ich meinen Stand sofort erfasse.

Akzeptanzkriterien:

- Die App öffnet standardmäßig auf der aktuellen Woche.
- Die Woche zeigt Montag bis Sonntag.
- Pro Tag ist die Summe sichtbar.
- Die Wochensumme ist sichtbar.
- Der aktuelle Tag ist optisch hervorgehoben.

### 3. Zwischen Wochen wechseln

Als Nutzer möchte ich zwischen Wochen wechseln, damit ich vergangene oder kommende Einträge prüfen kann.

Akzeptanzkriterien:

- Ich kann zur Vorwoche und zur Folgewoche wechseln.
- Beim Wechsel werden die Daten neu geladen.
- Ein Ladezustand ist sichtbar.

### 4. Einträge eines Tages prüfen

Als Nutzer möchte ich pro Tag die einzelnen Timesheet-Einträge sehen, damit ich Details kontrollieren kann.

Akzeptanzkriterien:

- Aus einer Wochenzeile kann ich den Tag öffnen.
- Ich sehe ID, Beschreibung, Stunden und Validierungsstatus.
- Leere Tage werden als leer dargestellt statt als Fehler.

### 5. Eintrag anlegen

Als Nutzer möchte ich einen neuen Zeiteintrag erstellen, damit ich Arbeitszeit mobil erfassen kann.

Akzeptanzkriterien:

- Ich kann für einen Tag einen Eintrag auf einer Projekt-/Task-Zeile anlegen.
- Stunden akzeptieren `1.5` und `1:30`.
- Beschreibung ist Pflicht.
- Nach dem Speichern wird die Woche aktualisiert.

### 6. Eintrag bearbeiten

Als Nutzer möchte ich einen vorhandenen Eintrag ändern, damit Korrekturen mobil möglich sind.

Akzeptanzkriterien:

- Ich kann Stunden und Beschreibung bearbeiten.
- Ungültige Eingaben werden klar abgewiesen.
- Nach dem Speichern sehe ich die aktualisierten Werte.

### 7. Eintrag löschen

Als Nutzer möchte ich einen Eintrag löschen, damit falsche Buchungen entfernt werden können.

Akzeptanzkriterien:

- Löschen erfordert eine Bestätigung.
- Nach dem Löschen wird die Woche neu geladen.
- Wenn eine Zeile danach keine Einträge mehr hat, bleibt sie im UI nur dann erhalten, wenn sie als Vorschlags- oder manuell hinzugefügte Zeile geführt wird.

### 8. Projekt oder Task suchen

Als Nutzer möchte ich Projekte und Tasks suchen, damit ich schnell neue Zeilen hinzufügen kann.

Akzeptanzkriterien:

- Die Suche findet Projekte und Tasks in einer gemeinsamen Ergebnisliste.
- Ergebnisse zeigen genug Kontext, z. B. Firma oder Projektname.
- Ein Treffer kann der Wochenansicht hinzugefügt werden.
- Bereits vorhandene Zeilen werden nicht doppelt erzeugt.

### 9. Attendance steuern

Als Nutzer möchte ich meinen Attendance-Status sehen und umschalten, damit ich Arbeitsbeginn und Arbeitsende mobil erfassen kann.

Akzeptanzkriterien:

- Die App zeigt klar, ob ich eingestempelt bin.
- Die laufende Zeit seit Check-in ist sichtbar.
- Clock-in und Clock-out sind direkt auslösbar.
- Heutige Attendance-Perioden werden angezeigt.

## Screen- und Navigationsstruktur

### 1. Splash / Startprüfung

Prüft, ob eine gültige Konfiguration vorhanden ist.

- mit Konfiguration: weiter zur Wochenansicht
- ohne Konfiguration: weiter zu Einstellungen/Onboarding

### 2. Einstellungen / Onboarding

Erster Screen für Setup und später auch über Navigation erreichbar.

Sektionen:

- Verbindung: URL, Datenbank, Username
- Credentials: API-Key, Web-Passwort, TOTP
- Lokale Regeln: Bundesland, Stundenlimits
- Aktionen: Verbindung testen, speichern

### 3. Home = Wochenansicht

Zentraler Hauptscreen des MVP.

Inhalte:

- Header mit Kalenderwoche und Wechsel Vor/Zurück
- Attendance-Status mit Clock-in/out-Aktion
- Liste der Projekt-/Task-Zeilen
- Pro Zeile Tagessummen und Wochensumme
- Aktion zum Hinzufügen neuer Projekt-/Task-Zeilen

### 4. Tagesdetail

Öffnet aus der Wochenansicht für eine Zeile und einen Tag.

Inhalte:

- Datum und Projekt-/Task-Kontext
- Liste der Einträge
- Button zum Hinzufügen
- Aktionen Bearbeiten und Löschen pro Eintrag

### 5. Eintrag-Formular

Modal oder eigener Screen.

Felder:

- Stunden
- Beschreibung
- optional Anzeige von Projekt und Task als Read-only-Kontext

### 6. Suche

Modaler Suchscreen.

Inhalte:

- Suchfeld
- Toggle für gefiltert / alle
- Trefferliste für Projekte und Tasks
- Auswahl fügt Zeile zur Woche hinzu

### 7. Attendance-Detail

Kann im MVP als Bottom Sheet oder Unterseite umgesetzt werden.

Inhalte:

- aktueller Status
- laufende Dauer
- Liste heutiger Attendance-Perioden

## Empfohlene MVP-Reihenfolge für die Umsetzung

1. Einstellungen und sichere Secret-Speicherung
2. Odoo-Client-Anbindung und Verbindungsprüfung
3. Wochenansicht mit Read-only-Daten
4. Tagesdetail
5. Eintrag anlegen/bearbeiten/löschen
6. Projektsuche/Tasksuche
7. Attendance
8. Feiertage, Farben und Vorwochen-Vorschläge
