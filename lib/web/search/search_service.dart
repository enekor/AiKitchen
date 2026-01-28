import 'dart:async';
import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/models/web_recipe_result.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';

class SearchService {
  String? web;

  Future<List<WebRecipeResult>> searchRecipes(String query) async {
    final url = 'https://recetas.lidl.es/todasrecetas?q=$query';
    return fetchRecipesFromUrl(url);
  }

  Future<List<WebRecipeResult>> fetchRecipesFromUrl(String urlString) async {
    try {
      final url = Uri.parse(urlString);
      final response = await http.get(url, headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
        'Accept-Language': 'es-ES,es;q=0.9',
      });

      if (response.statusCode == 200) {
        web = response.body;
        return _parseLidlDom(web!);
      }
    } catch (e) {
      print('Excepción durante el scraping: $e');
    }
    return [];
  }

  Future<Recipe?> getFullRecipe(String url) async {
    try {
      final response = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      });

      if (response.statusCode == 200) {
        return _parseFullRecipeDetails(response.body);
      }
    } catch (e) {
      print('Error al obtener la receta completa: $e');
    }
    return null;
  }

  Recipe? _parseFullRecipeDetails(String htmlContent) {
    try {
      var document = parse(htmlContent);

      // 1. KCAL
      String kcal = '0';
      try {
        var nutritionalDiv = document.querySelectorAll('div.rounded-lg').firstWhere(
          (div) => div.parent?.text.contains('Valor nutricional por ración') ?? false,
          orElse: () => Element.tag('div')
        );
        var kcalSpan = nutritionalDiv.querySelector('span.text-lidl-color-grayscale_darkest');
        if (kcalSpan != null) {
          kcal = RegExp(r'(\d+)').firstMatch(kcalSpan.text)?.group(1) ?? '0';
        }
      } catch (_) {}

      // 2. INGREDIENTES
      List<String> ingredients = [];
      var ingredientsContainer = document.querySelector('div[data-testid="recipe-detail-ingredients-list"]');
      if (ingredientsContainer != null) {
        var items = ingredientsContainer.querySelectorAll('ul li');
        for (var li in items) {
          var displayDiv = li.querySelector('div.flex.flex-col');
          if (displayDiv != null) {
            String combinedText = displayDiv.nodes
                .map((node) => node.text?.trim() ?? '')
                .where((text) => text.isNotEmpty)
                .join(' ');
            ingredients.add(combinedText);
          }
        }
      }

      // 3. PASOS
      List<String> steps = [];

// En Lidl, la lista suele estar en el siguiente contenedor hermano grande
      var stepsContainer = document.querySelector('article');

      if (stepsContainer != null) {
        // Buscamos todos los 'li' que estén dentro de cualquier 'ol' en esa zona
        var ol = stepsContainer.querySelector('ol');
        if (ol != null) {
          var liElements = ol.querySelectorAll('li');
          for (var li in liElements) {
            // El texto real del paso suele estar en un span con clase body_normal
            var stepText = li.querySelector('span')?.text.trim() ?? li.text.trim();
            if (stepText.isNotEmpty) steps.add(stepText);
          }
        }
      }

      // 4. PREPARACIÓN (Tiempo)
      String preparationTime = 'No encontrado';
      var prepBadge = document.querySelector('div[data-testid="recipe-info-badge-preparation"]');
      if (prepBadge != null) {
        var targetDiv = prepBadge.querySelector('div');
        var spans = targetDiv?.querySelectorAll('span');
        if (spans != null && spans.length >= 2) {
          preparationTime = spans[1].text.trim();
        }
      }

      // 5. PLATOS (Raciones)
      String servings = '1';
      var servingsGroup = document.querySelector('div[data-testid="servings-group"]');
      var servingsInput = servingsGroup?.querySelector('input[name="servings"]');
      servings = servingsInput?.attributes['value'] ?? '1';

      // 6. NOMBRE
      var name = document.querySelector('h1')?.text.trim() ?? 'No encontrado';

      return Recipe(
        nombre: name,
        descripcion: "", // Podrías extraerla de la meta-etiqueta si quisieras
        ingredientes: ingredients,
        preparacion: steps,
        tiempoEstimado: preparationTime,
        calorias: double.tryParse(kcal) ?? 0,
        raciones: int.tryParse(servings) ?? 1,
      );
    } catch (e) {
      print('Error parseando detalle de receta: $e');
      return null;
    }
  }

  List<WebRecipeResult> _parseLidlDom(String htmlContent) {
    final List<WebRecipeResult> results = [];
    var document = parse(htmlContent);
    var cards = document.querySelectorAll('article');

    for (var card in cards) {
      try {
        var nameElement = card.querySelector('[data-testid="recipe-name"]') ?? 
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
          if (text.contains('min') || (text.contains(' h ') && text.length < 15)) {
            time = span.text.trim();
            break;
          }
        }

        results.add(WebRecipeResult(
          title: title,
          imageUrl: imageUrl,
          time: time,
          url: fullUrl,
        ));
      } catch (e) {
        print('Error parseando tarjeta: $e');
      }
    }

    return results;
  }
}
