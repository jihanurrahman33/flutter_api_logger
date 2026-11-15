import 'package:dio/dio.dart';

import 'config.dart';
import 'logger.dart';

/// Dio interceptor that logs requests, responses and errors.
class ApiLoggerDioInterceptor extends Interceptor {
  static const String _idKey = 'flutter_api_logger.id';
  static const String _startKey = 'flutter_api_logger.start';

  final ApiLogger _logger;

  ApiLoggerDioInterceptor({ApiLoggerConfig? config})
      : _logger = ApiLogger(config: config);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final id = _logger.nextId();
    options.extra[_idKey] = id;
    options.extra[_startKey] = DateTime.now().millisecondsSinceEpoch;

    _logger.logRequest(
      id: id,
      method: options.method,
      url: options.uri.toString(),
      headers: options.headers,
      body: _describeBody(options.data),
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final options = response.requestOptions;
    _logger.logResponse(
      id: options.extra[_idKey] as int?,
      method: options.method,
      url: options.uri.toString(),
      statusCode: response.statusCode ?? 0,
      durationMs: _elapsed(options),
      headers: response.headers.map,
      body: _describeBody(response.data),
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final options = err.requestOptions;
    _logger.logResponse(
      id: options.extra[_idKey] as int?,
      method: options.method,
      url: options.uri.toString(),
      statusCode: err.response?.statusCode ?? 0,
      durationMs: _elapsed(options),
      headers: err.response?.headers.map,
      body: err.response?.data,
      error: _describeError(err),
    );
    handler.next(err);
  }

  /// Dio's message for bad responses is long boilerplate; the type suffices
  /// when the server answered.
  String _describeError(DioException err) {
    final message = err.message;
    if (err.response != null || message == null) return err.type.name;
    return '${err.type.name}: $message';
  }

  int _elapsed(RequestOptions options) {
    final start = options.extra[_startKey] as int?;
    return start == null ? 0 : DateTime.now().millisecondsSinceEpoch - start;
  }

  /// Dio's [FormData] has no useful `toString`, so describe it explicitly.
  dynamic _describeBody(dynamic data) {
    if (data is FormData) {
      return {
        'fields': {for (final f in data.fields) f.key: f.value},
        'files': [
          for (final f in data.files)
            '${f.key}: ${f.value.filename ?? 'file'} (${f.value.length} bytes)',
        ],
      };
    }
    return data;
  }
}
