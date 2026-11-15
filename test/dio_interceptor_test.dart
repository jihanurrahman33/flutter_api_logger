import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_api_logger/flutter_api_logger.dart';
import 'package:test/test.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._handler);

  final Future<ResponseBody> Function(RequestOptions options) _handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      _handler(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(String body, [int status = 200]) => ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

void main() {
  late List<String> out;

  Dio build(Future<ResponseBody> Function(RequestOptions) handler) {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'));
    dio.httpClientAdapter = _FakeAdapter(handler);
    dio.interceptors.add(
      ApiLoggerDioInterceptor(
        config: ApiLoggerConfig(logColor: false, output: out.add),
      ),
    );
    return dio;
  }

  setUp(() => out = []);

  test('logs a masked request and its response', () async {
    final dio = build((_) async => _json('{"token":"abc","name":"bob"}'));

    final response = await dio.post(
      '/login',
      data: {'password': 'hunter2', 'user': 'bob'},
    );

    expect(response.statusCode, 200);
    expect(out, hasLength(2));
    expect(out[0], contains('POST https://api.test/login'));
    expect(out[0], contains('"password": "***"'));
    expect(out[1], contains('Status: 200'));
    expect(out[1], contains('"token": "***"'));
    expect(out.join(), isNot(contains('hunter2')));
    expect(out.join(), isNot(contains('abc')));
  });

  test('keeps ids and durations separate for concurrent identical urls',
      () async {
    final dio = build((options) async {
      final delay = options.queryParameters['d'] as int;
      await Future<void>.delayed(Duration(milliseconds: delay));
      return _json('{"d":$delay}');
    });

    await Future.wait([
      dio.get('/same', queryParameters: {'d': 120}),
      dio.get('/same', queryParameters: {'d': 5}),
    ]);

    final responses = out.where((m) => m.contains('API RESPONSE')).toList();
    expect(responses, hasLength(2));
    expect(responses.any((m) => m.contains('API RESPONSE #1')), isTrue);
    expect(responses.any((m) => m.contains('API RESPONSE #2')), isTrue);

    int duration(String message) =>
        int.parse(RegExp(r'(\d+) ms').firstMatch(message)!.group(1)!);
    final byId = {
      for (final m in responses)
        RegExp(r'#(\d+)').firstMatch(m)!.group(1)!: duration(m),
    };
    expect(byId['1'], greaterThan(byId['2']!));
  });

  test('logs errors and still propagates them', () async {
    final dio = build((_) async => _json('{"error":"nope"}', 500));

    await expectLater(dio.get('/boom'), throwsA(isA<DioException>()));

    final text = out.last;
    expect(text, contains('Status: 500'));
    expect(text, contains('Error: badResponse'));
  });

  test('describes FormData without leaking secrets', () async {
    final dio = build((_) async => _json('{}'));

    await dio.post(
      '/upload',
      data: FormData.fromMap({
        'password': 'hunter2',
        'name': 'bob',
        'file': MultipartFile.fromBytes([1, 2, 3], filename: 'a.png'),
      }),
    );

    expect(out[0], contains('"name": "bob"'));
    expect(out[0], contains('a.png (3 bytes)'));
    expect(out[0], isNot(contains('hunter2')));
  });

  test('does not break the request when logging is disabled', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = _FakeAdapter((_) async => _json('{"ok":true}'))
      ..interceptors.add(
        ApiLoggerDioInterceptor(
          config: ApiLoggerConfig(enableLog: false, output: out.add),
        ),
      );
    final response = await dio.get('/x');
    expect(response.data, {'ok': true});
    expect(out, isEmpty);
  });
}
