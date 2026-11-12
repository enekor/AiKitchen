import 'package:aikitchen/models/cart_item.dart';
import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/services/storage/app_storage.dart';

/// Demo content used only for the Play Store screenshots.

Recipe _recipe(
  String nombre, {
  required String descripcion,
  required String tiempo,
  required String calorias,
  required String raciones,
  required List<String> ingredientes,
  required List<String> pasos,
  List<String> etiquetas = const [],
}) => Recipe(
  nombre: nombre,
  descripcion: descripcion,
  tiempoEstimado: tiempo,
  ingredientes: ingredientes,
  preparacion: pasos,
  calorias: calorias,
  raciones: raciones,
  etiquetas: etiquetas,
  origen: RecipeOrigin.ia,
);

/// The recipe shown in the detail and cooking-mode screenshots.
final featuredRecipe = _recipe(
  'Merluza al horno con patatas panaderas',
  descripcion:
      'Un clásico de domingo: merluza jugosa sobre una cama de patatas y '
      'cebolla pochadas, con un toque de ajo y perejil.',
  tiempo: '40 min',
  calorias: '380',
  raciones: '4',
  etiquetas: ['Pescado', 'Horno', 'Sin gluten'],
  ingredientes: [
    '4 lomos de merluza (600 g)',
    '4 patatas medianas',
    '1 cebolla grande',
    '2 dientes de ajo',
    '100 ml de vino blanco',
    '4 cucharadas de aceite de oliva virgen extra',
    'Perejil fresco picado',
    'Sal y pimienta negra',
  ],
  pasos: [
    'Precalienta el horno a 200 °C con calor arriba y abajo.',
    'Pela las patatas y córtalas en rodajas finas. Corta la cebolla en juliana.',
    'Coloca patatas y cebolla en una bandeja, salpimienta, riega con aceite y '
        'hornea 20 minutos.',
    'Machaca el ajo con el perejil y un chorrito de aceite.',
    'Pon la merluza sobre las patatas, añade el majado y el vino blanco.',
    'Hornea 12 minutos más, hasta que el pescado esté blanco y jugoso.',
  ],
);

final _pool = <Recipe>[
  featuredRecipe,
  _recipe(
    'Lentejas estofadas con verduras',
    descripcion:
        'Lentejas de toda la vida, con zanahoria, pimiento y un '
        'sofrito suave. Mejor aún al día siguiente.',
    tiempo: '45 min',
    calorias: '420',
    raciones: '4',
    etiquetas: ['Cuchara', 'Táper'],
    ingredientes: [
      '300 g de lentejas pardinas',
      '2 zanahorias',
      '1 pimiento verde',
    ],
    pasos: [
      'Sofríe las verduras.',
      'Añade las lentejas y el agua.',
      'Cuece 35 minutos.',
    ],
  ),
  _recipe(
    'Pollo al curry con arroz basmati',
    descripcion: 'Curry cremoso con leche de coco, listo en media hora.',
    tiempo: '35 min',
    calorias: '560',
    raciones: '4',
    etiquetas: ['Rápida'],
    ingredientes: [
      '500 g de pechuga de pollo',
      '400 ml de leche de coco',
      '2 cucharadas de curry',
    ],
    pasos: [
      'Dora el pollo.',
      'Añade el curry y la leche de coco.',
      'Sirve con el arroz.',
    ],
  ),
  _recipe(
    'Tortilla de patatas jugosa',
    descripcion: 'Con cebolla, poco cuajada y dorada por fuera.',
    tiempo: '30 min',
    calorias: '350',
    raciones: '4',
    etiquetas: ['Clásica', 'Vegetariana'],
    ingredientes: ['5 huevos', '4 patatas', '1 cebolla'],
    pasos: [
      'Confita patata y cebolla.',
      'Mezcla con el huevo.',
      'Cuaja por ambos lados.',
    ],
  ),
  _recipe(
    'Ensalada de garbanzos y aguacate',
    descripcion: 'Fresca, saciante y lista en un cuarto de hora.',
    tiempo: '15 min',
    calorias: '410',
    raciones: '2',
    etiquetas: ['Vegetariana', 'Rápida', 'Táper'],
    ingredientes: [
      '400 g de garbanzos cocidos',
      '1 aguacate',
      'Tomates cherry',
    ],
    pasos: ['Escurre los garbanzos.', 'Trocea el resto.', 'Aliña y mezcla.'],
  ),
  _recipe(
    'Crema de calabaza y jengibre',
    descripcion: 'Suave, ligera y con un punto picante.',
    tiempo: '40 min',
    calorias: '220',
    raciones: '4',
    etiquetas: ['Vegetariana', 'Ligera'],
    ingredientes: ['1 kg de calabaza', '1 puerro', 'Jengibre fresco'],
    pasos: [
      'Pocha el puerro.',
      'Cuece la calabaza.',
      'Tritura con el jengibre.',
    ],
  ),
  _recipe(
    'Salmón con verduras al vapor',
    descripcion: 'Cena ligera y completa en un solo paso.',
    tiempo: '25 min',
    calorias: '390',
    raciones: '2',
    etiquetas: ['Pescado', 'Ligera'],
    ingredientes: ['2 lomos de salmón', '1 brócoli', '2 zanahorias'],
    pasos: [
      'Cuece las verduras al vapor.',
      'Marca el salmón.',
      'Sirve con limón.',
    ],
  ),
  _recipe(
    'Pasta con pesto de albahaca',
    descripcion: 'Pesto casero con piñones y parmesano.',
    tiempo: '20 min',
    calorias: '610',
    raciones: '4',
    etiquetas: ['Rápida', 'Vegetariana'],
    ingredientes: [
      '400 g de espaguetis',
      '1 manojo de albahaca',
      '40 g de piñones',
    ],
    pasos: ['Cuece la pasta.', 'Tritura el pesto.', 'Mezcla y sirve.'],
  ),
];

const _days = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

Future<void> seedDemoData() async {
  // Favourites (newest last so the featured one shows first in "recent").
  for (final recipe in _pool.reversed) {
    await appStorage.insertFavRecipe(recipe);
  }

  // Weekly menu: lunch and dinner for every day, rotating through the pool.
  for (var d = 0; d < _days.length; d++) {
    await appStorage.insertMenuRecipe(
      _pool[d % _pool.length],
      _days[d],
      'Comida',
    );
    await appStorage.insertMenuRecipe(
      _pool[(d + 3) % _pool.length],
      _days[d],
      'Cena',
    );
  }

  final cart = <(String, CartCategory, bool)>[
    ('Merluza (4 lomos)', CartCategory.carnesPescados, false),
    ('Salmón fresco', CartCategory.carnesPescados, false),
    ('Patatas (2 kg)', CartCategory.frutasVerduras, false),
    ('Calabaza', CartCategory.frutasVerduras, false),
    ('Aguacates', CartCategory.frutasVerduras, true),
    ('Albahaca fresca', CartCategory.frutasVerduras, false),
    ('Huevos camperos', CartCategory.lacteosHuevos, false),
    ('Yogur natural', CartCategory.lacteosHuevos, true),
    ('Lentejas pardinas', CartCategory.despensa, false),
    ('Arroz basmati', CartCategory.despensa, false),
    ('Leche de coco', CartCategory.despensa, false),
    ('Guisantes', CartCategory.congelados, false),
    ('Agua con gas', CartCategory.bebidas, true),
  ];
  for (final (name, category, purchased) in cart) {
    await appStorage.insertCartItem(
      CartItem(name: name, categoria: category, isPurchased: purchased),
    );
  }
}
