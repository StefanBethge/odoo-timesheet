import 'package:flutter_test/flutter_test.dart';
import 'package:odoo_timesheet/core/models/app_models.dart';
import 'package:odoo_timesheet/core/services/odoo_rpc_client.dart';
import 'package:odoo_timesheet/core/services/real_odoo_gateway.dart';

void main() {
  test('loadWeek can merge previous-week hints into an empty week', () async {
    final settings = AppSettings.empty().copyWith(
      url: 'https://example.invalid',
      database: 'odoo',
      username: 'user@example.invalid',
      apiKey: 'api-key',
      webPassword: 'password',
    );
    final monday = DateTime(2026, 3, 16);
    final gateway = RealOdooGateway(
      clientFactory: (settings) => _FakeOdooRpcClient(settings: settings),
    );

    final snapshot = await gateway.loadWeek(settings: settings, monday: monday);

    expect(snapshot.rows, hasLength(1));
    expect(snapshot.rows.single.projectName, 'Acme');
    expect(snapshot.rows.single.taskName, 'Dev');
  });
}

class _FakeOdooRpcClient extends OdooRpcClient {
  _FakeOdooRpcClient({required super.settings});

  @override
  Future<List<Map<String, Object?>>> listTimesheets({
    required DateTime dateFrom,
    required DateTime dateTo,
  }) async {
    if (dateFrom == DateTime(2026, 3, 9) && dateTo == DateTime(2026, 3, 15)) {
      return [
        {
          'id': 1,
          'date': '2026-03-10',
          'project_id': [10, 'Acme'],
          'task_id': [20, 'Dev'],
          'name': 'Implementation',
          'unit_amount': 2.0,
          'validated_status': 'draft',
          'company_id': [30, 'Acme Corp'],
        },
      ];
    }

    return [];
  }
}
