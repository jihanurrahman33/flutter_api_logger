import 'package:dio/dio.dart';
import 'config.dart';
import 'logger.dart';

/// Dio Interceptor for logging API requests and responses.
class ApiLoggerDioInterceptor extends Interceptor {
  final ApiLogger _logger;
  final Map<String, int> _requestTimestamps = {};

  ApiLoggerDioInterceptor({ApiLoggerConfig? config})
      : _logger = ApiLogger(config: config);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _requestTimestamps[options.uri.toString()] =
        DateTime.now().millisecondsSinceEpoch;

    _logger.logRequest(
      method: options.method,
      url: options.uri.toString(),
      headers: options.headers,
      body: options.data,
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final startTime =
        _requestTimestamps.remove(response.requestOptions.uri.toString());
    final duration = startTime != null
        ? DateTime.now().millisecondsSinceEpoch - startTime
        : 0;

    _logger.logResponse(
      url: response.requestOptions.uri.toString(),
      statusCode: response.statusCode ?? 0,
      durationMs: duration,
      body: response.data,
      method: response.requestOptions.method,
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final startTime =
        _requestTimestamps.remove(err.requestOptions.uri.toString());
    final duration = startTime != null
        ? DateTime.now().millisecondsSinceEpoch - startTime
        : 0;

    _logger.logResponse(
      url: err.requestOptions.uri.toString(),
      statusCode: err.response?.statusCode ?? 0,
      durationMs: duration,
      body: err.response?.data ?? err.message,
      method: err.requestOptions.method,
    );
    handler.next(err);
  }
}
