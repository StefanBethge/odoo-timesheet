import 'dart:async';

import 'package:odoo_timesheet/core/models/app_models.dart';
import 'package:odoo_timesheet/core/services/odoo_gateway.dart';

class MockOdooGateway implements OdooGateway {
  final Map<String, WeekSnapshot> _weeks = {};
  int _nextEntryId = 3000;
  AttendanceStatus _attendance = AttendanceStatus(
    clockedIn: true,
    checkIn: DateTime.now().subtract(const Duration(hours: 2, minutes: 35)),
    periods: [
      AttendancePeriod(
        checkIn: DateTime.now().subtract(const Duration(hours: 4, minutes: 15)),
        checkOut:
            DateTime.now().subtract(const Duration(hours: 3, minutes: 15)),
        workedHours: 1,
      ),
      AttendancePeriod(
        checkIn: DateTime.now().subtract(const Duration(hours: 2, minutes: 35)),
        checkOut: null,
        workedHours: 0,
      ),
    ],
  );

  @override
  Future<void> validateConnection(AppSettings settings) async {
    if (!settings.isConfigured) {
      throw StateError('Odoo settings are incomplete.');
    }
  }

  @override
  Future<WeekSnapshot> loadWeek({
    required AppSettings settings,
    required DateTime monday,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final key = monday.toIso8601String();
    return _weeks.putIfAbsent(key, () => _seedWeek(monday));
  }

  @override
  Future<List<SearchItem>> searchItems({
    required AppSettings settings,
    required bool filtered,
    required String query,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final base = [
      const SearchItem(
        kind: SearchItemKind.project,
        company: 'digitalgedacht GmbH',
        projectId: 42,
        projectName: 'Mobile Timesheet',
        taskId: null,
        taskName: null,
        extra: 'digitalgedacht GmbH',
      ),
      const SearchItem(
        kind: SearchItemKind.task,
        company: 'digitalgedacht GmbH',
        projectId: 42,
        projectName: 'Mobile Timesheet',
        taskId: 501,
        taskName: 'Android MVP',
        extra: 'Mobile Timesheet',
      ),
      const SearchItem(
        kind: SearchItemKind.task,
        company: 'nexiles GmbH',
        projectId: 90,
        projectName: 'Internal Platform',
        taskId: 601,
        taskName: 'Code Review',
        extra: 'Internal Platform',
      ),
      const SearchItem(
        kind: SearchItemKind.project,
        company: 'Partner Corp',
        projectId: 77,
        projectName: 'Customer Rollout',
        taskId: null,
        taskName: null,
        extra: 'Partner Corp',
      ),
      const SearchItem(
        kind: SearchItemKind.task,
        company: 'Partner Corp',
        projectId: 77,
        projectName: 'Customer Rollout',
        taskId: 780,
        taskName: 'QA Sweep',
        extra: 'Customer Rollout',
      ),
    ];
    final extras = [
      const SearchItem(
        kind: SearchItemKind.task,
        company: 'Experimental Labs',
        projectId: 11,
        projectName: 'Sandbox',
        taskId: 901,
        taskName: 'Spike',
        extra: 'Sandbox',
      ),
    ];
    final source = filtered ? base : [...base, ...extras];
    final q = query.toLowerCase().trim();
    if (q.isEmpty) {
      return source;
    }
    return source.where((item) {
      return item.name.toLowerCase().contains(q) ||
          item.extra.toLowerCase().contains(q) ||
          item.company.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Future<WeekSnapshot> addRow({
    required AppSettings settings,
    required DateTime monday,
    required SearchItem item,
  }) async {
    final week = await loadWeek(settings: settings, monday: monday);
    if (week.rows.any((row) => row.key == item.key)) {
      return week;
    }
    final rows = [...week.rows];
    rows.add(
      WeekRow(
        key: item.key,
        company: item.company,
        projectId: item.projectId,
        taskId: item.taskId,
        projectName: item.projectName,
        taskName: item.taskName,
        entriesByDay: List.generate(7, (_) => const <TimesheetEntry>[]),
      ),
    );
    rows.sort((a, b) => a.label.compareTo(b.label));
    final updated = WeekSnapshot(monday: week.monday, rows: rows);
    _weeks[monday.toIso8601String()] = updated;
    return updated;
  }

  @override
  Future<WeekSnapshot> createEntry({
    required AppSettings settings,
    required DateTime monday,
    required String rowKey,
    required int dayIndex,
    required EntryDraft draft,
  }) async {
    final week = await loadWeek(settings: settings, monday: monday);
    final updated = _mapRow(week, rowKey, (row) {
      final entries = List<List<TimesheetEntry>>.generate(
        7,
        (index) => List<TimesheetEntry>.from(row.entriesByDay[index]),
      );
      entries[dayIndex].add(
        TimesheetEntry(
          id: _nextEntryId++,
          date: monday.add(Duration(days: dayIndex)),
          description: draft.description,
          hours: draft.hours,
          status: 'draft',
        ),
      );
      return row.copyWith(entriesByDay: entries);
    });
    _weeks[monday.toIso8601String()] = updated;
    return updated;
  }

  @override
  Future<WeekSnapshot> updateEntry({
    required AppSettings settings,
    required DateTime monday,
    required String rowKey,
    required int entryId,
    required EntryDraft draft,
  }) async {
    final week = await loadWeek(settings: settings, monday: monday);
    final updated = _mapRow(week, rowKey, (row) {
      final entries = List<List<TimesheetEntry>>.generate(
        7,
        (index) => List<TimesheetEntry>.from(row.entriesByDay[index]),
      );
      for (var dayIndex = 0; dayIndex < entries.length; dayIndex++) {
        final position =
            entries[dayIndex].indexWhere((entry) => entry.id == entryId);
        if (position != -1) {
          entries[dayIndex][position] = entries[dayIndex][position].copyWith(
            description: draft.description,
            hours: draft.hours,
          );
          break;
        }
      }
      return row.copyWith(entriesByDay: entries);
    });
    _weeks[monday.toIso8601String()] = updated;
    return updated;
  }

  @override
  Future<WeekSnapshot> deleteEntry({
    required AppSettings settings,
    required DateTime monday,
    required String rowKey,
    required int entryId,
  }) async {
    final week = await loadWeek(settings: settings, monday: monday);
    final updated = _mapRow(week, rowKey, (row) {
      final entries = List<List<TimesheetEntry>>.generate(
        7,
        (index) => List<TimesheetEntry>.from(row.entriesByDay[index]),
      );
      for (var dayIndex = 0; dayIndex < entries.length; dayIndex++) {
        entries[dayIndex].removeWhere((entry) => entry.id == entryId);
      }
      return row.copyWith(entriesByDay: entries);
    });
    _weeks[monday.toIso8601String()] = updated;
    return updated;
  }

  @override
  Future<AttendanceStatus> loadAttendance({
    required AppSettings settings,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _attendance;
  }

  @override
  Future<AttendanceStatus> toggleAttendance({
    required AppSettings settings,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (_attendance.clockedIn && _attendance.checkIn != null) {
      final now = DateTime.now();
      final periods = [..._attendance.periods];
      final runningIndex =
          periods.lastIndexWhere((period) => period.checkOut == null);
      if (runningIndex != -1) {
        final startedAt = periods[runningIndex].checkIn;
        periods[runningIndex] = AttendancePeriod(
          checkIn: startedAt,
          checkOut: now,
          workedHours: now.difference(startedAt).inMinutes / 60,
        );
      }
      _attendance = AttendanceStatus(
        clockedIn: false,
        checkIn: null,
        periods: periods,
      );
      return _attendance;
    }

    final now = DateTime.now();
    _attendance = AttendanceStatus(
      clockedIn: true,
      checkIn: now,
      periods: [
        ..._attendance.periods,
        AttendancePeriod(
          checkIn: now,
          checkOut: null,
          workedHours: 0,
        ),
      ],
    );
    return _attendance;
  }

  WeekSnapshot _mapRow(
    WeekSnapshot week,
    String rowKey,
    WeekRow Function(WeekRow row) mapper,
  ) {
    final rows = week.rows
        .map((row) => row.key == rowKey ? mapper(row) : row)
        .toList(growable: false);
    return WeekSnapshot(monday: week.monday, rows: rows);
  }

  WeekSnapshot _seedWeek(DateTime monday) {
    TimesheetEntry entry(
      int id,
      int dayIndex,
      double hours,
      String description,
      String status,
    ) {
      return TimesheetEntry(
        id: id,
        date: monday.add(Duration(days: dayIndex)),
        description: description,
        hours: hours,
        status: status,
      );
    }

    return WeekSnapshot(
      monday: monday,
      rows: [
        WeekRow(
          key: 'digitalgedacht GmbH|42|501',
          company: 'digitalgedacht GmbH',
          projectId: 42,
          taskId: 501,
          projectName: 'Mobile Timesheet',
          taskName: 'Android MVP',
          entriesByDay: [
            [entry(1001, 0, 2.5, 'Architecture sync', 'draft')],
            [entry(1002, 1, 4.0, 'Screen structure', 'validated')],
            [entry(1003, 2, 3.5, 'Wireframes and UX notes', 'draft')],
            const [],
            const [],
            const [],
            const [],
          ],
        ),
        WeekRow(
          key: 'nexiles GmbH|90|601',
          company: 'nexiles GmbH',
          projectId: 90,
          taskId: 601,
          projectName: 'Internal Platform',
          taskName: 'Code Review',
          entriesByDay: [
            const [],
            [entry(1101, 1, 1.5, 'Review and feedback', 'draft')],
            const [],
            [entry(1102, 3, 2.0, 'Regression check', 'draft')],
            const [],
            const [],
            const [],
          ],
        ),
        WeekRow(
          key: 'Partner Corp|77|0',
          company: 'Partner Corp',
          projectId: 77,
          taskId: null,
          projectName: 'Customer Rollout',
          taskName: null,
          entriesByDay: [
            const [],
            const [],
            [entry(1201, 2, 2.0, 'Coordination', 'validated')],
            [entry(1202, 3, 1.0, 'Status update', 'draft')],
            [entry(1203, 4, 3.0, 'Pilot prep', 'draft')],
            const [],
            const [],
          ],
        ),
      ],
    );
  }
}
