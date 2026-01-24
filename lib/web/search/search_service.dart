import 'dart:async';
import 'package:aikitchen/web/search/web_recipe_result.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';

class SearchService {
  String? web;

  Future<List<WebRecipeResult>> searchRecipes(String query) async {
    try {
      final url = Uri.parse('https://recetas.lidl.es/todasrecetas?q=$query');
      
      // Lidl puede bloquear peticiones sin User-Agent. Añadimos cabeceras de navegador real.
      final response = await http.get(url, headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
        'Accept-Language': 'es-ES,es;q=0.9',
      });

      if (response.statusCode == 200) {
        web = response.body;
        return _parseLidlDom(web!);
      } else {
        print('Error en la petición: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Excepción durante el scraping: $e');
      return [];
    }
  }

  List<WebRecipeResult> _parseLidlDom(String htmlContent) {
    final List<WebRecipeResult> results = [];
    var document = parse(htmlContent);

    // Las recetas están contenidas en etiquetas <article>
    var cards = document.querySelectorAll('article');

    for (var card in cards) {
      try {
        // 1. Extraer Título (Lidl usa data-testid="recipe-name" o clases font-headline)
        var nameElement = card.querySelector('[data-testid="recipe-name"]') ?? 
                          card.querySelector('span[class*="font-headline"]') ??
                          card.querySelector('p[class*="font-headline"]');
        String title = nameElement?.text.trim() ?? '';

        // 2. Extraer URL
        var linkElement = card.querySelector('a[href^="/recetas/"]');
        String? relativeUrl = linkElement?.attributes['href'];
        if (relativeUrl == null || title.isEmpty) continue;
        String fullUrl = 'https://recetas.lidl.es$relativeUrl';

        // 3. Extraer Imagen (Gestión de Lazy Loading de Next.js)
        var imgElement = card.querySelector('img');
        String imageUrl = '';
        
        // Primero intentamos srcSet que contiene las URLs reales de Next.js Image
        var srcSet = imgElement?.attributes['srcSet'];
        if (srcSet != null && srcSet.isNotEmpty) {
          imageUrl = srcSet.split(',').first.split(' ').first;
        } else {
          imageUrl = imgElement?.attributes['src'] ?? '';
        }

        // Si la imagen sigue siendo relativa, la convertimos en absoluta
        if (imageUrl.startsWith('/')) {
          imageUrl = 'https://recetas.lidl.es$imageUrl';
        }

        // 4. Extraer Tiempo (Buscamos texto con "min" o "h" en los badges)
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
        // Ignoramos errores en tarjetas individuales para no romper el flujo
        print('Error parseando tarjeta: $e');
      }
    }

    return results;
  }
}
