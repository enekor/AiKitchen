import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/services/structured_recipe_extractor.dart';
import 'package:flutter_test/flutter_test.dart';

/// El extractor es el primer escalón para cualquier web de recetas, así que
/// tiene que entender las variantes habituales de schema.org/Recipe. Si
/// devuelve `null` por error, la app cae en los parsers por sitio o en la IA
/// sin avisar, y el usuario solo nota que tarda más o que sale peor.
void main() {
  group('StructuredRecipeExtractor', () {
    test('lee JSON-LD con HowToStep, como Lidl', () {
      const html = '''
<html><head>
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Recipe",
  "name": "Tortillas de Halloween",
  "description": "Unas tortillas &amp; algo m\\u00e1s",
  "prepTime": "PT60M",
  "cookTime": "PT30M",
  "totalTime": "PT90M",
  "recipeYield": "4 raciones",
  "nutrition": {"@type": "NutritionInformation", "calories": "520 kcal"},
  "recipeIngredient": ["8 tortillas de trigo", "2 pechugas de pollo"],
  "recipeInstructions": [
    {"@type": "HowToStep", "position": 1, "text": "Marina el pollo."},
    {"@type": "HowToStep", "position": 2, "text": "2. Hornea 20 minutos."}
  ]
}
</script>
</head><body><h1>Otra cosa</h1></body></html>
''';

      final recipe = StructuredRecipeExtractor.extract(html);

      expect(recipe, isNotNull);
      expect(recipe!.nombre, 'Tortillas de Halloween');
      expect(recipe.descripcion, 'Unas tortillas & algo más');
      expect(recipe.ingredientes, ['8 tortillas de trigo', '2 pechugas de pollo']);
      expect(recipe.preparacion, ['Marina el pollo.', 'Hornea 20 minutos.']);
      expect(recipe.tiempoEstimado, '1 h 30 min');
      expect(recipe.raciones, '4');
      expect(recipe.calorias, '520');
      expect(recipe.origen, RecipeOrigin.web);
    });

    test('encuentra la receta dentro de @graph y con @type en lista', () {
      const html = '''
<script type="application/ld+json">
{"@context":"https://schema.org","@graph":[
  {"@type":"WebPage","name":"Página"},
  {"@type":["Recipe","Article"],"name":"Gazpacho",
   "recipeIngredient":"tomate\\npepino\\n",
   "recipeInstructions":"1. Triturar\\n2) Enfriar",
   "prepTime":"PT15M","recipeYield":["6","6 personas"]}
]}
</script>
''';

      final recipe = StructuredRecipeExtractor.extract(html);

      expect(recipe, isNotNull);
      expect(recipe!.nombre, 'Gazpacho');
      expect(recipe.ingredientes, ['tomate', 'pepino']);
      expect(recipe.preparacion, ['Triturar', 'Enfriar']);
      expect(recipe.tiempoEstimado, '15 min');
      expect(recipe.raciones, '6');
      expect(recipe.calorias, StructuredRecipeExtractor.caloriasDesconocidas);
    });

    test('aplana HowToSection y salta bloques JSON rotos', () {
      const html = '''
<script type="application/ld+json">{esto no es json</script>
<script type="application/ld+json">
{"@type":"Recipe","name":"Lasaña",
 "recipeIngredient":["pasta"],
 "recipeInstructions":[
   {"@type":"HowToSection","name":"Salsa","itemListElement":[
     {"@type":"HowToStep","text":"Sofreír"},
     {"@type":"HowToStep","text":"Reducir"}]},
   {"@type":"HowToSection","name":"Montaje","itemListElement":[
     {"@type":"HowToStep","text":"Capas"}]}
 ]}
</script>
''';

      final recipe = StructuredRecipeExtractor.extract(html);

      expect(recipe, isNotNull);
      expect(recipe!.preparacion, ['Sofreír', 'Reducir', 'Capas']);
      expect(recipe.tiempoEstimado, StructuredRecipeExtractor.tiempoDesconocido);
      expect(recipe.raciones, '1');
    });

    test('cae a microdata cuando no hay JSON-LD', () {
      const html = '''
<div itemscope itemtype="https://schema.org/Recipe">
  <h1 itemprop="name">Paella</h1>
  <meta itemprop="totalTime" content="PT45M">
  <span itemprop="recipeYield">4 personas</span>
  <ul>
    <li itemprop="recipeIngredient">arroz</li>
    <li itemprop="recipeIngredient">  caldo  </li>
  </ul>
  <ol itemprop="recipeInstructions">
    <li>Sofreír</li>
    <li>Añadir arroz</li>
  </ol>
  <span itemprop="calories">600 calorías</span>
</div>
''';

      final recipe = StructuredRecipeExtractor.extract(html);

      expect(recipe, isNotNull);
      expect(recipe!.nombre, 'Paella');
      expect(recipe.ingredientes, ['arroz', 'caldo']);
      expect(recipe.preparacion, ['Sofreír', 'Añadir arroz']);
      expect(recipe.tiempoEstimado, '45 min');
      expect(recipe.raciones, '4');
      expect(recipe.calorias, '600');
    });

    test('devuelve null si no hay receta o está vacía', () {
      expect(StructuredRecipeExtractor.extract('<html><body>Hola</body></html>'), isNull);
      expect(
        StructuredRecipeExtractor.extract(
          '<script type="application/ld+json">{"@type":"Recipe","name":"Sin nada"}</script>',
        ),
        isNull,
      );
      expect(
        StructuredRecipeExtractor.extract(
          '<script type="application/ld+json">{"@type":"Article","name":"Noticia"}</script>',
        ),
        isNull,
      );
    });
  });
}
