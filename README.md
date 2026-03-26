# Odoo Timesheet

Android-first Flutter MVP for mobile Odoo timesheets and attendance. The app
replaces the CLI TUI with a smartphone-oriented interface and uses the existing
CLI repository as the functional reference.

## Current state

This repository already contains:

- Flutter app scaffold for Android and iOS
- onboarding and settings flow with local persistence
- weekly mobile timesheet view
- day detail with create, edit, and delete flows
- project/task search flow
- attendance detail with clock in/out interaction
- Dart port of the Odoo XML-RPC and JSON-RPC client paths used by the CLI
- reproducible Android SDK setup via `android-commandlinetools`

The app now talks to Odoo through the Dart gateway used in
[`lib/core/services/real_odoo_gateway.dart`](./lib/core/services/real_odoo_gateway.dart).
`MockOdooGateway` remains in the repository for tests and local isolation only.

## Tooling with Mise

The repository uses `mise` for the Flutter toolchain and recurring commands.

### Initial setup

```bash
mise trust
mise install
mise run setup
```

### Platform prerequisites

- Flutter SDK is managed through `mise`
- Android builds require a local Android SDK and a configured `ANDROID_HOME`
- iOS builds require Xcode and signing on macOS

This repository is configured for the Homebrew-installed Android SDK command
line tools under `/opt/homebrew/share/android-commandlinetools`.

### Common commands

```bash
mise run format
mise run analyze
mise run test
mise run devices
mise run emulators
mise run emulator-start
mise run run
mise run run-android
mise run build
mise run install-apk
```

### Android emulator

This repository is preconfigured for a local Android emulator named
`odoo-timesheet-api-34`.

```bash
mise run emulators
mise run emulator-start
mise run run-android
```

Use `mise run run` when you want device selection. Use `mise run run-android`
for the default emulator without prompts.

The last verified APK output is:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Project structure

```text
lib/
  app/                 App root and theme
  core/                controller, models, services, utils
  features/            settings, home, day detail, search, attendance
test/                  widget tests
```

## Documentation

- [AGENTS.md](./AGENTS.md)
- [DEVELOPMENT.md](./DEVELOPMENT.md)
- [REQUIREMENTS.md](./REQUIREMENTS.md)
- [PRODUCT_PLAN.md](./PRODUCT_PLAN.md)
- [IMPLEMENTATION_BACKLOG.md](./IMPLEMENTATION_BACKLOG.md)
- [TECH_ARCHITECTURE.md](./TECH_ARCHITECTURE.md)
- [WIREFRAMES.md](./WIREFRAMES.md)
