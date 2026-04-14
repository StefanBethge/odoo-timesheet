# Odoo Timesheet

Flutter MVP for mobile Odoo timesheets and attendance on Android and iOS. The
app replaces the CLI TUI with a smartphone-oriented interface and uses the
existing CLI repository as the functional reference.

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
- iOS project files including `Podfile`, Face ID permission, and unsigned build support

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
- iOS builds require Xcode, CocoaPods, and signing on macOS

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
mise run pods
mise run run-ios
mise run build
mise run install-apk
mise run build-ios
mise run build-ios-simulator
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

## iOS development

Install Xcode and CocoaPods on macOS, then prepare iOS dependencies:

```bash
mise run pods
open -a Simulator
mise run run
```

Use `mise run run` and select the iPhone simulator in Flutter. For CI-style
unsigned validation builds, use:

```bash
mise run build-ios
mise run build-ios-simulator
```

Secrets are stored in the iOS Keychain with `unlocked_this_device`, so they do
not migrate to another device through backups or restores.

The last verified APK output is:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## GitHub Actions and Android releases

The repository is now ready for GitHub-based Android CI and release delivery:

- `.github/workflows/android-ci.yml` runs on pushes and pull requests
- `.github/workflows/android-release.yml` builds signed Android releases on Git tags like `v1.0.0`
- release assets are uploaded to the GitHub Releases page so they can be downloaded directly from GitHub

### One-time GitHub setup

1. Create an empty GitHub repository.
2. Add the remote and push the existing branch.

```bash
git remote add origin git@github.com:<owner>/<repo>.git
git push -u origin HEAD
```

3. Optionally add these GitHub repository secrets under `Settings > Secrets and variables > Actions` if you want a dedicated Android release keystore in CI:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

You can create the Base64 payload from a local keystore with:

```bash
base64 -i my-release-key.jks | pbcopy
```

If these secrets are present, the workflow writes a temporary
`android/key.properties` file in CI and uses it to sign both the APK and the
AAB. If they are missing, the release workflow still runs and falls back to the
debug signing config from the Android project so GitHub release downloads still
work.

### Release process

1. Update `version:` in [`pubspec.yaml`](./pubspec.yaml).
2. Commit and push the change.
3. Create a matching Git tag, for example `v1.0.0`.
4. Push the tag to GitHub.

```bash
git tag v1.0.0
git push origin v1.0.0
```

The release workflow verifies that the Git tag matches the app version from
`pubspec.yaml`, builds a signed `app-release.apk` and `app-release.aab`, and
publishes both files plus SHA-256 checksum files to the GitHub release page.

Anyone can then download the release artifacts from:

```text
https://github.com/<owner>/<repo>/releases
```

If the release upload fails with a permissions error, set
`Settings > Actions > General > Workflow permissions` to `Read and write
permissions`.

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
