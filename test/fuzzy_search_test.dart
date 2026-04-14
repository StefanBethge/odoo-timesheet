import 'package:flutter_test/flutter_test.dart';
import 'package:odoo_timesheet/core/models/app_models.dart';
import 'package:odoo_timesheet/core/utils/fuzzy_search.dart';

void main() {
  const items = [
    SearchItem(
      kind: SearchItemKind.task,
      company: 'digitalgedacht GmbH',
      projectId: 1,
      projectName: 'Mobile Timesheet',
      taskId: 10,
      taskName: 'Android MVP',
      extra: 'Mobile Timesheet',
    ),
    SearchItem(
      kind: SearchItemKind.task,
      company: 'digitalgedacht GmbH',
      projectId: 1,
      projectName: 'Mobile Timesheet',
      taskId: 11,
      taskName: 'Attendance Flow',
      extra: 'Mobile Timesheet',
    ),
    SearchItem(
      kind: SearchItemKind.project,
      company: 'Partner Corp',
      projectId: 2,
      projectName: 'Customer Rollout',
      taskId: null,
      taskName: null,
      extra: 'Partner Corp',
    ),
  ];

  test('prefers direct prefix matches over weaker fuzzy matches', () {
    final results = filterSearchItemsFuzzy(items, 'and');

    expect(results.first.name, 'Android MVP');
    expect(results.map((item) => item.name), contains('Attendance Flow'));
  });

  test('matches ordered subsequences', () {
    final results = filterSearchItemsFuzzy(items, 'crl');

    expect(results.single.name, 'Customer Rollout');
  });

  test('returns all items unchanged for an empty query', () {
    final results = filterSearchItemsFuzzy(items, '');

    expect(results.map((item) => item.name).toList(), [
      'Android MVP',
      'Attendance Flow',
      'Customer Rollout',
    ]);
  });
}
