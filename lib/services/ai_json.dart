import 'dart:convert';

/// La respuesta de la IA no contenía un JSON utilizable.
class AiJsonException implements Exception {
  const AiJsonException(this.message, {this.truncated = false});

  final String message;

  /// El JSON empezaba bien pero se cortó antes de cerrarse: casi siempre es
  /// que la respuesta superó el máximo de tokens de salida.
  final bool truncated;

  @override
  String toString() => message;
}

/// Saca el JSON de la respuesta de un modelo, por desordenada que venga.
///
/// Los modelos a veces añaden texto antes o después, lo envuelven en un bloque
/// de código, incluyen su razonamiento entre etiquetas `<think>` o repiten el
/// JSON dos veces. Aquí se ignora todo eso y se devuelve el primer valor JSON
/// completo y válido, reescrito de forma compacta.
class AiJson {
  const AiJson._();

  static String extract(String raw) {
    final text = raw
        .replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '')
        // Un <think> sin cerrar: todo lo que sigue es razonamiento.
        .replaceAll(RegExp(r'<think>.*', dotAll: true), '')
        .replaceAll(RegExp(r'```[a-zA-Z]*'), '');

    var searchFrom = 0;

    while (true) {
      final start = _nextOpening(text, searchFrom);
      if (start == -1) break;

      final end = _matchingClose(text, start);
      if (end == _endOfText) {
        // Abre y el texto se acaba sin cerrarlo: la respuesta está cortada.
        // No se busca dentro, porque devolvería un trozo (una sola receta
        // de la lista, por ejemplo) como si fuera la respuesta entera.
        throw const AiJsonException(
          'La respuesta de la IA llegó cortada.',
          truncated: true,
        );
      }
      if (end == _mismatch) {
        searchFrom = start + 1;
        continue;
      }

      final candidate = text.substring(start, end + 1);
      try {
        final decoded = jsonDecode(candidate);
        // Todos los prompts piden un objeto o una lista de objetos. Así no se
        // confunde con JSON un "[1]" que aparezca en el texto de alrededor.
        final usable = decoded is Map ||
            (decoded is List && decoded.isNotEmpty && decoded.every((e) => e is Map));
        if (usable) return jsonEncode(decoded);
      } catch (_) {
        // Equilibrado pero no es JSON válido; se sigue buscando más adelante.
      }
      searchFrom = start + 1;
    }

    throw const AiJsonException('La IA no devolvió un JSON válido.');
  }

  static const int _endOfText = -1;
  static const int _mismatch = -2;

  static int _nextOpening(String text, int from) {
    for (var i = from; i < text.length; i++) {
      final c = text[i];
      if (c == '{' || c == '[') return i;
    }
    return -1;
  }

  /// Posición del cierre que empareja con la apertura en [start], teniendo en
  /// cuenta las cadenas y sus escapes. [_endOfText] si el texto acaba antes de
  /// cerrarse y [_mismatch] si los cierres no casan.
  static int _matchingClose(String text, int start) {
    final stack = <String>[];
    var inString = false;
    var escaped = false;

    for (var i = start; i < text.length; i++) {
      final c = text[i];
      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (c == r'\') {
          escaped = true;
        } else if (c == '"') {
          inString = false;
        }
        continue;
      }
      switch (c) {
        case '"':
          inString = true;
        case '{':
          stack.add('}');
        case '[':
          stack.add(']');
        case '}':
        case ']':
          if (stack.isEmpty || stack.removeLast() != c) return _mismatch;
          if (stack.isEmpty) return i;
      }
    }
    return _endOfText;
  }
}
