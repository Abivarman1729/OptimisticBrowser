
enum AppErrorType {
  network,
  searchProvider,
  navigationBlocked,
  aiProvider,
  database,
  timeout,
  permission,
  certificate,
  validation,
  unknown,
}

class AppError implements Exception {
  const AppError(this.type, this.message, {this.cause});

  final AppErrorType type;
  final String message;
  final Object? cause;

  @override
  String toString() => 'AppError(${type.name}): $message';
}
