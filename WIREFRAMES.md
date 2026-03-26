# Wireframes

## 1. Splash / Startpruefung

Zweck:

- pruefen, ob eine gueltige Konfiguration vorhanden ist

Layout:

- Logo oder App-Name oben
- mittiger Ladeindikator
- kurzer Status wie `Konfiguration wird geprueft`

Navigation:

- bei gueltiger Konfiguration -> Home
- sonst -> Onboarding

## 2. Onboarding / Einstellungen

Zweck:

- Erstkonfiguration und spaetere Pflege der Verbindung

Layout:

- AppBar mit `Einrichtung`
- Scrollbare Form
- Bereich `Odoo Verbindung`
- Bereich `Zugangsdaten`
- Bereich `Lokale Regeln`
- Sticky-Aktionsleiste unten

Felder:

- URL
- Datenbank
- Username
- API-Key
- Web-Passwort
- TOTP optional
- Bundesland
- Tages- und Wochenlimits

Aktionen:

- `Verbindung testen`
- `Speichern`

## 3. Home / Wochenansicht

Zweck:

- zentrale Arbeitsansicht fuer den MVP

Layout:

- AppBar mit Kalenderwoche und Settings-Icon
- oberhalb eine kompakte Attendance-Karte
- darunter Wochen-Navigation mit links/rechts
- darunter scrollbare Liste der Projekt-/Task-Zeilen
- Floating Action Button fuer `Projekt/Task hinzufuegen`

Zeilenaufbau:

- linke Seite: Projekt-/Task-Label
- rechte Seite: Mon bis Sun kompakt als Chips oder kleine Karten
- ganz rechts oder unten: Wochensumme

Interaktion:

- Tap auf Tageswert -> Tagesdetail
- Tap auf Attendance-Karte -> Attendance-Detail

## 4. Tagesdetail

Zweck:

- einzelne Eintraege eines Tages anzeigen

Layout:

- Header mit Datum und Projekt-/Task-Kontext
- Liste der Eintraege als Cards
- pro Card: Stunden, Status, Beschreibung, ID
- Bottom Action fuer `Eintrag hinzufuegen`

Interaktion:

- Tap auf Card -> Bearbeiten
- Swipe oder Menue -> Loeschen

## 5. Eintrag-Formular

Zweck:

- neuen Eintrag anlegen oder vorhandenen bearbeiten

Layout:

- Modal Sheet oder eigener Screen
- Titel `Eintrag anlegen` oder `Eintrag bearbeiten`
- Read-only Kontext fuer Datum und Projekt/Task
- Eingabefeld `Stunden`
- Eingabefeld `Beschreibung`
- Fehlerhinweis direkt unter dem Feld

Aktionen:

- `Abbrechen`
- `Speichern`

## 6. Suche Projekt / Task

Zweck:

- neue Zeilen in die Woche aufnehmen

Layout:

- Suchfeld oben mit Fokus beim Oeffnen
- Toggle `Gefiltert` / `Alle`
- Ergebnisliste gruppiert nach `Projekte` und `Tasks`

Eintrag:

- Typ-Badge `P` oder `T`
- Name
- Zusatzkontext wie Firma oder Projekt

Interaktion:

- Tap auf Treffer -> Zeile zur Woche hinzufuegen und zur Wochenansicht zurueck

## 7. Attendance-Detail

Zweck:

- Clock-in/out und heutige Attendance transparent machen

Layout:

- Statuskarte mit `Clocked in` oder `Clocked out`
- laufende Dauer prominent
- Hauptaktion `Clock in` oder `Clock out`
- Liste heutiger Perioden darunter

Eintrag:

- Check-in
- Check-out
- Dauer

## Navigationsfluss

```text
Splash
  -> Onboarding
  -> Home

Home
  -> Settings
  -> Search
  -> Day Detail
  -> Attendance Detail

Day Detail
  -> Entry Form

Settings
  -> Home
```

## UI-Hinweise fuer Android-MVP

- Fokus auf einhaendige Bedienung
- wichtigste Aktionen im unteren Bereich erreichbar
- Wochenansicht nicht als starre Tabelle bauen
- lieber vertikale Liste mit kompakten Tageszellen
- Loading, Error und Empty States in jedem Hauptscreen explizit gestalten
