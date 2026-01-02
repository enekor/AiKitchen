import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'log_file_service.dart';

class GeminiService {
  Future<String> generateContent(
    String prompt,
    String apiKey, {
    BuildContext? context,
  }) async {
    final logService = LogFileService();
    try {
      final candidateModels = [
        'gemini-1.5-flash',
        'gemini-1.5-pro',
        'gemini-2.0-flash-exp',
      ];

      final List<String> modelErrors = [];
      const int maxAttemptsPerModel = 3;
      for (final modelId in candidateModels) {
        bool modelSucceeded = false;
        for (int attempt = 0; attempt < maxAttemptsPerModel; attempt++) {
          try {
            final model = GenerativeModel(model: modelId, apiKey: apiKey);
            final content = [Content.text(prompt)];
            final response = await model.generateContent(content);
            if (response.text != null && response.text!.isNotEmpty) {
              return response.text!;
            } else {
              final errorMsg = '$modelId: respuesta vacía (attempt ${attempt + 1})';
              modelErrors.add(errorMsg);
              await logService.appendLog('ERROR GeminiService: $errorMsg');
            }
            modelSucceeded = true;
            break;
          } on GenerativeAIException catch (e) {
            final msg = e.message.toLowerCase();
            final errorMsg = '$modelId (attempt ${attempt + 1}): ${e.message}';
            modelErrors.add(errorMsg);
            await logService.appendLog('ERROR GeminiService (GenerativeAIException): $errorMsg');

            if (msg.contains('not found') || (msg.contains('model') && msg.contains('not'))) {
              break;
            }

            if (msg.contains('quota exceeded') || msg.contains('exceeded your current quota')) {
              if (context != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Has excedido tu cuota de Gemini. Cambia la API Key en Ajustes o espera a que se recarguen tus tokens.',
                    ),
                    backgroundColor: Colors.orangeAccent,
                    duration: Duration(seconds: 5),
                  ),
                );
              }
              if (msg.contains('limit: 0')) {
                break;
              }
            }

            final retryMatch = RegExp(r'please retry in\s+([0-9]+\.?[0-9]*)s').firstMatch(msg);
            if (retryMatch != null) {
              try {
                final waitSeconds = double.parse(retryMatch.group(1)!);
                final extra = min(5, attempt * 2); 
                final wait = Duration(seconds: waitSeconds.ceil() + extra);
                if (context != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Modelo $modelId ocupado. Reintentando en ${wait.inSeconds}s...')),
                  );
                }
                await Future.delayed(wait);
                continue; 
              } catch (_) {}
            }

            final backoffMs = pow(2, attempt) * 500;
            await Future.delayed(Duration(milliseconds: backoffMs.toInt()));
            continue;
          } catch (e) {
            final errorMsg = '$modelId (attempt ${attempt + 1}): $e';
            modelErrors.add(errorMsg);
            await logService.appendLog('ERROR GeminiService (Generic): $errorMsg');
            final backoffMs = pow(2, attempt) * 500;
            await Future.delayed(Duration(milliseconds: backoffMs.toInt()));
            continue;
          }
        }
        if (modelSucceeded) break;
      }

      final details = modelErrors.join(' | ');
      String userMessage = 'No se pudo generar respuesta.';
      if (details.toLowerCase().contains('quota exceeded')) {
        userMessage = 'Error: Cuota excedida. Cambia la API Key o espera a que se recarguen tus tokens.';
      } else {
        userMessage = 'No se pudo generar respuesta: ningún modelo disponible. Detalles: $details';
      }
      await logService.appendLog('FATAL GeminiService: $userMessage');
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(userMessage)));
      }
      return userMessage;
    } on GenerativeAIException catch (e) {
      await logService.appendLog('ERROR GeminiService (Outer GenerativeAIException): ${e.message}');
      return 'Error: ${e.message}';
    } catch (e) {
      await logService.appendLog('ERROR GeminiService (Outer catch): $e');
      return 'Error: $e';
    }
  }
}
