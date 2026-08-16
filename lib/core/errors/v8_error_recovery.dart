import 'dart:async';

enum BrowserErrorKind {
  network,
  timeout,
  certificate,
  blocked,
  storage,
  engine,
  permission,
  download,
  upload,
  ai,
  unknown,
}

class BrowserFailure {
  const BrowserFailure({
    required this.kind,
    required this.message,
    this.retryable = false,
    this.cause,
  });

  final BrowserErrorKind kind;
  final String message;
  final bool retryable;
  final Object? cause;
}

class ErrorRecovery {
  const ErrorRecovery();

  BrowserFailure classify(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('timeout')) {
      return BrowserFailure(
        kind: BrowserErrorKind.timeout,
        message: 'The operation timed out.',
        retryable: true,
        cause: error,
      );
    }
    if (text.contains('certificate') || text.contains('ssl')) {
      return BrowserFailure(
        kind: BrowserErrorKind.certificate,
        message: 'The certificate could not be validated.',
        retryable: false,
        cause: error,
      );
    }
    if (text.contains('permission')) {
      return BrowserFailure(
        kind: BrowserErrorKind.permission,
        message: 'The requested permission was not available.',
        retryable: false,
        cause: error,
      );
    }
    if (text.contains('socket') || text.contains('network')) {
      return BrowserFailure(
        kind: BrowserErrorKind.network,
        message: 'A network error occurred.',
        retryable: true,
        cause: error,
      );
    }
    return BrowserFailure(
      kind: BrowserErrorKind.unknown,
      message: 'An unexpected browser error occurred.',
      retryable: false,
      cause: error,
    );
  }

  Future<T> retry<T>(
    Future<T> Function() action, {
    int attempts = 3,
    Duration delay = const Duration(milliseconds: 300),
  }) async {
    Object? lastError;
    StackTrace? lastStack;
    for (var i = 0; i < attempts; i++) {
      try {
        return await action();
      } catch (error, stack) {
        lastError = error;
        lastStack = stack;
        if (i + 1 < attempts) {
          await Future<void>.delayed(delay * (i + 1));
        }
      }
    }
    Error.throwWithStackTrace(lastError ?? StateError('Retry failed'), lastStack ?? StackTrace.current);
  }
}
