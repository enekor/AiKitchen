class Prompt {
  static String basePrompt = '''
Eres un chef de reconocido prestigio, que crea platos bien explicados y faciles de entender.
Para esta receta, necesito que me responns solo con la receta en formato json, nada mas  ue la receta. El formato es el siguiente:
[

    {

        "nombre": "nombre de la receta",

        "descripcion": "descripcion de la receta",

        "tiempo_estimado": "x min/h",

        "calorias": 123 (el numero de calorias aproximadas),

        "raciones": 2 (el numero de raciones/comensales),

        "ingredientes":[

            "ingrediente 1",

            "ingrediente 2",

            "ingrediente 3"

        ],

        "preparacion":[

            "paso 1",

            "paso 2",

            "paso 3"

        ]

    }

]

para los ingredientes, no te dejes ninguno por muy simpples u obvios que parezcan, por ejemplo si es una receta de pasta con tomate, no te dejes el tomate, la pasta, el aceite, la sal, la pimienta, etc.
en cuanto a los paso de la receta, todos los pasos son iual de  importantes, no des nada por hecho, por ejemplo si es una receta de pasta con tomate, no digas "cocina la pasta", di "pon agua a hervir, añade sal, cuando hierva añade la pasta y cocina durante 10 minutos, luego escurre la pasta y reserva".

Para la generación de la receta, ten en cuenta los siguientes parámetros:
''';

  static String recipePrompt(
    List<String> ingredientes,
    int numRecetas,
    String tono,
    String idioma,
    String tipoReceta,
  ) =>
      '$basePrompt numero de recetas: $numRecetas, idioma de las recetas: $idioma, tipo de cocina especifica: $tipoReceta, tono de los pasos de la receta: $tono, ingredientes: ${ingredientes.isEmpty ? 'cualquiera para recetas sencillas' : ingredientes.join(', ')}';

  static String recipePromptByName(
    String nombreReceta,
    int numRecetas,
    String tono,
    String idioma,
    String tipoReceta,
  ) =>
      '$basePrompt numero de recetas: $numRecetas, idioma de las recetas: $idioma, tipo de cocina especifica: $tipoReceta, tono de los pasos de la receta: $tono, nombre de la receta que quiere el usuario: $nombreReceta';

  static String shoppingListPrompt({
    required String tipoReceta,
    required String personas,
    String presupuesto = '',
  }) =>
      '''
Necesito que me generes una lista de la compra mensual. Responde únicamente con un JSON en este formato:

{
  "lista": [
    "ingrediente 1",
    "ingrediente 2",
    "ingrediente 3"
  ]
}

Información sobre mi hogar:
- Número de personas: $personas
${presupuesto.isNotEmpty ? '- Presupuesto mensual: $presupuesto' : ''}
- Tipo de cocina preferida: $tipoReceta

Genera una lista completa y equilibrada de ingredientes básicos y productos esenciales para un mes, teniendo en cuenta el número de personas y las preferencias indicadas.
''';

  static String UpdateRecipePrompt(String recipeJson, int numPlates) =>
      ''' Necesito que me actualices la receta que te voy a dar, cambiando el numero de raciones a $numPlates. Responde únicamente con el json de la receta actualizada, sin ningún texto adicional. Aquí tienes el json de la receta: $recipeJson''';

  static String UpdateRecipePromptExpress(String recipeJson) =>
      '''Necesito que me des una versión exprés (más rápida de preparar) de la siguiente receta. Responde únicamente with el json de la receta adaptada, sin ningún texto adicional. Aquí tienes el json de la receta: $recipeJson''';

  static String UpdateRecipePromptSaludable(String recipeJson) =>
      '''Necesito que me des una versión más saludable de la siguiente receta (menos calorías, menos grasas, etc). Responde únicamente con el json de la receta adaptada, sin ningún texto adicional. Aquí tienes el json de la receta: $recipeJson''';

  static String UpdateRecipePromptDieta(String recipeJson, String dieta) =>
      '''Necesito que adaptes la siguiente receta para que sea apta para una dieta "$dieta". Responde únicamente con el json de la receta adaptada, sin ningún texto adicional y respetando los tipados del json original, es decir, nombre, descripcion, tiempoEstimado, cada ingrediente, cada paso de preparacion son string, calorias es un double y las raciones es un int. Aquí tienes el json de la receta: $recipeJson''';

  static String UpdateRecipePromptUnidades(String recipeJson) =>
      '''Necesito que conviertas las medidas de los ingredientes de la receta a cucharas, tazas, etc, lo que venga mejor para la cantidad. En caso de que la medida sea más práctica en su unidad original (como por ejemplo "1 huevo" o "1 pizca de sal"), déjala como está. Responde únicamente con el json de la receta adaptada, sin ningún texto adicional. Aquí tienes el json de la receta: $recipeJson''';

  static String UpdateRecipePromptDificultad(
    String recipeJson,
    String dificultad,
  ) =>
      '''Necesito que adaptes la siguiente receta para que tenga un nivel de dificultad "$dificultad". Responde únicamente con el json de la receta adaptada, sin ningún texto adicional. Aquí tienes el json de la receta: $recipeJson''';

  static String UpdateRecipePromptTono(String recipeJson, String tono) =>
      '''Necesito que adaptes la explicación de la receta al siguiente tono: "$tono". No te preocupes, no me voy a ofender si el tono es negativo. Responde únicamente con el json de la receta adaptada, sin ningún texto adicional. Aquí tienes el json de la receta: $recipeJson''';

  static String weeklyMenuPrompt(
    String tipoReceta,
    String tono,
    String idioma,
  ) =>
      '''
$basePrompt
Necesito que me generes un menú semanal completo con 2 comidas por día (comida y cena) para los 7 días de la semana. En total son 14 recetas.

Parámetros:
- Idioma de las recetas: $idioma
- Tipo de cocina específica: $tipoReceta
- Tono de los pasos de la receta: $tono

Importante:
- Las recetas deben ser variadas y equilibradas
- Incluir diferentes tipos de alimentos
- Tener en cuenta el balance nutricional
- Las recetas deben ser prácticas y realizables
- Asegúrate de que el conjunto de recetas forme un menú coherente y saludable

El formato debe ser el mismo JSON que el base, generando una lista con las 14 recetas.
''';

  static String formatExternalWeeklyMenuPrompt(
    String externalContent,
    String tipoReceta,
    String tono,
    String idioma,
  ) {
    return '''
$externalContent

Responde ÚNICAMENTE en este formato JSON (lista de 14 recetas):
[
    {
        "nombre": "nombre de la receta",
        "descripcion": "descripcion de la receta",
        "tiempo_estimado": "x min/h",
        "calorias": 123 (el numero de calorias aproximadas),
        "raciones": 2 (el numero de raciones/comensales),
        "ingredientes":[
            "ingrediente 1",
            "ingrediente 2",
            "ingrediente 3"
        ],
        "preparacion":[
            "paso 1",
            "paso 2",
            "paso 3"
        ]
    }
]

Parámetros adicionales:
- Idioma de las recetas: $idioma
- Tipo de cocina específica: $tipoReceta
- Tono de los pasos de la receta: $tono
''';
  }
}
