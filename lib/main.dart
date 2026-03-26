import 'package:flutter/widgets.dart';
import 'package:odoo_timesheet/app/app.dart';
import 'package:odoo_timesheet/core/app_controller.dart';
import 'package:odoo_timesheet/core/services/app_unlock_service.dart';
import 'package:odoo_timesheet/core/services/real_odoo_gateway.dart';
import 'package:odoo_timesheet/core/services/settings_store.dart';

void main() {
  final controller = AppController(
    settingsStore: LocalSettingsStore(),
    gateway: RealOdooGateway(),
    unlockService: LocalAuthUnlockService(),
  );

  runApp(OdooTimesheetApp(controller: controller));
}
