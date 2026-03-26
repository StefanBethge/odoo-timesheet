import 'package:flutter/material.dart';
import 'package:odoo_timesheet/core/app_controller.dart';
import 'package:odoo_timesheet/core/utils/formatters.dart';

class AttendanceDetailSheet extends StatelessWidget {
  const AttendanceDetailSheet({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final attendance = controller.attendance;
    final running =
        attendance?.clockedIn == true && attendance?.checkIn != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Anwesenheit heute',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    running ? 'Eingestempelt' : 'Ausgestempelt',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                      'Gesamt heute ${formatHours(attendance?.totalHours ?? 0)}'),
                  if (attendance?.checkIn != null && running)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Laufend seit ${formatClockTime(attendance!.checkIn!)}',
                      ),
                    ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: controller.toggleAttendance,
                    child: Text(running ? 'Ausstempeln' : 'Einstempeln'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: attendance?.periods.length ?? 0,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final period = attendance!.periods[index];
                final duration = period.checkOut == null
                    ? DateTime.now().difference(period.checkIn).inMinutes / 60
                    : period.workedHours;
                return Card(
                  child: ListTile(
                    title: Text(
                      '${formatClockTime(period.checkIn)} - '
                      '${period.checkOut == null ? '--:--' : formatClockTime(period.checkOut!)}',
                    ),
                    subtitle:
                        Text(period.isRunning ? 'laufend' : 'abgeschlossen'),
                    trailing: Text(formatHours(duration)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
