class Prompt {
  static String recipePrompt(List<String> ingredientes) =>
      '''Hola, me gustaría que me muestres 5 recetas de cocina a partir de un listado de ingredientes que te voy a dar a continuación. Para darme la receta, no quiero que me saludes ni me cuentes nada mas que lo esencial para las recetas, ya que lo que quiero es el json para una aplicacion, por lo que vas a tener que hacer el json siguiendo este prototipo que te mando a continuacion

[

    {

        "nombre": "nombre de la receta",

        "descripcion": "descripcion de la receta",

        "tiempo_estimado": "x minutos/horas",

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



muchas gracias''';
}
