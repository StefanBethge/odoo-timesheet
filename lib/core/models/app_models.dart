import 'dart:math' as math;

enum SearchItemKind { project, task }

class AppSettings {
  static const defaultBundesland = 'Baden-Wuerttemberg';
  static const bundeslaender = <String>[
    defaultBundesland,
    'Bayern',
    'Berlin',
    'Brandenburg',
    'Bremen',
    'Hamburg',
    'Hessen',
    'Mecklenburg-Vorpommern',
    'Niedersachsen',
    'Nordrhein-Westfalen',
    'Rheinland-Pfalz',
    'Saarland',
    'Sachsen',
    'Sachsen-Anhalt',
    'Schleswig-Holstein',
    'Thueringen',
  ];

  const AppSettings({
    required this.url,
    required this.database,
    required this.username,
    required this.apiKey,
    required this.webPassword,
    required this.totpSecret,
    required this.bundesland,
    required this.dailyLow,
    required this.dailyHigh,
    required this.weeklyLow,
    required this.weeklyHigh,
    required this.lockEnabled,
    required this.biometricUnlockEnabled,
    required this.darkMode,
  });

  final String url;
  final String database;
  final String username;
  final String apiKey;
  final String webPassword;
  final String totpSecret;
  final String bundesland;
  final double dailyLow;
  final double dailyHigh;
  final double weeklyLow;
  final double weeklyHigh;
  final bool lockEnabled;
  final bool biometricUnlockEnabled;
  final bool darkMode;

  static String normalizeBundesland(String? value) {
    if (value != null && bundeslaender.contains(value)) {
      return value;
    }
    return defaultBundesland;
  }

  factory AppSettings.empty() {
    return const AppSettings(
      url: '',
      database: '',
      username: '',
      apiKey: '',
      webPassword: '',
      totpSecret: '',
      bundesland: defaultBundesland,
      dailyLow: 6,
      dailyHigh: 9,
      weeklyLow: 35,
      weeklyHigh: 40,
      lockEnabled: false,
      biometricUnlockEnabled: false,
      darkMode: false,
    );
  }

  bool get isConfigured =>
      url.trim().isNotEmpty &&
      database.trim().isNotEmpty &&
      username.trim().isNotEmpty &&
      apiKey.trim().isNotEmpty &&
      webPassword.trim().isNotEmpty;

  AppSettings copyWith({
    String? url,
    String? database,
    String? username,
    String? apiKey,
    String? webPassword,
    String? totpSecret,
    String? bundesland,
    double? dailyLow,
    double? dailyHigh,
    double? weeklyLow,
    double? weeklyHigh,
    bool? lockEnabled,
    bool? biometricUnlockEnabled,
    bool? darkMode,
  }) {
    return AppSettings(
      url: url ?? this.url,
      database: database ?? this.database,
      username: username ?? this.username,
      apiKey: apiKey ?? this.apiKey,
      webPassword: webPassword ?? this.webPassword,
      totpSecret: totpSecret ?? this.totpSecret,
      bundesland: normalizeBundesland(bundesland ?? this.bundesland),
      dailyLow: dailyLow ?? this.dailyLow,
      dailyHigh: dailyHigh ?? this.dailyHigh,
      weeklyLow: weeklyLow ?? this.weeklyLow,
      weeklyHigh: weeklyHigh ?? this.weeklyHigh,
      lockEnabled: lockEnabled ?? this.lockEnabled,
      biometricUnlockEnabled:
          biometricUnlockEnabled ?? this.biometricUnlockEnabled,
      darkMode: darkMode ?? this.darkMode,
    );
  }

  Map<String, String> nonSecretMap() {
    return {
      'url': url,
      'database': database,
      'username': username,
      'bundesland': bundesland,
      'dailyLow': dailyLow.toString(),
      'dailyHigh': dailyHigh.toString(),
      'weeklyLow': weeklyLow.toString(),
      'weeklyHigh': weeklyHigh.toString(),
      'lockEnabled': lockEnabled.toString(),
      'biometricUnlockEnabled': biometricUnlockEnabled.toString(),
      'darkMode': darkMode.toString(),
    };
  }

  Map<String, String> secretMap() {
    return {
      'apiKey': apiKey,
      'webPassword': webPassword,
      'totpSecret': totpSecret,
    };
  }

