import 'dart:async';
import 'dart:convert';
import 'package:aikitchen/models/cart_item.dart';
import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:home_widget/home_widget.dart';

class WidgetService {
  static const String _shoppingListGroupId = 'shopping_list_group';
  static const String _favoritesGroupId = 'favorites_group';

  /// Inicializa los widgets de Android
  static Future<void> initializeWidgets() async {
    try {
      print('Initializing Android widgets...');

      // Configurar app group si es necesario
      await HomeWidget.setAppGroupId(_shoppingListGroupId);

      // Actualizar ambos widgets
      await updateShoppingListWidget();
      await updateFavoritesWidget();

      print('Android widgets initialized successfully');
    } catch (e) {
      print('Error initializing widgets: $e');
    }
  }

  /// Actualiza el widget de la lista de compra
  static Future<void> updateShoppingListWidget() async {
    try {
      final cartItems = await JsonDocumentsService().getCartItems();

      print(
        'Updating shopping list widget with ${cartItems.length} items',
      ); // Debug

      // Preparar datos para el widget
      final pendingItems =
          cartItems.where((item) => !item.isPurchased).toList();
      final completedItems =
          cartItems.where((item) => item.isPurchased).toList();

      // Convertir a formato simple para el widget nativo
      final itemsData =
          cartItems
              .map(
                (item) => {'name': item.name, 'isPurchased': item.isPurchased},
              )
              .toList();

      // Enviar datos al widget nativo
      await HomeWidget.saveWidgetData<String>(
        'shopping_list_items',
        jsonEncode(itemsData),
      );
      await HomeWidget.saveWidgetData<int>(
        'pending_count',
        pendingItems.length,
      );
      await HomeWidget.saveWidgetData<int>(
        'completed_count',
        completedItems.length,
      );
      await HomeWidget.saveWidgetData<String>(
        'last_updated',
        DateTime.now().toIso8601String(),
      );

      print('Shopping list data saved: ${jsonEncode(itemsData)}'); // Debug

      // Actualizar el widget
      await HomeWidget.updateWidget(
        name: 'com.N3k0chan.aikitchen.ShoppingListWidgetProvider',
        androidName: 'com.N3k0chan.aikitchen.ShoppingListWidgetProvider',
      );

      print('Shopping list widget update triggered'); // Debug
    } catch (e) {
      print('Error updating shopping list widget: $e');
    }
  }

  /// Actualiza el widget de recetas favoritas
  static Future<void> updateFavoritesWidget() async {
    try {
      final favoriteRecipes = await JsonDocumentsService().getFavRecipes();

      print(
        'Updating favorites widget with ${favoriteRecipes.length} recipes',
      ); // Debug

      // Preparar datos para el widget (limitar a las primeras 5 recetas)
      final limitedRecipes = favoriteRecipes.take(5).toList();
      final widgetData =
          limitedRecipes
              .map(
                (recipe) => {
                  'nombre': recipe.nombre,
                  'descripcion': recipe.descripcion,
                  'tiempo': recipe.tiempoEstimado,
                  'calorias': recipe.calorias.toInt(),
                  'raciones': recipe.raciones,
                },
              )
              .toList();

      // Enviar datos al widget nativo
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

      print('Favorites data saved: ${jsonEncode(widgetData)}'); // Debug

      // Actualizar el widget
      await HomeWidget.updateWidget(
        name: 'com.N3k0chan.aikitchen.FavoritesWidgetProvider',
        androidName: 'com.N3k0chan.aikitchen.FavoritesWidgetProvider',
      );

      print('Favorites widget update triggered'); // Debug
    } catch (e) {
      print('Error updating favorites widget: $e');
    }
  }

  /// Maneja las acciones desde los widgets (como marcar items como completados)
  static Future<void> handleWidgetAction(
    String action,
    Map<String, dynamic> data,
  ) async {
    try {
      switch (action) {
        case 'toggle_shopping_item':
          await _toggleShoppingItem(data['item_name'] as String);
          break;
        case 'add_shopping_item':
          await _addShoppingItem(data['item_name'] as String);
          break;
        case 'clear_completed':
          await _clearCompletedItems();
          break;
        case 'open_recipe':
          // Esta acción será manejada por el MainActivity de Android
          break;
        default:
          print('Unknown widget action: $action');
      }
    } catch (e) {
      print('Error handling widget action: $e');
    }
  }

  /// Alterna el estado de un item de la lista de compra
  static Future<void> _toggleShoppingItem(String itemName) async {
    final cartItems = await JsonDocumentsService().getCartItems();
    final itemIndex = cartItems.firstWhere((item) => item.name == itemName);

    itemIndex.isPurchased = !itemIndex.isPurchased;
      await JsonDocumentsService().updateCartItem(itemIndex);
      await updateShoppingListWidget();

  }

  /// Añade un nuevo item a la lista de compra
  static Future<void> _addShoppingItem(String itemName) async {
    if (itemName.trim().isEmpty) return;

      await JsonDocumentsService().addCartItem(CartItem(name: itemName.trim()));
      await updateShoppingListWidget();
  }

