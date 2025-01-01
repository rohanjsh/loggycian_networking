import 'dart:convert';

/// Helper class for JSON-related operations
final class JsonHelper {
  const JsonHelper._();

  static String prettifyJson(dynamic jsonData, {int spaces = 4}) {
    if (jsonData == null) return '{}';

    try {
      final encoder = JsonEncoder.withIndent(' ' * spaces);
      dynamic data = jsonData;

      if (jsonData is String) {
        if (jsonData.trim().startsWith('{') ||
            jsonData.trim().startsWith('[')) {
          try {
            data = json.decode(jsonData);
          } catch (_) {
            return jsonData;
          }
        } else {
          return jsonData;
        }
      }

      return encoder.convert(data);
    } catch (ex) {
      return jsonData?.toString() ?? '{}';
    }
  }
}
