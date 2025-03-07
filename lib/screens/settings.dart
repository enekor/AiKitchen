import 'package:aikitchen/services/shared_preferences_service.dart';
import 'package:aikitchen/widgets/animated_card.dart';
import 'package:aikitchen/widgets/setting_widget.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../singleton/app_singleton.dart';

class ApiKeyScreen extends StatefulWidget {
  const ApiKeyScreen({super.key});

  @override
  State<ApiKeyScreen> createState() => _ApiKeyScreenState();
}

class _ApiKeyScreenState extends State<ApiKeyScreen> {
  final TextEditingController _apiKeyController = TextEditingController();

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    )) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el enlace')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AnimatedCard(
                      text: 'Gemini api key',
                      icon: Icon(Icons.api_rounded),
                      children: [
                        const Text(
                          'AI Kitchen',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),
                        const Text(
                          'Para usar la aplicación, necesitas una API Key de Google AI Studio. Sigue estos pasos:',
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        const Text('1. Ve a Google AI Studio'),
                        const SizedBox(height: 8),
                        const Text('2. Inicia sesión con tu cuenta de Google'),
                        const SizedBox(height: 8),
                        const Text('3. Ve a "Get API Key"'),
                        const SizedBox(height: 8),
                        const Text(
                          '4. Crea una nueva API Key o usa una existente',
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed:
                              () => _launchUrl(
                                'https://makersuite.google.com/app/apikey',
                              ),
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Ir a Google AI Studio'),
                        ),
                        const SizedBox(height: 48),
                        TextField(
                          controller: _apiKeyController,
                          decoration: const InputDecoration(
                            labelText: 'API Key de Gemini',
                            hintText: 'Pega aquí tu API Key',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () async {
                            if (_apiKeyController.text.isNotEmpty) {
                              await AppSingleton().setApiKey(
                                _apiKeyController.text,
                              );
                              if (context.mounted) {
                                Navigator.of(
                                  context,
                                ).pushReplacementNamed('/home');
                              }
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text('Continuar'),
                          ),
                        ),
                      ],
                    ),
                    AnimatedCard(
                      text: 'Ajustes de la app',
                      icon: Icon(Icons.settings_rounded),
                      children: [
                        ScrollbarSetting(
                          initialValue: AppSingleton().numRecetas,
                          maxValue: 5,
                          divisions: 4,
                          text: '¿Cantas recetas quieres ver?',
                          onChange: (int value) {
                            setState(() {
                              AppSingleton().numRecetas = value;
                            });
                            SharedPreferencesService.setStringValue(
                              SharedPreferencesKeys.numRecetas,
                              value.toString(),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        TextSetting(
                          initialValue: AppSingleton().personality,
                          text: '¿Qué tono de texto prefieres?',
                          onChange: (String value) {
                            setState(() {
                              AppSingleton().personality = value;
                            });
                            SharedPreferencesService.setStringValue(
                              SharedPreferencesKeys.tonoTextos,
                              value,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }
}
