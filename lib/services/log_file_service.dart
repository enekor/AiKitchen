import 'package:aikitchen/services/logging/log_store.dart';
import 'package:flutter/foundation.dart';

/// Registro de diagnóstico de la app.
///
/// Escribe en fichero en móvil y en memoria en navegador. Ningún fallo del
/// registro debe propagarse: anotar un error nunca puede causar otro.
class LogFileService {
  static final LogFileService _instance = LogFileService._internal();

  final LogStore _store = LogStore();

  LogFileService._internal();

  factory LogFileService() {
    return _instance;
  }

  Future<void> initialize() async {
    try {
      await _store.initialize();
    } catch (e) {
      debugPrint('No se pudo inicializar el registro: $e');
    }
  }

  Future<void> appendLog(String message) async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      await _store.append('[$timestamp] - $message\n');
    } catch (e) {
      debugPrint('No se pudo escribir en el registro: $e');
    }
  }

  Future<String> readLogs() async {
    try {
      return await _store.read();
    } catch (e) {
      return 'No se pudo leer el registro: $e';
    }
  }

  Future<void> clearLogs() async {
    try {
      await _store.clear();
    } catch (e) {
      debugPrint('No se pudo limpiar el registro: $e');
    }
  }
}
