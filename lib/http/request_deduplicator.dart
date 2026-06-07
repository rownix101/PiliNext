import 'dart:async';

import 'package:dio/dio.dart';

class RequestDeduplicator extends Interceptor {
  final Map<String, _PendingEntry> _pending = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final key = _requestKey(options);
    final entry = _pending[key];
    if (entry != null) {
      entry.completer.future.then(
        (response) => handler.resolve(
          Response(
            requestOptions: options,
            data: response.data,
            statusCode: response.statusCode,
            statusMessage: response.statusMessage,
            headers: response.headers,
            extra: response.extra,
          ),
        ),
        onError: (error) {
          if (error is DioException) {
            handler.reject(
              DioException(
                requestOptions: options,
                error: error.error,
                type: error.type,
                message: error.message,
                response: error.response,
              ),
            );
          } else {
            handler.reject(DioException(
              requestOptions: options,
              error: error,
            ));
          }
        },
      );
      return;
    }
    final completer = Completer<Response>();
    _pending[key] = _PendingEntry(completer);
    options.extra['_dedup_key'] = key;
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _complete(response.requestOptions, response);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _complete(err.requestOptions, null, error: err);
    handler.next(err);
  }

  void _complete(RequestOptions options, Response? response,
      {DioException? error}) {
    final key = options.extra['_dedup_key'] as String?;
    if (key == null) return;
    final entry = _pending.remove(key);
    if (entry == null || entry.completer.isCompleted) return;
    if (error != null) {
      entry.completer.completeError(error);
    } else {
      entry.completer.complete(response!);
    }
  }

  String _requestKey(RequestOptions options) {
    final data = options.data;
    String dataStr = '';
    if (data != null) {
      dataStr = data is Map ? data.entries.map((e) => '${e.key}=${e.value}').join('&') : data.toString();
    }
    return '${options.method}:${options.baseUrl}${options.path}?${_sortedQuery(options.queryParameters)}|$dataStr';
  }

  String _sortedQuery(Map<String, dynamic>? query) {
    if (query == null || query.isEmpty) return '';
    final keys = query.keys.toList()..sort();
    return keys.map((k) => '$k=${query[k]}').join('&');
  }
}

class _PendingEntry {
  final Completer<Response> completer;

  _PendingEntry(this.completer);
}
