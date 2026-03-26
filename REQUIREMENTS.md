# Anforderungen Mobile App

## Ziel

Die bestehende CLI `/Users/stefanbethge/dev/odoo-work-cli` liefert bereits die Odoo-Integration, Datenmodelle und Fachlogik. Die neue App ersetzt vor allem den TUI-Teil durch eine mobile Bedienoberfläche. Zielplattform ist Android als MVP; iOS folgt später mit derselben fachlichen Basis.

## Produktziel

Die App soll Timesheets und Attendance direkt auf dem Smartphone nutzbar machen:

- Wochenübersicht der Arbeitszeiten
- Schnelles Clock-in / Clock-out
- Einträge anlegen, bearbeiten und löschen
- Projekte und Tasks suchen und zur Woche hinzufügen
- Konfiguration direkt in der App statt über lokale TOML-Dateien

## Fachlicher Scope für MVP

### 1. Anmeldung und Einstellungen

Die App benötigt eine Einstellungsansicht für:

- Odoo-URL
- Datenbankname
- Benutzername
- API-Key für XML-RPC-Lese- und Schreibzugriffe
- Web-Passwort für Attendance per JSON-RPC
- optionales TOTP-Secret für 2FA
- Bundesland für deutsche Feiertage
- Grenzwerte für Tages- und Wochenstunden

Zugangsdaten müssen sicher auf dem Gerät gespeichert werden, nicht im Klartext.

### 2. Wochenansicht

Die zentrale Ansicht ist eine mobile Wochenansicht auf Basis der bestehenden TUI-Logik:

- Anzeige Montag bis Sonntag
- Fokus auf aktuelle Woche, Start standardmäßig auf heute
- Navigation zwischen Wochen
- Tagessummen und Wochensumme
- Hervorhebung von heute
- Markierung deutscher Feiertage je Bundesland
- Farb-/Statuslogik für zu wenig, normale und zu viele Stunden

Die TUI-Grid-Darstellung muss für Mobilgeräte neu gedacht werden, z. B. als kombinierte Wochenliste mit Tagesdetail statt als Terminal-Tabelle.

### 3. Projekt-/Task-Zeilen

Die App muss dieselbe Grundlogik wie die TUI übernehmen:

- bestehende Projekt-/Task-Kombinationen der Woche anzeigen
- Projekt-/Task-Kombinationen aus der Vorwoche als Vorschläge merken
- neue Projekt- oder Task-Zeilen per Suche hinzufügen
- Firmenbezug für Labels mitführen

Die Suche muss zwei Modi unterstützen:

- gefiltert gemäß konfigurierter Odoo-Model-Filter
- ungefiltert über alle Projekte und Tasks

### 4. Timesheet-Einträge

Pro Tag und Projekt/Task-Kombination müssen Einträge sichtbar und bearbeitbar sein:

- Detailansicht pro Tag
- Anzeige von ID, Beschreibung, Stunden und Validierungsstatus
- Eintrag anlegen
- Eintrag bearbeiten
- Eintrag löschen

Stundeneingaben müssen sowohl Dezimalwerte (`1.5`) als auch Zeitformat (`1:30`) akzeptieren. Beschreibung ist Pflicht. Projekt oder Task muss eindeutig zuordenbar sein.

### 5. Attendance

Attendance muss aus der CLI fachlich übernommen werden:

- aktuellen Status anzeigen
- Clock-in auslösen
- Clock-out auslösen
- laufende Zeit seit Check-in anzeigen
- heutige Attendance-Perioden anzeigen
- Overnight-Fälle korrekt behandeln

Wichtig: Attendance nutzt andere Zugangsdaten als Timesheets und muss deshalb im Setup klar getrennt sein.

## Nicht-Ziele für das erste MVP

Folgendes ist vorerst nicht erforderlich:

- Port der Terminal-spezifischen Bedienung, Shortcuts oder Help-Overlays
- generische `fields`-Ansicht für beliebige Odoo-Modelle
- vollständige CLI-Parität für alle Shell-Kommandos
- Desktop-/Tablet-optimierte Sonderlayouts
- Offline-Erfassung mit späterem Sync
- iOS-Release im ersten Schritt

## Qualitätsanforderungen

- Schnelle Ladezeiten für Wochenansicht und Suche
- Robuste Fehlerbehandlung bei Auth-, Netzwerk- und Odoo-Fehlern
- Manuelles Refresh der Daten
- Klare Rückmeldungen bei Speichern, Löschen und Clock-in/out
- Sichere Secret-Speicherung per Plattform-Mechanismus

## Offene Punkte vor Umsetzung

- Soll die App nur die TUI-Funktionen abbilden oder später auch weitere CLI-Kommandos wie `whoami`, `projects` und `tasks` als eigene Screens bekommen?
- Sollen erweiterte Modellfilter und `extra_fields` bereits im MVP in der UI pflegbar sein oder zunächst fest in einer Konfiguration liegen?
- Soll die mobile Wochenansicht eher tabellarisch, als Tageslisten-Flow oder als Hybrid umgesetzt werden?
