/// Receives a fully formatted log message.
typedef ApiLogOutput = void Function(String message);

/// Configuration for the API logger.
class ApiLoggerConfig {
  /// Master switch for logging.
  final bool enableLog;

  /// Allow logging in release builds. Defaults to `false`, so production apps
  /// stay silent even when [enableLog] is `true`.
  final bool enableInRelease;

  /// Show request headers.
  final bool showHeaders;

  /// Show response headers.
  final bool showResponseHeaders;

  /// Show request body.
  final bool showRequestBody;

  /// Show response body.
  final bool showResponseBody;

  /// Print an equivalent `curl` command for every request (masked).
  final bool showCurl;

  /// Keys to mask, matched case-insensitively as substrings. Applied to
  /// headers, JSON bodies (nested), form-encoded bodies and URL query
  /// parameters.
  final List<String> maskedKeys;

  /// Replacement text for masked values.
  final String maskValue;

  /// Maximum number of characters logged per body.
  final int maxBodyLength;

  /// Use ANSI colors.
  final bool logColor;

  /// URLs containing any of these substrings are not logged.
  final List<String> excludeUrlPatterns;

  /// Custom output sink. Defaults to `dart:developer` `log`.
  final ApiLogOutput? output;

  const ApiLoggerConfig({
    this.enableLog = true,
    this.enableInRelease = false,
    this.showHeaders = true,
    this.showResponseHeaders = false,
    this.showRequestBody = true,
    this.showResponseBody = true,
    this.showCurl = false,
    this.maskedKeys = const [
      'token',
      'password',
      'authorization',
      'secret',
      'key',
      'cookie',
      'otp',
      'credential',
    ],
    this.maskValue = '***',
    this.maxBodyLength = 10000,
    this.logColor = true,
    this.excludeUrlPatterns = const [],
    this.output,
  });

  /// Returns a copy with the given fields replaced.
  ApiLoggerConfig copyWith({
    bool? enableLog,
    bool? enableInRelease,
    bool? showHeaders,
    bool? showResponseHeaders,
    bool? showRequestBody,
    bool? showResponseBody,
    bool? showCurl,
    List<String>? maskedKeys,
    String? maskValue,
    int? maxBodyLength,
    bool? logColor,
    List<String>? excludeUrlPatterns,
    ApiLogOutput? output,
  }) {
    return ApiLoggerConfig(
      enableLog: enableLog ?? this.enableLog,
      enableInRelease: enableInRelease ?? this.enableInRelease,
      showHeaders: showHeaders ?? this.showHeaders,
      showResponseHeaders: showResponseHeaders ?? this.showResponseHeaders,
      showRequestBody: showRequestBody ?? this.showRequestBody,
      showResponseBody: showResponseBody ?? this.showResponseBody,
      showCurl: showCurl ?? this.showCurl,
      maskedKeys: maskedKeys ?? this.maskedKeys,
      maskValue: maskValue ?? this.maskValue,
      maxBodyLength: maxBodyLength ?? this.maxBodyLength,
      logColor: logColor ?? this.logColor,
      excludeUrlPatterns: excludeUrlPatterns ?? this.excludeUrlPatterns,
      output: output ?? this.output,
    );
  }
}
