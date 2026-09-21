import 'dart:async';
import 'dart:convert';

import 'package:aikitchen/navigation/app_shell_controller.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/services/platform/platform_info.dart' as platform;
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

class WidgetService {
  /// Los widgets de pantalla de inicio solo existen en Android. En navegador
  /// el plugin no tiene implementación y cada llamada lanzaría una excepción,
  /// así que se comprueba aquí una vez en lugar de en cada pantalla.
  static bool get isAvailable => platform.supportsHomeWidgets;

  static const String _shoppingListGroupId = 'shopping_list_group';

  /// Anfitrión del URI con el que el widget y el botón de ajustes rápidos piden
  /// abrir la lista de la compra. Debe coincidir con el de `WidgetUris.kt`.
  static const String _shoppingListHost = 'shopping_list';

  static StreamSubscription<Uri?>? _clickSubscription;

  /// Inicializa los widgets de Android
  static Future<void> initializeWidgets() async {
    if (!isAvailable) return;
    try {
      await HomeWidget.setAppGroupId(_shoppingListGroupId);
      await updateShoppingListWidget();
      await updateFavoritesWidget();
    } catch (e) {
      debugPrint('Error initializing widgets: $e');
    }
  }

  /// Actualiza el widget de la lista de compra
  static Future<void> updateShoppingListWidget() async {
    if (!isAvailable) return;
    try {
      final cartItems = await JsonDocumentsService().getCartItems();

      final pendingCount = cartItems.where((i) => !i.isPurchased).length;

      // Los pendientes van primero: son lo que el usuario necesita ver sin
      // desplazar el widget.
      final ordered = [
        ...cartItems.where((i) => !i.isPurchased),
        ...cartItems.where((i) => i.isPurchased),
      ];

      final itemsData = ordered
          .map(
            (item) => {
              'id': item.id,
              'name': item.name,
              'isPurchased': item.isPurchased,
            },
          )
          .toList();

      await HomeWidget.saveWidgetData<String>(
        'shopping_list_items',
        jsonEncode(itemsData),
      );
      await HomeWidget.saveWidgetData<int>('pending_count', pendingCount);
      await HomeWidget.saveWidgetData<int>(
        'completed_count',
        cartItems.length - pendingCount,
      );
      await HomeWidget.saveWidgetData<String>(
        'last_updated',
        DateTime.now().toIso8601String(),
      );

      await HomeWidget.updateWidget(
        name: 'com.N3k0chan.aikitchen.ShoppingListWidgetProvider',
        androidName: 'com.N3k0chan.aikitchen.ShoppingListWidgetProvider',
      );
    } catch (e) {
      debugPrint('Error updating shopping list widget: $e');
    }
  }

  /// Actualiza el widget de recetas favoritas
  static Future<void> updateFavoritesWidget() async {
    if (!isAvailable) return;
    try {
      final favoriteRecipes = await JsonDocumentsService().getFavRecipes();

      final widgetData = favoriteRecipes
          .take(5)
          .map(
            (recipe) => {
              'nombre': recipe.nombre,
              'descripcion': recipe.descripcion,
              'tiempo': recipe.tiempoEstimado,
              'calorias': recipe.calorias,
              'raciones': recipe.raciones,
            },
          )
          .toList();

      await HomeWidget.saveWidgetData<String>(
        'favorite_recipes',
        jsonEncode(widgetData),
      );
      await HomeWidget.saveWidgetData<int>(
        'favorites_count',
        favoriteRecipes.length,
      );
      await HomeWidget.saveWidgetData<String>(
        'last_updated',
        DateTime.now().toIso8601String(),
      );

      await HomeWidget.updateWidget(
        name: 'com.N3k0chan.aikitchen.FavoritesWidgetProvider',
        androidName: 'com.N3k0chan.aikitchen.FavoritesWidgetProvider',
      );
    } catch (e) {
      debugPrint('Error updating favorites widget: $e');
    }
  }

  /// Alterna el estado de un artículo desde el widget, identificándolo por su
  /// `id`: por nombre se tachaba el artículo equivocado cuando la lista tenía
  /// dos homónimos.
  static Future<void> _toggleShoppingItem(String? rawId) async {
    final id = int.tryParse(rawId ?? '');
    if (id == null) return;

    final items = await JsonDocumentsService().getCartItems();
    final item = items.where((i) => i.id == id).firstOrNull;
    if (item == null) return;

    item.isPurchased = !item.isPurchased;
    await JsonDocumentsService().updateCartItem(item);
    await updateShoppingListWidget();
  }

  /// Registra el manejador de acciones lanzadas desde los widgets.
  static void registerCallbacks() {
    if (!isAvailable) return;
    HomeWidget.registerInteractivityCallback(_backgroundCallback);
  }

  /// Se ejecuta en un contexto aparte cuando el usuario toca el widget.
  ///
  /// La anotación es obligatoria: sin ella el compilador de release descarta
  /// esta función, porque nada del código Dart la llama directamente.
  @pragma('vm:entry-point')
  static Future<void> _backgroundCallback(Uri? uri) async {
    if (uri == null) return;

    try {
      if (uri.queryParameters['action'] == 'toggle_shopping_item') {
        await _toggleShoppingItem(uri.queryParameters['item_id']);
      }
    } catch (e) {
      debugPrint('Error in background callback: $e');
    }
  }

  /// Lleva la app a la pestaña de la lista de la compra cuando se ha llegado
  /// desde el widget o desde el botón de ajustes rápidos.
  ///
  /// Cubre los dos caminos: el arranque en frío, donde el URI ya venía en el
  /// intent inicial, y la app ya viva, que lo recibe por el flujo.
  static Future<void> listenForLaunchRequests() async {
    if (!isAvailable) return;

    await _clickSubscription?.cancel();
    _clickSubscription = HomeWidget.widgetClicked.listen(_handleLaunchUri);

    try {
      _handleLaunchUri(await HomeWidget.initiallyLaunchedFromHomeWidget());
    } catch (e) {
      debugPrint('Error reading initial widget launch: $e');
    }
  }

  static void _handleLaunchUri(Uri? uri) {
    if (uri?.host != _shoppingListHost) return;
    AppShellController.instance.goTo(AppShellTab.shoppingList);
  }
}
