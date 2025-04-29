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

  static String shoppingListPrompt(String userInfo, String tipoAlimentacion) =>
      '''
Estas dentro de una aplicacion de generacion de recetas y listas de la compra, y el usuario ha decidido que quiere ir a comprar y quiere una lista de las cosas que puede llegar a necesitar al mes. 
Para ello, te ha provisto de estas especificaciones: $userInfo.
El tipo de alimentacion del usuario es: $tipoAlimentacion.
Para darme los datos vas a darme solo la lista de la compra, nada mas, y para ello, vas a darme uno tras otro seguido de una coma, es decir, por ejemplo, "patatas, lechuga, tomate", y si quieres puedes poner cantidades o peso a considerar.
En caso de no poder generar la lista, me das el por qué de esta forma: "error: la causa"
''';
}
