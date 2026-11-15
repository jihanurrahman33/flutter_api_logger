import 'package:flutter_api_logger/flutter_api_logger.dart';
import 'package:flutter_api_logger/src/logger.dart';
import 'package:test/test.dart';

void main() {
  late List<String> out;

  ApiLogger build({
    ApiLoggerConfig? config,
    bool release = false,
  }) {
    return ApiLogger(
      config: (config ?? const ApiLoggerConfig(logColor: false))
          .copyWith(output: out.add),
      isReleaseMode: release,
    );
  }

  setUp(() => out = []);

  group('release mode', () {
    test('is silent by default', () {
      build(release: true).logRequest(method: 'GET', url: 'https://a.test');
      expect(out, isEmpty);
    });

    test('logs when enableInRelease is true', () {
      build(
        config: const ApiLoggerConfig(enableInRelease: true),
        release: true,
      ).logRequest(method: 'GET', url: 'https://a.test');
      expect(out, hasLength(1));
    });

    test('enableLog false silences debug too', () {
      build(config: const ApiLoggerConfig(enableLog: false))
          .logRequest(method: 'GET', url: 'https://a.test');
      expect(out, isEmpty);
    });
  });

  group('request', () {
    test('masks headers, body and url, and shows the id', () {
      build().logRequest(
        id: 7,
        method: 'POST',
        url: 'https://a.test/login?token=abc',
        headers: {'Authorization': 'Bearer secret', 'Accept': 'json'},
        body: {'password': 'hunter2', 'user': 'bob'},
      );
      final text = out.single;
      expect(text, contains('API REQUEST #7'));
      expect(text, contains('token=***'));
      expect(text, contains('Authorization: ***'));
      expect(text, contains('Accept: json'));
      expect(text, contains('"user": "bob"'));
      expect(text, isNot(contains('hunter2')));
      expect(text, isNot(contains('secret')));
      expect(text, isNot(contains('abc')));
    });

    test('masks JSON string bodies', () {
      build().logRequest(
        method: 'POST',
        url: 'https://a.test',
        body: '{"password":"hunter2"}',
      );
      expect(out.single, isNot(contains('hunter2')));
    });

    test('hides headers and body when disabled', () {
      build(
        config: const ApiLoggerConfig(
          logColor: false,
          showHeaders: false,
          showRequestBody: false,
        ),
      ).logRequest(
        method: 'POST',
        url: 'https://a.test',
        headers: {'A': 'b'},
        body: 'payload',
      );
      expect(out.single, isNot(contains('Headers')));
      expect(out.single, isNot(contains('payload')));
    });

    test('prints a masked cURL command when enabled', () {
      build(
        config: const ApiLoggerConfig(logColor: false, showCurl: true),
      ).logRequest(
        method: 'POST',
        url: 'https://a.test',
        headers: {'Authorization': 'Bearer s'},
        body: {'password': 'p', 'a': 1},
      );
      expect(
        out.single,
        contains(
          "cURL: curl -X POST -H 'Authorization: ***' "
          "-d '{\"password\":\"***\",\"a\":1}' 'https://a.test'",
        ),
      );
    });

    test('summarizes byte bodies and truncates long ones', () {
      final logger = build(
        config: const ApiLoggerConfig(logColor: false, maxBodyLength: 5),
      );
      logger.logRequest(
        method: 'POST',
        url: 'https://a.test',
        body: [1, 2, 3],
      );
      logger.logRequest(
        method: 'POST',
        url: 'https://a.test',
        body: 'abcdefghij',
      );
      expect(out[0], contains('<3 bytes>'));
      expect(out[1], contains('abcde... (truncated)'));
    });
  });

  group('response', () {
    test('shows status, duration, method and url', () {
      build().logResponse(
        id: 3,
        method: 'GET',
        url: 'https://a.test/u',
        statusCode: 200,
        durationMs: 42,
        body: {'token': 't', 'name': 'x'},
      );
      final text = out.single;
      expect(text, contains('API RESPONSE #3'));
      expect(text, contains('GET https://a.test/u'));
      expect(text, contains('42 ms | Status: 200'));
      expect(text, contains('"token": "***"'));
    });

    test('shows failure details', () {
      build().logResponse(
        method: 'GET',
        url: 'https://a.test',
        statusCode: 0,
        durationMs: 1,
        error: 'timeout',
      );
      expect(out.single, contains('Status: FAILED'));
      expect(out.single, contains('Error: timeout'));
    });

    test('colors reflect status when enabled', () {
      final logger = build(config: const ApiLoggerConfig());
      for (final code in [200, 302, 404, 0]) {
        logger.logResponse(
          method: 'GET',
          url: 'https://a.test',
          statusCode: code,
          durationMs: 1,
        );
      }
      expect(out[0], contains('\x1B[32m'));
      expect(out[1], contains('\x1B[33m'));
      expect(out[2], contains('\x1B[31m'));
      expect(out[3], contains('\x1B[31m'));
    });

    test('response headers only when enabled', () {
      final base = {'set-cookie': 'sid=1', 'x-a': 'b'};
      build().logResponse(
        method: 'GET',
        url: 'https://a.test',
        statusCode: 200,
        durationMs: 1,
        headers: base,
      );
      build(
        config: const ApiLoggerConfig(
          logColor: false,
          showResponseHeaders: true,
        ),
      ).logResponse(
        method: 'GET',
        url: 'https://a.test',
        statusCode: 200,
        durationMs: 1,
        headers: base,
      );
      expect(out[0], isNot(contains('Headers')));
      expect(out[1], contains('x-a: b'));
      expect(out[1], isNot(contains('sid=1')));
    });
  });

  test('excludeUrlPatterns skips matching urls', () {
    build(
      config: const ApiLoggerConfig(
        logColor: false,
        excludeUrlPatterns: ['/health'],
      ),
    ).logRequest(method: 'GET', url: 'https://a.test/health');
    expect(out, isEmpty);
  });

  test('nextId increments per logger', () {
    final logger = build();
    expect([logger.nextId(), logger.nextId()], [1, 2]);
  });
}
