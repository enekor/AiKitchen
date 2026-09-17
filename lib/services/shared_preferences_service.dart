import 'package:aikitchen/services/storage/app_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SharedPreferencesKeys {
  numRecetas,
  tonoTextos,
  favRecipes,
  idioma,
  geminiApiKey,
  tipoReceta,
  historialBusquedaNombres,
  useTTS,
  termsAccepted,
  firstStart,
  selectedModel,
  themeMode,
  corsProxy,
  velocidadVoz,
  creatividad,
  densidadCompacta,
}

class SharedPreferencesService {
  /// `firstStart` y `termsAccepted` viven en SharedPreferences puro porque se
  /// leen antes de que el almacenamiento principal esté listo. El resto pasa
  /// por [appStorage], que en web es localStorage y en móvil es SQLite.
  static bool _isStorageKey(SharedPreferencesKeys key) {
    return key != SharedPreferencesKeys.firstStart &&
        key != SharedPreferencesKeys.termsAccepted;
  }

  static Future<void> setStringValue(
    SharedPreferencesKeys key,
    String value,
  ) async {
    if (_isStorageKey(key)) {
      await appStorage.setPreference(key.toString(), value);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key.toString(), value);
    }
  }

  static Future<String?> getStringValue(SharedPreferencesKeys key) async {
    if (_isStorageKey(key)) {
      return await appStorage.getPreference(key.toString());
    } else {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key.toString());
    }
  }

  static Future<List<String>> getStringListValue(
    SharedPreferencesKeys key,
  ) async {
    if (_isStorageKey(key)) {
      final val = await appStorage.getPreference(key.toString());
      return val != null && val.isNotEmpty ? val.split(',') : [];
    } else {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(key.toString()) ?? [];
    }
  }

  static Future<void> setStringListValue(
    SharedPreferencesKeys key,
    List<String> value,
  ) async {
    if (_isStorageKey(key)) {
      await appStorage.setPreference(key.toString(), value.join(','));
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(key.toString(), value);
    }
  }

  static Future<void> setBoolValue(
    SharedPreferencesKeys key,
    bool value,
  ) async {
    if (_isStorageKey(key)) {
      await appStorage.setPreference(key.toString(), value.toString());
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key.toString(), value);
    }
  }

  static Future<bool> getBoolValue(SharedPreferencesKeys key) async {
    if (_isStorageKey(key)) {
      final val = await appStorage.getPreference(key.toString());
      return val == 'true';
    } else {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key.toString()) ?? false;
    }
  }

  static Future<void> removeValue(SharedPreferencesKeys key) async {
    if (_isStorageKey(key)) {
      await appStorage.deletePreference(key.toString());
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key.toString());
  }
}
