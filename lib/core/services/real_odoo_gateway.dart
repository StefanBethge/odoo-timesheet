import 'package:odoo_timesheet/core/models/app_models.dart';
import 'package:odoo_timesheet/core/services/odoo_gateway.dart';
import 'package:odoo_timesheet/core/services/odoo_rpc_client.dart';
import 'package:odoo_timesheet/core/utils/formatters.dart';
import 'package:odoo_timesheet/core/utils/fuzzy_search.dart';

class RealOdooGateway implements OdooGateway {
  RealOdooGateway({
    OdooRpcClient Function(AppSettings settings)? clientFactory,
  }) : _clientFactory =
            clientFactory ?? ((settings) => OdooRpcClient(settings: settings));

  final Map<String, List<SearchItem>> _pendingRows = {};
  final Map<String, OdooRpcClient> _clients = {};
  final OdooRpcClient Function(AppSettings settings) _clientFactory;

  @override
  Future<void> validateConnection(AppSettings settings) async {
    _requireConfigured(settings);
    await _client(settings).validateConnection();
  }

  @override
  Future<WeekSnapshot> loadWeek({
    required AppSettings settings,
    required DateTime monday,
  }) async {
    _requireConfigured(settings);
    final client = _client(settings);
    final currentEntries = await client.listTimesheets(
      dateFrom: monday,
      dateTo: addDays(monday, 6),
    );
    final previousMonday = addDays(monday, -7);
    final previousEntries = await client.listTimesheets(
      dateFrom: previousMonday,
      dateTo: addDays(previousMonday, 6),
    );

    final rows = _buildRowsFromTimesheets(monday, currentEntries);
    _mergeHints(rows, _extractHints(previousEntries));
    _mergeHints(rows, _pendingRows[_weekKey(monday)] ?? const []);

    rows.sort((a, b) => a.label.compareTo(b.label));
    return WeekSnapshot(monday: monday, rows: rows);
  }

  @override
  Future<List<SearchItem>> searchItems({
    required AppSettings settings,
    required bool filtered,
    required String query,
  }) async {
    _requireConfigured(settings);
    final client = _client(settings);
    final projects = await client.listProjects(filtered: filtered);
    final tasks = await client.listTasks(projectId: 0, filtered: filtered);

    final items = <SearchItem>[
      ...projects.map(
        (record) => SearchItem(
          kind: SearchItemKind.project,
          company: many2OneName(record['company_id']),
          projectId: record['id'] as int,
          projectName: record['name'] as String? ?? '',
          taskId: null,
          taskName: null,
          extra: many2OneName(record['company_id']),
        ),
      ),
      ...tasks.map(
        (record) => SearchItem(
          kind: SearchItemKind.task,
          company: many2OneName(record['company_id']),
          projectId: many2OneId(record['project_id']),
          projectName: many2OneName(record['project_id']),
          taskId: record['id'] as int,
          taskName: record['name'] as String? ?? '',
          extra: many2OneName(record['project_id']),
        ),
      ),
    ];

    final normalizedQuery = query.toLowerCase().trim();
    if (normalizedQuery.isEmpty) {
      return items;
    }

    return filterSearchItemsFuzzy(items, normalizedQuery);
  }

  @override
  Future<WeekSnapshot> addRow({
    required AppSettings settings,
    required DateTime monday,
    required SearchItem item,
  }) async {
    _requireConfigured(settings);
    final key = _weekKey(monday);
    final existing = _pendingRows.putIfAbsent(key, () => <SearchItem>[]);
    if (!existing.any((entry) => entry.key == item.key)) {
      existing.add(item);
    }
    return loadWeek(settings: settings, monday: monday);
  }

  @override
  Future<WeekSnapshot> createEntry({
    required AppSettings settings,
    required DateTime monday,
    required String rowKey,
    required int dayIndex,
    required EntryDraft draft,
  }) async {
    _requireConfigured(settings);
    final row =
        await _rowForKey(settings: settings, monday: monday, rowKey: rowKey);
    await _client(settings).createTimesheet(
      projectId: row.projectId,
      taskId: row.taskId ?? 0,
      date: addDays(monday, dayIndex),
      description: draft.description,
      hours: draft.hours,
    );
    return loadWeek(settings: settings, monday: monday);
  }

  @override
  Future<WeekSnapshot> updateEntry({
    required AppSettings settings,
    required DateTime monday,
    required String rowKey,
    required int entryId,
    required EntryDraft draft,
  }) async {
    _requireConfigured(settings);
    await _client(settings).updateTimesheet(
      id: entryId,
      fields: {
        'unit_amount': draft.hours,
        'name': draft.description,
      },
    );
    return loadWeek(settings: settings, monday: monday);
  }

  @override
  Future<WeekSnapshot> deleteEntry({
    required AppSettings settings,
    required DateTime monday,
    required String rowKey,
    required int entryId,
  }) async {
    _requireConfigured(settings);
    await _client(settings).deleteTimesheet(entryId);
    return loadWeek(settings: settings, monday: monday);
  }

  @override
  Future<AttendanceStatus> loadAttendance({
    required AppSettings settings,
  }) async {
    _requireConfigured(settings);
    return _client(settings).attendanceStatus();
  }

