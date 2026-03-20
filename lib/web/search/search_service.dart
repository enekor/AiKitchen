import 'dart:async';
import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/models/web_recipe_result.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';

enum RecipeSource { lidl, cookpad }

class SearchService {
  String? web;

  // Usamos un cliente estático para mantener cookies y sesión entre peticiones
  static final http.Client _client = http.Client();

  final Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
    'Accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
    'Accept-Language': 'es-ES,es;q=0.9',
    'Cache-Control': 'no-cache',
    'Pragma': 'no-cache',
  };

  Future<List<WebRecipeResult>> searchRecipes(
    String query, {
    RecipeSource source = RecipeSource.lidl,
  }) async {
    final url = source == RecipeSource.lidl
        ? 'https://recetas.lidl.es/todasrecetas?q=$query'
        : 'https://cookpad.com/es/buscar/$query';
    return fetchRecipesFromUrl(url, source: source);
  }

  Future<List<WebRecipeResult>> fetchRecipesFromUrl(
    String urlString, {
    RecipeSource? source,
  }) async {
    try {
      final effectiveSource =
          source ??
          (urlString.contains('cookpad.com')
              ? RecipeSource.cookpad
              : RecipeSource.lidl);
      final response = await _client.get(
        Uri.parse(urlString),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        web = response.body;
        if (effectiveSource == RecipeSource.lidl) {
          return _parseLidlDom(web!);
        } else {
          return _parseCookpadSearch(web!);
        }
      }
    } catch (e) {
      print('Excepción durante el scraping de búsqueda: $e');
    }
    return [];
  }

  Future<Recipe?> getFullRecipe(String url) async {
    try {
      final isCookpad = url.contains('cookpad.com');

      var response = await _client.get(Uri.parse(url), headers: _headers);
      if (response.statusCode != 200) return null;

      var recipe = isCookpad
          ? _parseCookpadRecipeDetails(response.body)
          : _parseFullRecipeDetails(response.body);

      // SI LOS PASOS ESTÁN VACÍOS, REINTENTAMOS (Soluciona el problema del primer hit vacío en Lidl)
      if (!isCookpad && (recipe == null || recipe.preparacion.isEmpty)) {
        print('Pasos vacíos en el primer intento, reintentando...');
        await Future.delayed(const Duration(milliseconds: 500));

        response = await _client.get(Uri.parse(url), headers: _headers);
        if (response.statusCode == 200) {
          recipe = _parseFullRecipeDetails(response.body);
        }
      }

      return recipe;
    } catch (e) {
      print('Error al obtener la receta completa: $e');
    }
    return null;
  }

  Recipe? _parseFullRecipeDetails(String htmlContent) {
    try {
      var document = parse(htmlContent);

      // 1. NOMBRE
      var name = document.querySelector('h1')?.text.trim() ?? 'No encontrado';

      // 2. KCAL (Selector más robusto)
      String kcal = '0';
      var allSpans = document.querySelectorAll('span');
      for (var s in allSpans) {
        if (s.text.contains('kcal')) {
          kcal = RegExp(r'(\d+)').firstMatch(s.text)?.group(1) ?? '0';
          break;
        }
      }

      // 3. INGREDIENTES (Combinamos selectores de label y data-testid)
      List<String> ingredients = [];
      var ingredientsContainer = document.querySelector(
        'div[data-testid="recipe-detail-ingredients-list"]',
      );
      if (ingredientsContainer != null) {
        var items = ingredientsContainer.querySelectorAll('ul li');
        for (var li in items) {
          var text = li.text.trim();
          if (text.isNotEmpty) ingredients.add(text);
        }
      } else {
        // Fallback: buscar labels de ingredientes
        var labels = document.querySelectorAll('label');
        for (var l in labels) {
          if (l.text.trim().isNotEmpty && l.attributes.containsKey('for')) {
            ingredients.add(l.text.trim());
          }
        }
      }

      // 4. PASOS (Selector de artículo + fallback de párrafos numerados)
      List<String> steps = [];
      var article = document.querySelector('article');
      var ol = article?.querySelector('ol');

      if (ol != null) {
        var stepItems = ol.querySelectorAll('li');
        for (var li in stepItems) {
          var stepText =
              li.querySelector('span')?.text.trim() ?? li.text.trim();
          if (stepText.isNotEmpty) steps.add(stepText);
        }
      } else {
        // Fallback total: buscar cualquier párrafo que empiece por número después del texto "Preparación"
        bool afterPrep = false;
        var allPs = document.querySelectorAll('p, div');
        for (var p in allPs) {
          String txt = p.text.trim();
          if (txt.toLowerCase() == 'preparación') {
            afterPrep = true;
            continue;
          }
          if (afterPrep && RegExp(r'^\d+\.').hasMatch(txt)) {
            steps.add(txt.replaceFirst(RegExp(r'^\d+\.\s*'), ''));
          }
        }
      }

      // 5. PREPARACIÓN (Tiempo)
      String preparationTime = 'No indicado';
      var prepBadge = document.querySelector(
        'div[data-testid="recipe-info-badge-preparation"]',
      );
      if (prepBadge != null) {
        preparationTime = prepBadge.text.replaceAll('Preparación', '').trim();
      }

      // 6. PLATOS (Raciones)
      String servings = '1';
      var servingsInput = document.querySelector('input[name="servings"]');
      servings = servingsInput?.attributes['value'] ?? '1';

      return Recipe(
        nombre: name,
        descripcion: "",
        ingredientes: ingredients,
        preparacion: steps,
        tiempoEstimado: preparationTime,
        calorias: kcal,
        raciones: servings,
      );
    } catch (e) {
      print('Error parseando detalle de receta: $e');
      return null;
    }
  }

  Recipe? _parseCookpadRecipeDetails(String htmlContent) {
    try {
      var document = parse(htmlContent);

      // 1. NOMBRE
      var name =
          document.querySelector('h1.text-cookpad-36')?.text.trim() ??
          document.querySelector('h1')?.text.trim() ??
          'No encontrado';

      // 2. INGREDIENTES
      List<String> ingredients = [];
      var ingredientsList = document.querySelectorAll('div#ingredients ol li');
      for (var li in ingredientsList) {
        var text = li.text.trim().replaceAll(RegExp(r'\s+'), ' ');
        if (text.isNotEmpty) ingredients.add(text);
      }

      // 3. PASOS
      List<String> steps = [];
      var stepsList = document.querySelectorAll('div#steps ol li');
      for (var li in stepsList) {
        // El texto del paso suele estar en un div o p dentro del li
        var p = li.querySelector('p');
        var stepText = p?.text.trim() ?? li.text.trim();
        // Limpiamos el número del paso si está al principio
        stepText = stepText.replaceFirst(RegExp(r'^\d+\s*'), '').trim();
        if (stepText.isNotEmpty) steps.add(stepText);
      }

      // 4. TIEMPO
      String preparationTime = 'No indicado';
      var timeElement = document.querySelector(
        'div[id^="cooking_time_recipe_"] span.mise-icon-text',
      );
      if (timeElement != null) {
        preparationTime = timeElement.text.trim();
      }

      // 5. RACIONES
      String servings = '1';
      var servingsElement = document.querySelector(
        'div[id^="serving_recipe_"] span.mise-icon-text',
      );
      if (servingsElement != null) {
        servings =
            RegExp(r'(\d+)').firstMatch(servingsElement.text)?.group(1) ?? '1';
      }

      return Recipe(
        nombre: name,
        descripcion: "",
        ingredientes: ingredients,
        preparacion: steps,
        tiempoEstimado: preparationTime,
        calorias:
            'No especificado', // Cookpad no suele mostrar kcal directamente
        raciones: servings,
      );
    } catch (e) {
      print('Error parseando detalle de receta Cookpad: $e');
      return null;
    }
  }

  List<WebRecipeResult> _parseCookpadSearch(String htmlContent) {
    final List<WebRecipeResult> results = [];
    var document = parse(htmlContent);
    var items = document.querySelectorAll('li.block-link');

    for (var item in items) {
      try {
        var linkElement = item.querySelector('a.block-link__main');
        String? relativeUrl = linkElement?.attributes['href'];
        if (relativeUrl == null) continue;
        String fullUrl = relativeUrl.startsWith('http')
            ? relativeUrl
            : 'https://cookpad.com$relativeUrl';

        var titleElement =
            item.querySelector('h2') ??
            item.querySelector('.text-cookpad-body-16');
        String title = titleElement?.text.trim() ?? '';
        if (title.isEmpty) continue;

        // Intentar encontrar la imagen de la receta (evitando avatares y cooksnaps)
        var imgElements = item.querySelectorAll('picture img');
        var imgElement = imgElements.cast<Element?>().firstWhere(
          (img) => (img?.attributes['src'] ?? '').contains('/recipes/'),
          orElse: () => imgElements.isNotEmpty ? imgElements.first : null,
        );
        String imageUrl = imgElement?.attributes['src'] ?? '';

        String time = 'Desconocido';
        var timeElement = item.querySelector(
          'div.flex.items-center.gap-xs span.mise-icon-text',
        );
        if (timeElement != null) {
          time = timeElement.text.trim();
        }

        results.add(
          WebRecipeResult(
            title: title,
            imageUrl: imageUrl,
            time: time,
            url: fullUrl,
          ),
        );
      } catch (e) {
        print('Error parseando tarjeta Cookpad: $e');
      }
    }
    return results;
  }

  List<WebRecipeResult> _parseLidlDom(String htmlContent) {
    final List<WebRecipeResult> results = [];
    var document = parse(htmlContent);
    var cards = document.querySelectorAll('article');

    for (var card in cards) {
      try {
        var nameElement =
            card.querySelector('[data-testid="recipe-name"]') ??
            card.querySelector('span[class*="font-headline"]') ??
            card.querySelector('p[class*="font-headline"]');
        String title = nameElement?.text.trim() ?? '';

        var linkElement = card.querySelector('a[href^="/recetas/"]');
        String? relativeUrl = linkElement?.attributes['href'];
        if (relativeUrl == null || title.isEmpty) continue;
        String fullUrl = 'https://recetas.lidl.es$relativeUrl';

        var imgElement = card.querySelector('img');
        String imageUrl = '';
        var srcSet = imgElement?.attributes['srcSet'];
        if (srcSet != null && srcSet.isNotEmpty) {
          imageUrl = srcSet.split(',').first.split(' ').first;
        } else {
          imageUrl = imgElement?.attributes['src'] ?? '';
        }

        if (imageUrl.startsWith('/')) {
          imageUrl = 'https://recetas.lidl.es$imageUrl';
        }

        String time = 'Desconocido';
        var spans = card.querySelectorAll('span');
        for (var span in spans) {
          String text = span.text.toLowerCase();
          if (text.contains('min') ||
              (text.contains(' h ') && text.length < 15)) {
            time = span.text.trim();
            break;
          }
        }

        results.add(
          WebRecipeResult(
            title: title,
            imageUrl: imageUrl,
            time: time,
            url: fullUrl,
          ),
        );
      } catch (e) {
        print('Error parseando tarjeta: $e');
      }
    }
    return results;
  }
}
