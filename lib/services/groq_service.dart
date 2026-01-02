import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'log_file_service.dart';

class GroqService {
  Future<String> generateContent(
    String prompt,
    String apiKey, {
    BuildContext? context,
  }) async {
    final logService = LogFileService();
    const int maxAttempts = 3;
    List<String> attemptErrors = [];

    try {
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

      for (int attempt = 0; attempt < maxAttempts; attempt++) {
        try {
          await logService.appendLog('INFO GroqService: Intento ${attempt + 1} enviando petición...');

          final response = await http.post(
            url,
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': 'llama-3.3-70b-versatile',
              'messages': [
                {'role': 'user', 'content': prompt}
              ],
              'temperature': 0.7,
            }),
          ).timeout(const Duration(seconds: 30));

          if (response.statusCode == 200) {
            // Se usa utf8.decode con allowMalformed: true para evitar el error de "Missing extension byte"
            // si la respuesta contiene caracteres extraños o mal formados.
            final decodedBody = utf8.decode(response.bodyBytes, allowMalformed: true);
            final data = jsonDecode(decodedBody);
            final content = data['choices'][0]['message']['content'] as String;

            if (content.isNotEmpty) {
              return content;
            } else {
              final errorMsg = 'Respuesta vacía de Groq (Intento ${attempt + 1})';
              attemptErrors.add(errorMsg);
              await logService.appendLog('ERROR GroqService: $errorMsg');
            }
          } else {
            final errorData = jsonDecode(response.body);
            final errorMessage = errorData['error']?['message'] ?? 'Error desconocido';
            final errorMsg = 'Status ${response.statusCode} (Intento ${attempt + 1}): $errorMessage';
            attemptErrors.add(errorMsg);
            
            await logService.appendLog('ERROR GroqService: $errorMsg');

            if (response.statusCode == 401) {
              return 'Error: API Key de Groq inválida. Por favor, revísala en Ajustes.';
            }

            if (response.statusCode == 429) {
              if (context != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Límite de velocidad excedido en Groq. Reintentando...'),
                    backgroundColor: Colors.orangeAccent,
                  ),
                );
              }
              final waitMs = pow(2, attempt) * 1000 + 500;
              await Future.delayed(Duration(milliseconds: waitMs.toInt()));
              continue;
            }
            
            await Future.delayed(const Duration(seconds: 1));
            continue;
          }
        } catch (e) {
          final errorMsg = 'Error en intento ${attempt + 1}: $e';
          attemptErrors.add(errorMsg);
          await logService.appendLog('ERROR GroqService (Catch Intento): $errorMsg');
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      final details = attemptErrors.join(' | ');
      String userMessage = 'No se pudo generar respuesta con Groq tras varios intentos.';
      
      if (details.toLowerCase().contains('rate_limit') || details.contains('429')) {
        userMessage = 'Error: Has excedido el límite de velocidad de Groq. Por favor, espera un poco o cambia la clave.';
      }

      await logService.appendLog('FATAL GroqService: $userMessage. Detalles: $details');
      
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userMessage), backgroundColor: Colors.redAccent),
        );
      }
      return userMessage;

    } catch (e) {
      await logService.appendLog('ERROR GroqService (Outer catch): $e');
      return 'Error crítico: $e';
    }
  }
}
