import 'package:aikitchen/services/shared_preferences_service.dart';
import 'package:aikitchen/widgets/animated_card.dart';
import 'package:aikitchen/widgets/setting_widget.dart';
import 'package:aikitchen/widgets/text_input.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../singleton/app_singleton.dart';

class Settings extends StatefulWidget {
  Settings({super.key, this.isNotApiKeySetted = false});
  bool isNotApiKeySetted;

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool _isGeminiCardExpanded = false;
  bool _isSettingsCardExpanded = false;

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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 15,
                  children: [
                    AnimatedCard(
                      isExpanded:
                          widget.isNotApiKeySetted
                              ? true
                              : _isGeminiCardExpanded,
                      text:
                          'Gemini api key ${AppSingleton().apiKey != null ? 'aplicada' : 'no aplicada'}',
                      icon:
                          AppSingleton().apiKey == null
                              ? const Icon(Icons.api_rounded)
                              : const Icon(
                                Icons.check_circle_rounded,
                                color: Colors.green,
                              ),
                      onTap: () {
                        setState(() {
                          _isGeminiCardExpanded = !_isGeminiCardExpanded;
                        });
                      },
                      children: [
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
                        Center(
                          child: ElevatedButton.icon(
                            onPressed:
                                () => _launchUrl(
                                  'https://makersuite.google.com/app/apikey',
                                ),
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Ir a Google AI Studio'),
                          ),
                        ),
                        const SizedBox(height: 48),
                        BasicTextInput(
                          onSearch: (apiKey) {
                            setState(() {
                              AppSingleton().setApiKey(apiKey);
                            });
                            Toaster.showToast('API Key guardada');
                            Navigator.pop(context);
                          },
                          hint: 'Pega aquí tu API Key',
                          initialValue: AppSingleton().apiKey ?? '',
                          checkIcon: Icons.save_rounded,
                          padding: const EdgeInsets.all(2),
                          isInnerShadow: true,
                        ),
                      ],
                    ),
                    if (!widget.isNotApiKeySetted)
                      AnimatedCard(
                        isExpanded: _isSettingsCardExpanded,
                        text: 'Ajustes de la app',
                        icon: const Icon(Icons.settings_rounded),
                        onTap: () {
                          setState(() {
                            _isSettingsCardExpanded = !_isSettingsCardExpanded;
                          });
                        },
                        children: [
                          ScrollbarSetting(
                            initialValue: AppSingleton().numRecetas,
                            maxValue: 5,
                            divisions: 4,
                            text: '¿Cantas recetas quieres ver?',
                            onChange: (int value) {
                              setState(() {
                                AppSingleton().setNumRecetas = value;
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
                            onSave: (String value) {
                              setState(() {
                                AppSingleton().setPersonality = value;
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
}
