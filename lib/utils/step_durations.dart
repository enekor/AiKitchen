/// Una duración encontrada en el texto de un paso de receta.
class DetectedDuration {
  const DetectedDuration(this.duration, this.start);

  final Duration duration;

  /// Posición en el texto, para ordenar los hallazgos como aparecen.
  final int start;

  String get label => formatDuration(duration);
}

/// Busca tiempos de cocción en el texto de un paso ("hornea 20 minutos",
/// "1 h 30 min", "media hora", "15-20 minutos") para ofrecer un temporizador
/// con un toque. En los rangos se toma el valor menor: es cuando conviene
/// mirar, y siempre se puede añadir otro.
class StepDurations {
  const StepDurations._();

  static const Map<String, int> _wordNumbers = {
    'un': 1,
    'una': 1,
    'dos': 2,
    'tres': 3,
    'cuatro': 4,
    'cinco': 5,
    'seis': 6,
    'siete': 7,
    'ocho': 8,
    'nueve': 9,
    'diez': 10,
    'quince': 15,
    'veinte': 20,
    'treinta': 30,
  };

  static const String _hours = r'(?:horas?|hrs?|h)';
  static const String _minutes = r'(?:minutos?|mins?|min|m)';
  static const String _seconds = r'(?:segundos?|segs?|seg)';
  static const String _num = r'(\d+(?:[.,]\d+)?)';

  static final List<(RegExp, Duration? Function(RegExpMatch))> _rules = [
    // "1 h 30 min", "2 horas y 15 minutos"
    (
      RegExp('(\\d+)\\s*$_hours\\s*(?:y\\s*)?(\\d+)\\s*$_minutes(?![a-záéíóúüñ])'),
      (m) => Duration(
        hours: int.parse(m.group(1)!),
        minutes: int.parse(m.group(2)!),
      ),
    ),
    // "1 hora y media", "una hora y media"
    (
      RegExp('(\\d+|una?)\\s+horas?\\s+y\\s+media'),
      (m) => Duration(hours: _toInt(m.group(1)!), minutes: 30),
    ),
    (RegExp(r'media\s+hora'), (_) => const Duration(minutes: 30)),
    (RegExp(r'tres\s+cuartos\s+de\s+hora'), (_) => const Duration(minutes: 45)),
    (RegExp(r'(?:un\s+)?cuarto\s+de\s+hora'), (_) => const Duration(minutes: 15)),
    // "20 minutos", "15-20 min", "10 a 12 minutos", "1,5 horas", "30 segundos"
    (
      RegExp(
        '(?<![\\d.,])$_num(?:\\s*[-–]\\s*|\\s+(?:a|o)\\s+)?(?:\\d+(?:[.,]\\d+)?)?\\s*($_hours|$_minutes|$_seconds)(?![a-záéíóúüñ])',
      ),
      (m) {
        final value = double.parse(m.group(1)!.replaceAll(',', '.'));
        final unit = m.group(2)!;
        if (unit.startsWith('h')) return Duration(seconds: (value * 3600).round());
        if (unit.startsWith('s')) return Duration(seconds: value.round());
        return Duration(seconds: (value * 60).round());
      },
    ),
    // "dos minutos", "una hora"
    (
      RegExp(
        '(?<![a-záéíóúüñ])(${_wordNumbers.keys.join('|')})\\s+(horas?|minutos?)(?![a-záéíóúüñ])',
      ),
      (m) {
        final value = _wordNumbers[m.group(1)!]!;
        return m.group(2)!.startsWith('h')
            ? Duration(hours: value)
            : Duration(minutes: value);
      },
    ),
  ];

  static int _toInt(String value) => int.tryParse(value) ?? 1;

  /// Duraciones del texto, sin repetir y en el orden en que aparecen.
  static List<DetectedDuration> find(String text) {
    final lower = text.toLowerCase();
    final taken = <(int, int)>[];
    final found = <DetectedDuration>[];

    bool overlaps(int start, int end) =>
        taken.any((span) => start < span.$2 && end > span.$1);

    for (final (pattern, toDuration) in _rules) {
      for (final match in pattern.allMatches(lower)) {
        if (overlaps(match.start, match.end)) continue;
        final duration = toDuration(match);
        if (duration == null ||
            duration <= Duration.zero ||
            duration > const Duration(hours: 24)) {
          continue;
        }
        taken.add((match.start, match.end));
        found.add(DetectedDuration(duration, match.start));
      }
    }

    found.sort((a, b) => a.start.compareTo(b.start));
    final seen = <Duration>{};
    return [
      for (final d in found)
        if (seen.add(d.duration)) d,
    ];
  }
}

/// "1 h 30 min", "20 min", "45 s".
String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  final seconds = duration.inSeconds % 60;
  final parts = <String>[
    if (hours > 0) '$hours h',
    if (minutes > 0) '$minutes min',
    if (seconds > 0 && hours == 0) '$seconds s',
  ];
  return parts.isEmpty ? '0 s' : parts.join(' ');
}

/// Cuenta atrás de reloj: "04:59" o "1:04:59".
String formatCountdown(Duration duration) {
  final total = duration.inSeconds < 0 ? 0 : duration.inSeconds;
  final hours = total ~/ 3600;
  final minutes = (total % 3600) ~/ 60;
  final seconds = total % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  return hours > 0
      ? '$hours:${two(minutes)}:${two(seconds)}'
      : '${two(minutes)}:${two(seconds)}';
}
