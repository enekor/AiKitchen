import 'dart:convert';

import 'package:aikitchen/models/recipe.dart';
import 'package:flutter/foundation.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse, parseFragment;

/// Extrae una receta de los datos estructurados (schema.org/Recipe) que casi
/// todas las webs de recetas incrustan en su HTML, sin depender de la
/// maquetación concreta de cada sitio.
///
/// Google exige este marcado para mostrar recetas en sus resultados, así que
/// lo publican Lidl, Cookpad, Hogarmania, Bon Viveur, Allrecipes, BBC Good
/// Food y la mayoría de blogs de cocina. Se intenta primero JSON-LD, que es
/// el formato más extendido, y después microdata (`itemprop`), más antiguo.
///
/// Devuelve `null` si la página no trae una receta reconocible: entonces el
/// llamante debe recurrir a un parser específico del sitio o a la IA.
class StructuredRecipeExtractor {
  const StructuredRecipeExtractor._();

  static const String tiempoDesconocido = 'No indicado';
  static const String caloriasDesconocidas = 'No especificado';

  static Recipe? extract(String html) {
    try {
      final document = parse(html);
      return _fromJsonLd(document) ?? _fromMicrodata(document);
    } catch (e) {
      debugPrint('Error extrayendo receta estructurada: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------- JSON-LD

  static Recipe? _fromJsonLd(Document document) {
    final scripts = document.querySelectorAll(
      'script[type="application/ld+json"]',
    );
    for (final script in scripts) {
      dynamic data;
      try {
        data = jsonDecode(script.text);
      } catch (_) {
        // JSON mal formado: probamos con el siguiente bloque.
        continue;
      }
      final node = _findRecipeNode(data);
      if (node == null) continue;
      final recipe = _recipeFromJsonLd(node);
      if (recipe != null) return recipe;
    }
    return null;
  }

  /// Busca en profundidad el primer objeto cuyo `@type` sea `Recipe`.
  /// Contempla listas, `@graph` y entidades anidadas (`mainEntity`...).
  static Map<String, dynamic>? _findRecipeNode(dynamic data, [int depth = 0]) {
    if (depth > 6) return null;
    if (data is List) {
      for (final item in data) {
        final found = _findRecipeNode(item, depth + 1);
        if (found != null) return found;
      }
      return null;
    }
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      if (_isType(map['@type'], 'Recipe')) return map;
      for (final key in const [
        '@graph',
        'mainEntity',
        'mainEntityOfPage',
        'itemListElement',
        'item',
      ]) {
        if (!map.containsKey(key)) continue;
        final found = _findRecipeNode(map[key], depth + 1);
        if (found != null) return found;
      }
    }
    return null;
  }

  /// `@type` puede ser una cadena, una lista (`["Recipe", "NewsArticle"]`) o
  /// una URL completa (`https://schema.org/Recipe`).
  static bool _isType(dynamic type, String expected) {
    if (type is String) {
      return type.split('/').last.toLowerCase() == expected.toLowerCase();
    }
    if (type is List) return type.any((t) => _isType(t, expected));
    return false;
  }

  static Recipe? _recipeFromJsonLd(Map<String, dynamic> node) {
    final name = _text(node['name'] ?? node['headline']);
    final ingredients = _stringList(
      node['recipeIngredient'] ?? node['ingredients'],
    );
    final steps = _instructions(node['recipeInstructions']);
    if (name.isEmpty || (ingredients.isEmpty && steps.isEmpty)) return null;

    final time =
        _duration(node['totalTime']) ??
        _sumDurations(node['prepTime'], node['cookTime']);
    final servings = _firstInteger(_text(node['recipeYield'] ?? node['yield']));
    final nutrition = node['nutrition'];
    final calories = nutrition is Map
        ? _firstInteger(_text(nutrition['calories']))
        : null;

    return Recipe(
      nombre: name,
      descripcion: _text(node['description']),
      ingredientes: ingredients,
      preparacion: steps,
      tiempoEstimado: time ?? tiempoDesconocido,
      calorias: calories ?? caloriasDesconocidas,
      raciones: servings ?? '1',
      origen: RecipeOrigin.web,
    );
  }

  /// `recipeInstructions` admite muchas formas: texto plano, lista de textos,
  /// lista de `HowToStep` o `HowToSection` con pasos dentro, o un solo objeto.
  static List<String> _instructions(dynamic value) {
    if (value == null) return const [];
    if (value is String) return _splitLines(value);
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      if (map.containsKey('itemListElement')) {
        return _instructions(map['itemListElement']);
      }
      final text = _text(map['text'] ?? map['name']);
      return text.isEmpty ? const [] : [_stripStepNumber(text)];
    }
    if (value is List) {
      return [for (final item in value) ..._instructions(item)];
    }
    return const [];
  }

  // -------------------------------------------------------------- Microdata

  static Recipe? _fromMicrodata(Document document) {
    final scope = document.querySelector('[itemtype*="schema.org/Recipe"]');
    if (scope == null) return null;

    final name = _prop(scope, 'name');
    var ingredients = _props(scope, 'recipeIngredient');
    if (ingredients.isEmpty) ingredients = _props(scope, 'ingredients');
    final steps = _microdataInstructions(scope);
    if (name.isEmpty || (ingredients.isEmpty && steps.isEmpty)) return null;

    final time =
        _duration(_prop(scope, 'totalTime')) ??
        _sumDurations(_prop(scope, 'prepTime'), _prop(scope, 'cookTime'));

    return Recipe(
      nombre: name,
      descripcion: _prop(scope, 'description'),
      ingredientes: ingredients,
      preparacion: steps,
      tiempoEstimado: time ?? tiempoDesconocido,
      calorias: _firstInteger(_prop(scope, 'calories')) ?? caloriasDesconocidas,
      raciones: _firstInteger(_prop(scope, 'recipeYield')) ?? '1',
      origen: RecipeOrigin.web,
    );
  }

  static List<String> _microdataInstructions(Element scope) {
    final elements = scope.querySelectorAll('[itemprop="recipeInstructions"]');
    if (elements.isEmpty) return const [];

    // Un único contenedor con una lista dentro: cada `li` es un paso.
    if (elements.length == 1) {
      final items = elements.first.querySelectorAll('li');
      if (items.isNotEmpty) {
        return [
          for (final li in items)
            if (_clean(li.text).isNotEmpty) _stripStepNumber(_clean(li.text)),
        ];
      }
      return _splitLines(
        elements.first.attributes['content'] ?? elements.first.text,
      );
    }

    // Varios elementos marcados: cada uno es un paso.
    return [
      for (final e in elements)
        if (_clean(e.attributes['content'] ?? e.text).isNotEmpty)
          _stripStepNumber(_clean(e.attributes['content'] ?? e.text)),
    ];
  }

  /// Valor de un `itemprop`: en `<meta>` y `<time>` va en `content`, en el
  /// resto de etiquetas es el texto.
  static String _prop(Element scope, String name) {
    final element = scope.querySelector('[itemprop="$name"]');
    if (element == null) return '';
    return _clean(element.attributes['content'] ?? element.text);
  }

  static List<String> _props(Element scope, String name) {
    return [
      for (final e in scope.querySelectorAll('[itemprop="$name"]'))
        if (_clean(e.attributes['content'] ?? e.text).isNotEmpty)
          _clean(e.attributes['content'] ?? e.text),
    ];
  }

  // ------------------------------------------------------------- Utilidades

  /// Texto legible de un valor JSON-LD, que puede ser cadena, número, lista
  /// (se toma el primer elemento con texto) u objeto (`name`, `text`...).
  static String _text(dynamic value) {
    if (value == null) return '';
    if (value is String) return _clean(value);
    if (value is num) return value.toString();
    if (value is List) {
      for (final item in value) {
        final text = _text(item);
        if (text.isNotEmpty) return text;
      }
      return '';
    }
    if (value is Map) {
      return _text(value['name'] ?? value['text'] ?? value['@value']);
    }
    return '';
  }

  static List<String> _stringList(dynamic value) {
    if (value == null) return const [];
    if (value is String) return _splitLines(value);
    if (value is List) {
      return [
        for (final item in value)
          if (_text(item).isNotEmpty) _text(item),
      ];
    }
    return const [];
  }

  static List<String> _splitLines(String value) {
    return [
      for (final line in value.split(RegExp(r'\r?\n|<br\s*/?>')))
        if (_clean(line).isNotEmpty) _stripStepNumber(_clean(line)),
    ];
  }

  /// Quita entidades HTML, etiquetas sueltas y espacios repetidos.
  static String _clean(String value) {
    if (value.isEmpty) return '';
    final text = value.contains('<') || value.contains('&')
        ? parseFragment(value).text ?? value
        : value;
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Elimina numeraciones del tipo "1.", "2)", "Paso 3:" al inicio de un
  /// paso. Exige puntuación tras el número para no comerse "2 huevos".
  static String _stripStepNumber(String step) {
    return step
        .replaceFirst(
          RegExp(r'^(?:paso\s*)?\d+\s*[.):\-]\s*', caseSensitive: false),
          '',
        )
        .trim();
  }

  /// Minutos de una duración ISO 8601 (`PT1H30M`, `PT90M`, `P0DT2H`).
  static int? _isoMinutes(String value) {
    final match = RegExp(
      r'^P(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?$',
      caseSensitive: false,
    ).firstMatch(value.trim());
    if (match == null) return null;
    final days = int.tryParse(match.group(1) ?? '') ?? 0;
    final hours = int.tryParse(match.group(2) ?? '') ?? 0;
    final minutes = int.tryParse(match.group(3) ?? '') ?? 0;
    return days * 24 * 60 + hours * 60 + minutes;
  }

  static String _formatMinutes(int total) {
    final hours = total ~/ 60;
    final minutes = total % 60;
    if (hours > 0 && minutes > 0) return '$hours h $minutes min';
    if (hours > 0) return '$hours h';
    return '$minutes min';
  }

  /// Duración legible. Si no es ISO 8601 pero hay texto ("30 minutos"), se
  /// devuelve tal cual.
  static String? _duration(dynamic value) {
    final text = _text(value);
    if (text.isEmpty) return null;
    final minutes = _isoMinutes(text);
    if (minutes == null) return text;
    return minutes > 0 ? _formatMinutes(minutes) : null;
  }

  static String? _sumDurations(dynamic prep, dynamic cook) {
    final prepMinutes = _isoMinutes(_text(prep)) ?? 0;
    final cookMinutes = _isoMinutes(_text(cook)) ?? 0;
    final total = prepMinutes + cookMinutes;
    if (total > 0) return _formatMinutes(total);
    // Sin ISO: al menos devolver el texto que haya, si es que lo hay.
    return _duration(prep) ?? _duration(cook);
  }

  static String? _firstInteger(String value) {
    return RegExp(r'\d+').firstMatch(value)?.group(0);
  }
}
