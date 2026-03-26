import 'package:xml/xml.dart';

class XmlRpcFault implements Exception {
  XmlRpcFault(this.message);

  final String message;

  @override
  String toString() => message;
}

class XmlRpcCodec {
  const XmlRpcCodec._();

  static String encodeMethodCall(String methodName, List<Object?> params) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0"');
    builder.element(
      'methodCall',
      nest: () {
        builder.element('methodName', nest: methodName);
        builder.element(
          'params',
          nest: () {
            for (final param in params) {
              builder.element(
                'param',
                nest: () => _buildValue(builder, param),
              );
            }
          },
        );
      },
    );
    return builder.buildDocument().toXmlString(pretty: false);
  }

  static Object? decodeMethodResponse(String body) {
    final document = XmlDocument.parse(body);
    final fault = document.findAllElements('fault').firstOrNull;
    if (fault != null) {
      final value = fault.findElements('value').firstOrNull;
      final faultValue = value == null ? null : _decodeValue(value);
      throw XmlRpcFault(_faultMessage(faultValue));
    }

    final value = document
        .findAllElements('methodResponse')
        .expand((element) => element.findElements('params'))
        .expand((element) => element.findElements('param'))
        .expand((element) => element.findElements('value'))
        .firstOrNull;

    if (value == null) {
      throw XmlRpcFault('XML-RPC response did not contain a value.');
    }

    return _decodeValue(value);
  }

  static String _faultMessage(Object? faultValue) {
    if (faultValue is Map<String, Object?>) {
      final message = faultValue['faultString'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }
    return 'XML-RPC fault';
  }

  static void _buildValue(XmlBuilder builder, Object? value) {
    builder.element(
      'value',
      nest: () {
        if (value == null) {
          builder.element('nil');
          return;
        }
        if (value is bool) {
          builder.element('boolean', nest: value ? '1' : '0');
          return;
        }
        if (value is int) {
          builder.element('int', nest: value.toString());
          return;
        }
        if (value is double) {
          builder.element('double', nest: value.toString());
          return;
        }
        if (value is String) {
          builder.element('string', nest: value);
          return;
        }
        if (value is List) {
          builder.element(
            'array',
            nest: () {
              builder.element(
                'data',
                nest: () {
                  for (final item in value) {
                    _buildValue(builder, item);
                  }
                },
              );
            },
          );
          return;
        }
        if (value is Map) {
          builder.element(
            'struct',
            nest: () {
              for (final entry in value.entries) {
                builder.element(
                  'member',
                  nest: () {
                    builder.element('name', nest: entry.key.toString());
                    _buildValue(builder, entry.value);
                  },
                );
              }
            },
          );
          return;
        }
        throw XmlRpcFault('Unsupported XML-RPC type: ${value.runtimeType}');
      },
    );
  }

  static Object? _decodeValue(XmlElement value) {
    final element = value.childElements.firstOrNull;
    if (element == null) {
      return value.innerText;
    }

    switch (element.name.local) {
      case 'nil':
        return null;
      case 'string':
        return element.innerText;
      case 'boolean':
        return element.innerText == '1';
      case 'int':
      case 'i4':
        return int.tryParse(element.innerText) ?? 0;
      case 'double':
        return double.tryParse(element.innerText) ?? 0.0;
      case 'array':
        return element
            .findAllElements('value')
            .map(_decodeValue)
            .toList(growable: false);
      case 'struct':
        final result = <String, Object?>{};
        for (final member in element.findElements('member')) {
          final name = member.findElements('name').firstOrNull?.innerText;
          final memberValue = member.findElements('value').firstOrNull;
          if (name != null && memberValue != null) {
            result[name] = _decodeValue(memberValue);
          }
        }
        return result;
      default:
        return element.innerText;
    }
  }
}

extension on Iterable<XmlElement> {
  XmlElement? get firstOrNull => isEmpty ? null : first;
}
