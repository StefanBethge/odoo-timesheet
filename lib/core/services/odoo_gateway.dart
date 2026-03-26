import 'package:odoo_timesheet/core/models/app_models.dart';

abstract class OdooGateway {
  Future<void> validateConnection(AppSettings settings);

  Future<WeekSnapshot> loadWeek({
    required AppSettings settings,
    required DateTime monday,
  });

  Future<List<SearchItem>> searchItems({
    required AppSettings settings,
    required bool filtered,
    required String query,
  });

  Future<WeekSnapshot> addRow({
    required AppSettings settings,
    required DateTime monday,
    required SearchItem item,
  });

  Future<WeekSnapshot> createEntry({
    required AppSettings settings,
    required DateTime monday,
    required String rowKey,
    required int dayIndex,
    required EntryDraft draft,
  });

  Future<WeekSnapshot> updateEntry({
    required AppSettings settings,
    required DateTime monday,
    required String rowKey,
    required int entryId,
    required EntryDraft draft,
  });

  Future<WeekSnapshot> deleteEntry({
    required AppSettings settings,
    required DateTime monday,
    required String rowKey,
    required int entryId,
  });

  Future<AttendanceStatus> loadAttendance({
    required AppSettings settings,
  });

  Future<AttendanceStatus> toggleAttendance({
    required AppSettings settings,
  });
}
