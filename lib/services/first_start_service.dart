import 'package:aikitchen/services/shared_preferences_service.dart';
import 'package:aikitchen/services/storage/app_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Migración única desde el almacenamiento antiguo (SharedPreferences puro)
/// al almacenamiento actual ([appStorage]).
class FirstStartService {
  static final FirstStartService _instance = FirstStartService._internal();

  FirstStartService._internal();

  factory FirstStartService() {
    return _instance;
  }

  Future<void> firstStart() async {
    final alreadyStarted = await SharedPreferencesService.getBoolValue(
      SharedPreferencesKeys.firstStart,
    );
    if (alreadyStarted) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Se leen los valores heredados directamente de SharedPreferences y se
      // vuelcan al almacenamiento actual. Leerlos vía SharedPreferencesService
      // no serviría: ese ya apunta al destino de la migración.
      for (final key in SharedPreferencesKeys.values) {
        if (key == SharedPreferencesKeys.firstStart) continue;
        if (key == SharedPreferencesKeys.termsAccepted) continue;

        final name = key.toString();
        final legacy = prefs.get(name);
        if (legacy == null) continue;

        final value = legacy is List<String> ? legacy.join(',') : '$legacy';
        if (value.isNotEmpty) {
          await appStorage.setPreference(name, value);
        }
        await prefs.remove(name);
      }
    } catch (e) {
      // La migración nunca debe impedir que la app arranque.
      debugPrint('Error migrando preferencias heredadas: $e');
    }

    await SharedPreferencesService.setBoolValue(
      SharedPreferencesKeys.firstStart,
      true,
    );
  }
}
