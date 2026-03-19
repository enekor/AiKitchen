import 'dart:convert';
import 'dart:io';

import 'package:aikitchen/services/log_file_service.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Extrae una receta a partir de un video de YouTube, TikTok o Instagram.
///
/// Flujo:
///   cobalt.tools → descarga audio MP3 → Groq Whisper (transcripción) → Groq LLM (receta JSON)
///
/// Devuelve siempre un JSON String con el formato {status, response} del proyecto:
///   {"status": "ok",   "response": [{...Recipe json...}]}
///   {"status": "fail", "response": "motivo del error"}
///
/// Límites del tier gratuito de Groq:
///   Whisper: 7.200 segundos de audio/día (~2 h)
///   LLM:    14.400 tokens/minuto (Llama 3.3 70B)
class GroqVideoService {
  final String apiKey;

  static const _groqBase = 'https://api.groq.com/openai/v1';
  static const _whisperModel = 'whisper-large-v3-turbo';
  static const _llmModels = [
    'llama-3.3-70b-versatile',
    'llama-3.1-8b-instant',
  ];

  GroqVideoService({required this.apiKey});

  // ─── Punto de entrada público ─────────────────────────────────────────────

  /// [onStatus] callback opcional para notificar el paso actual a la UI.
  Future<String> extractRecipe(
    String videoUrl, {
    void Function(String)? onStatus,
  }) async {
    final log = LogFileService();
    _validateUrl(videoUrl);

    try {
      onStatus?.call('Obteniendo enlace de descarga...');
      await log.appendLog('INFO GroqVideoService: Obteniendo cobalt URL para $videoUrl');
      final downloadUrl = await _getCobaltUrl(videoUrl);

      onStatus?.call('Descargando audio...');
      await log.appendLog('INFO GroqVideoService: Descargando audio');
      final audioFile = await _downloadToTemp(downloadUrl);

      try {
        onStatus?.call('Transcribiendo el audio...');
        await log.appendLog('INFO GroqVideoService: Transcribiendo con Whisper');
        final transcript = await _transcribe(audioFile);

        if (transcript.trim().isEmpty) {
          return jsonEncode({
            'status': 'fail',
            'response': 'No se detectó voz en el video.',
          });
        }

        onStatus?.call('Extrayendo la receta...');
        await log.appendLog('INFO GroqVideoService: Extrayendo receta con LLM');
        return await _extractFromTranscript(transcript);
      } finally {
        try {
          audioFile.deleteSync();
        } catch (_) {}
      }
    } catch (e) {
      await log.appendLog('ERROR GroqVideoService: $e');
      return jsonEncode({'status': 'fail', 'response': e.toString().replaceAll('Exception: ', '')});
    }
  }

  // ─── Validación ───────────────────────────────────────────────────────────

  void _validateUrl(String url) {
    final supported = url.contains('youtube.com') ||
        url.contains('youtu.be') ||
        url.contains('tiktok.com') ||
        url.contains('instagram.com');
    if (!supported) {
      throw Exception('URL no soportada. Usa YouTube, TikTok o Instagram.');
    }
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

    final sizeMb = res.bodyBytes.length / (1024 * 1024);
    if (sizeMb > 24.5) {
      throw Exception(
        'El audio pesa ${sizeMb.toStringAsFixed(1)} MB y supera el límite de 25 MB. '
        'Prueba con un video más corto (máx ~25 min a 128 kbps).',
      );
    }

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/aikitchen_video_${DateTime.now().millisecondsSinceEpoch}.mp3',
    );
    await file.writeAsBytes(res.bodyBytes);
    return file;
  }

  // ─── Groq Whisper ─────────────────────────────────────────────────────────

  Future<String> _transcribe(File audioFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_groqBase/audio/transcriptions'),
    )
      ..headers['Authorization'] = 'Bearer $apiKey'
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        await audioFile.readAsBytes(),
        filename: 'audio.mp3',
      ))
      ..fields['model'] = _whisperModel
      ..fields['response_format'] = 'text';

    final streamRes =
        await request.send().timeout(const Duration(seconds: 300));
    final res = await http.Response.fromStream(streamRes);

    if (res.statusCode == 429) {
      throw Exception(
        'Cuota de Groq Whisper agotada (7.200 seg/día). Inténtalo mañana.',
      );
    }
    if (res.statusCode != 200) {
      throw Exception('Groq Whisper error ${res.statusCode}: ${res.body}');
    }

    return res.body.trim();
  }

  // ─── Groq LLM ─────────────────────────────────────────────────────────────

  Future<String> _extractFromTranscript(String transcript) async {
    final log = LogFileService();
    Exception? lastErr;

    for (final model in _llmModels) {
      try {
        final res = await http
            .post(
              Uri.parse('$_groqBase/chat/completions'),
              headers: {
                'Authorization': 'Bearer $apiKey',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'model': model,
                'response_format': {'type': 'json_object'},
                'temperature': 0.1,
                'max_tokens': 1024,
                'messages': [
                  {
                    'role': 'system',
                    'content':
                        'Eres un chef experto. Extraes recetas de cocina de '
                        'transcripciones de video. Respondes ÚNICAMENTE con '
                        'JSON válido, sin texto adicional.',
                  },
                  {
                    'role': 'user',
                    'content': _buildLlmPrompt(transcript),
                  },
                ],
              }),
            )
            .timeout(const Duration(seconds: 60));

        if (res.statusCode == 429) {
          lastErr = Exception('Cuota agotada en $model');
          await log.appendLog(
              'WARN GroqVideoService: Cuota agotada en $model, probando siguiente...');
          continue;
        }

        if (res.statusCode != 200) {
          throw Exception('Groq LLM ($model) error ${res.statusCode}: ${res.body}');
        }

        final decodedBody = utf8.decode(res.bodyBytes, allowMalformed: true);
        final data = jsonDecode(decodedBody) as Map<String, dynamic>;
        final content =
            (data['choices'] as List)[0]['message']['content'] as String;

        await log.appendLog('INFO GroqVideoService: Receta extraída con $model');
        return content;
      } catch (e) {
        lastErr = Exception(e.toString());
        await log.appendLog('ERROR GroqVideoService ($model): $e');
      }
    }

    throw lastErr ??
        Exception('No se pudo extraer la receta con ningún modelo disponible.');
  }

  String _buildLlmPrompt(String transcript) =>
      'TRANSCRIPCIÓN DEL VIDEO:\n'
      '$transcript\n\n'
      'Si la transcripción NO contiene una receta de cocina, devuelve EXACTAMENTE:\n'
      '{"status": "fail", "response": "No se encontró ninguna receta en este video"}\n\n'
      'Si SÍ contiene una receta, extráela y devuelve EXACTAMENTE este JSON:\n'
      '{"status": "ok", "response": [{'
      '"nombre": "nombre del plato",'
      '"descripcion": "descripción breve y apetitosa",'
      '"tiempoEstimado": "x min",'
      '"calorias": 350,'
      '"raciones": 2,'
      '"ingredientes": ["ingrediente con cantidad 1", "ingrediente con cantidad 2"],'
      '"preparacion": ["Paso 1 detallado", "Paso 2 detallado"]'
      '}]}\n'
      'Responde SOLO con el JSON, sin texto adicional ni markdown.';
}
