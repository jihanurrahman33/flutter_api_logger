import 'package:http/http.dart' as http;
import 'config.dart';
import 'logger.dart';

/// A wrapper around [http.Client] that logs requests and responses.
class ApiLoggerHttpClient extends http.BaseClient {
  final http.Client _inner;
  final ApiLogger _logger;

  ApiLoggerHttpClient({
    http.Client? inner,
    ApiLoggerConfig? config,
  })  : _inner = inner ?? http.Client(),
        _logger = ApiLogger(config: config);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final startTime = DateTime.now();

    // Log Request
    // Note: StreamedRequest body reading is one-off, so we might not be able to read
    // body of http.StreamedRequest unless we buffer it.
    // http.BaseRequest doesn't easily expose body if it's streamed.
    // Most users use http.Request which has .body or .bodyBytes.

    dynamic body;
    if (request is http.Request) {
      body = request.body;
      if (body.isEmpty) body = null;
    } else if (request is http.MultipartRequest) {
      body = "MultipartRequest: ${request.fields}";
    }

    _logger.logRequest(
      method: request.method,
      url: request.url.toString(),
      headers: request.headers,
      body: body,
    );

    try {
      final response = await _inner.send(request);
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds;

      // To log response body, we need to read the stream.
      // But StreamedResponse.stream is single subscription.
      // If we read it here, the caller cannot read it.
      // We must replace the stream.

      final content = await response.stream.toBytes();
      final responseBody = String.fromCharCodes(content);

      _logger.logResponse(
        url: request.url.toString(),
        statusCode: response.statusCode,
        durationMs: duration,
        body: responseBody,
        method: request.method,
      );

      // Return a new StreamedResponse with the same content
      return http.StreamedResponse(
        http.ByteStream.fromBytes(content),
        response.statusCode,
        contentLength: response.contentLength,
        request: response.request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
      );
    } catch (e) {
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds;
      _logger.logResponse(
          url: request.url.toString(),
          statusCode: 0, // 0 for error
          durationMs: duration,
          body: "Error: $e",
          method: request.method);
      rethrow;
    }
  }

  @override
  void close() {
    _inner.close();
  }
}
