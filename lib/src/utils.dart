import 'dart:convert';
import 'dart:developer' as dev;

/// ANSI color codes for console output.
class AnsiColor {
  static const String reset = '\x1B[0m';
  static const String red = '\x1B[31m';
  static const String green = '\x1B[32m';
  static const String yellow = '\x1B[33m';
  static const String blue = '\x1B[34m';
  static const String cyan = '\x1B[36m';
}

/// Helper functions for logging: masking, formatting and cURL generation.
class LoggerUtils {
  static final RegExp _formEncoded =
      RegExp(r'^[^\s=&{}\[\]"]+=[^\s&]*(&[^\s=&{}\[\]"]+=[^\s&]*)*$');

  /// Whether [key] contains any of [maskedKeys] (case-insensitive).
  static bool isSensitive(String key, List<String> maskedKeys) {
    final lower = key.toLowerCase();
    return maskedKeys.any((mask) => lower.contains(mask.toLowerCase()));
  }

  /// Returns a copy of [data] with sensitive values replaced by [mask].
  ///
  /// Handles nested maps and lists. When [parseStrings] is `true`, strings
  /// holding JSON or form-encoded data are parsed and masked as well.
  static dynamic maskData(
    dynamic data,
    List<String> maskedKeys,
    String mask, {
    bool parseStrings = true,
  }) {
    if (data is Map) {
      return {
        for (final entry in data.entries)
          '${entry.key}': isSensitive('${entry.key}', maskedKeys)
              ? mask
              : maskData(
                  entry.value,
                  maskedKeys,
                  mask,
                  parseStrings: parseStrings,
                ),
      };
    }
    if (data is List && data is! List<int>) {
      return [
        for (final item in data)
          maskData(item, maskedKeys, mask, parseStrings: parseStrings),
      ];
    }
    if (data is String && parseStrings) {
      return _maskString(data, maskedKeys, mask);
    }
    return data;
  }

  static dynamic _maskString(String text, List<String> keys, String mask) {
    final trimmed = text.trim();
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      try {
        return maskData(jsonDecode(trimmed), keys, mask);
      } on FormatException {
        return text;
      }
    }
    if (_formEncoded.hasMatch(trimmed)) {
      try {
        final params = Uri.splitQueryString(trimmed);
        return params.entries
            .map((e) => '${e.key}=${isSensitive(e.key, keys) ? mask : e.value}')
            .join('&');
      } on FormatException {
        return text;
      }
    }
    return text;
  }

  /// Masks sensitive query parameters and credentials embedded in [url].
  static String maskUrl(String url, List<String> maskedKeys, String mask) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    var result = uri;
    if (uri.userInfo.isNotEmpty) result = result.replace(userInfo: mask);
    if (uri.hasQuery) {
      final query = uri.query.split('&').map((pair) {
        final index = pair.indexOf('=');
        if (index < 0) return pair;
        final key = Uri.decodeQueryComponent(pair.substring(0, index));
        return isSensitive(key, maskedKeys)
            ? '${pair.substring(0, index)}=$mask'
            : pair;
      }).join('&');
      result = result.replace(query: query);
    }
    return result.toString();
  }

  /// Pretty prints JSON (maps, lists or JSON strings); other values use
  /// `toString`.
  static String formatJson(dynamic json) {
    try {
      if (json == null) return 'null';
      final dynamic parsed = (json is String) ? jsonDecode(json) : json;
      if (parsed is! Map && parsed is! List) return parsed.toString();
      return const JsonEncoder.withIndent('  ').convert(parsed);
    } catch (_) {
      return json.toString();
    }
  }

  /// Truncates [text] to [maxLength] characters.
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}... (truncated)';
  }

  /// Whether a response with [contentType] is safe to read as text.
  /// A missing content type is treated as text.
  static bool isTextContentType(String? contentType) {
    if (contentType == null || contentType.isEmpty) return true;
    final type = contentType.toLowerCase();
    return type.startsWith('text/') ||
        type.contains('json') ||
        type.contains('xml') ||
        type.contains('javascript') ||
        type.contains('x-www-form-urlencoded');
  }

  /// Builds a `curl` command. Values are expected to be masked already.
  static String toCurl({
    required String method,
    required String url,
    Map<String, dynamic>? headers,
    String? body,
  }) {
    String quote(String value) => "'${value.replaceAll("'", r"'\''")}'";
    final parts = <String>['curl', '-X', method.toUpperCase()];
    headers?.forEach((key, value) {
      parts.addAll(['-H', quote('$key: $value')]);
    });
    if (body != null && body.isNotEmpty) parts.addAll(['-d', quote(body)]);
    parts.add(quote(url));
    return parts.join(' ');
  }

  /// Default output: `dart:developer` log.
  static void log(String message) => dev.log(message, name: 'ApiLogger');
}
