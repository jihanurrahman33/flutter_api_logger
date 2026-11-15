import 'dart:convert';

import 'package:flutter_api_logger/flutter_api_logger.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  late List<String> out;

  ApiLoggerHttpClient build(http.Client inner) => ApiLoggerHttpClient(
        inner: inner,
        config: ApiLoggerConfig(logColor: false, output: out.add),
      );

  setUp(() => out = []);

  test('logs masked request and response and returns the body', () async {
    final client = build(MockClient((request) async => http.Response(
          '{"token":"abc","name":"বাংলা"}',
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        )));

    final response = await client.post(
      Uri.parse('https://api.test/login'),
      headers: {'Authorization': 'Bearer secret'},
      body: '{"password":"hunter2"}',
    );

    expect(jsonDecode(response.body)['name'], 'বাংলা');
    expect(out, hasLength(2));
    expect(out[0], contains('POST https://api.test/login'));
    expect(out[1], contains('বাংলা'));
    final all = out.join();
    for (final secret in ['hunter2', 'secret', 'abc']) {
      expect(all, isNot(contains(secret)));
    }
  });

  test('does not buffer binary responses', () async {
    final client =
        build(MockClient.streaming((request, _) async => http.StreamedResponse(
              Stream.value([1, 2, 3]),
              200,
              contentLength: 3,
              headers: {'content-type': 'image/png'},
            )));

    final response = await client.get(Uri.parse('https://api.test/a.png'));

    expect(response.bodyBytes, [1, 2, 3]);
    expect(out[1], contains('<3 bytes>'));
  });

  test('skips reading the body when showResponseBody is false', () async {
    final client = ApiLoggerHttpClient(
      inner: MockClient((_) async => http.Response('{"a":1}', 200)),
      config: ApiLoggerConfig(
        logColor: false,
        showResponseBody: false,
        output: out.add,
      ),
    );
    final response = await client.get(Uri.parse('https://api.test/x'));
    expect(response.body, '{"a":1}');
    expect(out[1], isNot(contains('"a"')));
  });

  test('logs failures and rethrows', () async {
    final client =
        build(MockClient((_) async => throw http.ClientException('offline')));

    await expectLater(
      client.get(Uri.parse('https://api.test/x')),
      throwsA(isA<http.ClientException>()),
    );
    expect(out.last, contains('Status: FAILED'));
    expect(out.last, contains('offline'));
  });

  test('describes multipart requests without leaking secrets', () async {
    final client = build(MockClient((_) async => http.Response('{}', 200)));
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.test/up'),
    )
      ..fields['password'] = 'hunter2'
      ..fields['name'] = 'bob'
      ..files.add(http.MultipartFile.fromBytes('f', [1, 2], filename: 'a.bin'));

    await client.send(request);

    expect(out[0], contains('"name": "bob"'));
    expect(out[0], contains('f: a.bin (2 bytes)'));
    expect(out[0], isNot(contains('hunter2')));
  });
}
