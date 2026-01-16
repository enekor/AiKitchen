import 'package:aikitchen/services/sqlite_service.dart';
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
  firstStart
}

class SharedPreferencesService {
  // Solo estas claves se mantienen en SharedPreferences. 
  // El resto van a SQLite tabla 'preferences'.
  static bool _isSqliteKey(SharedPreferencesKeys key) {
    return key != SharedPreferencesKeys.firstStart &&
           key != SharedPreferencesKeys.termsAccepted;
  }

  static Future<void> setStringValue(
    SharedPreferencesKeys key,
    String value,
  ) async {
    if (_isSqliteKey(key)) {
      await SqliteService().editPreference(key.toString(), value);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key.toString(), value);
    }
  }

  static Future<String?> getStringValue(SharedPreferencesKeys key) async {
    if (_isSqliteKey(key)) {
      return await SqliteService().getByPreference(key.toString());
    } else {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key.toString());
    }
  }

  static Future<List<String>> getStringListValue(
    SharedPreferencesKeys key,
  ) async {
    if (_isSqliteKey(key)) {
      String? val = await SqliteService().getByPreference(key.toString());
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
    if (_isSqliteKey(key)) {
      await SqliteService().editPreference(key.toString(), value.join(','));
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(key.toString(), value);
    }
  }

  static Future<void> setBoolValue(
    SharedPreferencesKeys key,
    bool value,
  ) async {
    if (_isSqliteKey(key)) {
      await SqliteService().editPreference(key.toString(), value.toString());
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key.toString(), value);
    }
  }

  static Future<bool> getBoolValue(SharedPreferencesKeys key) async {
    if (_isSqliteKey(key)) {
      String? val = await SqliteService().getByPreference(key.toString());
      return val == 'true';
    } else {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key.toString()) ?? false;
    }
  }

  static void removeValue(SharedPreferencesKeys key) async{
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(key.toString());
  }
}
