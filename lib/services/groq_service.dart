import 'dart:convert';
import 'dart:math';
import 'package:aikitchen/models/prompt.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'log_file_service.dart';

class GroqService {
  Future<String> generateContent(
    String prompt,
    String apiKey, {
    String model = 'llama-3.3-70b-versatile',
    int? maxTokens = 4096,
    BuildContext? context,
  }) async {
    final logService = LogFileService();
    const int maxAttempts = 3;
    List<String> attemptErrors = [];
    int? currentMaxTokens = maxTokens;

    try {
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

      for (int attempt = 0; attempt < maxAttempts; attempt++) {
        try {
          await logService.appendLog('INFO GroqService: Intento ${attempt + 1} enviando petición con modelo $model (maxTokens: $currentMaxTokens)...');

          final body = {
            'model': model,
            'messages': [
              {'role': 'system', 'content': Prompt.systemPrompt},
              {'role': 'user', 'content': prompt}
            ],
            'temperature': 0.1, // Mínima temperatura para evitar razonamientos
          };

          // Solo activamos modo JSON si es un modelo oficial soportado
          final officialModels = ['llama', 'mixtral', 'gemma'];
          if (officialModels.any((m) => model.toLowerCase().contains(m))) {
            body['response_format'] = {'type': 'json_object'};
          }

          if (currentMaxTokens != null) {
            body['max_tokens'] = currentMaxTokens;
          }

          final response = await http.post(
            url,
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          ).timeout(const Duration(seconds: 60));

          if (response.statusCode == 200) {
            final decodedBody = utf8.decode(response.bodyBytes, allowMalformed: true);
            
            Map<String, dynamic> data;
            try {
              data = jsonDecode(decodedBody);
            } catch (e) {
              final String lastChars = decodedBody.length > 500 
                ? '...${decodedBody.substring(decodedBody.length - 500)}' 
                : decodedBody;
              final errorMsg = 'Error JSON (Intento ${attempt + 1}). '
                  'Longitud: ${decodedBody.length}. Fin: $lastChars';
              attemptErrors.add(errorMsg);
              await logService.appendLog('ERROR GroqService: $errorMsg');

              // Recuperación de emergencia si el JSON viene envuelto en texto
              if (decodedBody.contains('"recetas"') || decodedBody.contains('"nombre"')) {
                 await logService.appendLog('INFO GroqService: Recuperación de emergencia...');
                 try {
                   int start = decodedBody.indexOf('{');
                   int end = decodedBody.lastIndexOf('}');
                   if (start != -1 && end > start) {
                     String candidate = decodedBody.substring(start, end + 1);
                     data = jsonDecode(candidate);
                     await logService.appendLog('INFO GroqService: Recuperación exitosa.');
                   } else {
                     continue;
                   }
                 } catch (_) {
                   continue;
                 }
              } else {
                continue;
              }
            }

            String content = data['choices'][0]['message']['content'] as String;

            if (content.isNotEmpty) {
              // Limpieza de seguridad adicional
              content = content.replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '');
              content = content.replaceAll(RegExp(r'```json\s*'), '');
              content = content.replaceAll(RegExp(r'```\s*'), '');
              content = content.trim();

              return content;
            } else {
              final errorMsg = 'Respuesta vacía (Intento ${attempt + 1})';
              attemptErrors.add(errorMsg);
              await logService.appendLog('ERROR GroqService: $errorMsg');
            }
          } else {
            String errorMessage = 'Error desconocido';
            try {
              final errorData = jsonDecode(response.body);
              errorMessage = errorData['error']?['message'] ?? 'Error desconocido';
            } catch (_) {
              errorMessage = 'Status ${response.statusCode}';
              if (response.body.isNotEmpty) {
                String cleanBody = response.body.replaceAll(RegExp(r'<[^>]*>'), '').trim();
                if (cleanBody.length > 100) cleanBody = '${cleanBody.substring(0, 100)}...';
                errorMessage += ': $cleanBody';
              }
            }
            
            final errorMsg = 'Error Groq (Intento ${attempt + 1}): $errorMessage';
            attemptErrors.add(errorMsg);
            await logService.appendLog('ERROR GroqService: $errorMsg');

            if (response.statusCode == 401) {
              return 'Error: API Key de Groq inválida. Por favor, revísala en Ajustes.';
            }

            if (response.statusCode == 413) {
              await logService.appendLog('WARNING GroqService: Error 413 detectado. Reintentando con menos tokens...');
              currentMaxTokens = (currentMaxTokens ?? 4000) ~/ 2;
              continue; 
            }

            if (response.statusCode == 429) {
              if (context != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Límite de velocidad excedido. Reintentando...'),
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
          await logService.appendLog('ERROR GroqService (Catch): $errorMsg');
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      final details = attemptErrors.join(' | ');
      String userMessage = 'No se pudo generar respuesta tras varios intentos.';
      
      if (details.toLowerCase().contains('rate_limit') || details.contains('429')) {
        userMessage = 'Error: Límite de velocidad excedido. Por favor, espera un poco.';
      }

      await logService.appendLog('FATAL GroqService: $userMessage. Detalles: $details');
      
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userMessage), backgroundColor: Colors.redAccent),
        );
      }
      return userMessage;

    } catch (e) {
      await logService.appendLog('ERROR GroqService (Outer): $e');
      return 'Error crítico: $e';
    }
  }
}
