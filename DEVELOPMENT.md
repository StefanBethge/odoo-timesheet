# Development Guide

## Prerequisites

- `mise`
- Android SDK for APK builds
- Xcode and CocoaPods for iOS builds on macOS

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
mise run pods
mise run run-ios
mise run install-apk
```

## Release-oriented commands

```bash
mise run build
mise run build-ios
mise run build-ios-simulator
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

## iOS setup

The repository now contains a committed [`Podfile`](./ios/Podfile) and can be
built for iOS once local Apple tooling is installed.

1. Install Xcode from the App Store.
2. Select the active developer directory:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

3. Install CocoaPods and fetch iOS dependencies:

```bash
brew install cocoapods
mise run pods
```

4. Start the simulator and run the app:

```bash
open -a Simulator
mise run run
```

Choose the iPhone simulator in Flutter's device picker. For unsigned local
build validation, use `mise run build-ios` or `mise run build-ios-simulator`.

## Security notes

- Android disables app backups in [`AndroidManifest.xml`](./android/app/src/main/AndroidManifest.xml).
- iOS secrets are stored in Keychain with `unlocked_this_device` in
  [`settings_store.dart`](./lib/core/services/settings_store.dart), so they do
  not migrate to another device backup or restore.

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