  factory AppSettings.fromMaps(
    Map<String, String> plain,
    Map<String, String> secrets,
  ) {
    double parseDouble(String key, double fallback) {
      return double.tryParse(plain[key] ?? '') ?? fallback;
    }

    bool parseBool(String key, bool fallback) {
      final value = plain[key];
      if (value == null || value.isEmpty) {
        return fallback;
      }
      return value.toLowerCase() == 'true';
    }

    return AppSettings(
      url: plain['url'] ?? '',
      database: plain['database'] ?? '',
      username: plain['username'] ?? '',
      apiKey: secrets['apiKey'] ?? '',
      webPassword: secrets['webPassword'] ?? '',
      totpSecret: secrets['totpSecret'] ?? '',
      bundesland: normalizeBundesland(plain['bundesland']),
      dailyLow: parseDouble('dailyLow', 6),
      dailyHigh: parseDouble('dailyHigh', 9),
      weeklyLow: parseDouble('weeklyLow', 35),
      weeklyHigh: parseDouble('weeklyHigh', 40),
      lockEnabled: parseBool('lockEnabled', false),
      biometricUnlockEnabled: parseBool('biometricUnlockEnabled', false),
      darkMode: parseBool('darkMode', false),
    );
  }
}

class AttendancePeriod {
  const AttendancePeriod({
    required this.checkIn,
    required this.checkOut,
    required this.workedHours,
  });

  final DateTime checkIn;
  final DateTime? checkOut;
  final double workedHours;

  bool get isRunning => checkOut == null;
}

class AttendanceStatus {
  const AttendanceStatus({
    required this.clockedIn,
    required this.checkIn,
    required this.periods,
  });

  final bool clockedIn;
  final DateTime? checkIn;
  final List<AttendancePeriod> periods;

  double get totalHours {
    return periods.fold<double>(0, (sum, period) {
      if (period.checkOut == null) {
        return sum + DateTime.now().difference(period.checkIn).inMinutes / 60;
      }
      return sum + period.workedHours;
    });
  }
}

class TimesheetEntry {
  const TimesheetEntry({
    required this.id,
    required this.date,
    required this.description,
    required this.hours,
    required this.status,
    this.synced = true,
  });

  final int id;
  final DateTime date;
  final String description;
  final double hours;
  final String status;
  final bool synced;

  TimesheetEntry copyWith({
    int? id,
    DateTime? date,
    String? description,
    double? hours,
    String? status,
    bool? synced,
  }) {
    return TimesheetEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      description: description ?? this.description,
      hours: hours ?? this.hours,
      status: status ?? this.status,
      synced: synced ?? this.synced,
    );
  }
}

class WeekRow {
  const WeekRow({
    required this.key,
    required this.company,
    required this.projectId,
    required this.taskId,
    required this.projectName,
    required this.taskName,
    required this.entriesByDay,
  });

  final String key;
  final String company;
  final int projectId;
  final int? taskId;
  final String projectName;
  final String? taskName;
  final List<List<TimesheetEntry>> entriesByDay;

  String get label =>
      taskName == null ? projectName : '$projectName / $taskName';

  double dailyTotal(int dayIndex) {
    return entriesByDay[dayIndex].fold<double>(
      0,
      (sum, entry) => sum + entry.hours,
    );
  }

  double get weekTotal {
    return List.generate(7, dailyTotal)
        .fold<double>(0, (sum, value) => sum + value);
  }

  WeekRow copyWith({
    String? key,
    String? company,
    int? projectId,
    int? taskId,
    String? projectName,
    String? taskName,
    List<List<TimesheetEntry>>? entriesByDay,
  }) {
    return WeekRow(
      key: key ?? this.key,
      company: company ?? this.company,
      projectId: projectId ?? this.projectId,
      taskId: taskId ?? this.taskId,
      projectName: projectName ?? this.projectName,
      taskName: taskName ?? this.taskName,
      entriesByDay: entriesByDay ?? this.entriesByDay,
    );
  }
}

class WeekSnapshot {
  const WeekSnapshot({
    required this.monday,
    required this.rows,
  });

  final DateTime monday;
  final List<WeekRow> rows;

  double dayTotal(int dayIndex) {
    return rows.fold<double>(0, (sum, row) => sum + row.dailyTotal(dayIndex));
  }

  double get weekTotal {
    return List.generate(7, dayTotal)
        .fold<double>(0, (sum, value) => sum + value);
  }
}

class SearchItem {
  const SearchItem({
    required this.kind,
    required this.company,
    required this.projectId,
    required this.projectName,
    required this.taskId,
    required this.taskName,
    required this.extra,
  });

  final SearchItemKind kind;
  final String company;
  final int projectId;
  final String projectName;
  final int? taskId;
  final String? taskName;
  final String extra;

  String get key => '$company|$projectId|${taskId ?? 0}';
  String get name =>
      kind == SearchItemKind.project ? projectName : taskName ?? '';
}

class EntryDraft {
  const EntryDraft({
    required this.description,
    required this.hours,
  });

  final String description;
  final double hours;
}

double clampHours(double value) => math.max(0, value);
