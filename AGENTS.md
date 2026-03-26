# Repository Guidelines

## Project Structure & Module Organization

This repository is currently a minimal scaffold. At the moment it contains IntelliJ project metadata in `.idea/` and the module file `odoo-timesheet.iml`, but no Dart package files, source tree, or tests yet.

As implementation is added, keep the layout conventional:

- `lib/` for application code
- `test/` for unit and integration tests
- `bin/` for entrypoints or scripts
- `assets/` for static fixtures or bundled resources

Avoid committing editor-specific files beyond the existing shared IntelliJ configuration. Local workspace files such as `.idea/workspace.xml` should stay untracked.

## Build, Test, and Development Commands

There is no `pubspec.yaml` yet, so build and test commands are not active today. Once the Dart package is initialized, use standard tooling:

- `dart pub get` to install dependencies
- `dart analyze` to run static analysis
- `dart test` to execute the test suite
- `dart format .` to format all Dart sources

If Odoo integration scripts are added later, place them under `bin/` and document any environment requirements beside the script or in `README.md`.

## Coding Style & Naming Conventions

Use 2-space indentation and keep code formatted with `dart format`. Follow Dart naming rules:

- `snake_case.dart` for files
- `PascalCase` for classes and enums
- `camelCase` for methods, variables, and parameters

Prefer small, focused libraries in `lib/`, and keep side effects at the edges of the codebase.

## Testing Guidelines

Use the `test` package for automated coverage. Name test files to mirror the implementation file with a `_test.dart` suffix, for example `lib/timesheet/client.dart` and `test/timesheet/client_test.dart`.

Add tests for each new public behavior and run `dart test` before opening a pull request.

## Commit & Pull Request Guidelines

This repository has no commit history yet, so there is no established message pattern to copy. Start with short, imperative commit subjects such as `Add Odoo API client`.

Pull requests should include:

- a short summary of the change
- linked issue or task context, if any
- test notes describing what was verified
- screenshots only when UI output is introduced
