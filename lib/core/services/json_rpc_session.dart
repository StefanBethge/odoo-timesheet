import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class JsonRpcSession {
  JsonRpcSession({
    required String baseUrl,
    required this.database,
    required this.username,
    required this.password,
    required this.totpSecret,
    http.Client? client,
  })  : _baseUrl = baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl,
        _client = client ?? http.Client();

  final String _baseUrl;
  final String database;
  final String username;
  final String password;
  final String totpSecret;
  final http.Client _client;

  final Map<String, String> _cookies = {};
  int _requestId = 1;
  bool _authenticated = false;

  Future<Map<String, dynamic>> call(
    String path,
    Map<String, Object?> params,
  ) async {
    if (!_authenticated) {
      await authenticate();
    }

    final response = await _sendJson(
      'POST',
      path,
      body: {
        'jsonrpc': '2.0',
        'id': _requestId++,
        'method': 'call',
        'params': params,
      },
    );

    final decoded = _decodeJsonResponse(response);
    final result = decoded['result'];
    if (result is Map<String, dynamic>) {
      return result;
    }
    return {'value': result};
  }

  Future<void> authenticate() async {
    final response = await _sendJson(
      'POST',
      '/web/session/authenticate',
      body: {
        'jsonrpc': '2.0',
        'id': _requestId++,
        'method': 'call',
        'params': {
          'db': database,
          'login': username,
          'password': password,
        },
      },
    );

    final decoded = _decodeJsonResponse(response);
    final result = decoded['result'];
    if (result is! Map<String, dynamic>) {
      throw StateError('Authentication did not return a result object.');
    }

    final uid = result['uid'];
    if (uid == false || uid == null) {
      if (totpSecret.trim().isEmpty) {
        throw StateError(
          'Authentication failed: 2FA is enabled but no TOTP secret is configured.',
        );
      }
      await _completeTotp();
      _authenticated = true;
      return;
    }

    _authenticated = true;
  }

  Future<void> _completeTotp() async {
    final csrfResponse = await _send('GET', '/web/login/totp');
    final csrfToken = _extractCsrfToken(csrfResponse.body);
    final totpCode =
        generateTotpCode(parseTotpSecret(totpSecret), DateTime.now().toUtc());

    final body = {
      'csrf_token': csrfToken,
      'totp_token': totpCode,
    };
    final response = await _send(
      'POST',
      '/web/login/totp',
      headers: const {
        'content-type': 'application/x-www-form-urlencoded',
      },
      body: body.entries
          .map((entry) =>
              '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}')
          .join('&'),
      followRedirects: false,
    );

    if (response.statusCode != 302 && response.statusCode != 303) {
      throw StateError(
        'TOTP verification failed (status ${response.statusCode}).',
      );
    }
  }

  Future<http.Response> _sendJson(
    String method,
    String path, {
    required Map<String, Object?> body,
  }) {
    return _send(
      method,
      path,
      headers: const {'content-type': 'application/json'},
      body: jsonEncode(body),
    );
  }

  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, String>? headers,
    String? body,
    bool followRedirects = true,
  }) async {
    final request = http.Request(method, Uri.parse('$_baseUrl$path'))
      ..headers.addAll(headers ?? const {})
      ..followRedirects = followRedirects;

    if (_cookies.isNotEmpty) {
      request.headers['cookie'] = _cookies.entries
          .map((entry) => '${entry.key}=${entry.value}')
          .join('; ');
    }
    if (body != null) {
      request.body = body;
    }

    final streamed = await _client.send(request);
    _captureCookies(streamed.headers['set-cookie']);
    return http.Response.fromStream(streamed);
  }

  Map<String, dynamic> _decodeJsonResponse(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('Unexpected JSON-RPC response.');
    }
    final error = decoded['error'];
    if (error is Map<String, dynamic>) {
      final data = error['data'];
      if (data is Map<String, dynamic> && data['message'] is String) {
        throw StateError(data['message'] as String);
      }
      if (error['message'] is String) {
        throw StateError(error['message'] as String);
      }
      throw StateError('JSON-RPC call failed.');
    }
    return decoded;
  }

  void _captureCookies(String? header) {
    if (header == null || header.isEmpty) {
      return;
    }

    for (final rawCookie in header.split(',')) {
      final firstPart = rawCookie.split(';').first.trim();
      final separator = firstPart.indexOf('=');
      if (separator == -1) {
        continue;
      }
      final name = firstPart.substring(0, separator);
      final value = firstPart.substring(separator + 1);
      _cookies[name] = value;
    }
  }

  String _extractCsrfToken(String body) {
    final match =
        RegExp(r'name="csrf_token"\s+value="([^"]+)"').firstMatch(body);
    if (match == null) {
      throw StateError('CSRF token not found in TOTP form.');
    }
    return match.group(1)!;
  }
}

String parseTotpSecret(String value) {
  if (value.startsWith('otpauth://')) {
    final uri = Uri.tryParse(value);
    final secret = uri?.queryParameters['secret'];
    if (secret != null && secret.isNotEmpty) {
      return secret;
    }
  }
  return value;
}

String generateTotpCode(String rawSecret, DateTime nowUtc) {
  final secret = _decodeBase32(rawSecret);
  final counter = nowUtc.millisecondsSinceEpoch ~/ 1000 ~/ 30;
  final data = ByteData(8)..setInt64(0, counter);
  final digest = Hmac(sha1, secret).convert(data.buffer.asUint8List()).bytes;
  final offset = digest.last & 0x0f;
  final binary = ((digest[offset] & 0x7f) << 24) |
      ((digest[offset + 1] & 0xff) << 16) |
      ((digest[offset + 2] & 0xff) << 8) |
      (digest[offset + 3] & 0xff);
  final otp = binary % pow(10, 6).toInt();
  return otp.toString().padLeft(6, '0');
}

List<int> _decodeBase32(String input) {
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  final normalized = input.toUpperCase().replaceAll(RegExp(r'[^A-Z2-7]'), '');

  final bytes = <int>[];
  var buffer = 0;
  var bitsLeft = 0;

  for (final rune in normalized.runes) {
    final char = String.fromCharCode(rune);
    final value = alphabet.indexOf(char);
    if (value == -1) {
      continue;
    }
    buffer = (buffer << 5) | value;
    bitsLeft += 5;

    if (bitsLeft >= 8) {
      bitsLeft -= 8;
      bytes.add((buffer >> bitsLeft) & 0xff);
    }
  }

  return bytes;
}
