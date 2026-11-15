import 'dart:convert';

import 'config.dart';
import 'utils.dart';

/// Formats and prints API requests and responses.
class ApiLogger {
  /// Active configuration.
  final ApiLoggerConfig config;

  final bool _isRelease;
  int _lastId = 0;

  /// Creates a logger. [isReleaseMode] exists for tests; it defaults to the
  /// real build mode.
  ApiLogger({ApiLoggerConfig? config, bool? isReleaseMode})
      : config = config ?? const ApiLoggerConfig(),
        _isRelease =
            isReleaseMode ?? const bool.fromEnvironment('dart.vm.product');

  /// Returns a new id used to correlate a request with its response.
  int nextId() => ++_lastId;

  /// Whether a call to [url] should be logged.
  bool shouldLog(String url) {
    if (!config.enableLog) return false;
    if (_isRelease && !config.enableInRelease) return false;
    return !config.excludeUrlPatterns.any(url.contains);
  }

  /// Logs an outgoing request.
  void logRequest({
    required String method,
    required String url,
    int? id,
    Map<String, dynamic>? headers,
    dynamic body,
  }) {
    if (!shouldLog(url)) return;
    final color = _color(AnsiColor.blue);
    final lines = <String>['$method ${_maskUrl(url)}'];

    if (config.showHeaders && headers != null && headers.isNotEmpty) {
      lines.add('Headers: ${_mask(headers, parseStrings: false)}');
    }
    final bodyText = config.showRequestBody ? _render(body) : null;
    lines.add('Body: ${bodyText ?? 'null'}');
    if (config.showCurl) {
      lines.add('cURL: ${_curl(method, url, headers, body)}');
    }
    _emit(_box('API REQUEST${_tag(id)}', lines, color));
  }

  /// Logs a response, or a failure when [error] is set.
  void logResponse({
    required String method,
    required String url,
    required int statusCode,
    required int durationMs,
    int? id,
    Map<String, dynamic>? headers,
    dynamic body,
    String? error,
  }) {
    if (!shouldLog(url)) return;
    final color = _color(_statusColor(statusCode));
    final status = statusCode == 0 && error != null ? 'FAILED' : '$statusCode';
    final lines = <String>[
      '$method ${_maskUrl(url)}',
      '⏱ $durationMs ms | Status: $status',
    ];
    if (error != null) lines.add('Error: $error');

    if (config.showResponseHeaders && headers != null && headers.isNotEmpty) {
      lines.add('Headers: ${_mask(headers, parseStrings: false)}');
    }
    if (config.showResponseBody && body != null) {
      lines.add(_render(body));
    }
    _emit(_box('API RESPONSE${_tag(id)}', lines, color));
  }

  String _statusColor(int statusCode) {
    if (statusCode == 0 || statusCode >= 400) return AnsiColor.red;
    if (statusCode >= 300) return AnsiColor.yellow;
    return AnsiColor.green;
  }

  String _color(String ansi) => config.logColor ? ansi : '';

  String _tag(int? id) => id == null ? '' : ' #$id';

  String _maskUrl(String url) =>
      LoggerUtils.maskUrl(url, config.maskedKeys, config.maskValue);

  dynamic _mask(dynamic data, {bool parseStrings = true}) =>
      LoggerUtils.maskData(
        data,
        config.maskedKeys,
        config.maskValue,
        parseStrings: parseStrings,
      );

  String _render(dynamic body) {
    if (body == null) return 'null';
    if (body is List<int>) return '<${body.length} bytes>';
    final masked = _mask(body);
    final text = masked is Map || masked is List
        ? LoggerUtils.formatJson(masked)
        : masked.toString();
    return LoggerUtils.truncate(text, config.maxBodyLength);
  }

  String _curl(
    String method,
    String url,
    Map<String, dynamic>? headers,
    dynamic body,
  ) {
    final masked = body == null || body is List<int> ? null : _mask(body);
    final bodyText = masked == null
        ? null
        : (masked is Map || masked is List)
            ? jsonEncode(masked)
            : masked.toString();
    return LoggerUtils.toCurl(
      method: method,
      url: _maskUrl(url),
      headers: headers == null ? null : _mask(headers, parseStrings: false),
      body: bodyText,
    );
  }

  String _box(String title, List<String> lines, String color) {
    final reset = config.logColor ? AnsiColor.reset : '';
    final buffer = StringBuffer('$color┌──────── $title ────────$reset\n');
    for (final line in lines) {
      for (final part in line.split('\n')) {
        buffer.writeln('$color│ $part$reset');
      }
    }
    buffer.write('$color└─────────────────────────────$reset');
    return buffer.toString();
  }

  void _emit(String message) => (config.output ?? LoggerUtils.log)(message);
}
