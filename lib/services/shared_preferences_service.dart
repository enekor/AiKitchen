import 'package:shared_preferences/shared_preferences.dart';

enum SharedPreferencesKeys { numRecetas, tonoTextos, favRecipes }

class SharedPreferencesService {
  static Future<void> setStringValue(
    SharedPreferencesKeys key,
    String value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key.toString(), value);
  }

  static Future<String?> getStringValue(SharedPreferencesKeys key) async {
    final prefs = await SharedPreferences.getInstance();
    var ret =  prefs.getString(key.toString());

    return ret;
  }
}
