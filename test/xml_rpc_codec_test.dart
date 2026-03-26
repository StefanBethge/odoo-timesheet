import 'package:flutter_test/flutter_test.dart';
import 'package:odoo_timesheet/core/services/json_rpc_session.dart';
import 'package:odoo_timesheet/core/services/xml_rpc_codec.dart';

void main() {
  test('XML-RPC method response decodes arrays and structs', () {
    const body = '''
<?xml version="1.0"?>
<methodResponse>
  <params>
    <param>
      <value>
        <array>
          <data>
            <value>
              <struct>
                <member><name>id</name><value><int>42</int></value></member>
                <member><name>name</name><value><string>Project Alpha</string></value></member>
              </struct>
            </value>
          </data>
        </array>
      </value>
    </param>
  </params>
</methodResponse>
''';

    final decoded = XmlRpcCodec.decodeMethodResponse(body) as List<dynamic>;
    final first = decoded.first as Map<String, Object?>;

    expect(first['id'], 42);
    expect(first['name'], 'Project Alpha');
  });

  test('parseTotpSecret extracts secret from otpauth URL', () {
    const secretUrl =
        'otpauth://totp/example:user@example.com?secret=XYNHNRPRJMRNG6UP&issuer=example';
    expect(parseTotpSecret(secretUrl), 'XYNHNRPRJMRNG6UP');
  });
}
