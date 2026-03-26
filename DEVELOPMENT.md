# Development Guide

## Prerequisites

- `mise`
- Android SDK for APK builds
- Xcode for iOS builds on macOS

## First-time setup

```bash
mise trust
mise install
mise run setup
```

## Daily workflow

```bash
mise run format
mise run analyze
mise run test
mise run devices
mise run emulators
mise run emulator-start
mise run run
mise run run-android
mise run install-apk
```

## Release-oriented commands

```bash
mise run build
mise run build-ios
```

`mise run build` currently requires a valid Android SDK in the environment.
This repository is set up for `/opt/homebrew/share/android-commandlinetools`.

## Android emulator

The default local emulator is `odoo-timesheet-api-34` based on Android 34
Google APIs ARM64. The repository `mise` config points Flutter to the emulator
location under `~/.config/.android/avd`.

```bash
mise run emulators
mise run emulator-start
mise run run-android
```

## Code map

- `lib/app/`: app bootstrap and theme
- `lib/core/`: controller, models, formatters, local services
- `lib/features/`: settings, home, attendance, search, and day detail screens
- `test/`: widget tests

## Current implementation boundary

The app now uses the real Dart Odoo gateway in
[`lib/core/services/real_odoo_gateway.dart`](./lib/core/services/real_odoo_gateway.dart).
`MockOdooGateway` in
[`lib/core/services/mock_odoo_gateway.dart`](./lib/core/services/mock_odoo_gateway.dart)
is still useful for tests and isolated UI work.

The current Dart backend already ports:

- XML-RPC timesheet, project, and task calls
- JSON-RPC attendance session flow
- shared parsing and validation logic from the CLI

## Recommended next implementation step

Deepen the CLI parity feature-by-feature:

1. add an explicit connection-test action in the settings UI
2. port configurable model filters from the CLI config layer
3. add richer attendance edge-case handling and dedicated tests
4. bring week hints and pending-row behavior to full TUI parity
5. add integration tests against a controllable Odoo test instance
