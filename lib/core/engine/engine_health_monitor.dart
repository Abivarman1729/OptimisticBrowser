/// Immutable snapshot of browser-engine health metrics.
class EngineHealthSnapshot {
  const EngineHealthSnapshot({
    required this.heartbeatAt,
    required this.navigationCount,
    required this.errorCount,
    required this.averageNavigationMs,
    required this.recentNavigationCount,
    required this.healthy,
  });

  final DateTime heartbeatAt;
  final int navigationCount;
  final int errorCount;
  final double averageNavigationMs;
  final int recentNavigationCount;
  final bool healthy;

  Map<String, Object> toJson() {
    return <String, Object>{
      'heartbeatAt': heartbeatAt.toIso8601String(),
      'navigationCount': navigationCount,
      'errorCount': errorCount,
      'averageNavigationMs': averageNavigationMs,
      'recentNavigationCount': recentNavigationCount,
      'healthy': healthy,
    };
  }

  @override
  String toString() {
    return 'EngineHealthSnapshot('
        'navigationCount: $navigationCount, '
        'errorCount: $errorCount, '
        'averageNavigationMs: $averageNavigationMs, '
        'recentNavigationCount: $recentNavigationCount, '
        'healthy: $healthy'
        ')';
  }
}

/// Lightweight health monitor for the active browser engine.
///
/// This class intentionally does not attempt to restart the engine itself.
/// Restart/recovery decisions belong to the higher-level recovery layer.
class EngineHealthMonitor {
  EngineHealthMonitor({
    this.maxTrackedNavigationSamples = 100,
    this.maxHealthyErrors = 19,
    this.maxAverageNavigationMs = 10000,
  }) : assert(maxTrackedNavigationSamples > 0),
       assert(maxHealthyErrors >= 0),
       assert(maxAverageNavigationMs > 0);

  final int maxTrackedNavigationSamples;
  final int maxHealthyErrors;
  final int maxAverageNavigationMs;

  final List<int> _durations = <int>[];

  int _navigationCount = 0;
  int _errorCount = 0;

  int get navigationCount => _navigationCount;

  int get errorCount => _errorCount;

  int get recentNavigationCount => _durations.length;

  /// Records a completed navigation duration.
  void recordNavigation(Duration duration) {
    final int milliseconds = duration.inMilliseconds < 0
        ? 0
        : duration.inMilliseconds;

    _navigationCount++;
    _durations.add(milliseconds);

    while (_durations.length > maxTrackedNavigationSamples) {
      _durations.removeAt(0);
    }
  }

  /// Records an engine error.
  void recordError() {
    _errorCount++;
  }

  /// Resets all accumulated health metrics.
  void reset() {
    _durations.clear();
    _navigationCount = 0;
    _errorCount = 0;
  }

  /// Returns the average duration of the currently retained samples.
  double get averageNavigationMs {
    if (_durations.isEmpty) {
      return 0.0;
    }

    var total = 0;

    for (final int duration in _durations) {
      total += duration;
    }

    return total / _durations.length;
  }

  /// Whether the current engine health is inside the configured thresholds.
  bool get healthy {
    return _errorCount <= maxHealthyErrors &&
        (_durations.isEmpty || averageNavigationMs < maxAverageNavigationMs);
  }

  EngineHealthSnapshot snapshot() {
    return EngineHealthSnapshot(
      heartbeatAt: DateTime.now(),
      navigationCount: _navigationCount,
      errorCount: _errorCount,
      averageNavigationMs: averageNavigationMs,
      recentNavigationCount: _durations.length,
      healthy: healthy,
    );
  }
}
