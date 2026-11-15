import 'package:flutter_api_logger/src/utils.dart';
import 'package:test/test.dart';

const _keys = ['token', 'password', 'authorization'];

void main() {
  group('maskData', () {
    test('masks nested maps and lists', () {
      final masked = LoggerUtils.maskData({
        'user': 'a',
        'password': 'p',
        'profile': {
          'Token': 't',
          'tags': ['x']
        },
        'items': [
          {'authorization': 'z', 'ok': 1},
        ],
      }, _keys, '***');

      expect(masked, {
        'user': 'a',
        'password': '***',
        'profile': {
          'Token': '***',
          'tags': ['x']
        },
        'items': [
          {'authorization': '***', 'ok': 1},
        ],
      });
    });

    test('masks JSON strings', () {
      final masked =
          LoggerUtils.maskData('{"password":"hunter2","n":1}', _keys, '***');
      expect(masked, {'password': '***', 'n': 1});
    });

    test('masks form-encoded strings', () {
      final masked =
          LoggerUtils.maskData('user=bob&password=hunter2', _keys, '***');
      expect(masked, 'user=bob&password=***');
    });

    test('leaves plain text and invalid JSON untouched', () {
      expect(LoggerUtils.maskData('hello world', _keys, '***'), 'hello world');
      expect(LoggerUtils.maskData('{oops', _keys, '***'), '{oops');
    });

    test('does not parse strings when parseStrings is false', () {
      expect(
        LoggerUtils.maskData('{"password":"x"}', _keys, '***',
            parseStrings: false),
        '{"password":"x"}',
      );
    });

    test('does not mutate the input', () {
      final input = {'password': 'p'};
      LoggerUtils.maskData(input, _keys, '***');
      expect(input['password'], 'p');
    });

    test('keeps byte lists as is', () {
      final bytes = [1, 2, 3];
      expect(LoggerUtils.maskData(bytes, _keys, '***'), bytes);
    });
  });

  group('maskUrl', () {
    test('masks sensitive query params and user info', () {
      expect(
        LoggerUtils.maskUrl(
            'https://u:pw@api.test/x?token=abc&page=2', _keys, '***'),
        'https://***@api.test/x?token=***&page=2',
      );
    });

    test('returns urls without query unchanged', () {
      expect(LoggerUtils.maskUrl('https://api.test/x', _keys, '***'),
          'https://api.test/x');
    });
  });

  group('helpers', () {
    test('truncate', () {
      expect(LoggerUtils.truncate('abcdef', 3), 'abc... (truncated)');
      expect(LoggerUtils.truncate('abc', 3), 'abc');
    });

    test('formatJson pretty prints and tolerates plain text', () {
      expect(LoggerUtils.formatJson({'a': 1}), '{\n  "a": 1\n}');
      expect(LoggerUtils.formatJson('plain'), 'plain');
      expect(LoggerUtils.formatJson(null), 'null');
    });

    test('isTextContentType', () {
      expect(LoggerUtils.isTextContentType(null), isTrue);
      expect(LoggerUtils.isTextContentType('application/json'), isTrue);
      expect(LoggerUtils.isTextContentType('text/html; charset=utf-8'), isTrue);
      expect(LoggerUtils.isTextContentType('image/png'), isFalse);
      expect(
          LoggerUtils.isTextContentType('application/octet-stream'), isFalse);
    });

    test('toCurl quotes values safely', () {
      expect(
        LoggerUtils.toCurl(
          method: 'post',
          url: 'https://a.test/x',
          headers: {'A': "it's"},
          body: '{"k":1}',
        ),
        "curl -X POST -H 'A: it'\\''s' -d '{\"k\":1}' 'https://a.test/x'",
      );
    });
  });
}
