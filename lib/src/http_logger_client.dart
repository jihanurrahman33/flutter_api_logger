import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';
import 'logger.dart';
import 'utils.dart';

/// A wrapper around [http.Client] that logs requests and responses.
class ApiLoggerHttpClient extends http.BaseClient {
  final http.Client _inner;
  final ApiLogger _logger;

  ApiLoggerHttpClient({http.Client? inner, ApiLoggerConfig? config})
      : _inner = inner ?? http.Client(),
        _logger = ApiLogger(config: config);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final id = _logger.nextId();
    final url = request.url.toString();
    final stopwatch = Stopwatch()..start();

    _logger.logRequest(
      id: id,
      method: request.method,
      url: url,
      headers: request.headers,
      body: _describeBody(request),
    );

    final http.StreamedResponse response;
    try {
      response = await _inner.send(request);
    } catch (e) {
      _logger.logResponse(
        id: id,
        method: request.method,
        url: url,
        statusCode: 0,
        durationMs: stopwatch.elapsedMilliseconds,
        error: '$e',
      );
      rethrow;
    }

    return _logResponse(id, request, response, stopwatch);
  }

  Future<http.StreamedResponse> _logResponse(
    int id,
    http.BaseRequest request,
    http.StreamedResponse response,
    Stopwatch stopwatch,
  ) async {
    final url = request.url.toString();
    final canRead = _logger.shouldLog(url) &&
        _logger.config.showResponseBody &&
        LoggerUtils.isTextContentType(response.headers['content-type']);

    // Only buffer the stream when the body will actually be logged, so large
    // or binary downloads are passed through untouched.
    if (!canRead) {
      stopwatch.stop();
      _logger.logResponse(
        id: id,
        method: request.method,
        url: url,
        statusCode: response.statusCode,
        durationMs: stopwatch.elapsedMilliseconds,
        headers: response.headers,
        body: response.contentLength == null
            ? null
            : '<${response.contentLength} bytes>',
      );
      return response;
    }

    final bytes = await response.stream.toBytes();
    stopwatch.stop();
    _logger.logResponse(
      id: id,
      method: request.method,
      url: url,
      statusCode: response.statusCode,
      durationMs: stopwatch.elapsedMilliseconds,
      headers: response.headers,
      body: utf8.decode(bytes, allowMalformed: true),
    );

    return http.StreamedResponse(
      http.ByteStream.fromBytes(bytes),
      response.statusCode,
      contentLength: bytes.length,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  dynamic _describeBody(http.BaseRequest request) {
    if (request is http.Request) {
      return request.body.isEmpty ? null : request.body;
    }
    if (request is http.MultipartRequest) {
      return {
        'fields': request.fields,
        'files': [
          for (final f in request.files)
            '${f.field}: ${f.filename ?? 'file'} (${f.length} bytes)',
        ],
      };
    }
    return request.contentLength == null ? null : '<streamed body>';
  }

  @override
  void close() => _inner.close();
}
