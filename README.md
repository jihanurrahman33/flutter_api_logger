# Flutter API Logger

A lightweight, beautiful, and flexible API request & response logger for Flutter. Supports both `http` and `dio` packages.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Dart](https://img.shields.io/badge/dart-3.0%2B-blue.svg)
![Flutter](https://img.shields.io/badge/flutter-3.0%2B-blue.svg)

## Features

- 🚀 **Easy Integration**: Works with `http` and `dio` out of the box.
- 🎨 **Beautiful Logs**: Color-coded, easy-to-read console output.
- 🔒 **Secure**: Automatically masks sensitive fields like passwords and tokens.
- ⚙️ **Configurable**: Control what to log (headers, body, etc.).
- 🛡️ **Production Safe**: Disabled by default in release mode unless explicitly enabled.

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_api_logger: ^1.0.0
```

## Usage

### 1. Using with `http` package

Use `ApiLoggerHttpClient` as a wrapper around your `http.Client`.

```dart
import 'package:http/http.dart' as http;
import 'package:flutter_api_logger/flutter_api_logger.dart';

void main() async {
  // Create the client with default config
  final client = ApiLoggerHttpClient();

  // Make requests as usual
  final response = await client.get(Uri.parse('https://jsonplaceholder.typicode.com/posts/1'));
  
  print(response.body);
  
  // Close the client when done
  client.close();
}
```

### 2. Using with `dio` package

Add `ApiLoggerDioInterceptor` to your Dio instance.

```dart
import 'package:dio/dio.dart';
import 'package:flutter_api_logger/flutter_api_logger.dart';

void main() async {
  final dio = Dio();
  
  // Add the interceptor
  dio.interceptors.add(ApiLoggerDioInterceptor());

  // Make requests
  await dio.get('https://jsonplaceholder.typicode.com/users/1');
}
```

## Configuration

You can customize the logger by passing an `ApiLoggerConfig` object.

```dart
final config = ApiLoggerConfig(
  enableLog: true,                  // Enable/Disable logging
  showHeaders: true,                // Show request headers
  showRequestBody: true,            // Show request body
  showResponseBody: true,           // Show response body
  logColor: true,                   // Use ANSI colors
  maskedKeys: ['password', 'token'], // Keys to mask in JSON body/headers
  maxBodyLength: 1000,              // Truncate long bodies
);

final client = ApiLoggerHttpClient(config: config);
// or
dio.interceptors.add(ApiLoggerDioInterceptor(config: config));
```

### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enableLog` | `bool` | `true` | Master switch to enable/disable logging. |
| `showHeaders` | `bool` | `true` | Whether to log request headers. |
| `showRequestBody` | `bool` | `true` | Whether to log request body. |
| `showResponseBody` | `bool` | `true` | Whether to log response body. |
| `logColor` | `bool` | `true` | Whether to use ANSI colors for output. |
| `maskedKeys` | `List<String>` | `['token', 'password', ...]` | List of JSON keys to mask. Matches partially and case-insensitive. |
| `maxBodyLength` | `int` | `10000` | Max characters to log for body before truncating. |

## Log Example

```
┌──────── API REQUEST ────────
│ GET https://api.example.com/users/1
│ Headers: {Authorization: ***}
│ Body: null
└─────────────────────────────

⏱ 312 ms | Status: 200 OK
┌──────── API RESPONSE ───────
│ {
│   "id": 1,
│   "name": "Leanne Graham",
│   "email": "Sincere@april.biz"
│ }
└─────────────────────────────
```

## License

MIT License. See [LICENSE](LICENSE) for details.
