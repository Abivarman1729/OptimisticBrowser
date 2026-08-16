enum PipState { unavailable, inactive, active }

class PipStateService {
  PipState _state = PipState.inactive;
  double _aspectRatio = 16 / 9;
  List<String> _actions = const [];

  PipState get state => _state;
  double get aspectRatio => _aspectRatio;
  List<String> get actions => List.unmodifiable(_actions);

  void markUnavailable() => _state = PipState.unavailable;

  void enter({
    double aspectRatio = 16 / 9,
    List<String> actions = const [],
  }) {
    if (_state == PipState.unavailable) return;
    _aspectRatio = aspectRatio.clamp(0.5, 2.5);
    _actions = List<String>.from(actions);
    _state = PipState.active;
  }

  void exit() => _state = PipState.inactive;

  bool toggle() {
    if (_state == PipState.unavailable) return false;
    if (_state == PipState.active) {
      exit();
      return false;
    }
    enter();
    return true;
  }

  Map<String, Object?> snapshot() => {
        'state': _state.name,
        'aspectRatio': _aspectRatio,
        'actions': _actions,
      };
}
