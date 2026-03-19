import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:aikitchen/services/log_file_service.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Extrae una receta a partir de un video de YouTube, TikTok o Instagram
/// usando la API de Gemini.
///
/// Flujo:
///   YouTube            → URL directa a Gemini (sin descarga)
///   TikTok / Instagram → cobalt.tools → audio MP3 → Gemini Files API → generateContent
///
/// Devuelve siempre un JSON String con el formato {status, response} del proyecto:
///   {"status": "ok",   "response": [{...Recipe json...}]}
///   {"status": "fail", "response": "motivo del error"}
class GeminiVideoService {
  final String apiKey;

  static const _base = 'https://generativelanguage.googleapis.com';

  static const _models = [
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-2.5-flash-lite',
  ];

  GeminiVideoService({required this.apiKey});

  // ─── Punto de entrada público ─────────────────────────────────────────────

  /// [onStatus] callback opcional para notificar el paso actual a la UI.
  Future<String> extractRecipe(
    String videoUrl, {
    void Function(String)? onStatus,
  }) async {
    final log = LogFileService();
    try {
      final platform = _detectPlatform(videoUrl);
      if (platform == 'youtube') {
        onStatus?.call('Enviando video a Gemini...');
        await log.appendLog('INFO GeminiVideoService: Procesando YouTube URL directamente');
        return await _processYouTube(videoUrl);
      } else {
        onStatus?.call('Obteniendo enlace de descarga...');
        await log.appendLog('INFO GeminiVideoService: Obteniendo cobalt URL para $videoUrl');
        final downloadUrl = await _getCobaltUrl(videoUrl);

        onStatus?.call('Descargando audio...');
        await log.appendLog('INFO GeminiVideoService: Descargando audio');
        final audioFile = await _downloadToTemp(downloadUrl);

        try {
          onStatus?.call('Subiendo audio a Gemini...');
          await log.appendLog('INFO GeminiVideoService: Subiendo a Files API');
          final fileInfo = await _uploadToFilesApi(audioFile);

          onStatus?.call('Procesando audio...');
          await log.appendLog('INFO GeminiVideoService: Esperando estado ACTIVE');
          final activeFile = await _waitForActive(fileInfo['name'] as String);

          onStatus?.call('Extrayendo la receta...');
          await log.appendLog('INFO GeminiVideoService: Generando contenido');
          final result = await _processAudio(videoUrl, activeFile);

          _deleteFromFilesApi(fileInfo['name'] as String);
          return result;
        } finally {
          try {
            audioFile.deleteSync();
          } catch (_) {}
        }
      }
    } catch (e) {
      await LogFileService().appendLog('ERROR GeminiVideoService: $e');
      return jsonEncode({
        'status': 'fail',
        'response': e.toString().replaceAll('Exception: ', ''),
      });
    }
  }

  // ─── YouTube ──────────────────────────────────────────────────────────────

  Future<String> _processYouTube(String videoUrl) {
    return _generate([
      {
        'parts': [
          {
            'fileData': {'fileUri': videoUrl},
          },
          {'text': _recipePrompt(videoUrl)},
        ],
      }
    ]);
  }

  // ─── TikTok / Instagram ───────────────────────────────────────────────────

  Future<String> _processAudio(
    String videoUrl,
    Map<String, dynamic> activeFile,
  ) {
    return _generate([
      {
        'parts': [
          {
            'fileData': {
              'mimeType': activeFile['mimeType'] ?? 'audio/mpeg',
              'fileUri': activeFile['uri'],
            },
          },
          {'text': _recipePrompt(videoUrl)},
        ],
      }
    ]);
  }

  // ─── cobalt.tools ─────────────────────────────────────────────────────────

  Future<String> _getCobaltUrl(String videoUrl) async {
    final res = await http
        .post(
          Uri.parse('https://api.cobalt.tools/'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'url': videoUrl,
            'downloadMode': 'audio',
            'audioFormat': 'mp3',
            'audioBitrate': '128',
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (res.statusCode != 200) {
      throw Exception('No se pudo acceder al video (cobalt ${res.statusCode})');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final status = data['status'] as String;

    if (status == 'redirect' || status == 'tunnel' || status == 'stream') {
      return data['url'] as String;
    }
    if (status == 'picker') {
      return (data['picker'] as List).first['url'] as String;
    }

    final code = (data['error'] as Map?)?['code'] ?? status;
    throw Exception('No se pudo obtener el audio: $code');
  }

  // ─── Descarga a temp ──────────────────────────────────────────────────────

  Future<File> _downloadToTemp(String url) async {
    final res = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 120));

    if (res.statusCode != 200) {
      throw Exception('Error descargando audio (${res.statusCode})');
    }

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/aikitchen_video_${DateTime.now().millisecondsSinceEpoch}.mp3',
    );
    await file.writeAsBytes(res.bodyBytes);
    return file;
  }

