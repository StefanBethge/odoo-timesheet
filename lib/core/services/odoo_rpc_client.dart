import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:odoo_timesheet/core/models/app_models.dart';
import 'package:odoo_timesheet/core/services/json_rpc_session.dart';
import 'package:odoo_timesheet/core/services/xml_rpc_codec.dart';

class OdooRpcClient {
  OdooRpcClient({
    required this.settings,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final AppSettings settings;
  final http.Client _httpClient;
  int? _userId;
  JsonRpcSession? _jsonSession;

  Future<void> validateConnection() async {
    await whoAmI();
    await attendanceStatus();
  }

  Future<Map<String, Object?>> whoAmI() async {
    final users = await searchRead(
      model: 'res.users',
      domain: [
        ['login', '=', settings.username],
      ],
      fields: const ['id', 'name', 'login', 'email', 'company_id'],
      limit: 1,
    );

    if (users.isEmpty) {
      throw StateError('Authenticated Odoo user could not be found.');
    }
    return users.first;
  }

  Future<List<Map<String, Object?>>> listProjects({
    required bool filtered,
  }) {
    return searchRead(
      model: 'project.project',
      domain: filtered ? _projectDomain() : const [],
      fields: const [
        'id',
        'name',
        'active',
        'partner_id',
        'company_id',
        'stage_id',
        'user_id'
      ],
    );
  }

  Future<List<Map<String, Object?>>> listTasks({
    required int projectId,
    required bool filtered,
  }) {
    final domain = <List<Object?>>[
      if (projectId > 0) ['project_id', '=', projectId],
      if (filtered) ..._taskDomain(),
    ];

    return searchRead(
      model: 'project.task',
      domain: domain,
      fields: const [
        'id',
        'name',
        'active',
        'project_id',
        'stage_id',
        'company_id'
      ],
    );
  }

  Future<List<Map<String, Object?>>> listTimesheets({
    required DateTime dateFrom,
    required DateTime dateTo,
  }) {
    return searchRead(
      model: 'account.analytic.line',
      domain: [
        ['date', '>=', _formatDate(dateFrom)],
        ['date', '<=', _formatDate(dateTo)],
        ['user_id.login', '=', settings.username],
      ],
      fields: const [
        'id',
        'date',
        'project_id',
        'task_id',
        'name',
        'unit_amount',
        'employee_id',
        'validated_status',
        'company_id',
      ],
    );
  }

  Future<int> createTimesheet({
    required int projectId,
    required int taskId,
    required DateTime date,
    required String description,
    required double hours,
  }) async {
    final response = await executeKw(
      model: 'account.analytic.line',
      method: 'create',
      args: [
        {
          'project_id': projectId,
          if (taskId > 0) 'task_id': taskId,
          'date': _formatDate(date),
          'name': description,
          'unit_amount': hours,
        },
      ],
    );

    if (response is int) {
      return response;
    }
    throw StateError('Unexpected response from create timesheet.');
  }

  Future<void> updateTimesheet({
    required int id,
    required Map<String, Object?> fields,
  }) async {
    await executeKw(
      model: 'account.analytic.line',
      method: 'write',
      args: [
        [id],
        fields,
      ],
    );
  }

  Future<void> deleteTimesheet(int id) async {
    await executeKw(
      model: 'account.analytic.line',
      method: 'unlink',
      args: [
        [id],
      ],
    );
  }

  Future<AttendanceStatus> attendanceStatus() async {
    final employeeId = await _findEmployeeId();
    final now = DateTime.now();
    final todayStartUtc = DateTime.utc(now.year, now.month, now.day);
    final tomorrowStartUtc = todayStartUtc.add(const Duration(days: 1));

    final todayRecords = await searchRead(
      model: 'hr.attendance',
      domain: [
        ['employee_id', '=', employeeId],
        ['check_in', '>=', _formatDateTimeUtc(todayStartUtc)],
        ['check_in', '<', _formatDateTimeUtc(tomorrowStartUtc)],
      ],
      fields: const [
        'id',
        'employee_id',
        'check_in',
        'check_out',
        'worked_hours'
      ],
    );

    final openRecords = await searchRead(
      model: 'hr.attendance',
      domain: [
        ['employee_id', '=', employeeId],
        ['check_in', '<', _formatDateTimeUtc(todayStartUtc)],
        ['check_out', '=', false],
      ],
      fields: const [
        'id',
        'employee_id',
        'check_in',
        'check_out',
        'worked_hours'
      ],
    );

    final periods = <AttendancePeriod>[
      ...openRecords.map(_attendancePeriodFromRecord),
      ...todayRecords.map(_attendancePeriodFromRecord),
    ];

    DateTime? openCheckIn;
    for (final period in periods) {
      if (period.checkOut == null) {
        openCheckIn = period.checkIn;
      }
    }

    return AttendanceStatus(
      clockedIn: openCheckIn != null,
      checkIn: openCheckIn,
      periods: periods,
    );
  }

  Future<AttendanceStatus> toggleAttendance() async {
    final session = _jsonSession ??= JsonRpcSession(
      baseUrl: settings.url,
      database: settings.database,
      username: settings.username,
      password: settings.webPassword,
      totpSecret: settings.totpSecret,
    );
    await session.call('/hr_attendance/systray_check_in_out', const {});
    return attendanceStatus();
  }

  Future<List<Map<String, Object?>>> searchRead({
    required String model,
    required List<List<Object?>> domain,
    required List<String> fields,
    int? limit,
  }) async {
    final result = await executeKw(
      model: model,
      method: 'search_read',
      args: [domain],
      kwargs: {
        'fields': fields,
        if (limit != null) 'limit': limit,
      },
    );

    if (result is! List) {
      return const [];
    }

    return result
        .whereType<Map>()
        .map(
          (item) => item.map(
            (key, value) => MapEntry(key.toString(), value),
          ),
        )
        .toList(growable: false);
  }

  Future<Object?> executeKw({
    required String model,
    required String method,
    required List<Object?> args,
    Map<String, Object?> kwargs = const {},
  }) async {
    final userId = await _authenticate();
    return _xmlCall(
      service: 'object',
      methodName: 'execute_kw',
      params: [
        settings.database,
        userId,
        settings.apiKey,
        model,
        method,
        args,
        kwargs,
      ],
    );
  }

  Future<int> _authenticate() async {
    if (_userId != null) {
      return _userId!;
    }
    final response = await _xmlCall(
      service: 'common',
      methodName: 'authenticate',
      params: [
        settings.database,
        settings.username,
        settings.apiKey,
        <String, Object?>{},
      ],
    );
    if (response is int && response > 0) {
      _userId = response;
      return response;
    }
    throw StateError('Odoo XML-RPC authentication failed.');
  }

  Future<Object?> _xmlCall({
    required String service,
    required String methodName,
    required List<Object?> params,
  }) async {
    final uri = Uri.parse('${settings.url}/xmlrpc/2/$service');
    final response = await _httpClient.post(
      uri,
      headers: const {'content-type': 'text/xml'},
      body: XmlRpcCodec.encodeMethodCall(methodName, params),
    );

    if (response.statusCode >= 400) {
      throw StateError(
        'Odoo XML-RPC request failed with status ${response.statusCode}.',
      );
    }

    return XmlRpcCodec.decodeMethodResponse(utf8.decode(response.bodyBytes));
  }

  Future<int> _findEmployeeId() async {
    final response = await searchRead(
      model: 'hr.employee',
      domain: [
        ['user_id.login', '=', settings.username],
      ],
      fields: const ['id'],
      limit: 1,
    );
    if (response.isEmpty) {
      throw StateError('No employee record found for the configured user.');
    }
    final id = response.first['id'];
    if (id is int) {
      return id;
    }
    throw StateError('Employee ID has an unexpected type.');
  }

  AttendancePeriod _attendancePeriodFromRecord(Map<String, Object?> record) {
    final checkIn = _parseOdooDateTime(record['check_in']);
    final rawCheckOut = record['check_out'];
    final checkOut =
        rawCheckOut is String ? _parseOdooDateTime(rawCheckOut) : null;
    final workedHours = _asDouble(record['worked_hours']);

    return AttendancePeriod(
      checkIn: checkIn,
      checkOut: checkOut,
      workedHours: workedHours,
    );
  }

  List<List<Object?>> _projectDomain() => const [];

  List<List<Object?>> _taskDomain() => const [];
}

DateTime _parseOdooDateTime(Object? raw) {
  if (raw is! String || raw.trim().isEmpty) {
    throw StateError('Missing Odoo datetime value.');
  }
  final parts = raw.split(RegExp(r'[- :T]'));
  if (parts.length < 6) {
    throw StateError('Invalid Odoo datetime: $raw');
  }
  final utc = DateTime.utc(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
    int.parse(parts[3]),
    int.parse(parts[4]),
    int.parse(parts[5]),
  );
  return utc.toLocal();
}

double _asDouble(Object? value) {
  if (value is int) {
    return value.toDouble();
  }
  if (value is double) {
    return value;
  }
  return double.tryParse('$value') ?? 0;
}

String _formatDate(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String _formatDateTimeUtc(DateTime value) {
  final utc = value.toUtc();
  final year = utc.year.toString().padLeft(4, '0');
  final month = utc.month.toString().padLeft(2, '0');
  final day = utc.day.toString().padLeft(2, '0');
  final hour = utc.hour.toString().padLeft(2, '0');
  final minute = utc.minute.toString().padLeft(2, '0');
  final second = utc.second.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute:$second';
}

String many2OneName(Object? value) {
  if (value is List && value.length >= 2 && value[1] is String) {
    return value[1] as String;
  }
  return '';
}

int many2OneId(Object? value) {
  if (value is List && value.isNotEmpty && value.first is int) {
    return value.first as int;
  }
  return 0;
}
