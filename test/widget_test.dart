import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odoo_timesheet/app/app.dart';
import 'package:odoo_timesheet/core/app_controller.dart';
import 'package:odoo_timesheet/core/models/app_models.dart';
import 'package:odoo_timesheet/core/services/app_unlock_service.dart';
import 'package:odoo_timesheet/core/services/mock_odoo_gateway.dart';
import 'package:odoo_timesheet/core/services/settings_store.dart';

void main() {
  testWidgets('shows onboarding when no settings are configured',
      (tester) async {
    final controller = AppController(
      settingsStore: MemorySettingsStore(),
      gateway: MockOdooGateway(),
    );

    await tester.pumpWidget(OdooTimesheetApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Einrichtung'), findsOneWidget);
    expect(find.text('Odoo Verbindung'), findsOneWidget);
  });

  testWidgets('settings screen tolerates invalid saved bundesland values',
      (tester) async {
    final controller = AppController(
      settingsStore:
          MemorySettingsStore(AppSettings.empty().copyWith(bundesland: '')),
      gateway: MockOdooGateway(),
    );

    await tester.pumpWidget(OdooTimesheetApp(controller: controller));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Einrichtung'), findsOneWidget);
  });

  testWidgets('shows unlock screen and unlocks with the Odoo password',
      (tester) async {
    final controller = AppController(
      settingsStore: MemorySettingsStore(
        AppSettings.empty().copyWith(
          url: 'https://example.invalid',
          database: 'odoo',
          username: 'user@example.invalid',
          apiKey: 'api-key',
          webPassword: 'secret',
          lockEnabled: true,
        ),
      ),
      gateway: MockOdooGateway(),
      unlockService: _FakeUnlockService(),
    );

    await tester.pumpWidget(OdooTimesheetApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('App entsperren'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'secret');
    await tester.tap(find.text('Mit Passwort entsperren'));
    await tester.pumpAndSettle();

    expect(find.text('Wochenansicht'), findsOneWidget);
  });
}

class _FakeUnlockService implements AppUnlockService {
  @override
  Future<bool> authenticateWithBiometrics() async => false;

  @override
  Future<bool> isBiometricAvailable() async => false;
}
