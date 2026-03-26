import 'package:flutter/material.dart';
import 'package:odoo_timesheet/core/app_controller.dart';
import 'package:odoo_timesheet/core/models/app_models.dart';
import 'package:odoo_timesheet/core/utils/formatters.dart';
import 'package:odoo_timesheet/features/entries/entry_editor_dialog.dart';

class DayDetailScreen extends StatelessWidget {
  const DayDetailScreen({
    super.key,
    required this.controller,
    required this.rowKey,
    required this.dayIndex,
  });

  final AppController controller;
  final String rowKey;
  final int dayIndex;

  @override
  Widget build(BuildContext context) {
    final week = controller.week;
    WeekRow? row;
    if (week != null) {
      for (final item in week.rows) {
        if (item.key == rowKey) {
          row = item;
          break;
        }
      }
    }
    if (week == null || row == null) {
      return const Scaffold(
          body: Center(child: Text('Eintrag nicht gefunden')));
    }
    final resolvedRow = row;

    final date = week.monday.add(Duration(days: dayIndex));
    final entries = resolvedRow.entriesByDay[dayIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(formatDateLabel(date)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEntryDialog(
          context,
          controller,
          resolvedRow,
          week.monday,
          dayIndex,
        ),
        icon: const Icon(Icons.add),
        label: const Text('Eintrag'),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7F3EB), Color(0xFFE6EFF8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(resolvedRow.label,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      resolvedRow.company,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Tagessumme ${formatHours(resolvedRow.dailyTotal(dayIndex))}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (entries.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('Keine Eintraege fuer diesen Tag.'),
                ),
              )
            else
              for (final entry in entries) ...[
                _EntryCard(
                  entry: entry,
                  onEdit: () => _openEntryDialog(
                    context,
                    controller,
                    resolvedRow,
                    week.monday,
                    dayIndex,
                    entry: entry,
                  ),
                  onDelete: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Eintrag loeschen?'),
                        content: Text('Eintrag #${entry.id} wird entfernt.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Abbrechen'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Loeschen'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await controller.deleteEntry(
                        monday: week.monday,
                        rowKey: resolvedRow.key,
                        entryId: entry.id,
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }

  Future<void> _openEntryDialog(
    BuildContext context,
    AppController controller,
    WeekRow row,
    DateTime monday,
    int dayIndex, {
    TimesheetEntry? entry,
  }) async {
    final draft = await showEntryEditorDialog(
      context,
      title: entry == null ? 'Eintrag anlegen' : 'Eintrag bearbeiten',
      initialDescription: entry?.description ?? '',
      initialHours: entry == null ? '' : entry.hours.toString(),
    );
    if (draft == null) {
      return;
    }
    if (entry == null) {
      await controller.createEntry(
        monday: monday,
        rowKey: row.key,
        dayIndex: dayIndex,
        draft: draft,
      );
      return;
    }
    await controller.updateEntry(
      monday: monday,
      rowKey: row.key,
      entryId: entry.id,
      draft: draft,
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  final TimesheetEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        title: Text(entry.description),
        subtitle: Text('ID ${entry.id} · ${entry.status}'),
        trailing: Wrap(
          spacing: 8,
          children: [
            Text(
              formatHours(entry.hours),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}
