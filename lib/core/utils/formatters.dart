import 'package:flutter/material.dart';
import 'package:odoo_timesheet/core/models/app_models.dart';

const _weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _weekdayLong = [
  'Montag',
  'Dienstag',
  'Mittwoch',
  'Donnerstag',
  'Freitag',
  'Samstag',
  'Sonntag',
];
const _monthShort = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Add [days] to a date, keeping midnight in local time (DST-safe).
DateTime addDays(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);

/// Number of calendar days from [from] to [to] (DST-safe).
int calendarDaysBetween(DateTime from, DateTime to) =>
    DateTime.utc(to.year, to.month, to.day)
        .difference(DateTime.utc(from.year, from.month, from.day))
        .inDays;

DateTime mondayFor(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  return addDays(normalized, DateTime.monday - normalized.weekday);
}

String formatWeekLabel(DateTime monday) {
  final sunday = addDays(monday, 6);
  final week = isoWeekNumber(monday);
  return 'W$week · ${monday.day} ${monthLabel(monday)} - ${sunday.day} ${monthLabel(sunday)}';
}

String monthLabel(DateTime value) => _monthShort[value.month - 1];

String weekdayShortLabel(DateTime value) => _weekdayShort[value.weekday - 1];

String weekdayLongLabel(DateTime value) => _weekdayLong[value.weekday - 1];

String formatDateLabel(DateTime value) {
  return '${weekdayLongLabel(value)}, ${value.day}. ${monthLabel(value)}';
}

String formatClockTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String formatHours(double hours) {
  final totalMinutes = (hours * 60).round();
  final h = totalMinutes ~/ 60;
  final m = totalMinutes % 60;
  return '$h:${m.toString().padLeft(2, '0')}';
}

double parseHours(String raw) {
  final value = raw.trim();
  if (value.isEmpty) {
    throw const FormatException('Stunden sind erforderlich.');
  }
  if (value.contains(':')) {
    final parts = value.split(':');
    if (parts.length != 2) {
      throw const FormatException('Zeitformat muss H:MM sein.');
    }
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || m < 0 || m >= 60) {
      throw const FormatException('Zeitformat muss H:MM sein.');
    }
    final result = h + (m / 60);
    if (result <= 0) {
      throw const FormatException('Stunden muessen groesser als 0 sein.');
    }
    return result;
  }
  final decimal = double.tryParse(value.replaceAll(',', '.'));
  if (decimal == null || decimal <= 0) {
    throw const FormatException('Stunden muessen groesser als 0 sein.');
  }
  return decimal;
}

int isoWeekNumber(DateTime date) {
  final thursday = addDays(date, 4 - date.weekday);
  final yearStart = DateTime(thursday.year, 1, 1);
  return ((thursday.difference(yearStart).inDays) / 7).floor() + 1;
}

Color hoursColor({
  required double value,
  required AppSettings settings,
  required BuildContext context,
  bool weekly = false,
}) {
  final scheme = Theme.of(context).colorScheme;
  final low = weekly ? settings.weeklyLow : settings.dailyLow;
  final high = weekly ? settings.weeklyHigh : settings.dailyHigh;
  if (value < low) {
    return const Color(0xFFF2B84B);
  }
  if (value > high) {
    return scheme.secondary;
  }
  return const Color(0xFF2F8F66);
}
