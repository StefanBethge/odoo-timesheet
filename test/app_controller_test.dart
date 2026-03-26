import 'package:flutter_test/flutter_test.dart';
import 'package:odoo_timesheet/core/app_controller.dart';
import 'package:odoo_timesheet/core/models/app_models.dart';
import 'package:odoo_timesheet/core/services/odoo_gateway.dart';
import 'package:odoo_timesheet/core/services/settings_store.dart';

void main() {
  test('createEntry uses the monday passed by the caller', () async {
    final gateway = _RecordingGateway();
    final controller = AppController(
      settingsStore: MemorySettingsStore(
        AppSettings.empty().copyWith(
          url: 'https://example.invalid',
          database: 'odoo',
          username: 'user@example.invalid',
          apiKey: 'api-key',
          webPassword: 'password',
        ),
      ),
      gateway: gateway,
    );

    await controller.bootstrap();
    final detailMonday = controller.selectedMonday;

    await controller.goToNextWeek();
    expect(controller.selectedMonday, isNot(detailMonday));

    await controller.createEntry(
      monday: detailMonday,
      rowKey: 'row-1',
      dayIndex: 0,
      draft: const EntryDraft(description: 'Test', hours: 1.0),
    );

    expect(gateway.lastCreateMonday, detailMonday);
  });
}

class _RecordingGateway implements OdooGateway {
  DateTime? lastCreateMonday;

  @override
  Future<void> validateConnection(AppSettings settings) async {}

  @override
  Future<WeekSnapshot> loadWeek({
    required AppSettings settings,
    required DateTime monday,
  }) async {
    return WeekSnapshot(monday: monday, rows: const []);
  }

  @override
  Future<List<SearchItem>> searchItems({
    required AppSettings settings,
    required bool filtered,
    required String query,
  }) async {
    return const [];
  }

  @override
  Future<WeekSnapshot> addRow({
    required AppSettings settings,
    required DateTime monday,
    required SearchItem item,
  }) async {
    return WeekSnapshot(monday: monday, rows: const []);
  }

  @override
  Future<WeekSnapshot> createEntry({
    required AppSettings settings,
    required DateTime monday,
    required String rowKey,
    required int dayIndex,
    required EntryDraft draft,
  }) async {
    lastCreateMonday = monday;
    return WeekSnapshot(monday: monday, rows: const []);
  }

  @override
  Future<WeekSnapshot> updateEntry({
    required AppSettings settings,
    required DateTime monday,
    required String rowKey,
    required int entryId,
    required EntryDraft draft,
  }) async {
    return WeekSnapshot(monday: monday, rows: const []);
  }

  @override
  Future<WeekSnapshot> deleteEntry({
    required AppSettings settings,
    required DateTime monday,
    required String rowKey,
    required int entryId,
  }) async {
    return WeekSnapshot(monday: monday, rows: const []);
  }

  @override
  Future<AttendanceStatus> loadAttendance({
    required AppSettings settings,
  }) async {
    return const AttendanceStatus(
      clockedIn: false,
      checkIn: null,
      periods: [],
    );
  }

  @override
  Future<AttendanceStatus> toggleAttendance({
    required AppSettings settings,
  }) async {
    return const AttendanceStatus(
      clockedIn: false,
      checkIn: null,
      periods: [],
    );
  }
}
