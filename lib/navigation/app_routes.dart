/// Nombres de ruta de toda la aplicación.
///
/// Se usan siempre con rutas nombradas, y no `MaterialPageRoute` a secas, para
/// que la barra de direcciones del navegador refleje la pantalla actual y el
/// botón atrás funcione.
abstract class AppRoutes {
  // Los cinco destinos persistentes del armazón de navegación.
  static const String home = '/inicio';
  static const String search = '/buscar';
  static const String shoppingList = '/compra';
  static const String favourites = '/favoritos';
  static const String weeklyMenu = '/menu';

  // Pantallas apiladas, fuera de los cinco destinos.
  static const String recipe = '/receta';
  static const String createRecipe = '/crear';
  static const String settings = '/ajustes';
  static const String logs = '/registros';
  static const String sharedPreview = '/compartida';
}
