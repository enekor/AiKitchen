import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Registros en fichero, para plataformas con sistema de ficheros.
class LogStore {
  File? _logFile;

  Future<void> initialize() async {
    if (_logFile != null) return;

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/app_logs.txt');
    _logFile = file;

    // Se descarta el registro si es de antes de ayer, para que no crezca sin fin.
    if (await file.exists()) {
      final stat = await file.stat();
      final fileDate = DateTime(
        stat.modified.year,
        stat.modified.month,
        stat.modified.day,
      );
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayDate = DateTime(
        yesterday.year,
        yesterday.month,
        yesterday.day,
      );

      if (fileDate.isBefore(yesterdayDate)) {
        await file.delete();
        await file.create();
      }
    }
  }

  Future<void> append(String entry) async {
    await initialize();
    await _logFile!.writeAsString(entry, mode: FileMode.append);
  }

  Future<String> read() async {
    await initialize();
    if (await _logFile!.exists()) {
      return await _logFile!.readAsString();
    }
    return '';
  }

  Future<void> clear() async {
    await initialize();
    if (await _logFile!.exists()) {
      await _logFile!.delete();
    }
  }
}
