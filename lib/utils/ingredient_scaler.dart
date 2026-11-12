/// Ajusta la cantidad de una línea de ingrediente a otro número de raciones.
///
/// Trabaja en local, sin IA: busca la primera cantidad numérica de la línea
/// ("200 g", "1/2 cucharadita", "1 ½ tazas", "2-3 dientes") y la multiplica.
/// Las cantidades escritas con palabras ("una cebolla", "al gusto") se dejan
/// como están, porque reescribirlas exigiría concordar género y número.
class IngredientScaler {
  const IngredientScaler._();

  static const Map<String, double> _unicodeFractions = {
    '½': 1 / 2,
    '¼': 1 / 4,
    '¾': 3 / 4,
    '⅓': 1 / 3,
    '⅔': 2 / 3,
    '⅛': 1 / 8,
  };

  static const String _fractionChars = '½¼¾⅓⅔⅛';

  /// Un número: mixto ("1 1/2"), fracción ("1/2"), decimal o entero con una
  /// fracción unicode opcional pegada ("1½", "1 ½"), o la fracción sola.
  static const String _number =
      '(?:\\d+\\s+\\d+/\\d+|\\d+/\\d+|\\d+(?:[.,]\\d+)?(?:\\s?[$_fractionChars])?|[$_fractionChars])';

  /// Cantidad simple o rango ("2-3", "2 a 3"). No puede ir pegada a una
  /// palabra por delante ("T45") ni seguida de "%" (chocolate al 70 %).
  static final RegExp _quantity = RegExp(
    '(?<![\\p{L}\\d/.,])($_number)(?:(\\s*[-–]\\s*|\\s+a\\s+)($_number))?(?!\\s*%)(?![/\\d])',
    unicode: true,
  );

  /// Raciones de partida de una receta: el primer entero positivo del campo
  /// ("4", "4 personas"). `null` si no hay ninguno.
  static int? baseServings(String raciones) {
    final value = int.tryParse(RegExp(r'\d+').firstMatch(raciones)?.group(0) ?? '');
    return value != null && value > 0 ? value : null;
  }

  /// Devuelve [line] con su primera cantidad multiplicada por [factor].
  static String scale(String line, double factor) {
    if ((factor - 1).abs() < 1e-9) return line;

    final match = _quantity.firstMatch(line);
    if (match == null) return line;

    final first = parse(match.group(1)!);
    if (first == null) return line;

    final separator = match.group(2);
    final secondRaw = match.group(3);
    final second = secondRaw == null ? null : parse(secondRaw);

    // Si la cantidad termina pegada a una unidad ("200g") se conserva igual.
    var replacement = format(first * factor);
    if (separator != null && second != null) {
      replacement += separator + format(second * factor);
    } else if (separator != null && secondRaw != null) {
      replacement += separator + secondRaw;
    }

    return line.replaceRange(match.start, match.end, replacement);
  }

  /// Valor numérico de una cantidad escrita. `null` si no se entiende.
  static double? parse(String raw) {
    var text = raw.trim();
    if (text.isEmpty) return null;

    var extra = 0.0;
    final last = text.substring(text.length - 1);
    if (_unicodeFractions.containsKey(last)) {
      extra = _unicodeFractions[last]!;
      text = text.substring(0, text.length - 1).trim();
      if (text.isEmpty) return extra;
    }

    final mixed = RegExp(r'^(\d+)\s+(\d+)/(\d+)$').firstMatch(text);
    if (mixed != null) {
      final den = int.parse(mixed.group(3)!);
      if (den == 0) return null;
      return int.parse(mixed.group(1)!) + int.parse(mixed.group(2)!) / den + extra;
    }

    final fraction = RegExp(r'^(\d+)/(\d+)$').firstMatch(text);
    if (fraction != null) {
      final den = int.parse(fraction.group(2)!);
      if (den == 0) return null;
      return int.parse(fraction.group(1)!) / den + extra;
    }

    // "1.000" con punto de millares, como se escribe en español.
    if (RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(text)) {
      return double.parse(text.replaceAll('.', '')) + extra;
    }

    final value = double.tryParse(text.replaceAll(',', '.'));
    return value == null ? null : value + extra;
  }

  static const List<(double, String)> _niceFractions = [
    (1 / 4, '1/4'),
    (1 / 3, '1/3'),
    (1 / 2, '1/2'),
    (2 / 3, '2/3'),
    (3 / 4, '3/4'),
  ];

  /// Escribe una cantidad de forma legible en la cocina: enteros a partir de
  /// 10, fracciones habituales por debajo y un decimal como último recurso.
  static String format(double value) {
    if (value <= 0) return '0';
    if (value >= 10) return value.round().toString();

    final whole = value.floor();
    final rest = value - whole;

    if (rest < 0.06) {
      if (whole > 0) return '$whole';
    } else if (rest > 0.94) {
      return '${whole + 1}';
    } else {
      for (final (fraction, text) in _niceFractions) {
        if ((rest - fraction).abs() < 0.04) {
          return whole == 0 ? text : '$whole $text';
        }
      }
    }

    final text = value.toStringAsFixed(1);
    return (text.endsWith('.0') ? text.substring(0, text.length - 2) : text)
        .replaceAll('.', ',');
  }
}
