class Prompt {
  static String recipePrompt(
    List<String> ingredientes,
    int numRecetas,
    String tono,
  ) =>
      '''Hola, me gustaría que me muestres $numRecetas recetas de cocina a partir de un listado de ingredientes que te voy a dar a continuación. Para darme la receta, no quiero que me saludes ni me cuentes nada mas que lo esencial para las recetas, ya que lo que quiero es el json para una aplicacion, por lo que vas a tener que hacer el json siguiendo este prototipo que te mando a continuacion

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



la lista de ingredientes es esta: ${ingredientes.join(',')}.

a la hora de describir los pasos quiero que seas lo mas especifico posible y no des nada por hecho.
ademas, quiero que cuando me des los pasos lo hagas con un tono $tono.



muchas gracias''';

  static String recipePromptByName(
    String nombreReceta,
    int numRecetas,
    String tono,
  ) =>
      '''Eres un chef mundialmente conocido por hacer recetas faciles, rapidas y deliciosas, y me gustaria que me hicieses $numRecetas recetas en formato json para hacer $nombreReceta, pero solo quiero que me mandes las recetas. Para ello vas a mandarme el json en este formato 

[

    {

        "nombre": "nombre de la receta",

        "descripcion": "descripcion de la receta",

        "tiempo_estimado": "x minutos/horas",
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

para los pasos, quiero que me los digas usando un tono de voz $tono.
 no que me saludes ni que me hables, solo mandame el json con la o las recetas ''';
}