  /// Limpia los items completados de la lista de compra
  static Future<void> _clearCompletedItems() async {
    List<CartItem> cartItems = await JsonDocumentsService().getCartItems();
    cartItems = cartItems.where((item) => item.isPurchased).toList();

    for (var item in cartItems) {
      await JsonDocumentsService().removeCartItem(item.id!);
    }


    await updateShoppingListWidget();
  }

  /// Registra callbacks para manejar acciones desde widgets
  static void registerCallbacks() {
    HomeWidget.registerBackgroundCallback(_backgroundCallback);
  }

  /// Callback para manejar acciones en segundo plano
  static void _backgroundCallback(Uri? uri) {
    if (uri != null) {
      final action = uri.queryParameters['action'];
      final data = uri.queryParameters;

      if (action != null) {
        // Ejecutar la acción de forma asíncrona sin esperar
        handleWidgetAction(action, data).catchError((error) {
          print('Error in background callback: $error');
        });
      }
    }
  }

  /// Fuerza la actualización de todos los widgets
  static Future<void> refreshAllWidgets() async {
    print('Forcing refresh of all widgets...');
    await updateShoppingListWidget();
    await updateFavoritesWidget();
    print('All widgets refreshed');
  }

  /// Añade datos de prueba simples para debugging
  static Future<void> addSimpleTestData() async {
    print('Adding simple test data...');

    // Crear datos de prueba muy simples
    final testData = [
      {'name': 'Test Item 1', 'isPurchased': false},
      {'name': 'Test Item 2', 'isPurchased': true},
      {'name': 'Test Item 3', 'isPurchased': false},
    ];

    // Enviar directamente al widget sin pasar por JsonDocumentsService
    await HomeWidget.saveWidgetData<String>(
      'shopping_list_items',
      jsonEncode(testData),
    );
    await HomeWidget.saveWidgetData<int>('pending_count', 2);
    await HomeWidget.saveWidgetData<int>('completed_count', 1);
    await HomeWidget.saveWidgetData<String>(
      'last_updated',
      DateTime.now().toIso8601String(),
    );

    print('Simple test data saved: ${jsonEncode(testData)}');

    // Actualizar el widget
    await HomeWidget.updateWidget(
      name: 'com.N3k0chan.aikitchen.ShoppingListWidgetProvider',
      androidName: 'com.N3k0chan.aikitchen.ShoppingListWidgetProvider',
    );

    print('Simple test widget update triggered');
  }

  /// Método de depuración mejorado con logging detallado
  static Future<void> addDebugTestData() async {
    print('=== DEBUG: Adding test data with detailed logging ===');

    try {
      // Crear datos de prueba
      final testData = [
        {'name': 'Debug Item 1', 'isPurchased': false},
        {'name': 'Debug Item 2', 'isPurchased': true},
        {'name': 'Debug Item 3', 'isPurchased': false},
        {'name': 'Debug Item 4', 'isPurchased': false},
      ];

      print('DEBUG: Test data created: ${jsonEncode(testData)}');

      // Guardar datos usando HomeWidget
      print('DEBUG: Saving shopping_list_items...');
      await HomeWidget.saveWidgetData<String>(
        'shopping_list_items',
        jsonEncode(testData),
      );

      print('DEBUG: Saving counts...');
      await HomeWidget.saveWidgetData<int>('pending_count', 3);
      await HomeWidget.saveWidgetData<int>('completed_count', 1);

      print('DEBUG: Saving timestamp...');
      await HomeWidget.saveWidgetData<String>(
        'last_updated',
        DateTime.now().toIso8601String(),
      );

      // Verificar que los datos se guardaron
      print('DEBUG: Verifying saved data...');
      final savedData = await HomeWidget.getWidgetData<String>(
        'shopping_list_items',
        defaultValue: '[]',
      );
      print('DEBUG: Retrieved data: $savedData');

      // Forzar actualización del widget con múltiples intentos
      print('DEBUG: Updating widget (attempt 1)...');
      await HomeWidget.updateWidget(
        name: 'com.N3k0chan.aikitchen.ShoppingListWidgetProvider',
        androidName: 'com.N3k0chan.aikitchen.ShoppingListWidgetProvider',
      );

      // Esperar un momento y actualizar de nuevo
      await Future.delayed(Duration(milliseconds: 500));

      print('DEBUG: Updating widget (attempt 2)...');
      await HomeWidget.updateWidget(
        name: 'com.N3k0chan.aikitchen.ShoppingListWidgetProvider',
        androidName: 'com.N3k0chan.aikitchen.ShoppingListWidgetProvider',
      );

      print('=== DEBUG: Test data setup completed ===');
    } catch (e, stackTrace) {
      print('DEBUG ERROR: $e');
      print('DEBUG STACKTRACE: $stackTrace');
    }
  }
}
