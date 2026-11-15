# flutter_api_logger

[![pub package](https://img.shields.io/pub/v/flutter_api_logger.svg)](https://pub.dev/packages/flutter_api_logger)
[![CI](https://github.com/jihanurrahman33/flutter_api_logger/actions/workflows/ci.yml/badge.svg)](https://github.com/jihanurrahman33/flutter_api_logger/actions/workflows/ci.yml)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A secure API request & response logger for **`http`** and **`dio`**. One
package, one config, same output for both clients. Pure Dart, so it also works
in server and CLI code.

## Features

- 🔒 **Secure by default:** tokens, passwords, cookies and API keys are masked in headers, nested JSON, JSON *strings*, form bodies and URL query parameters.
- 🛡️ **Silent in release builds** unless you set `enableInRelease: true`.
- 🔗 **Request/response correlation:** every pair shares an id (`#3`), so concurrent calls to the same URL never get mixed up.
- 🧾 **Optional masked cURL output** to reproduce a call in a terminal or Postman.
- 📦 Understands `FormData` / multipart (field values masked, files summarized) and binary bodies.
- 🌐 UTF-8 safe (Bangla and other non-ASCII responses stay readable).
- ⚡ Doesn't buffer binary or large downloads when it won't log the body.
- 🔌 Custom output sink and URL exclusions.

## Install

```yaml
dependencies:
  flutter_api_logger: ^1.1.0
```

## Usage

### dio

```dart
final dio = Dio();
dio.interceptors.add(ApiLoggerDioInterceptor());
```

### http

```dart
final client = ApiLoggerHttpClient();
final response = await client.get(Uri.parse('https://example.com/users/1'));
client.close();
```

### Configure

```dart
const config = ApiLoggerConfig(
  showCurl: true,
  showResponseHeaders: true,
  maskedKeys: ['token', 'password', 'authorization', 'ssn'],
  excludeUrlPatterns: ['/health', 'analytics'],
);

dio.interceptors.add(ApiLoggerDioInterceptor(config: config));
final client = ApiLoggerHttpClient(config: config);
```

| Option | Default | Description |
|---|---|---|
| `enableLog` | `true` | Master switch. |
| `enableInRelease` | `false` | Allow logging in release builds. |
| `showHeaders` | `true` | Request headers. |
| `showResponseHeaders` | `false` | Response headers. |
| `showRequestBody` / `showResponseBody` | `true` | Bodies. |
| `showCurl` | `false` | Masked cURL command per request. |
| `maskedKeys` | token, password, authorization, secret, key, cookie, otp, credential | Case-insensitive substring match. |
| `maskValue` | `***` | Replacement text. |
| `maxBodyLength` | `10000` | Truncate long bodies. |
| `logColor` | `true` | ANSI colors. |
| `excludeUrlPatterns` | `[]` | Skip URLs containing any of these. |
| `output` | `dart:developer` log | Custom sink, e.g. `print` or your own logger. |

## Example output

```
┌──────── API REQUEST #1 ────────
│ POST https://api.example.com/login?token=***
│ Headers: {Authorization: ***, Accept: application/json}
│ Body: {
│   "user": "bob",
│   "password": "***"
│ }
└─────────────────────────────
┌──────── API RESPONSE #1 ────────
│ POST https://api.example.com/login?token=***
│ ⏱ 312 ms | Status: 200
│ {
│   "token": "***"
│ }
└─────────────────────────────
```

## Upgrading to 1.1

- **Release builds no longer log** unless `enableInRelease: true` (this is what 1.0 documented, but it was not enforced).
- Masking now also covers JSON strings (the `http` client's bodies), form bodies and URLs.
- The package no longer depends on Flutter or `rxdart`.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Licensed under MIT.