  // ─── Gemini Files API ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _uploadToFilesApi(File file) async {
    final bytes = await file.readAsBytes();
    const mimeType = 'audio/mpeg';
    final boundary = 'b${DateTime.now().millisecondsSinceEpoch}';

    final metaJson = jsonEncode({
      'file': {'display_name': 'aikitchen_audio', 'mimeType': mimeType},
    });

    final body = Uint8List.fromList([
      ...utf8.encode('--$boundary\r\n'),
      ...utf8.encode('Content-Type: application/json; charset=UTF-8\r\n\r\n'),
      ...utf8.encode(metaJson),
      ...utf8.encode('\r\n--$boundary\r\n'),
      ...utf8.encode('Content-Type: $mimeType\r\n\r\n'),
      ...bytes,
      ...utf8.encode('\r\n--$boundary--\r\n'),
    ]);

    final res = await http
        .post(
          Uri.parse(
            '$_base/upload/v1beta/files?uploadType=multipart&key=$apiKey',
          ),
          headers: {
            'Content-Type': 'multipart/related; boundary=$boundary',
            'Content-Length': '${body.length}',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 120));

    if (res.statusCode != 200) {
      throw Exception('Error subiendo archivo a Gemini: ${res.body}');
    }

    return (jsonDecode(res.body) as Map<String, dynamic>)['file']
        as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _waitForActive(String fileName) async {
    for (var i = 0; i < 40; i++) {
      await Future.delayed(const Duration(seconds: 5));
      final res = await http.get(
        Uri.parse('$_base/v1beta/$fileName?key=$apiKey'),
      );
      if (res.statusCode == 200) {
        final f = jsonDecode(res.body) as Map<String, dynamic>;
        final state = f['state'] as String?;
        if (state == 'ACTIVE') return f;
        if (state == 'FAILED') {
          throw Exception('Gemini no pudo procesar el archivo de audio.');
        }
      }
    }
    throw Exception('Timeout: el archivo tardó demasiado en procesarse.');
  }

  Future<void> _deleteFromFilesApi(String fileName) async {
    try {
      await http.delete(Uri.parse('$_base/v1beta/$fileName?key=$apiKey'));
    } catch (_) {}
  }

  // ─── generateContent con fallback de modelos ──────────────────────────────

  Future<String> _generate(List<Map<String, dynamic>> contents) async {
    final log = LogFileService();
    Exception? lastErr;

    for (final model in _models) {
      try {
        final res = await http
            .post(
              Uri.parse(
                '$_base/v1beta/models/$model:generateContent?key=$apiKey',
              ),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'contents': contents}),
            )
            .timeout(const Duration(seconds: 120));

        if (res.statusCode == 429) {
          lastErr = Exception('Cuota agotada en $model');
          await log.appendLog(
              'WARN GeminiVideoService: Cuota agotada en $model, probando siguiente...');
          continue;
        }

        if (res.statusCode != 200) {
          throw Exception('Gemini ($model) error ${res.statusCode}: ${res.body}');
        }

        await log.appendLog('INFO GeminiVideoService: Receta extraída con $model');
        return _parseGeminiResponse(res.body);
      } catch (e) {
        lastErr = Exception(e.toString());
        await log.appendLog('ERROR GeminiVideoService ($model): $e');
      }
    }

    throw lastErr ?? Exception('Todos los modelos de Gemini están agotados.');
  }

  String _parseGeminiResponse(String body) {
    final data = jsonDecode(body) as Map<String, dynamic>;
    final parts =
        (data['candidates'] as List)[0]['content']['parts'] as List;
    final text = (parts[0]['text'] as String)
        .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
        .replaceAll(RegExp(r'```\s*$', multiLine: true), '')
        .trim();
    return text;
  }

  // ─── Detección de plataforma ──────────────────────────────────────────────

  String _detectPlatform(String url) {
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      return 'youtube';
    }
    if (url.contains('tiktok.com')) return 'tiktok';
    if (url.contains('instagram.com')) return 'instagram';
    throw Exception('URL no soportada. Usa YouTube, TikTok o Instagram.');
  }

  // ─── Prompt ───────────────────────────────────────────────────────────────

  String _recipePrompt(String url) =>
      'Analiza este contenido de cocina y extrae la receta completa.\n\n'
      'Si NO contiene ninguna receta de cocina, devuelve EXACTAMENTE:\n'
      '{"status": "fail", "response": "No se encontró ninguna receta en este video"}\n\n'
      'Si SÍ contiene una receta, devuelve EXACTAMENTE este JSON:\n'
      '{"status": "ok", "response": [{'
      '"nombre": "nombre del plato",'
      '"descripcion": "descripción breve y apetitosa",'
      '"tiempoEstimado": "x min",'
      '"calorias": 350,'
      '"raciones": 2,'
      '"ingredientes": ["ingrediente con cantidad 1", "ingrediente con cantidad 2"],'
      '"preparacion": ["Paso 1 detallado", "Paso 2 detallado"]'
      '}]}\n\n'
      'Responde SOLO con el JSON, sin texto adicional ni markdown.';
}
