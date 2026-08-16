class EngineHealthSnapshot {
  const EngineHealthSnapshot({
    required this.heartbeatAt,
    required this.navigationCount,
    required this.errorCount,
    required this.averageNavigationMs,
  });
  final DateTime heartbeatAt;
  final int navigationCount;
  final int errorCount;
  final double averageNavigationMs;
}

class EngineHealthMonitor {
  final List<int> _durations = [];
  int _navigationCount = 0;
  int _errorCount = 0;

  void recordNavigation(Duration duration) {
    _navigationCount++;
    _durations.add(duration.inMilliseconds);
    if (_durations.length > 100) _durations.removeAt(0);
  }

  void recordError() => _errorCount++;

  EngineHealthSnapshot snapshot() {
    final average = _durations.isEmpty
        ? 0.0
        : _durations.reduce((a, b) => a + b) / _durations.length;
    return EngineHealthSnapshot(
      heartbeatAt: DateTime.now(),
      navigationCount: _navigationCount,
      errorCount: _errorCount,
      averageNavigationMs: average,
    );
  }

  bool get healthy =>
      _errorCount < 20 &&
      (_durations.isEmpty || snapshot().averageNavigationMs < 10000);
}
