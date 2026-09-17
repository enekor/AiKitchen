import 'package:flutter/foundation.dart';

/// Índice de cada destino del [AppShell], en el mismo orden que su barra de
/// navegación.
abstract class AppShellTab {
  static const int home = 0;
  static const int search = 1;
  static const int shoppingList = 2;
  static const int favourites = 3;
  static const int weeklyMenu = 4;
}

/// Modo inicial con el que abrir el centro de búsqueda.
enum SearchMode { byName, byIngredients, web, fromUrl }

/// Permite navegar entre los destinos del armazón desde fuera de él, por
/// ejemplo desde los accesos rápidos de Inicio hacia un modo concreto de
/// Buscar. Los destinos comparten un único `Scaffold` con `IndexedStack`, así
/// que cambiar de pestaña no es una ruta nueva: es un cambio de índice.
class AppShellController extends ChangeNotifier {
  AppShellController._();

  static final AppShellController instance = AppShellController._();

  int tab = AppShellTab.home;

  /// Se consume una sola vez: `SearchHub` lo lee al construirse y lo limpia,
  /// para que volver a abrir Buscar por la barra no fuerce siempre el mismo
  /// modo.
  SearchMode? pendingSearchMode;

  void goTo(int tab, {SearchMode? searchMode}) {
    this.tab = tab;
    pendingSearchMode = searchMode;
    notifyListeners();
  }

  SearchMode? consumePendingSearchMode() {
    final mode = pendingSearchMode;
    pendingSearchMode = null;
    return mode;
  }
}
