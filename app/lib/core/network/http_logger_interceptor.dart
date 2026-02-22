import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Global HTTP logger interceptor. Logs request and response (headers, body).
/// Only logs when [kDebugMode] is true.
class HttpLoggerInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!kDebugMode) {
      handler.next(options);
      return;
    }
    final buffer = StringBuffer();
    buffer.writeln('┌────────── HTTP REQUEST ──────────');
    buffer.writeln('│ ${options.method} ${options.uri}');
    buffer.writeln('│ Headers: ${options.headers}');
    if (options.queryParameters.isNotEmpty) {
      buffer.writeln('│ Query: ${options.queryParameters}');
    }
    if (options.data != null) {
      buffer.writeln('│ Body: ${_bodyToString(options.data)}');
    }
    buffer.writeln('└──────────────────────────────────');
    // ignore: avoid_print
    print(buffer.toString());
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (!kDebugMode) {
      handler.next(response);
      return;
    }
    final buffer = StringBuffer();
    buffer.writeln('┌────────── HTTP RESPONSE ──────────');
    buffer.writeln('│ ${response.requestOptions.method} ${response.requestOptions.uri}');
    buffer.writeln('│ Status: ${response.statusCode}');
    buffer.writeln('│ Headers: ${response.headers.map}');
    buffer.writeln('│ Data: ${_bodyToString(response.data)}');
    buffer.writeln('└──────────────────────────────────');
    // ignore: avoid_print
    print(buffer.toString());
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!kDebugMode) {
      handler.next(err);
      return;
    }
    final buffer = StringBuffer();
    buffer.writeln('┌────────── HTTP ERROR ──────────');
    buffer.writeln('│ ${err.requestOptions.method} ${err.requestOptions.uri}');
    buffer.writeln('│ Message: ${err.message}');
    if (err.response != null) {
      buffer.writeln('│ Status: ${err.response?.statusCode}');
      buffer.writeln('│ Headers: ${err.response?.headers.map}');
      buffer.writeln('│ Data: ${_bodyToString(err.response?.data)}');
    }
    buffer.writeln('└──────────────────────────────────');
    // ignore: avoid_print
    print(buffer.toString());
    handler.next(err);
  }

  static String _bodyToString(dynamic data) {
    if (data == null) return 'null';
    if (data is FormData) return '[FormData]';
    if (data is List<int>) return '[Binary ${data.length} bytes]';
    if (data is String && data.length > 500) return 'String(${data.length} chars)';
    return data.toString();
  }
}
