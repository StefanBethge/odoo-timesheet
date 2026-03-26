# Technische Architektur

## Technologieentscheidung

Empfehlung: Flutter als gemeinsamer App-Stack fuer Android und spaeter iOS.

Gruende:

- Android-MVP schnell lieferbar
- spaeter iOS ohne zweiten UI-Stack
- Repository ist bereits im Dart-Kontext angelegt

## Architekturprinzip

Die App portiert die Fachlogik der CLI nach Dart. Uebernommen werden:

- Odoo-Datenmodelle
- XML-RPC fuer Timesheets, Projekte und Tasks
- JSON-RPC fuer Attendance
- Stundenparser, Wochenlogik, Feiertagslogik und Suchlogik

Nicht uebernommen wird:

- Terminal-TUI
- Keybinding-Logik
- CLI-spezifische Konfigurationsdateien

## Schichten

### 1. Presentation

- Flutter Screens, Dialoge und Formulare
- State Management pro Feature
- Navigation und UI-spezifische ViewModels

### 2. Application

- Use Cases wie `LoadWeek`, `SearchProjectsAndTasks`, `CreateEntry`, `ClockIn`
- Validierung und Orchestrierung

### 3. Data

- Odoo-Remote-Clients
- Repositories
- Lokaler Settings-Store

## Modulstruktur

```text
lib/
  app/
  core/
    error/
    network/
    storage/
    utils/
  features/
    onboarding/
    settings/
    week/
    entry_detail/
    entry_form/
    search/
    attendance/
  shared/
    widgets/
    models/
```

## API-Design

### XML-RPC Client

Verantwortlich fuer:

- `whoAmI`
- `listProjects`
- `listAllProjects`
- `listTasks`
- `listAllTasks`
- `listTimesheets`
- `createTimesheet`
- `updateTimesheet`
- `deleteTimesheet`

Authentifizierung mit URL, Datenbank, Username und API-Key.

### JSON-RPC Client

Verantwortlich fuer:

- Session-Login
- Attendance-Status
- Clock-in
- Clock-out

Authentifizierung mit Username, Web-Passwort und optional TOTP.

## Lokale Speicherung

Trennung zwischen:

- sichere Secrets in `flutter_secure_storage`
- nicht-sensitive Einstellungen in lokalem App-Store, z. B. `shared_preferences`

Zu speichern:

- URL
- Datenbank
- Username
- API-Key
- Web-Passwort
- TOTP
- Bundesland
- Stundenlimits

## State Management

Empfehlung: Riverpod.

Gruende:

- sauber fuer asynchrone Datenfluesse
- gut testbar
- klar fuer feature-basierte Struktur

Wichtige States:

- `settingsState`
- `weekState`
- `dayDetailState`
- `searchState`
- `attendanceState`

## Fehlerbehandlung

Zentrale Fehlerkategorien:

- Konfigurationsfehler
- Netzwerkfehler
- Authentifizierungsfehler
- Odoo-Fachfehler
- Validierungsfehler

Jeder Fehler wird in eine app-interne Fehlerklasse gemappt und UI-tauglich dargestellt.

## Synchronisationsmodell

Fuer MVP online-first:

- Woche wird bei Oeffnen geladen
- Speichern/Loeschen laedt betroffene Daten neu
- Attendance aktualisiert sich nach Aktion sofort
- kein Offline-Sync im ersten Release

## Tests

- Unit-Tests fuer Parser, Use Cases und Mapper
- Widget-Tests fuer Kern-Screens
- Mock-Tests fuer XML-RPC- und JSON-RPC-Clients
- spaeter Integrationstest fuer Setup -> Woche -> Create/Edit/Delete -> Attendance

## Empfohlene Pakete

- `flutter_riverpod`
- `go_router`
- `dio` oder `http`
- `xml_rpc` oder eigener kleiner XML-RPC-Adapter
- `flutter_secure_storage`
- `shared_preferences`
- `intl`

## Wichtige technische Entscheidung

Die Go-CLI sollte nicht in die App eingebettet werden. Fuer das MVP ist es sauberer, die relevanten Odoo-Calls in Dart nachzubauen und die Fachlogik der CLI gezielt zu portieren. Das reduziert Plattformkomplexitaet und macht Android/iOS langfristig wartbar.
