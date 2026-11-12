import 'dart:async';

import 'package:flutter/foundation.dart';

/// Un temporizador de cocina. Guarda la hora a la que termina, no los segundos
/// que le quedan: así sigue siendo exacto aunque la app pase un rato en
/// segundo plano y el ticker no se ejecute.
class KitchenTimer {
  KitchenTimer._({
    required this.id,
    required this.label,
    required this.total,
    required DateTime endsAt,
  }) : _endsAt = endsAt;

  final int id;
  final String label;
  final Duration total;

  DateTime _endsAt;
  Duration? _pausedRemaining;
  bool _finished = false;

  bool get isPaused => _pausedRemaining != null;
  bool get isFinished => _finished;
  bool get isRunning => !isPaused && !isFinished;

  Duration _remainingAt(DateTime now) {
    if (_finished) return Duration.zero;
    if (_pausedRemaining != null) return _pausedRemaining!;
    final remaining = _endsAt.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }
}

/// Temporizadores activos de toda la app. Viven fuera de las pantallas para
/// que sigan contando al salir del modo cocina o cambiar de receta.
class KitchenTimers extends ChangeNotifier {
  KitchenTimers({
    DateTime Function()? now,
    this.onFinished,
    this.autoTick = true,
  }) : _now = now ?? DateTime.now;

  static final KitchenTimers instance = KitchenTimers();

  final DateTime Function() _now;

  /// Se llama una vez por temporizador al llegar a cero: sonido, vibración,
  /// aviso... Se asigna al arrancar la app.
  void Function(KitchenTimer timer)? onFinished;

  /// En pruebas se desactiva y se llama a [tick] a mano.
  final bool autoTick;

  final List<KitchenTimer> _timers = [];
  Timer? _ticker;
  int _nextId = 1;

  List<KitchenTimer> get timers => List.unmodifiable(_timers);
  bool get isEmpty => _timers.isEmpty;

  Duration remaining(KitchenTimer timer) => timer._remainingAt(_now());

  KitchenTimer start(String label, Duration duration) {
    final timer = KitchenTimer._(
      id: _nextId++,
      label: label,
      total: duration,
      endsAt: _now().add(duration),
    );
    _timers.add(timer);
    _ensureTicker();
    notifyListeners();
    return timer;
  }

  void pause(KitchenTimer timer) {
    if (!timer.isRunning) return;
    timer._pausedRemaining = timer._remainingAt(_now());
    notifyListeners();
  }

  void resume(KitchenTimer timer) {
    if (!timer.isPaused) return;
    timer._endsAt = _now().add(timer._pausedRemaining!);
    timer._pausedRemaining = null;
    _ensureTicker();
    notifyListeners();
  }

  void togglePause(KitchenTimer timer) =>
      timer.isPaused ? resume(timer) : pause(timer);

  /// Quita el temporizador, tanto si está en marcha como si ya sonó.
  void cancel(KitchenTimer timer) {
    _timers.removeWhere((t) => t.id == timer.id);
    _stopTickerIfIdle();
    notifyListeners();
  }

  /// Comprueba cuáles han llegado a cero y refresca las cuentas atrás.
  @visibleForTesting
  void tick() {
    final now = _now();
    for (final timer in _timers) {
      if (timer.isRunning && !timer._endsAt.isAfter(now)) {
        timer._finished = true;
        onFinished?.call(timer);
      }
    }
    _stopTickerIfIdle();
    notifyListeners();
  }

  void _ensureTicker() {
    if (!autoTick || _ticker != null) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  void _stopTickerIfIdle() {
    if (_timers.any((t) => t.isRunning)) return;
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