  @override
  Future<AttendanceStatus> toggleAttendance({
    required AppSettings settings,
  }) async {
    _requireConfigured(settings);
    return _client(settings).toggleAttendance();
  }

  OdooRpcClient _client(AppSettings settings) {
    final key = [
      settings.url,
      settings.database,
      settings.username,
      settings.apiKey,
      settings.webPassword,
      settings.totpSecret,
    ].join('|');

    return _clients.putIfAbsent(
      key,
      () => _clientFactory(settings),
    );
  }

  void _requireConfigured(AppSettings settings) {
    if (!settings.isConfigured) {
      throw StateError('Odoo settings are incomplete.');
    }
  }

  Future<_ResolvedRow> _rowForKey({
    required AppSettings settings,
    required DateTime monday,
    required String rowKey,
  }) async {
    final searchItems = [
      ...(_pendingRows[_weekKey(monday)] ?? const []),
      ..._extractHints(
        await _client(settings).listTimesheets(
          dateFrom: addDays(monday, -7),
          dateTo: addDays(monday, -1),
        ),
      ),
    ];

    final existing =
        searchItems.where((item) => item.key == rowKey).firstOrNull;
    if (existing != null) {
      return _ResolvedRow(
        projectId: existing.projectId,
        taskId: existing.taskId,
      );
    }

    final snapshot = await loadWeek(settings: settings, monday: monday);
    for (final row in snapshot.rows) {
      if (row.key == rowKey) {
        return _ResolvedRow(projectId: row.projectId, taskId: row.taskId);
      }
    }

    throw StateError('Project/task row could not be resolved for create.');
  }
}

List<WeekRow> _buildRowsFromTimesheets(
  DateTime monday,
  List<Map<String, Object?>> records,
) {
  final rowsByKey = <String, WeekRow>{};

  for (final record in records) {
    final projectId = many2OneId(record['project_id']);
    final taskId = many2OneId(record['task_id']);
    final projectName = many2OneName(record['project_id']);
    final taskName = many2OneName(record['task_id']);
    final company = many2OneName(record['company_id']);
    final key = _rowIdentity(company, projectId, taskId, projectName, taskName);
    final row = rowsByKey.putIfAbsent(
      key,
      () => WeekRow(
        key: key,
        company: company,
        projectId: projectId,
        taskId: taskId == 0 ? null : taskId,
        projectName: projectName,
        taskName: taskName.isEmpty ? null : taskName,
        entriesByDay: List.generate(7, (_) => <TimesheetEntry>[]),
      ),
    );

    final date = DateTime.parse(record['date'] as String);
    final dayIndex = calendarDaysBetween(monday, date);
    if (dayIndex < 0 || dayIndex > 6) {
      continue;
    }

    row.entriesByDay[dayIndex].add(
      TimesheetEntry(
        id: record['id'] as int,
        date: date,
        description: record['name'] as String? ?? '',
        hours: _timesheetHours(record['unit_amount']),
        status: record['validated_status'] as String? ?? '',
      ),
    );
  }

  return rowsByKey.values.toList();
}

List<SearchItem> _extractHints(List<Map<String, Object?>> records) {
  final byKey = <String, SearchItem>{};
  for (final record in records) {
    final projectId = many2OneId(record['project_id']);
    final taskId = many2OneId(record['task_id']);
    final company = many2OneName(record['company_id']);
    final projectName = many2OneName(record['project_id']);
    final taskName = many2OneName(record['task_id']);
    final item = SearchItem(
      kind: taskId > 0 ? SearchItemKind.task : SearchItemKind.project,
      company: company,
      projectId: projectId,
      projectName: projectName,
      taskId: taskId > 0 ? taskId : null,
      taskName: taskId > 0 ? taskName : null,
      extra: taskId > 0 ? projectName : company,
    );
    byKey[item.key] = item;
  }
  return byKey.values.toList(growable: false);
}

void _mergeHints(List<WeekRow> rows, List<SearchItem> hints) {
  final existingKeys = rows.map((row) => row.key).toSet();
  for (final item in hints) {
    if (existingKeys.contains(item.key)) {
      continue;
    }
    rows.add(
      WeekRow(
        key: item.key,
        company: item.company,
        projectId: item.projectId,
        taskId: item.taskId,
        projectName: item.projectName,
        taskName: item.taskName,
        entriesByDay: List.generate(7, (_) => <TimesheetEntry>[]),
      ),
    );
    existingKeys.add(item.key);
  }
}

String _rowIdentity(
  String company,
  int projectId,
  int taskId,
  String projectName,
  String taskName,
) {
  if (projectId > 0 || taskId > 0) {
    return '$company|$projectId|$taskId';
  }
  return '$company|$projectName|$taskName';
}

String _weekKey(DateTime monday) {
  return '${monday.year}-${monday.month}-${monday.day}';
}

double _timesheetHours(Object? value) {
  if (value is int) {
    return value.toDouble();
  }
  if (value is double) {
    return value;
  }
  return double.tryParse('$value') ?? 0;
}

class _ResolvedRow {
  const _ResolvedRow({
    required this.projectId,
    required this.taskId,
  });

  final int projectId;
  final int? taskId;
}

extension on Iterable<SearchItem> {
  SearchItem? get firstOrNull => isEmpty ? null : first;
}
