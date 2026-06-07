import 'package:dio/dio.dart';

class CircuitBreaker {
  final int failureThreshold;
  final Duration resetTimeout;
  final List<String>? hostWhitelist;

  int _failureCount = 0;
  DateTime? _openedAt;
  bool _isHalfOpen = false;

  CircuitBreaker({
    this.failureThreshold = 5,
    this.resetTimeout = const Duration(seconds: 30),
    this.hostWhitelist,
  });

  CircuitBreakerState get state {
    if (_openedAt != null) {
      if (_isHalfOpen) return CircuitBreakerState.halfOpen;
      if (DateTime.now().difference(_openedAt!) >= resetTimeout) {
        _isHalfOpen = true;
        return CircuitBreakerState.halfOpen;
      }
      return CircuitBreakerState.open;
    }
    return CircuitBreakerState.closed;
  }

  bool get allowRequest {
    final host = _currentRequestHost;
    if (host != null && hostWhitelist != null && hostWhitelist!.contains(host)) {
      return true;
    }
    return state != CircuitBreakerState.open || _isHalfOpen;
  }

  String? _currentRequestHost;

  void beforeRequest(RequestOptions options) {
    _currentRequestHost = Uri.tryParse(options.baseUrl)?.host ?? options.baseUrl;
  }

  void recordSuccess() {
    if (_isHalfOpen) {
      _failureCount = 0;
      _openedAt = null;
      _isHalfOpen = false;
    } else if (_failureCount > 0) {
      _failureCount = max(0, _failureCount - 1);
    }
  }

  void recordFailure() {
    _failureCount++;
    if (_isHalfOpen) {
      _openedAt = DateTime.now();
      _isHalfOpen = false;
    } else if (_failureCount >= failureThreshold) {
      _openedAt = DateTime.now();
    }
  }
}

enum CircuitBreakerState { closed, open, halfOpen }

class CircuitBreakerInterceptor extends Interceptor {
  final CircuitBreaker breaker;

  CircuitBreakerInterceptor(this.breaker);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    breaker.beforeRequest(options);
    if (!breaker.allowRequest) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          message: 'Circuit breaker is open',
        ),
      );
      return;
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    breaker.recordSuccess();
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      breaker.recordFailure();
    }
    handler.next(err);
  }
}

int max(int a, int b) => a > b ? a : b;
