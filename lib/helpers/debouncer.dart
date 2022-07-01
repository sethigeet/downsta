import 'dart:async';

class Debouncer<T> {
  Debouncer({required this.duration, required this.cb});

  final Duration duration;
  void Function(T? value) cb;

  T? _value;
  Timer? _timer;

  T? get value => _value;
  set value(T? val) {
    _value = val;
    _timer?.cancel();
    _timer = Timer(duration, () => cb(_value));
  }
}
