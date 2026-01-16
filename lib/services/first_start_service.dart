import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/services/shared_preferences_service.dart';
import 'package:aikitchen/services/sqlite_service.dart';

class FirstStartService {
  static final FirstStartService _instance = FirstStartService._internal();

  FirstStartService._internal();

  factory FirstStartService() {
    return _instance;
  }

  Future<void> firstStart() async {
    // Si 'firstStart' es false (valor por defecto), significa que es la primera vez
    // que ejecutamos esta versión con SQLite y debemos migrar los datos.
    bool alreadyStarted = await SharedPreferencesService.getBoolValue(
      SharedPreferencesKeys.firstStart,
    );

    if (!alreadyStarted) {
      final sqlite = SqliteService();
      final jsonService = JsonDocumentsService();

      // 1. Migrar todas las SharedPreferences a la tabla 'preferences' de SQLite
      for (var key in SharedPreferencesKeys.values) {
        if (key == SharedPreferencesKeys.firstStart) continue;
        if (key == SharedPreferencesKeys.termsAccepted) continue;

        // Intentamos obtener el valor como String (la mayoría lo son o se pueden tratar como tal)
        String? value;
        if (key == SharedPreferencesKeys.useTTS ||
            key == SharedPreferencesKeys.termsAccepted) {
          bool boolVal = await SharedPreferencesService.getBoolValue(key);
          value = boolVal.toString();
        } else if (key == SharedPreferencesKeys.historialBusquedaNombres) {
          List<String> listVal = await SharedPreferencesService.getStringListValue(
            key,
          );
          value = listVal.join(',');
        } else {
          value = await SharedPreferencesService.getStringValue(key);
        }

        if (value != null) {
          await sqlite.editPreference(key.toString(), value);
        }

        SharedPreferencesService.removeValue(key);
      }

      // 2. Migrar recetas favoritas
      final favRecipes = await jsonService.getFavRecipes();
      for (var recipe in favRecipes) {
        await sqlite.insertFavRecipe(recipe);
      }

      // 3. Migrar lista de la compra
      final cartItems = await jsonService.getCartItems();
      for (var item in cartItems) {
        await sqlite.insertCartItem(item);
      }

      // 4. Migrar menú semanal
      final weeklyMenu = await jsonService.loadWeeklyMenu();
      if (weeklyMenu.isNotEmpty) {
        await sqlite.clearMenu(); // Limpiar por si acaso
        weeklyMenu.forEach((dia, recetas) {
          for (var i = 0; i < recetas.length; i++) {
            // Asumimos el orden basado en la lógica de WeeklyMenu (Comida, Cena)
            String tipoComida = i == 0 ? 'Comida' : 'Cena';
            sqlite.insertMenuRecipe(recetas[i], dia, tipoComida);
          }
        });
      }

      // Marcar que la migración se ha completado
      await SharedPreferencesService.setBoolValue(
        SharedPreferencesKeys.firstStart,
        true,
      );
    }
  }
}
