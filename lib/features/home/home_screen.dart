import 'package:flutter/material.dart';
import 'package:odoo_timesheet/core/app_controller.dart';
import 'package:odoo_timesheet/core/models/app_models.dart';
import 'package:odoo_timesheet/core/utils/formatters.dart';
import 'package:odoo_timesheet/features/attendance/attendance_detail_sheet.dart';
import 'package:odoo_timesheet/features/day_detail/day_detail_screen.dart';
import 'package:odoo_timesheet/features/search/search_screen.dart';
import 'package:odoo_timesheet/features/settings/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final week = controller.week;
    final attendance = controller.attendance;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Odoo Timesheet'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SettingsScreen(controller: controller),
                ),
              );
            },
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: Stack(
        children: [
          const _Backdrop(),
          RefreshIndicator(
            onRefresh: controller.refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              children: [
                _AttendanceCard(
                  attendance: attendance,
                  onTap: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (_) =>
                          AttendanceDetailSheet(controller: controller),
                    );
                  },
                  onToggle: controller.toggleAttendance,
                ),
                const SizedBox(height: 14),
                _WeekHeader(controller: controller),
                const SizedBox(height: 14),
                if (week != null)
                  _DayTotalsStrip(controller: controller, week: week),
                const SizedBox(height: 14),
                if (week == null)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  for (var dayIndex = 0; dayIndex < 7; dayIndex++) ...[
                    _DayTimelineCard(
                      controller: controller,
                      week: week,
                      dayIndex: dayIndex,
                    ),
                    const SizedBox(height: 14),
                  ],
                ],
                if (controller.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      controller.errorMessage!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (controller.isBusy)
            const Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 3),
            ),
        ],
      ),
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFF7F3EB),
            Color(0xFFE6EFF8),
            Color(0xFFDDE7F5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SizedBox.expand(),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({
    required this.attendance,
    required this.onTap,
    required this.onToggle,
  });

  final AttendanceStatus? attendance;
  final VoidCallback onTap;
  final Future<void> Function() onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final running =
        attendance?.clockedIn == true && attendance?.checkIn != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: running
                      ? const Color(0xFFDBF0E5)
                      : const Color(0xFFF6DFD3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  running ? Icons.alarm_on_rounded : Icons.alarm_off_rounded,
                  color: running
                      ? const Color(0xFF2F8F66)
                      : theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      running ? 'Eingestempelt' : 'Nicht eingestempelt',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      running && attendance?.checkIn != null
                          ? 'Seit ${formatClockTime(attendance!.checkIn!)} · ${formatHours(attendance!.totalHours)} heute'
                          : 'Heute ${formatHours(attendance?.totalHours ?? 0)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: onToggle,
                child: Text(running ? 'Ausstempeln' : 'Einstempeln'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final monday = controller.selectedMonday;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: controller.goToPreviousWeek,
                  icon: const Icon(Icons.chevron_left),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Wochenansicht', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(formatWeekLabel(monday),
                          style: theme.textTheme.bodyLarge),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: controller.goToNextWeek,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: () => _openTaskSearch(context, controller),
                icon: const Icon(Icons.add_task),
                label: const Text('Aufgabe hinzufuegen'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayTotalsStrip extends StatelessWidget {
  const _DayTotalsStrip({
    required this.controller,
    required this.week,
  });

  final AppController controller;
  final WeekSnapshot week;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final date = week.monday.add(Duration(days: index));
          final total = week.dayTotal(index);
          final isToday = mondayFor(DateTime.now()) == week.monday &&
              DateTime.now().weekday == date.weekday;
          final color = hoursColor(
            value: total,
            settings: controller.settings,
            context: context,
          );
          return Container(
            width: 104,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isToday ? const Color(0xFF173042) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color:
                    isToday ? const Color(0xFF173042) : const Color(0xFFD6E0EA),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weekdayShortLabel(date),
                  style: TextStyle(
                    color: isToday ? Colors.white : const Color(0xFF173042),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  '${date.day}',
                  style: TextStyle(
                    color: isToday ? Colors.white70 : const Color(0xFF4F6474),
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  formatHours(total),
                  style: TextStyle(
                    color: isToday ? Colors.white : color,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DayTimelineCard extends StatelessWidget {
  const _DayTimelineCard({
    required this.controller,
    required this.week,
    required this.dayIndex,
  });

  final AppController controller;
  final WeekSnapshot week;
  final int dayIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = week.monday.add(Duration(days: dayIndex));
    final total = week.dayTotal(dayIndex);
    final tasks = List<WeekRow>.from(week.rows)
      ..sort((a, b) => a.label.compareTo(b.label));
    final isToday = mondayFor(DateTime.now()) == week.monday &&
        DateTime.now().weekday == date.weekday;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isToday,
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          title: Text(
            formatDateLabel(date),
            style: theme.textTheme.titleMedium,
          ),
          subtitle: Text(
            '${tasks.length} Aufgaben · ${formatHours(total)}',
            style: theme.textTheme.bodyMedium,
          ),
          trailing: Text(
            formatHours(total),
            style: theme.textTheme.titleSmall?.copyWith(
              color: hoursColor(
                value: total,
                settings: controller.settings,
                context: context,
              ),
            ),
          ),
          children: [
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _openTaskSearch(context, controller),
                  icon: const Icon(Icons.add_task),
                  label: const Text('Aufgabe'),
                ),
                const SizedBox(width: 8),
                Text('Aufgaben dieser Woche', style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            if (tasks.isEmpty)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Noch keine Aufgaben fuer diese Woche.'),
              )
            else
              Column(
                children: [
                  for (final row in tasks) ...[
                    _DayTaskTile(
                      row: row,
                      dayIndex: dayIndex,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => DayDetailScreen(
                              controller: controller,
                              rowKey: row.key,
                              dayIndex: dayIndex,
                            ),
                          ),
                        );
                      },
                    ),
                    if (row != tasks.last) const SizedBox(height: 8),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _DayTaskTile extends StatelessWidget {
  const _DayTaskTile({
    required this.row,
    required this.dayIndex,
    required this.onTap,
  });

  final WeekRow row;
  final int dayIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = row.dailyTotal(dayIndex);
    final entryCount = row.entriesByDay[dayIndex].length;

    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: CircleAvatar(
        radius: 18,
        child: Text(
          entryCount.toString(),
          style: theme.textTheme.labelMedium,
        ),
      ),
      title: Text(
        row.label,
        style: theme.textTheme.titleSmall,
      ),
      subtitle: Text(row.company),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'Summe ${formatHours(total)}',
            style: theme.textTheme.titleSmall,
          ),
          Text(
            entryCount == 1 ? '1 Eintrag' : '$entryCount Eintraege',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

Future<void> _openTaskSearch(
  BuildContext context,
  AppController controller,
) async {
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => SearchScreen(controller: controller),
      fullscreenDialog: true,
    ),
  );
}
