import 'dart:async';
import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/models/web_recipe_result.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';

class SearchService {
  String? web;
  
  // Usamos un cliente estático para mantener cookies y sesión entre peticiones
  static final http.Client _client = http.Client();

  final Map<String, String> _headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
    'Accept-Language': 'es-ES,es;q=0.9',
    'Cache-Control': 'no-cache',
    'Pragma': 'no-cache',
  };

  Future<List<WebRecipeResult>> searchRecipes(String query) async {
    final url = 'https://recetas.lidl.es/todasrecetas?q=$query';
    return fetchRecipesFromUrl(url);
  }

  Future<List<WebRecipeResult>> fetchRecipesFromUrl(String urlString) async {
    try {
      final response = await _client.get(Uri.parse(urlString), headers: _headers);

      if (response.statusCode == 200) {
        web = response.body;
        return _parseLidlDom(web!);
      }
    } catch (e) {
      print('Excepción durante el scraping de búsqueda: $e');
    }
    return [];
  }

  Future<Recipe?> getFullRecipe(String url) async {
    try {
      // Intento 1
      var response = await _client.get(Uri.parse(url), headers: _headers);
      if (response.statusCode != 200) return null;

      var recipe = _parseFullRecipeDetails(response.body);

      // SI LOS PASOS ESTÁN VACÍOS, REINTENTAMOS (Soluciona el problema del primer hit vacío)
      if (recipe == null || recipe.preparacion.isEmpty) {
        print('Pasos vacíos en el primer intento, reintentando...');
        // Esperamos un momento mínimo para que el servidor procese la sesión
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
      var ingredientsContainer = document.querySelector('div[data-testid="recipe-detail-ingredients-list"]');
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
          var stepText = li.querySelector('span')?.text.trim() ?? li.text.trim();
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
      var prepBadge = document.querySelector('div[data-testid="recipe-info-badge-preparation"]');
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
