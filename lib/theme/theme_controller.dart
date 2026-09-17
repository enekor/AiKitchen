import 'package:aikitchen/services/shared_preferences_service.dart';
import 'package:flutter/material.dart';

/// Modo de tema elegido por el usuario.
///
/// En navegador no existe el color dinámico del sistema, así que poder elegir
/// claro u oscuro a mano deja de ser un lujo y pasa a ser necesario.
class ThemeController extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  Future<void> load() async {
    final stored = await SharedPreferencesService.getStringValue(
      SharedPreferencesKeys.themeMode,
    );
    _mode = _parse(stored);
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    await SharedPreferencesService.setStringValue(
      SharedPreferencesKeys.themeMode,
      mode.name,
    );
  }

  static ThemeMode _parse(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String get label {
    switch (_mode) {
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Oscuro';
      case ThemeMode.system:
        return 'Según el sistema';
    }
  }
}

final ThemeController themeController = ThemeController();
