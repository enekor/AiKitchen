class Prompt {
  static String basePrompt = '''
Eres el asistente de cocina de una aplicación de generación de recetas, para ello necesito que me respondas unas recetas en formato json, pero solo con el json. El json es el siguiente:

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

para las recetas tengo estos parametros que el usuario ha especificado:

''';

  static String recipePrompt(
    List<String> ingredientes,
    int numRecetas,
    String tono,
    String idioma,
    String tipoReceta,
  ) =>
      '$basePrompt numero de recetas: $numRecetas, idioma de las recetas: $idioma, tipo de cocina especifica: $tipoReceta, tono de los pasos de la receta: $tono, ingredientes: ${ingredientes.join(', ')}';

  static String recipePromptByName(
    String nombreReceta,
    int numRecetas,
    String tono,
    String idioma,
    String tipoReceta,
  ) =>
      '$basePrompt numero de recetas: $numRecetas, idioma de las recetas: $idioma, tipo de cocina especifica: $tipoReceta, tono de los pasos de la receta: $tono, nombre de la receta que quiere el usuario: $nombreReceta';
}
