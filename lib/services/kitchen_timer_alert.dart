import 'package:aikitchen/services/kitchen_timers.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

FlutterTts? _tts;

/// Aviso de temporizador terminado. Se anuncia en voz alta aunque la lectura
/// de pasos esté desactivada: es la única señal sonora fiable en todas las
/// plataformas, y un temporizador que no se oye no sirve en la cocina.
Future<void> alertTimerFinished(KitchenTimer timer) async {
  HapticFeedback.heavyImpact();
  SystemSound.play(SystemSoundType.alert);
  Toaster.showWarning('Temporizador terminado: ${timer.label}', long: true);

  try {
    final tts = _tts ??= FlutterTts();
    await tts.setLanguage('es-ES');
    await tts.speak('Temporizador terminado. ${timer.label}');
  } catch (_) {
    // Sin voz disponible quedan el aviso en pantalla y la vibración.
  }
}
