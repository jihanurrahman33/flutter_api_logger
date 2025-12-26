/// Configuration for ApiLogger
class ApiLoggerConfig {
  /// Enable or disable logging globally
  final bool enableLog;

  /// Show request headers
  final bool showHeaders;

  /// Show request body
  final bool showRequestBody;

  /// Show response body
  final bool showResponseBody;

  /// List of keys to mask (case insensitive partial match)
  final List<String> maskedKeys;

  /// Maximum length for body logging
  final int maxBodyLength;

  /// Enable ANSI colors
  final bool logColor;

  const ApiLoggerConfig({
    this.enableLog = true,
    this.showHeaders = true,
    this.showRequestBody = true,
    this.showResponseBody = true,
    this.maskedKeys = const ['token', 'password', 'authorization', 'secret', 'key'],
    this.maxBodyLength = 10000,
    this.logColor = true,
  });

  ApiLoggerConfig copyWith({
    bool? enableLog,
    bool? showHeaders,
    bool? showRequestBody,
    bool? showResponseBody,
    List<String>? maskedKeys,
    int? maxBodyLength,
    bool? logColor,
  }) {
    return ApiLoggerConfig(
      enableLog: enableLog ?? this.enableLog,
      showHeaders: showHeaders ?? this.showHeaders,
      showRequestBody: showRequestBody ?? this.showRequestBody,
      showResponseBody: showResponseBody ?? this.showResponseBody,
      maskedKeys: maskedKeys ?? this.maskedKeys,
      maxBodyLength: maxBodyLength ?? this.maxBodyLength,
      logColor: logColor ?? this.logColor,
    );
  }
}
