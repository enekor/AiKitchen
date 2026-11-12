/// Decide si una línea de ingrediente ("3 cucharadas de aceite de oliva") está
/// cubierta por algún producto de la despensa ("Aceite de oliva").
///
/// Compara palabras, no subcadenas, para que "sal" no cubra "salmón", e
/// ignora tildes, mayúsculas, plurales simples y palabras vacías. Un producto
/// cubre la línea si todas sus palabras significativas aparecen en ella.
class PantryMatcher {
  const PantryMatcher._();

  static const Set<String> _stopWords = {
    'de', 'del', 'la', 'el', 'los', 'las', 'y', 'e', 'en', 'con', 'al', 'a',
    'un', 'una', 'unos', 'unas', 'para', 'o', 'u', 'sin', 'por', 'su',
  };

  static const Map<String, String> _accents = {
    'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'à': 'a',
    'è': 'e', 'ì': 'i', 'ò': 'o', 'ù': 'u',
  };

  /// Unidades que se quitan al limpiar un nombre para la despensa.
  static const String _units =
      r'(?:kg|kilos?|kilogramos?|g|gr|grs|gramos?|mg|ml|cl|dl|l|litros?|'
      r'cucharadas?|cucharaditas?|cdas?|cdtas?|cdas?\.|cdtas?\.|'
      r'tazas?|vasos?|pizcas?|chorritos?|chorros?|puñados?|dientes?|latas?|'
      r'botes?|paquetes?|sobres?|unidades?|uds?\.?|rodajas?|ramitas?|ramas?|'
      r'hojas?|lonchas?|filetes?|trozos?|tarros?|botellas?|bricks?|piezas?|'
      r'manojos?|cabezas?|tiras?|cubitos?|pastillas?|bolsas?|mallas?|docenas?)';

  static String normalize(String text) {
    final lower = text.toLowerCase();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_accents[char] ?? char);
    }
    return buffer.toString();
  }

  /// Palabras significativas, sin números ni palabras vacías.
  static List<String> _words(String text) {
    return normalize(text)
        .split(RegExp(r'[^a-zñ]+'))
        .where((w) => w.length > 1 && !_stopWords.contains(w))
        .toList();
  }

  /// Formas con las que puede aparecer una palabra: tal cual y sin la "s" o
  /// "es" del plural. Así "tomates" y "tomate", o "limones" y "limón",
  /// comparten al menos una forma.
  static Set<String> _forms(String word) {
    return {
      word,
      if (word.length > 3 && word.endsWith('s')) word.substring(0, word.length - 1),
      if (word.length > 4 && word.endsWith('es')) word.substring(0, word.length - 2),
    };
  }

  static bool _sameWord(String a, String b) =>
      _forms(a).intersection(_forms(b)).isNotEmpty;

  /// Si algún producto de [pantry] cubre la línea [ingredient].
  static bool isCovered(String ingredient, Iterable<String> pantry) {
    final ingredientWords = _words(ingredient);
    if (ingredientWords.isEmpty) return false;

    for (final item in pantry) {
      final itemWords = _words(item);
      if (itemWords.isEmpty) continue;
      final allPresent = itemWords.every(
        (iw) => ingredientWords.any((w) => _sameWord(iw, w)),
      );
      if (allPresent) return true;
    }
    return false;
  }

  /// Si dos nombres de producto son el mismo a efectos de la despensa
  /// ("Huevos" y "huevo"), para no guardarlos dos veces.
  static bool sameProduct(String a, String b) {
    final wa = _words(a);
    final wb = _words(b);
    if (wa.isEmpty || wa.length != wb.length) {
      return normalize(a).trim() == normalize(b).trim();
    }
    for (var i = 0; i < wa.length; i++) {
      if (!_sameWord(wa[i], wb[i])) return false;
    }
    return true;
  }

  /// Nombre de producto a partir de una línea de compra o de receta:
  /// "2 kg de patatas" pasa a "Patatas" y "3 dientes de ajo, picados" a "Ajo".
  static String cleanName(String line) {
    var text = line.trim();

    // Lo que va entre paréntesis o tras una coma suele ser preparación.
    text = text.replaceAll(RegExp(r'\([^)]*\)'), ' ');
    final comma = text.indexOf(',');
    if (comma > 0) text = text.substring(0, comma);

    text = text
        .replaceFirst(RegExp(r'^[\d½¼¾⅓⅔⅛.,/\s\-–]+(?:a\s+[\d½¼¾⅓⅔⅛.,/]+\s*)?'), '')
        .replaceFirst(
          RegExp('^$_units(?![a-záéíóúüñ])\\s*', caseSensitive: false),
          '',
        )
        .replaceFirst(RegExp(r'^de\s+', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (text.isEmpty) return line.trim();
    return text[0].toUpperCase() + text.substring(1);
  }
}
