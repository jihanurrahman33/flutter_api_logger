import 'dart:convert';
import 'dart:developer' as dev;

/// ANSI Color codes for console output
class AnsiColor {
  static const String reset = '\x1B[0m';
  static const String red = '\x1B[31m';
  static const String green = '\x1B[32m';
  static const String yellow = '\x1B[33m';
  static const String blue = '\x1B[34m';
  static const String cyan = '\x1B[36m';
}

/// Helper functions for logging
class LoggerUtils {
  
  /// Pretty print JSON string
  static String formatJson(dynamic json) {
    try {
      if (json == null) return 'null';
      final dynamic parsedJson = (json is String) ? jsonDecode(json) : json;
      if (parsedJson is! Map && parsedJson is! List) return parsedJson.toString();
      
      const JsonEncoder encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(parsedJson);
    } catch (e) {
      return json.toString();
    }
  }

  /// Mask sensitive keys in a Map
  static Map<String, dynamic> maskSensitiveKeys(
      Map<String, dynamic> data, List<String> maskedKeys) {
    final Map<String, dynamic> masked = Map<String, dynamic>.from(data);
    
    for (var key in data.keys) {
      if (maskedKeys.any((mask) => key.toLowerCase().contains(mask.toLowerCase()))) {
        masked[key] = '***';
      } else if (masked[key] is Map<String, dynamic>) {
        masked[key] = maskSensitiveKeys(masked[key], maskedKeys);
      } else if (masked[key] is List) {
        masked[key] = (masked[key] as List).map((item) {
          if (item is Map<String, dynamic>) {
            return maskSensitiveKeys(item, maskedKeys);
          }
          return item;
        }).toList();
      }
    }
    return masked;
  }

  /// Truncate long strings
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}... (truncated)';
  }

  /// Print with color
  static void log(String message, {String color = AnsiColor.reset, bool isRelease = false}) {
    // In release mode, 'print' might be stripped or ignored depending on setup, 
    // but requirements say "Never log in release mode unless explicitly enabled".
    // We will handle the enable check in the logger class. 
    // Here we just handle the printing mechanism.
    // using dart:developer log for better integration with IDEs
    dev.log('$color$message${AnsiColor.reset}', name: 'ApiLogger');
  }
}
